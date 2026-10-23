import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage();

class RelayNames {
  final String relay1;
  final String relay2;
  final String relay3;

  const RelayNames({
    this.relay1 = 'Light',
    this.relay2 = 'Fan',
    this.relay3 = 'Socket',
  });

  RelayNames copyWith({
    String? relay1,
    String? relay2,
    String? relay3,
  }) {
    return RelayNames(
      relay1: relay1 ?? this.relay1,
      relay2: relay2 ?? this.relay2,
      relay3: relay3 ?? this.relay3,
    );
  }

  String getName(int relayNumber) {
    switch (relayNumber) {
      case 1:
        return relay1;
      case 2:
        return relay2;
      case 3:
        return relay3;
      default:
        return 'Relay $relayNumber';
    }
  }
}

class RelayNamesNotifier extends StateNotifier<RelayNames> {
  RelayNamesNotifier() : super(const RelayNames()) {
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final r1 = await _storage.read(key: 'haven_relay_1_name') ?? 'Light';
      final r2 = await _storage.read(key: 'haven_relay_2_name') ?? 'Fan';
      final r3 = await _storage.read(key: 'haven_relay_3_name') ?? 'Socket';
      state = RelayNames(relay1: r1, relay2: r2, relay3: r3);
    } catch (_) {}
  }

  Future<void> setRelayName(int relayNumber, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;

    switch (relayNumber) {
      case 1:
        state = state.copyWith(relay1: trimmed);
        await _storage.write(key: 'haven_relay_1_name', value: trimmed);
        break;
      case 2:
        state = state.copyWith(relay2: trimmed);
        await _storage.write(key: 'haven_relay_2_name', value: trimmed);
        break;
      case 3:
        state = state.copyWith(relay3: trimmed);
        await _storage.write(key: 'haven_relay_3_name', value: trimmed);
        break;
    }
  }

  Future<void> resetToDefaults() async {
    state = const RelayNames(relay1: 'Light', relay2: 'Relay 2', relay3: 'Socket');
    await _storage.write(key: 'haven_relay_1_name', value: 'Light');
    await _storage.write(key: 'haven_relay_2_name', value: 'Relay 2');
    await _storage.write(key: 'haven_relay_3_name', value: 'Socket');
  }
}

final relayNamesProvider =
    StateNotifierProvider<RelayNamesNotifier, RelayNames>((ref) {
  return RelayNamesNotifier();
});
