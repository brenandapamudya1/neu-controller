// NeuController Desktop Renderer

// Button bitmasks (PROJECT.md §5 & protocol.py)
const BTN_CROSS = 1 << 0;
const BTN_CIRCLE = 1 << 1;
const BTN_SQUARE = 1 << 2;
const BTN_TRIANGLE = 1 << 3;
const BTN_L1 = 1 << 4;
const BTN_R1 = 1 << 5;
const BTN_L3 = 1 << 6;
const BTN_R3 = 1 << 7;
const BTN_DPAD_UP = 1 << 8;
const BTN_DPAD_DOWN = 1 << 9;
const BTN_DPAD_LEFT = 1 << 10;
const BTN_DPAD_RIGHT = 1 << 11;
const BTN_OPTIONS = 1 << 12;
const BTN_SHARE = 1 << 13;
const BTN_HOME = 1 << 14;

// DOM Elements
const serverBtn = document.getElementById('server-btn');
const serverBtnText = document.getElementById('server-btn-text');
const serverBtnIcon = document.getElementById('server-btn-icon');
const portInput = document.getElementById('port-input');
const dryRunCheckbox = document.getElementById('dry-run-checkbox');
const statusPill = document.getElementById('status-pill');
const statusText = document.getElementById('status-text');
const primaryIpEl = document.getElementById('primary-ip');
const copyIpBtn = document.getElementById('copy-ip-btn');
const clientStatusEl = document.getElementById('client-status');
const packetCountEl = document.getElementById('packet-count');
const packetSeqEl = document.getElementById('packet-seq');
const logConsole = document.getElementById('log-console');
const clearLogBtn = document.getElementById('clear-log-btn');
const themeToggle = document.getElementById('theme-toggle');
const themeIcon = document.getElementById('theme-icon');
const lightbar = document.getElementById('lightbar');
const backendStatus = document.getElementById('backend-status');

// Button Elements Map
const buttonEls = {
  cross: document.getElementById('btn-cross'),
  circle: document.getElementById('btn-circle'),
  square: document.getElementById('btn-square'),
  triangle: document.getElementById('btn-triangle'),
  l1: document.getElementById('btn-l1'),
  r1: document.getElementById('btn-r1'),
  l3: document.getElementById('btn-l3'),
  r3: document.getElementById('btn-r3'),
  dpadUp: document.getElementById('btn-dpad-up'),
  dpadDown: document.getElementById('btn-dpad-down'),
  dpadLeft: document.getElementById('btn-dpad-left'),
  dpadRight: document.getElementById('btn-dpad-right'),
  options: document.getElementById('btn-options'),
  share: document.getElementById('btn-share'),
  home: document.getElementById('btn-home'),
};

// Sticks & Triggers
const leftStickKnob = document.getElementById('left-stick-knob');
const rightStickKnob = document.getElementById('right-stick-knob');
const leftCoordsEl = document.getElementById('left-stick-coords');
const rightCoordsEl = document.getElementById('right-stick-coords');
const fillL2 = document.getElementById('fill-l2');
const fillR2 = document.getElementById('fill-r2');
const valL2 = document.getElementById('val-l2');
const valR2 = document.getElementById('val-r2');

let isRunning = false;
let packetCount = 0;
const STICK_MAX_TRAVEL_PX = 20; // Maximum knob visual travel from center

// Theme handling
const savedTheme = localStorage.getItem('neu-theme') || 'light';
setTheme(savedTheme);

themeToggle.addEventListener('click', () => {
  const current = document.body.classList.contains('dark') ? 'dark' : 'light';
  const next = current === 'dark' ? 'light' : 'dark';
  setTheme(next);
});

function setTheme(theme) {
  if (theme === 'dark') {
    document.body.classList.remove('light');
    document.body.classList.add('dark');
    themeIcon.textContent = '☀️';
  } else {
    document.body.classList.remove('dark');
    document.body.classList.add('light');
    themeIcon.textContent = '🌙';
  }
  localStorage.setItem('neu-theme', theme);
}

