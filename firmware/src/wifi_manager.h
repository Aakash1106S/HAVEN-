#pragma once

#include <Arduino.h>
#include <WiFi.h>

/**
 * WiFiManager
 * Handles WiFi connection lifecycle, background reconnection, and IP/RSSI queries.
 */
class WiFiManager {
public:
  void begin();
  void connect(); // Blocks until connected or timeout
  void loop();    // Call in main loop, handles non-blocking reconnection
  bool isConnected() const;
  String getLocalIP() const;
  int getRSSI() const;

private:
  unsigned long _lastReconnectAttempt = 0;
  static const unsigned long RECONNECT_INTERVAL = 5000; // 5 seconds
  static const int MAX_CONNECT_ATTEMPTS = 20;
  void _attemptReconnect();
};
