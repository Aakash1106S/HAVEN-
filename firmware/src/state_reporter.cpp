#include "state_reporter.h"
#include "mqtt_client_manager.h"
#include "relay_controller.h"
#include "credentials_config.h"
#include "hardware_config.h"
#include <ArduinoJson.h>
#include <WiFi.h>
#include <time.h>

void StateReporter::begin(MQTTClientManager* mqttManager, RelayController* relayCtrl) {
  _mqttManager = mqttManager;
  _relayController = relayCtrl;
  _lastTelemetryTime = millis();
  Serial.println(F("[HAVEN] StateReporter initialized"));
}

void StateReporter::setRelayController(RelayController* relayCtrl) {
  _relayController = relayCtrl;
}

void StateReporter::reportFullState() {
  if (!_mqttManager || !_mqttManager->isConnected()) {
    Serial.println(F("[HAVEN] Notice: Cannot report full state, MQTT is not connected"));
    return;
  }

  String payload = _buildStatePayload();
  String topic = MQTTClientManager::stateTopic();

  Serial.printf("[HAVEN] Reporting full state to [%s]: %s\n", topic.c_str(), payload.c_str());
  _mqttManager->publish(topic.c_str(), payload.c_str(), true); // Retained so app retrieves current state immediately
}

void StateReporter::reportCommandAck(const String& commandId, const String& correlationId, 
                                     int channel, bool success, bool resultState) {
  if (!_mqttManager || !_mqttManager->isConnected()) {
    Serial.println(F("[HAVEN] Notice: Cannot report command ACK, MQTT is not connected"));
    return;
  }

  String payload = _buildAckPayload(commandId, correlationId, channel, success, resultState);
  String topic = MQTTClientManager::ackTopic();

  Serial.printf("[HAVEN] Reporting command ACK to [%s]: %s\n", topic.c_str(), payload.c_str());
  _mqttManager->publish(topic.c_str(), payload.c_str(), false); // ACK is NOT retained
}

void StateReporter::reportTelemetry() {
  if (!_mqttManager || !_mqttManager->isConnected()) {
    return;
  }

  _lastTelemetryTime = millis();

  JsonDocument doc;
  doc["deviceId"] = DEVICE_ID;
  doc["homeId"] = HOME_ID;
  doc["firmwareVersion"] = FIRMWARE_VERSION;
  doc["uptimeSeconds"] = (uint32_t)(millis() / 1000);
  doc["wifiRSSI"] = WiFi.RSSI();
  doc["ip"] = WiFi.localIP().toString();
  doc["freeHeap"] = ESP.getFreeHeap();
  doc["minFreeHeap"] = ESP.getMinFreeHeap();
  doc["timestamp"] = (uint32_t)time(nullptr);

  String payload;
  serializeJson(doc, payload);

  String topic = MQTTClientManager::telemetryTopic();
  Serial.printf("[HAVEN] Reporting telemetry to [%s]: %s\n", topic.c_str(), payload.c_str());
  _mqttManager->publish(topic.c_str(), payload.c_str(), false);
}

String StateReporter::_buildStatePayload() {
  JsonDocument doc;
  doc["deviceId"] = DEVICE_ID;
  doc["homeId"] = HOME_ID;
  doc["timestamp"] = (uint32_t)time(nullptr);

  JsonArray channels = doc["channels"].to<JsonArray>();
  for (int i = 0; i < CHANNEL_COUNT; i++) {
    JsonObject ch = channels.add<JsonObject>();
    ch["channelNumber"] = i;
    bool isOn = (_relayController != nullptr) ? _relayController->getRelay(i) : false;
    ch["state"] = isOn ? "on" : "off";
    ch["isOn"] = isOn;
  }

  String output;
  serializeJson(doc, output);
  return output;
}

String StateReporter::_buildAckPayload(const String& commandId, const String& correlationId,
                                       int channel, bool success, bool resultState) {
  JsonDocument doc;
  doc["commandId"] = commandId;
  doc["correlationId"] = correlationId;
  doc["deviceId"] = DEVICE_ID;
  doc["homeId"] = HOME_ID;
  doc["channel"] = channel;
  doc["channelNumber"] = channel;
  doc["success"] = success;
  doc["status"] = success ? "succeeded" : "failed";
  doc["state"] = resultState ? "on" : "off";
  doc["isOn"] = resultState;
  doc["timestamp"] = (uint32_t)time(nullptr);

  String output;
  serializeJson(doc, output);
  return output;
}