// Log utility
function appendLog(text, type = 'info') {
  const entry = document.createElement('div');
  entry.className = `log-entry ${type}`;
  const time = new Date().toLocaleTimeString();
  entry.textContent = `[${time}] ${text}`;
  logConsole.appendChild(entry);
  logConsole.scrollTop = logConsole.scrollHeight;
}

clearLogBtn.addEventListener('click', () => {
  logConsole.innerHTML = '';
});

// Copy IP button
copyIpBtn.addEventListener('click', async () => {
  const ip = primaryIpEl.textContent.trim();
  if (ip) {
    await window.api.copyText(ip);
    copyIpBtn.textContent = '✅ Copied!';
    setTimeout(() => {
      copyIpBtn.textContent = '📋 Copy';
    }, 1500);
  }
});

// Server Button Toggle
serverBtn.addEventListener('click', async () => {
  if (!isRunning) {
    const port = parseInt(portInput.value, 10) || 9876;
    const dryRun = dryRunCheckbox.checked;
    appendLog(`Starting server on port ${port} (dryRun=${dryRun})...`);
    serverBtn.disabled = true;
    const res = await window.api.startServer(port, dryRun);
    serverBtn.disabled = false;
    if (!res.success) {
      appendLog(`Failed to start server: ${res.message}`, 'error');
    }
  } else {
    appendLog('Stopping server...');
    serverBtn.disabled = true;
    await window.api.stopServer();
    serverBtn.disabled = false;
  }
});

// UI State update
function updateServerUI(status) {
  isRunning = status.running;
  if (isRunning) {
    statusPill.className = 'status-pill running';
    statusText.textContent = `Running :${status.port}`;
    serverBtn.className = 'neu-btn danger big-btn';
    serverBtnIcon.textContent = '⏹';
    serverBtnText.textContent = 'Stop Server';
    portInput.disabled = true;
    dryRunCheckbox.disabled = true;

    backendStatus.textContent = status.dryRun ? 'Logging (Dry Run)' : 'uinput (PadLink)';

    if (status.ips && status.ips.length > 0) {
      primaryIpEl.textContent = status.ips[0];
      appendLog(`Server listening. Local IP: ${status.ips.join(', ')}`, 'success');
    }
  } else {
    statusPill.className = 'status-pill stopped';
    statusText.textContent = 'Server Stopped';
    serverBtn.className = 'neu-btn primary big-btn';
    serverBtnIcon.textContent = '▶';
    serverBtnText.textContent = 'Start Server';
    portInput.disabled = false;
    dryRunCheckbox.disabled = false;
    lightbar.className = 'lightbar';
    clientStatusEl.textContent = 'None';
  }

  if (status.connectedClient) {
    clientStatusEl.textContent = status.connectedClient;
    lightbar.className = 'lightbar connected';
  }
}

