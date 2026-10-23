#include "mqtt_client_manager.h"
#include "hardware_config.h"
#include "credentials_config.h"
#include "relay_controller.h"
#include "state_reporter.h"
#include <time.h>

MQTTClientManager* MQTTClientManager::_instance = nullptr;

String MQTTClientManager::commandTopic() {
  return String("haven/") + HOME_ID + "/" + DEVICE_ID + "/commands/control";
}

String MQTTClientManager::stateTopic() {
  return String("haven/") + HOME_ID + "/" + DEVICE_ID + "/state/reported";
}

String MQTTClientManager::ackTopic() {
  return String("haven/") + HOME_ID + "/" + DEVICE_ID + "/ack/command";
}

String MQTTClientManager::availTopic() {
  return String("haven/") + HOME_ID + "/" + DEVICE_ID + "/state/availability";
}

String MQTTClientManager::telemetryTopic() {
  return String("haven/") + HOME_ID + "/" + DEVICE_ID + "/telemetry";
}

void MQTTClientManager::begin(RelayController* relayCtrl, StateReporter* reporter) {
  _relayController = relayCtrl;
  _stateReporter = reporter;
  _instance = this;

  // For ESP32 TLS communication with HiveMQ Cloud
  _wifiClient.setInsecure(); // Recommended for initial provisioning; configure CA cert in production
  _mqttClient.setClient(_wifiClient);
  _mqttClient.setServer(MQTT_BROKER_HOST, MQTT_BROKER_PORT);
  _mqttClient.setCallback(_messageCallback);
  _mqttClient.setBufferSize(1024);
}

void MQTTClientManager::connect() {
  if (_mqttClient.connected()) return;

  Serial.println("[HAVEN] Connecting to MQTT broker over TLS...");

  String willTopic = availTopic();
  const char* willPayload = "{\"status\":\"offline\"}";

  // Connect with Last Will and Testament (LWT)
  if (_mqttClient.connect(DEVICE_ID, MQTT_USERNAME, MQTT_PASSWORD,
                          willTopic.c_str(), 1, true, willPayload)) {
    Serial.println("[HAVEN] Connected to HiveMQ Cloud MQTT broker!");

    // Publish online availability
    _publishAvailability(true);

    // Subscribe to commands topic
    String subTopic = commandTopic();
    _mqttClient.subscribe(subTopic.c_str(), 1);
    Serial.printf("[HAVEN] Subscribed to topic: %s\n", subTopic.c_str());

    // Report initial physical states
    if (_stateReporter) {
      _stateReporter->reportFullState();
    }
  } else {
    Serial.printf("[HAVEN] MQTT connection failed, rc=%d\n", _mqttClient.state());
  }
}

void MQTTClientManager::loop() {
  if (!_mqttClient.connected()) {
    unsigned long now = millis();
    if (now - _lastReconnectAttempt > 5000) {
      _lastReconnectAttempt = now;
      _reconnect();
    }
  } else {
    _mqttClient.loop();
  }
}

bool MQTTClientManager::isConnected() const {
  return const_cast<PubSubClient&>(_mqttClient).connected();
}

bool MQTTClientManager::publish(const char* topic, const char* payload, bool retained) {
  if (!_mqttClient.connected()) return false;
  return _mqttClient.publish(topic, payload, retained);
}

bool MQTTClientManager::subscribe(const char* topic) {
  if (!_mqttClient.connected()) return false;
  return _mqttClient.subscribe(topic);
}

void MQTTClientManager::_publishAvailability(bool online) {
  String topic = availTopic();
  String payload = online ? "{\"status\":\"online\"}" : "{\"status\":\"offline\"}";
  publish(topic.c_str(), payload.c_str(), true);
}

void MQTTClientManager::_reconnect() {
  connect();
}

void MQTTClientManager::_messageCallback(char* topic, byte* payload, unsigned int length) {
  if (!_instance) return;

  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';

  _instance->_handleMessage(topic, payload, length);
}

void MQTTClientManager::_handleMessage(char* topic, byte* payload, unsigned int length) {
  char message[length + 1];
  memcpy(message, payload, length);
  message[length] = '\0';

  Serial.printf("[HAVEN] MQTT Message received on topic: %s\n", topic);

  if (String(topic) == commandTopic()) {
    _handleControlCommand(message);
  }
}

void MQTTClientManager::_handleControlCommand(const char* payload) {
  JsonDocument doc;
  DeserializationError err = deserializeJson(doc, payload);

  if (err) {
    Serial.printf("[HAVEN] Failed to parse command JSON: %s\n", err.c_str());
    return;
  }

  const char* commandId = doc["commandId"] | "";
  const char* correlationId = doc["correlationId"] | "";
  int channel = doc["channel"] | -1;
  const char* actionStr = doc["action"] | "";

  Serial.printf("[HAVEN] Received command: id=%s channel=%d action=%s\n",
                commandId, channel, actionStr);

  if (!_relayController || !_relayController->isValidChannel(channel)) {
    Serial.printf("[HAVEN] Invalid channel %d received!\n", channel);
    if (_stateReporter && strlen(commandId) > 0) {
      _stateReporter->reportCommandAck(commandId, correlationId, channel, false, false);
    }
    return;
  }

  bool targetState = (strcmp(actionStr, "on") == 0 || strcmp(actionStr, "ON") == 0);

  // Apply relay state
  _relayController->setRelay(channel, targetState);
  bool actualState = _relayController->getRelay(channel);

  // Report acknowledgement
  if (_stateReporter && strlen(commandId) > 0) {
    _stateReporter->reportCommandAck(commandId, correlationId, channel, true, actualState);
  }
}
