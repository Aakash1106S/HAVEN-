#include <WiFi.h>
#include <WebServer.h>
#include <time.h>
#include <Preferences.h>

// ─── ESP32 Hotspot Details ──────────────────────────────────────────────────
const char* ssid = "ESP32_Relay";
const char* password = "12345678";

// ─── Relay GPIO Pins ────────────────────────────────────────────────────────
const int relay1 = 25;
const int relay2 = 26;
const int relay3 = 27;

// Most 5V relay modules are active LOW
const int RELAY_ON = LOW;
const int RELAY_OFF = HIGH;

WebServer server(80);

bool state1 = false;
bool state2 = false;
bool state3 = false;

// ─── Schedules & Timers ─────────────────────────────────────────────────────
#define MAX_SCHEDULES 12

struct Schedule {
  int id;
  int relay;      // 1, 2, or 3
  bool turnOn;    // true = ON, false = OFF
  int hour;       // 0-23
  int minute;     // 0-59
  uint8_t days;   // Bitmask: bit 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat (127=Every day)
  bool enabled;
};

Schedule schedules[MAX_SCHEDULES];
int scheduleCount = 0;
Preferences prefs;
bool timeSynced = false;
int lastFiredMinute = -1;
int lastFiredDay = -1;
unsigned long lastLoopSec = 0;

struct CountdownTimer {
  bool active;
  int relay;
  bool turnOn;
  unsigned long endMillis;
  int totalSeconds;
};

CountdownTimer timers[3]; // for relay 1, 2, 3

// ─── Hardware Helper ────────────────────────────────────────────────────────
void setRelayHardware(int relay, bool turnOn) {
  if (relay == 1) {
    state1 = turnOn;
    digitalWrite(relay1, state1 ? RELAY_ON : RELAY_OFF);
  } else if (relay == 2) {
    state2 = turnOn;
    digitalWrite(relay2, state2 ? RELAY_ON : RELAY_OFF);
  } else if (relay == 3) {
    state3 = turnOn;
    digitalWrite(relay3, state3 ? RELAY_ON : RELAY_OFF);
  }
}

// ─── NVS Flash Storage for Schedules ────────────────────────────────────────
void loadSchedules() {
  prefs.begin("haven_sched", false);
  scheduleCount = prefs.getInt("count", 0);
  if (scheduleCount > MAX_SCHEDULES) scheduleCount = MAX_SCHEDULES;
  for (int i = 0; i < scheduleCount; i++) {
    String prefix = "s" + String(i) + "_";
    schedules[i].id = prefs.getInt((prefix + "id").c_str(), i + 1);
    schedules[i].relay = prefs.getInt((prefix + "r").c_str(), 1);
    schedules[i].turnOn = prefs.getBool((prefix + "on").c_str(), true);
    schedules[i].hour = prefs.getInt((prefix + "h").c_str(), 0);
    schedules[i].minute = prefs.getInt((prefix + "m").c_str(), 0);
    schedules[i].days = (uint8_t)prefs.getInt((prefix + "d").c_str(), 127);
    schedules[i].enabled = prefs.getBool((prefix + "en").c_str(), true);
  }
  prefs.end();
  Serial.printf("[HAVEN] Loaded %d schedules from flash\n", scheduleCount);
}

void saveSchedules() {
  prefs.begin("haven_sched", false);
  prefs.putInt("count", scheduleCount);
  for (int i = 0; i < scheduleCount; i++) {
    String prefix = "s" + String(i) + "_";
    prefs.putInt((prefix + "id").c_str(), schedules[i].id);
    prefs.putInt((prefix + "r").c_str(), schedules[i].relay);
    prefs.putBool((prefix + "on").c_str(), schedules[i].turnOn);
    prefs.putInt((prefix + "h").c_str(), schedules[i].hour);
    prefs.putInt((prefix + "m").c_str(), schedules[i].minute);
    prefs.putInt((prefix + "d").c_str(), schedules[i].days);
    prefs.putBool((prefix + "en").c_str(), schedules[i].enabled);
  }
  prefs.end();
  Serial.printf("[HAVEN] Saved %d schedules to flash\n", scheduleCount);
}