// Controller Visualizer Update
function updateControllerState(input) {
  packetCount++;
  packetCountEl.textContent = packetCount;
  packetSeqEl.textContent = input.seq ?? '-';

  const mask = input.buttons || 0;

  // Toggle button active classes
  buttonEls.cross?.classList.toggle('active', Boolean(mask & BTN_CROSS));
  buttonEls.circle?.classList.toggle('active', Boolean(mask & BTN_CIRCLE));
  buttonEls.square?.classList.toggle('active', Boolean(mask & BTN_SQUARE));
  buttonEls.triangle?.classList.toggle('active', Boolean(mask & BTN_TRIANGLE));

  buttonEls.l1?.classList.toggle('active', Boolean(mask & BTN_L1));
  buttonEls.r1?.classList.toggle('active', Boolean(mask & BTN_R1));
  buttonEls.l3?.classList.toggle('active', Boolean(mask & BTN_L3));
  buttonEls.r3?.classList.toggle('active', Boolean(mask & BTN_R3));

  buttonEls.dpadUp?.classList.toggle('active', Boolean(mask & BTN_DPAD_UP));
  buttonEls.dpadDown?.classList.toggle('active', Boolean(mask & BTN_DPAD_DOWN));
  buttonEls.dpadLeft?.classList.toggle('active', Boolean(mask & BTN_DPAD_LEFT));
  buttonEls.dpadRight?.classList.toggle('active', Boolean(mask & BTN_DPAD_RIGHT));

  buttonEls.options?.classList.toggle('active', Boolean(mask & BTN_OPTIONS));
  buttonEls.share?.classList.toggle('active', Boolean(mask & BTN_SHARE));
  buttonEls.home?.classList.toggle('active', Boolean(mask & BTN_HOME));

  // Analog Sticks (-127..127)
  const lx = input.lx ?? 0;
  const ly = input.ly ?? 0;
  const rx = input.rx ?? 0;
  const ry = input.ry ?? 0;

  const leftNormX = lx / 127;
  const leftNormY = ly / 127;
  const rightNormX = rx / 127;
  const rightNormY = ry / 127;

  leftStickKnob.style.transform = `translate(${leftNormX * STICK_MAX_TRAVEL_PX}px, ${leftNormY * STICK_MAX_TRAVEL_PX}px)`;
  rightStickKnob.style.transform = `translate(${rightNormX * STICK_MAX_TRAVEL_PX}px, ${rightNormY * STICK_MAX_TRAVEL_PX}px)`;

  leftStickKnob.classList.toggle('active', Boolean(mask & BTN_L3));
  rightStickKnob.classList.toggle('active', Boolean(mask & BTN_R3));

  leftCoordsEl.textContent = `LX: ${lx}, LY: ${ly}`;
  rightCoordsEl.textContent = `RX: ${rx}, RY: ${ry}`;

  // Triggers (0..255)
  const l2 = input.l2 ?? 0;
  const r2 = input.r2 ?? 0;

  valL2.textContent = l2;
  valR2.textContent = r2;
  fillL2.style.width = `${(l2 / 255) * 100}%`;
  fillR2.style.width = `${(r2 / 255) * 100}%`;
}

// Reset controller visualizer to center/neutral
function resetController() {
  for (const el of Object.values(buttonEls)) {
    el?.classList.remove('active');
  }
  leftStickKnob.style.transform = 'translate(0px, 0px)';
  rightStickKnob.style.transform = 'translate(0px, 0px)';
  leftCoordsEl.textContent = 'LX: 0, LY: 0';
  rightCoordsEl.textContent = 'RX: 0, RY: 0';
  valL2.textContent = '0';
  valR2.textContent = '0';
  fillL2.style.width = '0%';
  fillR2.style.width = '0%';
  lightbar.className = isRunning ? 'lightbar' : 'lightbar';
}

// Event Listeners from Preload IPC
window.api.onServerStatusChanged((status) => {
  updateServerUI(status);
});

window.api.onServerEvent((data) => {
  if (data.event === 'input') {
    updateControllerState(data);
  } else if (data.event === 'client_connected') {
    appendLog(`Mobile connected from ${data.client}:${data.port}`, 'success');
    clientStatusEl.textContent = `${data.client}:${data.port}`;
    lightbar.className = 'lightbar connected';
  } else if (data.event === 'failsafe_reset') {
    appendLog('Failsafe triggered: No packet for 500ms, resetting controller inputs', 'info');
    resetController();
    clientStatusEl.textContent = 'Disconnected (Idle)';
    lightbar.className = 'lightbar';
  } else if (data.event === 'ping') {
    // Ping probe received
  }
});

window.api.onServerLog((data) => {
  appendLog(data.text, data.type || 'info');
});

window.api.onServerError((data) => {
  appendLog(`Server Error: ${data.error}`, 'error');
});

window.api.onServerStopped((data) => {
  appendLog(`Server process exited (code: ${data.code})`, 'info');
  resetController();
});

// Initial Status Query
window.api.getServerStatus().then((status) => {
  updateServerUI(status);
});
