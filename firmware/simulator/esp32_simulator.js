#!/usr/bin/env node

/**
 * ============================================================================
 * HAVEN SMART HOME - VIRTUAL ESP32 HARDWARE SIMULATOR
 * ============================================================================
 * 
 * This script simulates the real ESP32 microcontroller with:
 * - 3 Relays (GPIO 26, 27, 14) controlling appliances
 * - 3 Debounced Physical Wall Switches (GPIO 34, 35, 32)
 * - WiFi connection & IP address management
 * - State reporting and command listener (HTTP & Firestore)
 * 
 * Works out-of-the-box with Node.js (v18+) without requiring external libraries.
 */

const http = require('http');
const readline = require('readline');

// --- SIMULATED HARDWARE CONFIGURATION ---
const HARDWARE = {
  deviceId: 'esp32-haven-dev-01',
  firmwareVersion: '1.0.0',
  macAddress: '24:0A:C4:B8:12:34',
  wifiSSID: 'Haven-WiFi-2.4GHz',
  localIP: '192.168.1.105',
  rssi: -52,
  wifiConnected: true,
  port: 8088,
  relays: [
    { channel: 0, pin: 26, name: 'Relay 1 (Living Room Light)', state: false },
    { channel: 1, pin: 27, name: 'Relay 2 (Bedroom Fan)', state: false },
    { channel: 2, pin: 14, name: 'Relay 3 (Kitchen Geyser)', state: false },
  ],
  switches: [
    { channel: 0, pin: 34, label: 'Wall Switch 1' },
    { channel: 1, pin: 35, label: 'Wall Switch 2' },
    { channel: 2, pin: 32, label: 'Wall Switch 3' },
  ]
};

// --- TERMINAL COLORS ---
const C = {
  reset: '\x1b[0m',
  bold: '\x1b[1m',
  cyan: '\x1b[36m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  red: '\x1b[31m',
  gray: '\x1b[90m',
  bgBlue: '\x1b[44m',
  bgGreen: '\x1b[42m',
};

function logSerial(msg) {
  const ts = new Date().toISOString().split('T')[1].replace('Z', '');
  console.log(`${C.gray}[${ts}]${C.reset} ${msg}`);
}

function printStatusDashboard() {
  console.log(`\n${C.cyan}${C.bold}┌────────────────────────────────────────────────────────┐${C.reset}`);
  console.log(`${C.cyan}${C.bold}│        HAVEN ESP32 HARDWARE DASHBOARD                  │${C.reset}`);
  console.log(`${C.cyan}${C.bold}├────────────────────────────────────────────────────────┤${C.reset}`);
  console.log(`│ Device ID : ${C.bold}${HARDWARE.deviceId}${C.reset.padEnd(20)} Firmware: v${HARDWARE.firmwareVersion} │`);
  console.log(`│ WiFi Status: ${HARDWARE.wifiConnected ? `${C.green}● CONNECTED${C.reset}` : `${C.red}○ DISCONNECTED${C.reset}`} SSID: ${HARDWARE.wifiSSID.padEnd(16)} │`);
  console.log(`│ IP Address: ${C.bold}${HARDWARE.localIP}${C.reset.padEnd(16)} RSSI: ${HARDWARE.rssi} dBm       │`);
  console.log(`│ Listener  : ${C.green}http://localhost:${HARDWARE.port}${C.reset.padEnd(25)} │`);
  console.log(`${C.cyan}${C.bold}├────────────────────────────────────────────────────────┤${C.reset}`);
  console.log(`│ ${C.bold}RELAY OUTPUT CHANNELS:${C.reset.padEnd(50)}│`);
  
  HARDWARE.relays.forEach(r => {
    const badge = r.state 
      ? `${C.green}${C.bold}[ ON  ● ]${C.reset}` 
      : `${C.gray}[ OFF ○ ]${C.reset}`;
    console.log(`│  Ch ${r.channel} (GPIO ${r.pin}): ${badge}  ${r.name.padEnd(28)}│`);
  });

  console.log(`${C.cyan}${C.bold}├────────────────────────────────────────────────────────┤${C.reset}`);
  console.log(`│ ${C.yellow}KEYBOARD CONTROLS (Simulate Physical Wall Switches):${C.reset.padEnd(21)}│`);
  console.log(`│  [1] Flip Wall Switch 1 (GPIO 34 -> Toggles Relay 1) │`);
  console.log(`│  [2] Flip Wall Switch 2 (GPIO 35 -> Toggles Relay 2) │`);
  console.log(`│  [3] Flip Wall Switch 3 (GPIO 32 -> Toggles Relay 3) │`);
  console.log(`│  [s] Refresh Status    [w] Toggle WiFi   [q] Exit     │`);
  console.log(`${C.cyan}${C.bold}└────────────────────────────────────────────────────────┘${C.reset}\n`);
}

function setRelay(channelIndex, state, source = 'App') {
  const relay = HARDWARE.relays[channelIndex];
  if (!relay) return;

  const previousState = relay.state;
  relay.state = state;

  const stateStr = state ? `${C.green}${C.bold}ON  [HIGH]${C.reset}` : `${C.yellow}OFF [LOW]${C.reset}`;
  console.log(`\n⚡ ${C.bold}[ESP32 HARDWARE EVENT]${C.reset}`);
  console.log(`   Source : ${C.cyan}${source}${C.reset}`);
  console.log(`   Channel: ${relay.channel} (GPIO ${relay.pin}) - ${relay.name}`);
  console.log(`   Action : ${previousState ? 'ON' : 'OFF'} ➔ ${stateStr}`);
  console.log(`   Time   : ${new Date().toLocaleTimeString()}\n`);
}

function toggleSwitch(channelIndex) {
  const sw = HARDWARE.switches[channelIndex];
  const relay = HARDWARE.relays[channelIndex];
  if (!sw || !relay) return;

  console.log(`\n🔘 ${C.yellow}${C.bold}[WALL SWITCH PRESSED]${C.reset} ${sw.label} on GPIO ${sw.pin} (Debounce 50ms)`);
  setRelay(channelIndex, !relay.state, 'Physical Wall Switch');
}

// --- HTTP SERVER TO RECEIVE COMMANDS FROM FLUTTER APP ---
const server = http.createServer((req, res) => {
  // CORS Headers for Flutter Web / Chrome
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  // Health check endpoint
  if (req.method === 'GET' && (req.url === '/health' || req.url === '/api/devices/status')) {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({
      status: 'ok',
      device: HARDWARE,
      timestamp: new Date().toISOString(),
    }));
    return;
  }

  // Command execution endpoint
  if (req.method === 'POST' && req.url === '/api/commands') {
    let body = '';
    req.on('data', chunk => { body += chunk; });
    req.on('end', () => {
      try {
        const payload = JSON.parse(body || '{}');
        const action = (payload.action || 'off').toLowerCase();
        const targetState = action === 'on';

        // Match channel index
        let channelIndex = 0;
        if (payload.channelId !== undefined) {
          const num = parseInt(payload.channelId.replace(/\D/g, ''), 10);
          if (!isNaN(num) && num >= 0 && num < HARDWARE.relays.length) {
            channelIndex = num;
          }
        }

        setRelay(channelIndex, targetState, 'Flutter App Command');

        const commandId = 'cmd_' + Date.now();
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
          status: 'succeeded',
          commandId: commandId,
          correlationId: payload.idempotencyKey || commandId,
          channel: channelIndex,
          action: targetState ? 'on' : 'off',
          timestamp: new Date().toISOString(),
        }));
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON', message: err.message }));
      }
    });
    return;
  }

  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Not found' }));
});