// ─── HTML Web Page (For Browser at http://192.168.4.1) ──────────────────────
String webpage() {
  String html = R"rawliteral(
  <!DOCTYPE html>
  <html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>ESP32 Relay Control</title>
    <style>
      body {
        font-family: Arial, sans-serif;
        text-align: center;
        background: #1a1b2e;
        color: #e8edf2;
        padding: 20px;
        margin: 0;
      }
      h2 { color: #00b4a0; margin-bottom: 5px; }
      p.sub { color: #8892a4; margin-top: 0; }
      .card {
        background: #16213e;
        padding: 20px;
        margin: 15px auto;
        max-width: 350px;
        border-radius: 14px;
        box-shadow: 0 4px 12px rgba(0,0,0,0.3);
      }
      .status { font-weight: bold; font-size: 16px; margin: 10px 0; }
      .status-on { color: #00b4a0; }
      .status-off { color: #8892a4; }
      button {
        padding: 12px 28px;
        border: none;
        border-radius: 8px;
        color: white;
        font-size: 16px;
        font-weight: bold;
        cursor: pointer;
        width: 100%;
        transition: 0.2s;
      }
      .on { background: #00b4a0; }
      .off { background: #e94560; }
      .footer { color: #8892a4; font-size: 12px; margin-top: 25px; }
    </style>
  </head>
  <body>
    <h2>Haven • ESP32 Control</h2>
    <p class="sub">Direct Wi-Fi Hotspot Mode (192.168.4.1)</p>
  )rawliteral";

  html += "<div class='card'><h3>Relay 1 (GPIO 25)</h3>";
  html += "<p class='status'>Status: <span class='" + String(state1 ? "status-on" : "status-off") + "'>" + String(state1 ? "ON" : "OFF") + "</span></p>";
  html += "<a href='/toggle?relay=1'><button class='";
  html += state1 ? "off" : "on";
  html += "'>";
  html += state1 ? "Turn OFF" : "Turn ON";
  html += "</button></a></div>";

  html += "<div class='card'><h3>Relay 2 (GPIO 26)</h3>";
  html += "<p class='status'>Status: <span class='" + String(state2 ? "status-on" : "status-off") + "'>" + String(state2 ? "ON" : "OFF") + "</span></p>";
  html += "<a href='/toggle?relay=2'><button class='";
  html += state2 ? "off" : "on";
  html += "'>";
  html += state2 ? "Turn OFF" : "Turn ON";
  html += "</button></a></div>";

  html += "<div class='card'><h3>Relay 3 (GPIO 27)</h3>";
  html += "<p class='status'>Status: <span class='" + String(state3 ? "status-on" : "status-off") + "'>" + String(state3 ? "ON" : "OFF") + "</span></p>";
  html += "<a href='/toggle?relay=3'><button class='";
  html += state3 ? "off" : "on";
  html += "'>";
  html += state3 ? "Turn OFF" : "Turn ON";
  html += "</button></a></div>";

  html += "<p class='footer'>Haven Smart Home • Offline AP Mode</p>";
  html += "</body></html>";
  return html;
}

// ─── Browser Root Handler ───────────────────────────────────────────────────
void handleRoot() {
  server.send(200, "text/html", webpage());
}

// ─── Browser Toggle Handler (Redirects to /) ────────────────────────────────
void handleToggle() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  if (server.hasArg("relay")) {
    int relay = server.arg("relay").toInt();
    if (relay == 1) setRelayHardware(1, !state1);
    else if (relay == 2) setRelayHardware(2, !state2);
    else if (relay == 3) setRelayHardware(3, !state3);
  }
  server.sendHeader("Location", "/");
  server.send(303);
}

// ─── JSON API: Get Current Status (For Haven App) ───────────────────────────
void handleApiStatus() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String json = "{\"relays\":[";
  json += "{\"channel\":1,\"state\":\"" + String(state1 ? "on" : "off") + "\",\"pin\":25},";
  json += "{\"channel\":2,\"state\":\"" + String(state2 ? "on" : "off") + "\",\"pin\":26},";
  json += "{\"channel\":3,\"state\":\"" + String(state3 ? "on" : "off") + "\",\"pin\":27}";
  json += "],\"timeSynced\":" + String(timeSynced ? "true" : "false");
  json += "}";
  server.send(200, "application/json", json);
}

// ─── JSON API: Set / Toggle Relay (For Haven App) ───────────────────────────
void handleApiSet() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  if (!server.hasArg("relay")) {
    server.send(400, "application/json", "{\"error\":\"Missing relay parameter\"}");
    return;
  }

  int relay = server.arg("relay").toInt();
  bool turnOn = true;

  if (server.hasArg("state")) {
    String s = server.arg("state");
    s.toLowerCase();
    turnOn = (s == "on" || s == "1" || s == "true");
  } else {
    if (relay == 1) turnOn = !state1;
    else if (relay == 2) turnOn = !state2;
    else if (relay == 3) turnOn = !state3;
  }

  setRelayHardware(relay, turnOn);

  String json = "{\"relay\":" + String(relay) + ",\"state\":\"" + String(turnOn ? "on" : "off") + "\",\"success\":true}";
  server.send(200, "application/json", json);
}

// ─── JSON API: Set All Relays (ALL ON / ALL OFF) ────────────────────────────
void handleApiAll() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  bool turnOn = true;
  if (server.hasArg("state")) {
    String s = server.arg("state");
    s.toLowerCase();
    turnOn = (s == "on" || s == "1" || s == "true");
  }
  setRelayHardware(1, turnOn);
  setRelayHardware(2, turnOn);
  setRelayHardware(3, turnOn);
  server.send(200, "application/json", "{\"all\":\"" + String(turnOn ? "on" : "off") + "\",\"success\":true}");
}

// ─── JSON API: Sync Time from Phone ─────────────────────────────────────────
void handleApiTime() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  if (server.hasArg("epoch")) {
    time_t epoch = (time_t)server.arg("epoch").toInt();
    int tz = server.hasArg("tz_offset") ? server.arg("tz_offset").toInt() : 0;
    time_t local = epoch + tz;
    struct timeval tv = { local, 0 };
    settimeofday(&tv, NULL);
    timeSynced = true;
    Serial.printf("[HAVEN] Time synchronized from phone: epoch=%ld\n", (long)local);
  }

  time_t nowSec = time(NULL);
  struct tm* t = localtime(&nowSec);
  char buf[32];
  strftime(buf, sizeof(buf), "%Y-%m-%d %H:%M:%S", t);

  String json = "{\"synced\":" + String(timeSynced ? "true" : "false") +
                ",\"time\":\"" + String(buf) +
                "\",\"epoch\":" + String((unsigned long)nowSec) + "}";
  server.send(200, "application/json", json);
}

// ─── JSON API: Get Schedules and Active Timers ──────────────────────────────
void handleApiSchedules() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  time_t nowSec = time(NULL);
  struct tm* t = localtime(&nowSec);
  char timeBuf[10];
  strftime(timeBuf, sizeof(timeBuf), "%H:%M", t);

  String json = "{";
  json += "\"timeSynced\":" + String(timeSynced ? "true" : "false") + ",";
  json += "\"currentTime\":\"" + String(timeBuf) + "\",";
  json += "\"schedules\":[";
  for (int i = 0; i < scheduleCount; i++) {
    if (i > 0) json += ",";
    char tBuf[10];
    snprintf(tBuf, sizeof(tBuf), "%02d:%02d", schedules[i].hour, schedules[i].minute);
    json += "{\"id\":" + String(schedules[i].id) + ",";
    json += "\"relay\":" + String(schedules[i].relay) + ",";
    json += "\"action\":\"" + String(schedules[i].turnOn ? "on" : "off") + "\",";
    json += "\"time\":\"" + String(tBuf) + "\",";
    json += "\"hour\":" + String(schedules[i].hour) + ",";
    json += "\"minute\":" + String(schedules[i].minute) + ",";
    json += "\"days\":" + String(schedules[i].days) + ",";
    json += "\"enabled\":" + String(schedules[i].enabled ? "true" : "false") + "}";
  }
  json += "],\"timers\":[";
  unsigned long curMs = millis();
  bool firstT = true;
  for (int r = 0; r < 3; r++) {
    if (timers[r].active) {
      if (!firstT) json += ",";
      firstT = false;
      int remainingSec = (long)(timers[r].endMillis - curMs) / 1000;
      if (remainingSec < 0) remainingSec = 0;
      json += "{\"relay\":" + String(timers[r].relay) + ",";
      json += "\"action\":\"" + String(timers[r].turnOn ? "on" : "off") + "\",";
      json += "\"remaining\":" + String(remainingSec) + ",";
      json += "\"total\":" + String(timers[r].totalSeconds) + "}";
    }
  }
  json += "]}";
  server.send(200, "application/json", json);
}

