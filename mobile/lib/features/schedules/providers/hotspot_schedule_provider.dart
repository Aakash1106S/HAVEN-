import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/services/esp32_hotspot_service.dart';
import '../../devices/providers/esp32_hotspot_provider.dart';
import '../models/esp32_schedule_model.dart';

class HotspotScheduleState {
  final bool isLoading;
  final bool isTimeSynced;
  final String esp32Time;
  final List<Esp32ScheduleModel> schedules;
  final List<Esp32TimerModel> timers;
  final String? errorMessage;

  const HotspotScheduleState({
    this.isLoading = false,
    this.isTimeSynced = false,
    this.esp32Time = '--:--',
    this.schedules = const [],
    this.timers = const [],
    this.errorMessage,
  });

  HotspotScheduleState copyWith({
    bool? isLoading,
    bool? isTimeSynced,
    String? esp32Time,
    List<Esp32ScheduleModel>? schedules,
    List<Esp32TimerModel>? timers,
    String? errorMessage,
  }) {
    return HotspotScheduleState(
      isLoading: isLoading ?? this.isLoading,
      isTimeSynced: isTimeSynced ?? this.isTimeSynced,
      esp32Time: esp32Time ?? this.esp32Time,
      schedules: schedules ?? this.schedules,
      timers: timers ?? this.timers,
      errorMessage: errorMessage,
    );
  }
}

class HotspotScheduleNotifier extends StateNotifier<HotspotScheduleState> {
  final Esp32HotspotService _service;
  final FlutterSecureStorage _storage;
  static const _cacheKey = 'haven_cached_schedules';
  Timer? _periodicTimer;

