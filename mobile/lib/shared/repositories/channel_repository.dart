import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/channel_model.dart';
import '../models/command_model.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_constants.dart';

class ChannelRepository {
  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  ChannelRepository(this._db, this._auth);

  CollectionReference _channels(String homeId) =>
      _db.collection('homes').doc(homeId).collection('channels');

  CollectionReference _commands(String homeId) =>
      _db.collection('homes').doc(homeId).collection('commands');

  Future<String> createChannel(String homeId, ChannelModel channel) async {
    final ref = _channels(homeId).doc();
    final data = channel.toFirestore();
    data['id'] = ref.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  Stream<ChannelModel?> watchChannel(String homeId, String channelId) {
    return _channels(homeId).doc(channelId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChannelModel.fromFirestore(doc);
    });
  }

  Stream<List<ChannelModel>> watchRoomChannels(
      String homeId, String roomId) {
    return _channels(homeId)
        .where('roomId', isEqualTo: roomId)
        .snapshots()
        .map((snap) => snap.docs.map(ChannelModel.fromFirestore).toList());
  }

  Stream<List<ChannelModel>> watchHomeChannels(String homeId) {
    return _channels(homeId)
        .snapshots()
        .map((snap) => snap.docs.map(ChannelModel.fromFirestore).toList());
  }

  Future<void> updateChannel(String homeId, ChannelModel channel) async {
    await _channels(homeId).doc(channel.id).update({
      'applianceName': channel.applianceName,
      'roomId': channel.roomId,
    });
  }

  Future<void> updateChannelRoom(
      String homeId, String channelId, String? roomId) async {
    await _channels(homeId).doc(channelId).update({'roomId': roomId});
  }

  Future<void> deleteChannel(String homeId, String channelId) async {
    await _channels(homeId).doc(channelId).delete();
  }

  /// Submit an ON/OFF command via the backend API with fallback to direct Firestore for local dev/simulator.
  /// Returns the commandId on success.
  Future<String> sendCommand(
    String homeId,
    String channelId,
    ApplianceState action,
    String userId,
  ) async {
    final idempotencyKey = const Uuid().v4();

    // Get fresh ID token
    final token = await _auth.currentUser?.getIdToken(true);
    if (token == null) throw Exception('Not authenticated');

    // 1. Attempt dispatch via backend command service if configured
    if (!AppConstants.commandServiceUrl.contains('YOUR-CLOUD-RUN-URL')) {
      try {
        final response = await http.post(
          Uri.parse('${AppConstants.commandServiceUrl}/api/commands'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'homeId': homeId,
            'channelId': channelId,
            'action': action == ApplianceState.on ? 'on' : 'off',
            'idempotencyKey': idempotencyKey,
          }),
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200 || response.statusCode == 201) {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          return body['commandId'] as String;
        }
      } catch (_) {
        // Fall through
      }
    }

    // 2. Direct dispatch to ESP32 Hotspot if phone is on ESP32_Relay Wi-Fi
    try {
      final chDoc = await _channels(homeId).doc(channelId).get();
      final data = chDoc.data() as Map<String, dynamic>?;
      final chNum = data?['channelNumber'] as int? ?? 0;
      final relayNum = chNum + 1;
      final stateStr = action == ApplianceState.on ? 'on' : 'off';
      await http
          .get(Uri.parse('http://192.168.4.1/api/set?relay=$relayNum&state=$stateStr'))
          .timeout(const Duration(milliseconds: 1500));
    } catch (_) {
      try {
        final chDoc = await _channels(homeId).doc(channelId).get();
        final data = chDoc.data() as Map<String, dynamic>?;
        final chNum = data?['channelNumber'] as int? ?? 0;
        await http
            .get(Uri.parse('http://192.168.4.1/toggle?relay=${chNum + 1}'))
            .timeout(const Duration(milliseconds: 1500));
      } catch (_) {}
    }

    // 3. Direct Firestore command dispatch (for cloud history and simulator sync)
    final cmdRef = _commands(homeId).doc();
    final cmdId = cmdRef.id;
    final now = DateTime.now();
    await cmdRef.set({
      'id': cmdId,
      'homeId': homeId,
      'channelId': channelId,
      'userId': userId,
      'action': action.name,
      'status': 'dispatched',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(now.add(const Duration(seconds: 30))),
      'correlationId': const Uuid().v4(),
      'idempotencyKey': idempotencyKey,
    });

    await _channels(homeId).doc(channelId).update({
      'desiredState': action.name,
      'commandStatus': 'dispatched',
      'lastCommandId': cmdId,
      'lastCommandAt': FieldValue.serverTimestamp(),
    });

    return cmdId;
  }

  Stream<CommandModel?> watchCommand(String homeId, String commandId) {
    return _commands(homeId).doc(commandId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return CommandModel.fromFirestore(doc);
    });
  }

  Future<List<CommandModel>> getRecentCommands(
    String homeId,
    String channelId, {
    int limit = 10,
  }) async {
    final snap = await _commands(homeId)
        .where('channelId', isEqualTo: channelId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map(CommandModel.fromFirestore).toList();
  }
}
