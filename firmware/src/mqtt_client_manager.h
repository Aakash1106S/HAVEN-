#pragma once

#include <Arduino.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

class RelayController;
class StateReporter;

/**
 * MQTTClientManager
 * Handles TLS connection to HiveMQ broker, Last Will and Testament (LWT),
 * topic subscriptions, command routing, ISO 8601 expiresAt validation,
 * and reliable message publishing.
 */
class MQTTClientManager {
public:
  void begin(RelayController* relayCtrl, StateReporter* reporter);
  void connect();  // Connect to MQTT broker
  void loop();     // Handle messages, background reconnection, telemetry
  bool isConnected() const;
  bool publish(const char* topic, const char* payload, bool retained = false);
  bool subscribe(const char* topic);

  static String commandTopic();   // haven/{homeId}/{deviceId}/commands/control
  static String stateTopic();     // haven/{homeId}/{deviceId}/state/reported
  static String ackTopic();       // haven/{homeId}/{deviceId}/ack/command
  static String availTopic();     // haven/{homeId}/{deviceId}/state/availability
  static String telemetryTopic(); // haven/{homeId}/{deviceId}/telemetry

private:
  WiFiClientSecure _wifiClient;
  PubSubClient _mqttClient;
  RelayController* _relayController = nullptr;
  StateReporter* _stateReporter = nullptr;
  unsigned long _lastReconnectAttempt = 0;

  void _handleMessage(char* topic, byte* payload, unsigned int length);
  void _handleControlCommand(const char* payload);
  void _publishAvailability(bool online);
  void _reconnect();
  bool _isCommandExpired(const JsonVariantConst& expiresAtVariant);

  // Static callback bridge for PubSubClient
  static MQTTClientManager* _instance;
  static void _messageCallback(char* topic, byte* payload, unsigned int length);
};