  HotspotScheduleNotifier(this._service, [FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const HotspotScheduleState()) {
    _init();
  }

  Future<void> _init() async {
    await _loadFromCache();
    await refresh();

    // Auto-refresh countdown timers and state every 3 seconds while active
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _refreshSilently();
      }
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadFromCache() async {
    try {
      final jsonStr = await _storage.read(key: _cacheKey);
      if (jsonStr != null) {
        final list = (jsonDecode(jsonStr) as List<dynamic>)
            .map((e) => Esp32ScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) {
          state = state.copyWith(schedules: list);
        }
      }
    } catch (_) {}
  }

  Future<void> _saveToCache(List<Esp32ScheduleModel> list) async {
    try {
      final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
      await _storage.write(key: _cacheKey, value: jsonStr);
    } catch (_) {}
  }

  /// Full refresh: Syncs time and reads schedules & active timers from ESP32.
  Future<void> refresh() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Automatically synchronize phone clock with ESP32
      await _service.syncTime();

      // 2. Fetch schedules and active timers
      final data = await _service.getSchedulesAndTimers();
      if (data != null && mounted) {
        final schedules = data['schedules'] as List<Esp32ScheduleModel>;
        final timers = data['timers'] as List<Esp32TimerModel>;
        final timeSynced = data['timeSynced'] as bool;
        final currentTime = data['currentTime'] as String;

        await _saveToCache(schedules);

        state = state.copyWith(
          isLoading: false,
          isTimeSynced: timeSynced,
          esp32Time: currentTime,
          schedules: schedules,
          timers: timers,
          errorMessage: null,
        );
        return;
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Could not reach ESP32_Relay. Connect to Wi-Fi to sync.',
        );
      }
      return;
    }

    if (mounted) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Connect phone to ESP32_Relay Wi-Fi to load schedules.',
      );
    }
  }

  Future<void> _refreshSilently() async {
    try {
      final data = await _service.getSchedulesAndTimers();
      if (data != null && mounted) {
        final schedules = data['schedules'] as List<Esp32ScheduleModel>;
        final timers = data['timers'] as List<Esp32TimerModel>;
        final timeSynced = data['timeSynced'] as bool;
        final currentTime = data['currentTime'] as String;

        state = state.copyWith(
          isTimeSynced: timeSynced,
          esp32Time: currentTime,
          schedules: schedules,
          timers: timers,
        );
      }
    } catch (_) {}
  }

  /// Sync phone time manually.
  Future<bool> syncTime() async {
    final success = await _service.syncTime();
    if (success) {
      await refresh();
    }
    return success;
  }

  /// Add or update a schedule.
  Future<bool> addSchedule({
    int? id,
    required int relay,
    required bool turnOn,
    required int hour,
    required int minute,
    int daysMask = 127,
    bool enabled = true,
  }) async {
    // Generate an ID if creating new
    final schedId = id ??
        (state.schedules.isEmpty
            ? 1
            : (state.schedules.map((s) => s.id).reduce((a, b) => a > b ? a : b) + 1));

    final newSchedule = Esp32ScheduleModel(
      id: schedId,
      relay: relay,
      turnOn: turnOn,
      hour: hour,
      minute: minute,
      daysMask: daysMask,
      enabled: enabled,
    );

    // Optimistically update local state & cache
    final updatedList = List<Esp32ScheduleModel>.from(state.schedules);
    final existingIdx = updatedList.indexWhere((s) => s.id == schedId);
    if (existingIdx >= 0) {
      updatedList[existingIdx] = newSchedule;
    } else {
      updatedList.add(newSchedule);
    }
    state = state.copyWith(schedules: updatedList, isLoading: false);
    await _saveToCache(updatedList);

    // Attempt sync to ESP32
    final syncedId = await _service.addSchedule(
      id: id,
      relay: relay,
      turnOn: turnOn,
      hour: hour,
      minute: minute,
      daysMask: daysMask,
      enabled: enabled,
    );

    if (syncedId != null) {
      await refresh();
      return true;
    } else {
      return false;
    }
  }

  /// Toggle an existing schedule.
  Future<void> toggleSchedule(int id) async {
    final idx = state.schedules.indexWhere((s) => s.id == id);
    if (idx < 0) return;

    final current = state.schedules[idx];
    final next = !current.enabled;

    // Optimistic update
    final updatedList = List<Esp32ScheduleModel>.from(state.schedules);
    updatedList[idx] = current.copyWith(enabled: next);
    state = state.copyWith(schedules: updatedList);
    await _saveToCache(updatedList);

    await _service.toggleSchedule(id, next);
  }

  /// Delete a schedule.
  Future<bool> deleteSchedule(int id) async {
    final updatedList = state.schedules.where((s) => s.id != id).toList();
    state = state.copyWith(schedules: updatedList);
    await _saveToCache(updatedList);

    final success = await _service.deleteSchedule(id);
    return success;
  }

  /// Set countdown timer (e.g. Turn off Relay 1 in 30 minutes).
  Future<bool> setTimer({
    required int relay,
    required bool turnOn,
    required int minutes,
  }) async {
    // Optimistic timer
    final updatedTimers = state.timers.where((t) => t.relay != relay).toList()
      ..add(Esp32TimerModel(
        relay: relay,
        turnOn: turnOn,
        remainingSeconds: minutes * 60,
        totalSeconds: minutes * 60,
      ));
    state = state.copyWith(timers: updatedTimers);

    final success = await _service.setTimer(
      relay: relay,
      turnOn: turnOn,
      minutes: minutes,
    );
    if (success) {
      await refresh();
    }
    return success;
  }

  /// Cancel an active timer.
  Future<bool> cancelTimer(int relay) async {
    final updatedTimers = state.timers.where((t) => t.relay != relay).toList();
    state = state.copyWith(timers: updatedTimers);

    final success = await _service.cancelTimer(relay);
    return success;
  }
}

final hotspotScheduleProvider =
    StateNotifierProvider<HotspotScheduleNotifier, HotspotScheduleState>((ref) {
  final service = ref.watch(esp32HotspotServiceProvider);
  return HotspotScheduleNotifier(service);
});
