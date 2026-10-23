import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haven_mobile/core/services/esp32_hotspot_service.dart';

final esp32HotspotServiceProvider = Provider<Esp32HotspotService>((ref) {
  return Esp32HotspotService();
});

class Esp32RelayState {
  final bool isConnected;
  final bool isChecking;
  final Map<int, bool> relays; // 1: bool, 2: bool, 3: bool
  final String? errorMessage;

  const Esp32RelayState({
    this.isConnected = false,
    this.isChecking = false,
    this.relays = const {1: false, 2: false, 3: false},
    this.errorMessage,
  });

  Esp32RelayState copyWith({
    bool? isConnected,
    bool? isChecking,
    Map<int, bool>? relays,
    String? errorMessage,
  }) {
    return Esp32RelayState(
      isConnected: isConnected ?? this.isConnected,
      isChecking: isChecking ?? this.isChecking,
      relays: relays ?? this.relays,
      errorMessage: errorMessage,
    );
  }
}

class Esp32RelayNotifier extends StateNotifier<Esp32RelayState> {
  final Esp32HotspotService _service;
  Timer? _pollTimer;

  Esp32RelayNotifier(this._service) : super(const Esp32RelayState()) {
    checkConnectionAndRefresh();
    // Periodically check every 5 seconds if connected
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        checkConnectionAndRefresh(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> checkConnectionAndRefresh({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isChecking: true, errorMessage: null);
    }

    final connected = await _service.isConnected();
    if (!connected) {
      if (mounted) {
        state = state.copyWith(
          isConnected: false,
          isChecking: false,
        );
      }
      return;
    }

    final relayStates = await _service.getRelayStates();
    if (mounted) {
      state = state.copyWith(
        isConnected: true,
        isChecking: false,
        relays: relayStates,
        errorMessage: null,
      );
    }
  }

  Future<bool> toggleRelay(int relayNum) async {
    final current = state.relays[relayNum] ?? false;
    final next = !current;

    // Optimistic update
    final updated = Map<int, bool>.from(state.relays);
    updated[relayNum] = next;
    state = state.copyWith(relays: updated);

    final success = await _service.toggleRelay(relayNum);
    if (!success) {
      // Revert if failed
      updated[relayNum] = current;
      state = state.copyWith(
        relays: updated,
        errorMessage: 'Failed to toggle Relay $relayNum on ESP32',
      );
      return false;
    }

    return true;
  }

  Future<void> setAllRelays(bool turnOn) async {
    // Optimistic update
    state = state.copyWith(
      relays: {1: turnOn, 2: turnOn, 3: turnOn},
    );
    await _service.setAllRelays(turnOn);
    await checkConnectionAndRefresh(silent: true);
  }
}

final esp32RelayNotifierProvider =
    StateNotifierProvider<Esp32RelayNotifier, Esp32RelayState>((ref) {
  final service = ref.watch(esp32HotspotServiceProvider);
  return Esp32RelayNotifier(service);
});
