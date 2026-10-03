const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('api', {
  startServer: (port, dryRun) => ipcRenderer.invoke('start-server', { port, dryRun }),
  stopServer: () => ipcRenderer.invoke('stop-server'),
  getServerStatus: () => ipcRenderer.invoke('get-server-status'),
  copyText: (text) => ipcRenderer.invoke('copy-text', text),

  onServerStatusChanged: (callback) => {
    const subscription = (event, data) => callback(data);
    ipcRenderer.on('server-status-changed', subscription);
    return () => ipcRenderer.removeListener('server-status-changed', subscription);
  },

  onServerEvent: (callback) => {
    const subscription = (event, data) => callback(data);
    ipcRenderer.on('server-event', subscription);
    return () => ipcRenderer.removeListener('server-event', subscription);
  },

  onServerLog: (callback) => {
    const subscription = (event, data) => callback(data);
    ipcRenderer.on('server-log', subscription);
    return () => ipcRenderer.removeListener('server-log', subscription);
  },

  onServerError: (callback) => {
    const subscription = (event, data) => callback(data);
    ipcRenderer.on('server-error', subscription);
    return () => ipcRenderer.removeListener('server-error', subscription);
  },

  onServerStopped: (callback) => {
    const subscription = (event, data) => callback(data);
    ipcRenderer.on('server-stopped', subscription);
    return () => ipcRenderer.removeListener('server-stopped', subscription);
  },
});
