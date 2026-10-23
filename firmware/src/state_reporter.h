#pragma once

#include <Arduino.h>

class MQTTClientManager;
class RelayController;

/**
 * StateReporter
 * Constructs and publishes full channel states, command acknowledgments,
 * and periodic device telemetry payloads to MQTT topics.
 */
class StateReporter {
public:
  void begin(MQTTClientManager* mqttManager, RelayController* relayCtrl = nullptr);
  void setRelayController(RelayController* relayCtrl);

  // Report all channel states
  void reportFullState();

  // Report state after a command acknowledgement
  void reportCommandAck(const String& commandId, const String& correlationId, 
                        int channel, bool success, bool resultState);

  // Publish telemetry (WiFi RSSI, uptime, free heap, etc.)
  void reportTelemetry();

  unsigned long _lastTelemetryTime = 0;
  static const unsigned long TELEMETRY_INTERVAL = 60000; // 1 minute (60,000 ms)

private:
  MQTTClientManager* _mqttManager = nullptr;
  RelayController* _relayController = nullptr;

  String _buildStatePayload();
  String _buildAckPayload(const String& commandId, const String& correlationId,
                          int channel, bool success, bool resultState);
};
