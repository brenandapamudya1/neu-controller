const { app, BrowserWindow, ipcMain, clipboard, Tray, Menu, nativeImage } = require('electron');
const path = require('path');
const fs = require('fs');
const { spawn } = require('child_process');

let mainWindow = null;
let tray = null;
let serverProcess = null;
let serverStatus = {
  running: false,
  port: 9876,
  ips: [],
  dryRun: false,
  connectedClient: null,
};

function getPythonPath() {
  // Check virtual environment in server directory
  const venvPy = path.resolve(__dirname, '../../server/.venv/bin/python');
  if (fs.existsSync(venvPy)) {
    return venvPy;
  }
  return 'python3';
}

function getServerScriptPath() {
  return path.resolve(__dirname, '../../server/server.py');
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1080,
    height: 720,
    minWidth: 920,
    minHeight: 640,
    title: 'NeuController Desktop',
    backgroundColor: '#E0E5EC',
    frame: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
    },
  });

  mainWindow.loadFile(path.join(__dirname, 'renderer/index.html'));

  mainWindow.on('close', (event) => {
    // If not quitting entire app, minimize or close normally
    if (serverProcess) {
      stopServer();
    }
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

function createTray() {
  // Create 16x16 placeholder icon for tray
  const size = 16;
  const canvas = Buffer.alloc(size * size * 4);
  for (let i = 0; i < size * size; i++) {
    canvas[i * 4] = 79;     // B
    canvas[i * 4 + 1] = 138;// G
    canvas[i * 4 + 2] = 249;// R
    canvas[i * 4 + 3] = 255;// A
  }
  const icon = nativeImage.createFromBuffer(canvas, { width: size, height: size });
  tray = new Tray(icon);
  tray.setToolTip('NeuController Desktop Server');

  const contextMenu = Menu.buildFromTemplate([
    {
      label: 'Show NeuController',
      click: () => {
        if (mainWindow) {
          mainWindow.show();
          mainWindow.focus();
        }
      },
    },
    { type: 'separator' },
    {
      label: 'Start Server',
      click: () => startServer(serverStatus.port, serverStatus.dryRun),
    },
    {
      label: 'Stop Server',
      click: () => stopServer(),
    },
    { type: 'separator' },
    {
      label: 'Quit',
      click: () => {
        stopServer();
        app.quit();
      },
    },
  ]);

  tray.setContextMenu(contextMenu);
  tray.on('click', () => {
    if (mainWindow) {
      if (mainWindow.isVisible()) {
        mainWindow.hide();
      } else {
        mainWindow.show();
        mainWindow.focus();
      }
    }
  });
}

function startServer(port = 9876, dryRun = false) {
  if (serverProcess) {
    return { success: false, message: 'Server is already running' };
  }

  const pyPath = getPythonPath();
  const scriptPath = getServerScriptPath();

  const args = [scriptPath, '--port', String(port), '--json'];
  if (dryRun) {
    args.push('--dry-run');
  }

  try {
    serverProcess = spawn(pyPath, args, {
      cwd: path.resolve(__dirname, '../../server'),
      env: { ...process.env, PYTHONUNBUFFERED: '1' },
    });

    serverStatus.running = true;
    serverStatus.port = port;
    serverStatus.dryRun = dryRun;

    let buffer = '';

    serverProcess.stdout.on('data', (chunk) => {
      buffer += chunk.toString();
      const lines = buffer.split('\n');
      buffer = lines.pop(); // keep last incomplete line

      for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed) continue;
        try {
          const data = JSON.parse(trimmed);
          handleServerEvent(data);
        } catch (e) {
          if (mainWindow) {
            mainWindow.webContents.send('server-log', { text: trimmed, type: 'info' });
          }
        }
      }
    });

    serverProcess.stderr.on('data', (chunk) => {
      const text = chunk.toString().trim();
      if (!text) return;
      if (mainWindow) {
        mainWindow.webContents.send('server-log', { text, type: 'error' });
      }
    });

    serverProcess.on('error', (err) => {
      serverStatus.running = false;
      serverProcess = null;
      if (mainWindow) {
        mainWindow.webContents.send('server-error', { error: err.message });
        mainWindow.webContents.send('server-status-changed', serverStatus);
      }
    });

    serverProcess.on('close', (code) => {
      serverStatus.running = false;
      serverStatus.connectedClient = null;
      serverProcess = null;
      if (mainWindow) {
        mainWindow.webContents.send('server-stopped', { code });
        mainWindow.webContents.send('server-status-changed', serverStatus);
      }
    });

    if (mainWindow) {
      mainWindow.webContents.send('server-status-changed', serverStatus);
    }
    return { success: true };
  } catch (err) {
    return { success: false, message: err.message };
  }
}

function stopServer() {
  if (serverProcess) {
    serverProcess.kill('SIGTERM');
    setTimeout(() => {
      if (serverProcess) {
        serverProcess.kill('SIGKILL');
      }
    }, 1000);
    serverStatus.running = false;
    serverStatus.connectedClient = null;
    serverProcess = null;
    if (mainWindow) {
      mainWindow.webContents.send('server-status-changed', serverStatus);
    }
  }
  return { success: true };
}

function handleServerEvent(event) {
  if (!mainWindow) return;

  if (event.event === 'listening') {
    serverStatus.ips = event.ips || [];
    serverStatus.port = event.port;
    serverStatus.dryRun = event.dry_run;
    mainWindow.webContents.send('server-status-changed', serverStatus);
  } else if (event.event === 'client_connected') {
    serverStatus.connectedClient = event.client;
    mainWindow.webContents.send('server-status-changed', serverStatus);
  } else if (event.event === 'failsafe_reset') {
    serverStatus.connectedClient = null;
    mainWindow.webContents.send('server-status-changed', serverStatus);
  }

  // Forward event to renderer (input, ping, discovery, etc.)
  mainWindow.webContents.send('server-event', event);
}

// IPC Handlers
ipcMain.handle('start-server', (event, { port, dryRun }) => {
  return startServer(port, dryRun);
});

ipcMain.handle('stop-server', () => {
  return stopServer();
});

ipcMain.handle('get-server-status', () => {
  return serverStatus;
});

ipcMain.handle('copy-text', (event, text) => {
  clipboard.writeText(text);
  return true;
});

app.whenReady().then(() => {
  createWindow();
  createTray();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    stopServer();
    app.quit();
  }
});