// ─── JSON API: Add or Edit Schedule ─────────────────────────────────────────
void handleApiScheduleAdd() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  if (!server.hasArg("relay") || !server.hasArg("time")) {
    server.send(400, "application/json", "{\"error\":\"Missing relay or time parameter\"}");
    return;
  }

  int relay = server.arg("relay").toInt();
  String action = server.hasArg("action") ? server.arg("action") : "on";
  bool turnOn = (action == "on" || action == "1" || action == "true");

  String timeStr = server.arg("time"); // e.g. "06:30"
  int colonIdx = timeStr.indexOf(':');
  int hour = 0, minute = 0;
  if (colonIdx > 0) {
    hour = timeStr.substring(0, colonIdx).toInt();
    minute = timeStr.substring(colonIdx + 1).toInt();
  }

  uint8_t days = 127; // default 127 = every day
  if (server.hasArg("days")) {
    days = (uint8_t)server.arg("days").toInt();
  }

  bool enabled = true;
  if (server.hasArg("enabled")) {
    String en = server.arg("enabled");
    enabled = (en == "true" || en == "1");
  }

  int schedId = server.hasArg("id") ? server.arg("id").toInt() : 0;
  int foundIdx = -1;
  if (schedId > 0) {
    for (int i = 0; i < scheduleCount; i++) {
      if (schedules[i].id == schedId) {
        foundIdx = i;
        break;
      }
    }
  }

  if (foundIdx >= 0) {
    schedules[foundIdx].relay = relay;
    schedules[foundIdx].turnOn = turnOn;
    schedules[foundIdx].hour = hour;
    schedules[foundIdx].minute = minute;
    schedules[foundIdx].days = days;
    schedules[foundIdx].enabled = enabled;
  } else {
    if (scheduleCount >= MAX_SCHEDULES) {
      server.send(400, "application/json", "{\"error\":\"Max schedules reached (limit 12)\"}");
      return;
    }
    schedId = (int)(millis() % 100000) + 1;
    schedules[scheduleCount].id = schedId;
    schedules[scheduleCount].relay = relay;
    schedules[scheduleCount].turnOn = turnOn;
    schedules[scheduleCount].hour = hour;
    schedules[scheduleCount].minute = minute;
    schedules[scheduleCount].days = days;
    schedules[scheduleCount].enabled = enabled;
    scheduleCount++;
  }

  saveSchedules();
  server.send(200, "application/json", "{\"success\":true,\"id\":" + String(schedId) + "}");
}