// --- BOOT SEQUENCE ---
console.clear();
console.log(`${C.cyan}${C.bold}[HAVEN ESP32] Booting firmware v${HARDWARE.firmwareVersion}...${C.reset}`);
setTimeout(() => logSerial(`Device UUID: ${HARDWARE.deviceId}`), 200);
setTimeout(() => logSerial(`RelayController initialized. Active low: false, Safe startup: ALL OFF`), 400);
setTimeout(() => logSerial(`SwitchHandler initialized (GPIOs: 34, 35, 32)`), 600);
setTimeout(() => logSerial(`Connecting to WiFi SSID: ${HARDWARE.wifiSSID} ............`), 800);
setTimeout(() => {
  logSerial(`${C.green}WiFi connected! Local IP: ${HARDWARE.localIP}, RSSI: ${HARDWARE.rssi} dBm${C.reset}`);
  logSerial(`SNTP time synchronization complete (UTC)`);

  server.listen(HARDWARE.port, () => {
    logSerial(`${C.green}${C.bold}ESP32 listening for commands on port ${HARDWARE.port}${C.reset}`);
    printStatusDashboard();
  });
}, 1200);

// --- INTERACTIVE KEYBOARD INPUT ---
readline.emitKeypressEvents(process.stdin);
if (process.stdin.isTTY) {
  process.stdin.setRawMode(true);
}

process.stdin.on('keypress', (str, key) => {
  if (key.ctrl && key.name === 'c' || key.name === 'q') {
    console.log(`\n[HAVEN ESP32] Powering down. Goodbye!\n`);
    process.exit(0);
  }

  switch (str) {
    case '1':
      toggleSwitch(0);
      break;
    case '2':
      toggleSwitch(1);
      break;
    case '3':
      toggleSwitch(2);
      break;
    case 's':
    case 'S':
      printStatusDashboard();
      break;
    case 'w':
    case 'W':
      HARDWARE.wifiConnected = !HARDWARE.wifiConnected;
      console.log(`\n📶 WiFi status changed: ${HARDWARE.wifiConnected ? `${C.green}CONNECTED${C.reset}` : `${C.red}DISCONNECTED${C.reset}`}`);
      break;
  }
});
