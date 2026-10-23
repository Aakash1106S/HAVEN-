#include "switch_handler.h"
#include "relay_controller.h"
#include "state_reporter.h"

void SwitchHandler::begin(RelayController* relayCtrl, StateReporter* reporter) {
  _relayController = relayCtrl;
  _stateReporter = reporter;

  Serial.println(F("[HAVEN] Initializing SwitchHandler..."));

  for (int i = 0; i < CHANNEL_COUNT; i++) {
    int pin = _switchPin(i);
    if (pin >= 0) {
      _debouncers[i].attach(pin, SWITCH_INPUT_MODE);
      _debouncers[i].interval(50); // 50ms debounce window
      Serial.printf("[HAVEN] Switch CH%d attached to GPIO %d (debounce 50ms)\n", i, pin);
    }
  }

  Serial.println(F("[HAVEN] SwitchHandler initialized successfully."));
}

void SwitchHandler::loop() {
  for (int i = 0; i < CHANNEL_COUNT; i++) {
    _debouncers[i].update();

    // With INPUT_PULLUP, pressing the button/switch connects GPIO to GND (falling edge HIGH -> LOW).
    // Bounce2 fell() triggers only on the edge transition, not continuous level.
    if (_debouncers[i].fell()) {
      Serial.printf("[HAVEN] Physical switch press detected on CH%d\n", i);
      _handleSwitchToggle(i);
    }
  }
}

void SwitchHandler::_handleSwitchToggle(int channel) {
  if (!_relayController || !_relayController->isValidChannel(channel)) {
    return;
  }

  // Toggle relay: pressing once = ON, pressing again = OFF
  bool currentState = _relayController->getRelay(channel);
  bool newState = !currentState;

  Serial.printf("[HAVEN] Toggling CH%d from %s to %s via physical switch\n",
                channel, currentState ? "ON" : "OFF", newState ? "ON" : "OFF");

  // Directly actuate hardware relay immediately (independent of cloud/MQTT status)
  _relayController->setRelay(channel, newState);

  // Notify state reporter (will publish if MQTT is connected)
  if (_stateReporter) {
    _stateReporter->reportFullState();
  }
}

int SwitchHandler::_switchPin(int channel) const {
  switch (channel) {
    case 0: return SWITCH_CH0_PIN;
    case 1: return SWITCH_CH1_PIN;
    case 2: return SWITCH_CH2_PIN;
    default: return -1;
  }
}