// ─── JSON API: Delete Schedule ──────────────────────────────────────────────
void handleApiScheduleDelete() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  if (!server.hasArg("id")) {
    server.send(400, "application/json", "{\"error\":\"Missing id parameter\"}");
    return;
  }

  int id = server.arg("id").toInt();
  int foundIdx = -1;
  for (int i = 0; i < scheduleCount; i++) {
    if (schedules[i].id == id) {
      foundIdx = i;
      break;
    }
  }

  if (foundIdx >= 0) {
    for (int i = foundIdx; i < scheduleCount - 1; i++) {
      schedules[i] = schedules[i + 1];
    }
    scheduleCount--;
    saveSchedules();
    server.send(200, "application/json", "{\"success\":true}");
  } else {
    server.send(404, "application/json", "{\"error\":\"Schedule not found\"}");
  }
}

// ─── JSON API: Toggle Schedule Enable / Disable ─────────────────────────────
void handleApiScheduleToggle() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  if (!server.hasArg("id")) {
    server.send(400, "application/json", "{\"error\":\"Missing id parameter\"}");
    return;
  }

  int id = server.arg("id").toInt();
  for (int i = 0; i < scheduleCount; i++) {
    if (schedules[i].id == id) {
      if (server.hasArg("enabled")) {
        String en = server.arg("enabled");
        schedules[i].enabled = (en == "true" || en == "1");
      } else {
        schedules[i].enabled = !schedules[i].enabled;
      }
      saveSchedules();
      server.send(200, "application/json", "{\"success\":true,\"enabled\":" + String(schedules[i].enabled ? "true" : "false") + "}");
      return;
    }
  }
  server.send(404, "application/json", "{\"error\":\"Schedule not found\"}");
}

// ─── JSON API: Countdown Timer (e.g. Turn OFF in 30 minutes) ────────────────
void handleApiTimer() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  if (!server.hasArg("relay")) {
    server.send(400, "application/json", "{\"error\":\"Missing relay parameter\"}");
    return;
  }

  int relay = server.arg("relay").toInt();
  if (relay < 1 || relay > 3) {
    server.send(400, "application/json", "{\"error\":\"Invalid relay (must be 1, 2, or 3)\"}");
    return;
  }

  String action = server.hasArg("action") ? server.arg("action") : "off";
  if (action == "cancel") {
    timers[relay - 1].active = false;
    server.send(200, "application/json", "{\"success\":true,\"cancelled\":true}");
    return;
  }

  int minutes = server.hasArg("minutes") ? server.arg("minutes").toInt() : 0;
  int seconds = server.hasArg("seconds") ? server.arg("seconds").toInt() : (minutes * 60);

  if (seconds <= 0) {
    server.send(400, "application/json", "{\"error\":\"Invalid timer duration\"}");
    return;
  }

  bool turnOn = (action == "on" || action == "1" || action == "true");
  timers[relay - 1].active = true;
  timers[relay - 1].relay = relay;
  timers[relay - 1].turnOn = turnOn;
  timers[relay - 1].totalSeconds = seconds;
  timers[relay - 1].endMillis = millis() + ((unsigned long)seconds * 1000UL);

  Serial.printf("[HAVEN] Timer set for Relay %d: %s in %d seconds\n", relay, turnOn ? "ON" : "OFF", seconds);
  server.send(200, "application/json", "{\"success\":true,\"relay\":" + String(relay) + ",\"seconds\":" + String(seconds) + ",\"action\":\"" + (turnOn ? "on" : "off") + "\"}");
}

