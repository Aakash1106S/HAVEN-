import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:haven_mobile/shared/models/home_model.dart';
import 'package:haven_mobile/shared/models/room_model.dart';
import 'package:haven_mobile/shared/models/channel_model.dart';
import 'package:haven_mobile/shared/models/device_model.dart';
import 'package:haven_mobile/shared/models/schedule_model.dart';
import 'package:haven_mobile/shared/models/activity_event_model.dart';
import 'package:haven_mobile/shared/repositories/auth_repository.dart';
import 'package:haven_mobile/shared/repositories/home_repository.dart';
import 'package:haven_mobile/shared/repositories/room_repository.dart';
import 'package:haven_mobile/shared/repositories/channel_repository.dart';
import 'package:haven_mobile/shared/repositories/device_repository.dart';
import 'package:haven_mobile/shared/repositories/schedule_repository.dart';
import 'package:haven_mobile/shared/repositories/activity_repository.dart';
import 'package:haven_mobile/core/di/providers.dart';

// ─── Auth ────────────────────────────────────────────────────────────────────
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(firebaseAuthProvider),
    ref.watch(firestoreProvider),
  );
});

// ─── Home ────────────────────────────────────────────────────────────────────
final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(firestoreProvider));
});

// ─── Room ────────────────────────────────────────────────────────────────────
final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  return RoomRepository(ref.watch(firestoreProvider));
});

// ─── Channel ─────────────────────────────────────────────────────────────────
final channelRepositoryProvider = Provider<ChannelRepository>((ref) {
  return ChannelRepository(
    ref.watch(firestoreProvider),
    ref.watch(firebaseAuthProvider),
  );
});

// ─── Device ──────────────────────────────────────────────────────────────────
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(ref.watch(firestoreProvider));
});

// ─── Schedule ─────────────────────────────────────────────────────────────────
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(firestoreProvider));
});

// ─── Activity ─────────────────────────────────────────────────────────────────
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository(ref.watch(firestoreProvider));
});

// ─── Derived data providers ────────────────────────────────────────────────────

/// The currently selected home ID (persisted via StateProvider).
final selectedHomeIdProvider = StateProvider<String?>((ref) => null);

/// Stream of the current user's homes.
final userHomesProvider = StreamProvider<List<HomeModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return const Stream.empty();
  return ref.watch(homeRepositoryProvider).getUserHomes(userId);
});

/// The first/active home for the current user.
final currentHomeProvider = StreamProvider<HomeModel?>((ref) {
  final homes = ref.watch(userHomesProvider);
  return homes.when(
    data: (list) {
      if (list.isEmpty) return Stream.value(null);
      return ref.watch(homeRepositoryProvider).watchHome(list.first.id);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

/// Rooms in the current home.
final homeRoomsProvider = StreamProvider<List<RoomModel>>((ref) {
  final home = ref.watch(currentHomeProvider).valueOrNull;
  if (home == null) return const Stream.empty();
  return ref.watch(roomRepositoryProvider).getRooms(home.id);
});

/// All channels (appliances) in the current home.
final homeChannelsProvider = StreamProvider<List<ChannelModel>>((ref) {
  final home = ref.watch(currentHomeProvider).valueOrNull;
  if (home == null) return const Stream.empty();
  return ref.watch(channelRepositoryProvider).watchHomeChannels(home.id);
});

/// Channels grouped by roomId.
final channelsByRoomProvider =
    Provider<Map<String?, List<ChannelModel>>>((ref) {
  final channels = ref.watch(homeChannelsProvider).valueOrNull ?? [];
  final map = <String?, List<ChannelModel>>{};
  for (final ch in channels) {
    map.putIfAbsent(ch.roomId, () => []).add(ch);
  }
  return map;
});

/// All devices in the current home.
final homeDevicesProvider = StreamProvider<List<DeviceModel>>((ref) {
  final home = ref.watch(currentHomeProvider).valueOrNull;
  if (home == null) return const Stream.empty();
  return ref.watch(deviceRepositoryProvider).getHomeDevices(home.id);
});

/// All schedules in the current home.
final homeSchedulesProvider = StreamProvider<List<ScheduleModel>>((ref) {
  final home = ref.watch(currentHomeProvider).valueOrNull;
  if (home == null) return const Stream.empty();
  return ref.watch(scheduleRepositoryProvider).watchSchedules(home.id);
});

/// Recent activity events in the current home.
final homeActivityProvider = StreamProvider<List<ActivityEventModel>>((ref) {
  final home = ref.watch(currentHomeProvider).valueOrNull;
  if (home == null) return const Stream.empty();
  return ref.watch(activityRepositoryProvider).watchEvents(home.id);
});

/// Unread activity count.
final unreadActivityCountProvider = StreamProvider<int>((ref) {
  final home = ref.watch(currentHomeProvider).valueOrNull;
  if (home == null) return Stream.value(0);
  return ref.watch(activityRepositoryProvider).getUnreadCount(home.id);
});
