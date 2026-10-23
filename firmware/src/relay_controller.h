#pragma once

#include <Arduino.h>
#include "hardware_config.h"

/**
 * RelayController
 * Manages low-level GPIO pin driving for multiple relay channels.
 * Correctly accounts for RELAY_ACTIVE_HIGH / active-low polarity, safe initial states,
 * and status LED indications.
 */
class RelayController {
public:
  void begin();                            // Set pin modes, apply safe startup state
  void setRelay(int channel, bool state);  // Set relay on/off
  bool getRelay(int channel) const;        // Get current relay state
  void setAllRelays(bool state);           // Set all relays
  bool isValidChannel(int channel) const;  // Validate channel number

private:
  bool _states[CHANNEL_COUNT];
  void _applyState(int channel, bool state);
  int _relayPin(int channel) const;
};
