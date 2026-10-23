#include "wifi_manager.h"
#include "credentials_config.h"
#include <time.h>

void WiFiManager::begin() {
  Serial.println(F("[HAVEN] Initializing WiFiManager..."));
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
}

void WiFiManager::connect() {
  Serial.printf("[HAVEN] Connecting to WiFi SSID: %s", WIFI_SSID);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < MAX_CONNECT_ATTEMPTS) {
    delay(500);
    Serial.print(F("."));
    attempts++;
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("[HAVEN] WiFi connected! Local IP: %s, RSSI: %d dBm\n",
                  WiFi.localIP().toString().c_str(), WiFi.RSSI());
    
    // Initialize SNTP for ISO 8601 command expiration checks
    configTime(0, 0, "pool.ntp.org", "time.google.com");
    Serial.println(F("[HAVEN] SNTP time synchronization requested (UTC)"));
  } else {
    Serial.println(F("[HAVEN] WiFi initial connection timed out. Will continue retrying in background."));
    _lastReconnectAttempt = millis();
  }
}

void WiFiManager::loop() {
  if (WiFi.status() != WL_CONNECTED) {
    unsigned long now = millis();
    if (now - _lastReconnectAttempt >= RECONNECT_INTERVAL) {
      _lastReconnectAttempt = now;
      _attemptReconnect();
    }
  }
}

void WiFiManager::_attemptReconnect() {
  Serial.printf("[HAVEN] Reconnecting to WiFi SSID: %s...\n", WIFI_SSID);
  WiFi.disconnect();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
}

bool WiFiManager::isConnected() const {
  return WiFi.status() == WL_CONNECTED;
}

String WiFiManager::getLocalIP() const {
  if (WiFi.status() == WL_CONNECTED) {
    return WiFi.localIP().toString();
  }
  return "0.0.0.0";
}

int WiFiManager::getRSSI() const {
  if (WiFi.status() == WL_CONNECTED) {
    return WiFi.RSSI();
  }
  return 0;
}
