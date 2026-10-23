#pragma once

#include <Arduino.h>

/**
 * HAVEN SMART HOME - HARDWARE CONFIGURATION
 * ==========================================
 * 
 * ⚠️  WARNING: VERIFY ALL PIN ASSIGNMENTS AGAINST YOUR ACTUAL PCB SCHEMATIC
 *     BEFORE FLASHING. Incorrect pin assignments can damage hardware.
 *
 * ⚠️  MAINS VOLTAGE WARNING: This firmware may control relays connected to
 *     mains-voltage appliances. Have all mains wiring verified by a qualified
 *     electrician before connecting power.
 *
 * ⚠️  RELAY SAFETY: Verify RELAY_ACTIVE_HIGH matches your relay module.
 *     Wrong polarity may turn relays ON at startup unexpectedly.
 * 
 * ⚠️  ESP32 INPUT PINS: GPIO 34 and GPIO 35 are input-only pins without
 *     internal pullup/pulldown resistors. Ensure external 10kΩ pullup
 *     resistors are present on your PCB if using switch-to-GND wiring.
 */

// ─── RELAY OUTPUT PINS ────────────────────────────────────────────────────────
#define RELAY_CH0_PIN  25  // Channel 0 (Relay 1) GPIO
#define RELAY_CH1_PIN  26  // Channel 1 (Relay 2) GPIO
#define RELAY_CH2_PIN  27  // Channel 2 (Relay 3) GPIO

// ─── RELAY POLARITY ──────────────────────────────────────────────────────────
// true  = relay activates on HIGH (most common solid-state relays)
// false = relay activates on LOW  (most common electromechanical relay modules)
// TODO: Verify against your relay module datasheet
#define RELAY_ACTIVE_HIGH  false  // VERIFY!

// ─── PHYSICAL SWITCH INPUT PINS ──────────────────────────────────────────────
// TODO: Verify these GPIO numbers against your PCB schematic
#define SWITCH_CH0_PIN  34  // Channel 0 physical switch input GPIO - VERIFY!
#define SWITCH_CH1_PIN  35  // Channel 1 physical switch input GPIO - VERIFY!
#define SWITCH_CH2_PIN  32  // Channel 2 physical switch input GPIO - VERIFY!

// Switch input type:
// INPUT_PULLUP = switch shorts to GND (most common)
// INPUT = switch provides voltage, needs external resistor
#define SWITCH_INPUT_MODE  INPUT_PULLUP  // VERIFY!

// ─── STATUS LED (optional) ───────────────────────────────────────────────────
#define STATUS_LED_PIN  2  // Built-in LED on most ESP32 dev boards

// ─── CHANNEL COUNT ───────────────────────────────────────────────────────────
#define CHANNEL_COUNT  3

// ─── SAFE STARTUP STATE ──────────────────────────────────────────────────────
// State to put relays in at boot (before receiving any commands)
// false = OFF is safe default for most appliance control applications
#define RELAY_SAFE_STARTUP_STATE  false  // false = OFF, true = ON