// ─── Setup ──────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);

  // Set relays OFF before normal operation
  pinMode(relay1, OUTPUT);
  pinMode(relay2, OUTPUT);
  pinMode(relay3, OUTPUT);

  digitalWrite(relay1, RELAY_OFF);
  digitalWrite(relay2, RELAY_OFF);
  digitalWrite(relay3, RELAY_OFF);

  // Initialize timers
  for (int i = 0; i < 3; i++) {
    timers[i].active = false;
    timers[i].relay = i + 1;
    timers[i].turnOn = false;
    timers[i].endMillis = 0;
    timers[i].totalSeconds = 0;
  }

  // Load schedules from non-volatile storage
  loadSchedules();

  // Start ESP32 Wi-Fi Hotspot
  WiFi.mode(WIFI_AP);
  WiFi.softAP(ssid, password);

  Serial.println("[HAVEN] ESP32 Hotspot Started");
  Serial.print("[HAVEN] Connect Phone to Wi-Fi: ");
  Serial.println(ssid);
  Serial.print("[HAVEN] IP Address: http://");
  Serial.println(WiFi.softAPIP());

  // Web routes
  server.on("/", handleRoot);
  server.on("/toggle", handleToggle);
  server.on("/api/status", handleApiStatus);
  server.on("/api/set", handleApiSet);
  server.on("/api/toggle", handleApiSet);
  server.on("/api/all", handleApiAll);

  // Scheduling routes
  server.on("/api/time", handleApiTime);
  server.on("/api/schedules", handleApiSchedules);
  server.on("/api/schedule/add", handleApiScheduleAdd);
  server.on("/api/schedule/delete", handleApiScheduleDelete);
  server.on("/api/schedule/toggle", handleApiScheduleToggle);
  server.on("/api/timer", handleApiTimer);

  server.begin();
  Serial.println("[HAVEN] Web server started on port 80 with Schedule Engine");
}

// ─── Main Loop ──────────────────────────────────────────────────────────────
void loop() {
  server.handleClient();

  unsigned long curMs = millis();
  if (curMs - lastLoopSec >= 1000) {
    lastLoopSec = curMs;

    // 1. Process Countdown Timers
    for (int i = 0; i < 3; i++) {
      if (timers[i].active) {
        if ((long)(curMs - timers[i].endMillis) >= 0) {
          timers[i].active = false;
          Serial.printf("[HAVEN] Timer expired! Turning %s Relay %d\n", timers[i].turnOn ? "ON" : "OFF", timers[i].relay);
          setRelayHardware(timers[i].relay, timers[i].turnOn);
        }
      }
    }

    // 2. Process Daily Schedules if clock is synchronized
    if (timeSynced) {
      time_t nowSec = time(NULL);
      struct tm* t = localtime(&nowSec);
      int curDay = t->tm_wday; // 0=Sun, 1=Mon, ..., 6=Sat
      int curHour = t->tm_hour;
      int curMin = t->tm_min;

      if (curMin != lastFiredMinute || curDay != lastFiredDay) {
        for (int i = 0; i < scheduleCount; i++) {
          if (schedules[i].enabled) {
            if (schedules[i].hour == curHour && schedules[i].minute == curMin) {
              // Check day of week bitmask
              if ((schedules[i].days & (1 << curDay)) != 0) {
                Serial.printf("[HAVEN] Triggering Schedule #%d: Relay %d -> %s at %02d:%02d\n",
                              schedules[i].id, schedules[i].relay, schedules[i].turnOn ? "ON" : "OFF", curHour, curMin);
                setRelayHardware(schedules[i].relay, schedules[i].turnOn);
              }
            }
          }
        }
        lastFiredMinute = curMin;
        lastFiredDay = curDay;
      }
    }
  }
}
