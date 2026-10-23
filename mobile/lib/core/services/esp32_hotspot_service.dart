import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../features/schedules/models/esp32_schedule_model.dart';

/// Service for direct local communication with the ESP32 in Hotspot (AP) Mode.
/// Default ESP32 AP IP is 192.168.4.1.
class Esp32HotspotService {
  static const String defaultBaseUrl = 'http://192.168.4.1';

  final String baseUrl;
  final http.Client _client;

  Esp32HotspotService({
    this.baseUrl = defaultBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Check if the ESP32 hotspot is reachable.
  Future<bool> isConnected() async {
    try {
      final uri = Uri.parse('$baseUrl/api/status');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 1500));
      return res.statusCode == 200;
    } catch (_) {
      // Fallback check to root page if api endpoint is not yet flashed
      try {
        final rootUri = Uri.parse('$baseUrl/');
        final res = await _client.get(rootUri).timeout(const Duration(milliseconds: 1500));
        return res.statusCode == 200 || res.statusCode == 303;
      } catch (_) {
        return false;
      }
    }
  }

  /// Fetch the current states of all 3 relays.
  /// Returns a Map where keys are 1, 2, 3 and values are booleans (true = ON, false = OFF).
  Future<Map<int, bool>> getRelayStates() async {
    try {
      final uri = Uri.parse('$baseUrl/api/status');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 2000));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final relays = data['relays'] as List<dynamic>?;
        if (relays != null) {
          final result = <int, bool>{};
          for (final item in relays) {
            final ch = item['channel'] as int;
            final stateStr = (item['state'] as String).toLowerCase();
            result[ch] = stateStr == 'on';
          }
          return result;
        }
      }
    } catch (e) {
      debugPrint('Esp32HotspotService.getRelayStates error: $e');
    }
    return {1: false, 2: false, 3: false};
  }

  /// Toggle a relay (1, 2, or 3) on the ESP32.
  Future<bool> toggleRelay(int relayNumber) async {
    // 1. Try modern JSON API first
    try {
      final uri = Uri.parse('$baseUrl/api/toggle?relay=$relayNumber');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 2000));
      if (res.statusCode == 200) {
        return true;
      }
    } catch (_) {}

    // 2. Fallback to existing Arduino WebServer endpoint: /toggle?relay=1
    try {
      final fallbackUri = Uri.parse('$baseUrl/toggle?relay=$relayNumber');
      final res = await _client.get(fallbackUri).timeout(const Duration(milliseconds: 2500));
      return res.statusCode == 200 || res.statusCode == 303;
    } catch (e) {
      debugPrint('Esp32HotspotService.toggleRelay failed: $e');
      return false;
    }
  }

  /// Explicitly set relay state (on = true, off = false).
  Future<bool> setRelayState(int relayNumber, bool turnOn) async {
    final stateStr = turnOn ? 'on' : 'off';
    try {
      final uri = Uri.parse('$baseUrl/api/set?relay=$relayNumber&state=$stateStr');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 2000));
      if (res.statusCode == 200) {
        return true;
      }
    } catch (_) {}

    // Fallback: use toggle if set endpoint not available
    return toggleRelay(relayNumber);
  }

  /// Set all 3 relays to ON or OFF.
  Future<bool> setAllRelays(bool turnOn) async {
    final stateStr = turnOn ? 'on' : 'off';
    try {
      final uri = Uri.parse('$baseUrl/api/all?state=$stateStr');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 2000));
      if (res.statusCode == 200) {
        return true;
      }
    } catch (_) {}

    // Fallback: iterate through all 3 relays
    bool allSuccess = true;
    for (int i = 1; i <= 3; i++) {
      final success = await setRelayState(i, turnOn);
      if (!success) allSuccess = false;
    }
    return allSuccess;
  }

  /// Synchronize the phone's local time and timezone with the ESP32.
  Future<bool> syncTime() async {
    try {
      final now = DateTime.now();
      final epoch = now.millisecondsSinceEpoch ~/ 1000;
      final tzOffset = now.timeZoneOffset.inSeconds;

      final uri = Uri.parse('$baseUrl/api/time?epoch=$epoch&tz_offset=$tzOffset');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 2000));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Esp32HotspotService.syncTime failed: $e');
      return false;
    }
  }

  /// Fetch all schedules and active countdown timers from the ESP32.
  Future<Map<String, dynamic>?> getSchedulesAndTimers() async {
    try {
      final uri = Uri.parse('$baseUrl/api/schedules');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 2500));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final rawSchedules = data['schedules'] as List<dynamic>? ?? [];
        final rawTimers = data['timers'] as List<dynamic>? ?? [];

        final schedules = rawSchedules
            .map((s) => Esp32ScheduleModel.fromJson(s as Map<String, dynamic>))
            .toList();

        final timers = rawTimers
            .map((t) => Esp32TimerModel.fromJson(t as Map<String, dynamic>))
            .toList();

        return {
          'timeSynced': data['timeSynced'] as bool? ?? false,
          'currentTime': data['currentTime'] as String? ?? '--:--',
          'schedules': schedules,
          'timers': timers,
        };
      }
    } catch (e) {
      debugPrint('Esp32HotspotService.getSchedulesAndTimers failed: $e');
    }
    return null;
  }

  /// Add or update a recurring daily schedule on the ESP32.
  Future<int?> addSchedule({
    int? id,
    required int relay,
    required bool turnOn,
    required int hour,
    required int minute,
    int daysMask = 127,
    bool enabled = true,
  }) async {
    try {
      final action = turnOn ? 'on' : 'off';
      final timeStr = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      var urlStr = '$baseUrl/api/schedule/add?relay=$relay&action=$action&time=$timeStr&days=$daysMask&enabled=$enabled';
      if (id != null && id > 0) {
        urlStr += '&id=$id';
      }

      final uri = Uri.parse(urlStr);
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 2500));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return data['id'] as int?;
      }
    } catch (e) {
      debugPrint('Esp32HotspotService.addSchedule failed: $e');
    }
    return null;
  }

  /// Delete a schedule on the ESP32 by ID.
  Future<bool> deleteSchedule(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/api/schedule/delete?id=$id');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 2000));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Esp32HotspotService.deleteSchedule failed: $e');
      return false;
    }
  }

  /// Toggle a schedule on the ESP32 (enable or disable).
  Future<bool> toggleSchedule(int id, bool enabled) async {
    try {
      final uri = Uri.parse('$baseUrl/api/schedule/toggle?id=$id&enabled=$enabled');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 2000));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Esp32HotspotService.toggleSchedule failed: $e');
      return false;
    }
  }

  /// Set a countdown timer for a relay (e.g. Turn OFF Relay 1 in 30 minutes).
  Future<bool> setTimer({
    required int relay,
    required bool turnOn,
    required int minutes,
  }) async {
    try {
      final action = turnOn ? 'on' : 'off';
      final uri = Uri.parse('$baseUrl/api/timer?relay=$relay&action=$action&minutes=$minutes');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 2000));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Esp32HotspotService.setTimer failed: $e');
      return false;
    }
  }

  /// Cancel an active countdown timer for a relay.
  Future<bool> cancelTimer(int relay) async {
    try {
      final uri = Uri.parse('$baseUrl/api/timer?relay=$relay&action=cancel');
      final res = await _client.get(uri).timeout(const Duration(milliseconds: 2000));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Esp32HotspotService.cancelTimer failed: $e');
      return false;
    }
  }
}
