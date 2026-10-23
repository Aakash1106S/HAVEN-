#pragma once

#include <Arduino.h>
#include <Bounce2.h>
#include "hardware_config.h"

class RelayController;
class StateReporter;

/**
 * SwitchHandler
 * Debounces physical wall switch/button inputs and toggles corresponding relays.
 * Works completely independently of WiFi/MQTT connectivity.
 */
class SwitchHandler {
public:
  void begin(RelayController* relayCtrl, StateReporter* reporter);
  void loop();  // Poll switches, detect transitions

private:
  Bounce _debouncers[CHANNEL_COUNT];
  RelayController* _relayController = nullptr;
  StateReporter* _stateReporter = nullptr;

  void _handleSwitchToggle(int channel);
  int _switchPin(int channel) const;
};
