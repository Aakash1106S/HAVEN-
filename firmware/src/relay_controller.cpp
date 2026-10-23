#include "relay_controller.h"

void RelayController::begin() {
  Serial.println(F("[HAVEN] Initializing RelayController..."));

  #ifdef STATUS_LED_PIN
  pinMode(STATUS_LED_PIN, OUTPUT);
  digitalWrite(STATUS_LED_PIN, LOW);
  #endif

  for (int i = 0; i < CHANNEL_COUNT; i++) {
    int pin = _relayPin(i);
    if (pin >= 0) {
      pinMode(pin, OUTPUT);
      _applyState(i, RELAY_SAFE_STARTUP_STATE);
    }
  }

  Serial.println(F("[HAVEN] RelayController initialized in safe state."));
}

void RelayController::setRelay(int channel, bool state) {
  if (!isValidChannel(channel)) {
    Serial.printf("[HAVEN] Error: Cannot set relay, invalid channel: %d\n", channel);
    return;
  }
  _applyState(channel, state);
}

bool RelayController::getRelay(int channel) const {
  if (!isValidChannel(channel)) {
    return false;
  }
  return _states[channel];
}

void RelayController::setAllRelays(bool state) {
  for (int i = 0; i < CHANNEL_COUNT; i++) {
    _applyState(i, state);
  }
}

bool RelayController::isValidChannel(int channel) const {
  return (channel >= 0 && channel < CHANNEL_COUNT);
}

void RelayController::_applyState(int channel, bool state) {
  int pin = _relayPin(channel);
  if (pin < 0) return;

  _states[channel] = state;

  // Active-high vs Active-low relay module logic:
  // If RELAY_ACTIVE_HIGH is true: HIGH = ON, LOW = OFF
  // If RELAY_ACTIVE_HIGH is false: LOW = ON, HIGH = OFF
  int pinLevel;
  if (RELAY_ACTIVE_HIGH) {
    pinLevel = state ? HIGH : LOW;
  } else {
    pinLevel = state ? LOW : HIGH;
  }

  digitalWrite(pin, pinLevel);

  Serial.printf("[HAVEN] Relay CH%d (GPIO %d) set to %s [Pin Level: %s]\n",
                channel, pin, state ? "ON" : "OFF", pinLevel == HIGH ? "HIGH" : "LOW");

  #ifdef STATUS_LED_PIN
  // Light status LED if any relay is active
  bool anyActive = false;
  for (int i = 0; i < CHANNEL_COUNT; i++) {
    if (_states[i]) {
      anyActive = true;
      break;
    }
  }
  digitalWrite(STATUS_LED_PIN, anyActive ? HIGH : LOW);
  #endif
}

int RelayController::_relayPin(int channel) const {
  switch (channel) {
    case 0: return RELAY_CH0_PIN;
    case 1: return RELAY_CH1_PIN;
    case 2: return RELAY_CH2_PIN;
    default: return -1;
  }
}
