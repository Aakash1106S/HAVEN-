import 'package:flutter_test/flutter_test.dart';
import 'package:haven_mobile/shared/models/channel_model.dart';
import 'package:haven_mobile/shared/models/home_model.dart';
import 'package:haven_mobile/shared/models/room_model.dart';
import 'package:haven_mobile/shared/models/device_model.dart';
import 'package:haven_mobile/core/utils/validators.dart';

void main() {
  group('Data Models Unit Tests', () {
    test('ChannelModel state properties', () {
      final channel = ChannelModel(
        id: 'ch-0',
        homeId: 'home-123',
        deviceId: 'esp32-abc',
        roomId: 'room-1',
        channelNumber: 0,
        applianceName: 'Living Room Light',
        desiredState: ApplianceState.on,
        reportedState: ApplianceState.off,
        commandStatus: CommandStatus.queued,
        createdAt: DateTime.now(),
      );

      expect(channel.isPending, isTrue);
      expect(channel.isStale, isTrue);
      expect(channel.displayStatus, equals('Queued'));
    });

    test('DeviceModel online status', () {
      final device = DeviceModel(
        id: 'esp32-abc',
        homeId: 'home-123',
        name: 'Main Controller',
        status: DeviceStatus.online,
        ownerId: 'user-456',
        createdAt: DateTime.now(),
      );

      expect(device.isOnline, isTrue);
    });

    test('RoomModel icon codepoint lookup', () {
      final room = RoomModel(
        id: 'room-1',
        homeId: 'home-123',
        name: 'Living Room',
        icon: 'living_room',
        order: 0,
        createdAt: DateTime.now(),
      );

      expect(room.name, equals('Living Room'));
      expect(RoomModel.roomIcons.contains('living_room'), isTrue);
    });

    test('HomeModel member verification', () {
      final home = HomeModel(
        id: 'home-123',
        name: 'Sweet Home',
        timezone: 'Asia/Kolkata',
        ownerId: 'user-1',
        memberIds: ['user-2'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(home.ownerId, equals('user-1'));
      expect(home.memberIds, contains('user-2'));
    });
  });

  group('Validators Unit Tests', () {
    test('Email validator', () {
      expect(Validators.email('test@example.com'), isNull);
      expect(Validators.email('invalid-email'), isNotNull);
      expect(Validators.email(''), isNotNull);
    });

    test('Password validator', () {
      expect(Validators.password('Secret123!'), isNull);
      expect(Validators.password('short'), isNotNull);
    });
  });
}
