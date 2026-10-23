#include <Arduino.h>
#include "hardware_config.h"
#include "credentials_config.h"
#include "wifi_manager.h"
#include "mqtt_client_manager.h"
#include "relay_controller.h"
#include "switch_handler.h"
#include "state_reporter.h"

// Hardware and Network Controller Instances
WiFiManager wifiManager;
MQTTClientManager mqttManager;
RelayController relayController;
SwitchHandler switchHandler;
StateReporter stateReporter;

void setup() {
  Serial.begin(115200);
  delay(200);

  Serial.println();
  Serial.println("==================================================");
  Serial.println("   HAVEN SMART HOME AUTOMATION FIRMWARE v" FIRMWARE_VERSION);
  Serial.println("   Device ID: " DEVICE_ID);
  Serial.println("   Home ID:   " HOME_ID);
  Serial.println("==================================================");

  // 1. Initialize Relay Outputs (applies RELAY_SAFE_STARTUP_STATE)
  relayController.begin();

  // 2. Initialize State Reporter
  stateReporter.begin(&mqttManager, &relayController);

  // 3. Initialize Physical Switch Debounce Handlers
  switchHandler.begin(&relayController, &stateReporter);

  // 4. Initialize and Connect to Wi-Fi
  wifiManager.begin();
  wifiManager.connect();

  // 5. Initialize and Connect to HiveMQ MQTT Broker over TLS
  mqttManager.begin(&relayController, &stateReporter);
  if (wifiManager.isConnected()) {
    mqttManager.connect();
  }

  Serial.println("[HAVEN] Hardware & services initialized successfully.");
}

void loop() {
  // 1. Maintain Wi-Fi Connection
  wifiManager.loop();

  // 2. Maintain MQTT over TLS & Process Incoming Commands
  if (wifiManager.isConnected()) {
    mqttManager.loop();
    stateReporter.reportTelemetry();
  }

  // 3. Handle Local Physical Switches with 50ms Debounce
  // (Works locally even if Wi-Fi or MQTT broker is disconnected)
  switchHandler.loop();

  // Yield to RTOS watchdog
  delay(10);
}
