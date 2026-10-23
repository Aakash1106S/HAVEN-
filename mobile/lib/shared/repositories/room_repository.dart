import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/room_model.dart';

class RoomRepository {
  final FirebaseFirestore _db;
  RoomRepository(this._db);

  CollectionReference _rooms(String homeId) =>
      _db.collection('homes').doc(homeId).collection('rooms');

  CollectionReference _channels(String homeId) =>
      _db.collection('homes').doc(homeId).collection('channels');

  Future<String> createRoom(String homeId, RoomModel room) async {
    final ref = _rooms(homeId).doc();
    final data = room.toFirestore();
    data['id'] = ref.id;
    data['homeId'] = homeId;
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  Stream<List<RoomModel>> getRooms(String homeId) {
    return _rooms(homeId)
        .orderBy('order')
        .snapshots()
        .map((snap) => snap.docs.map(RoomModel.fromFirestore).toList());
  }

  Future<RoomModel?> getRoom(String homeId, String roomId) async {
    final doc = await _rooms(homeId).doc(roomId).get();
    if (!doc.exists) return null;
    return RoomModel.fromFirestore(doc);
  }

  Future<void> updateRoom(String homeId, RoomModel room) async {
    await _rooms(homeId).doc(room.id).update(room.toFirestore());
  }

  Future<void> deleteRoom(String homeId, String roomId) async {
    // Unassign channels from this room first
    final channelSnap = await _channels(homeId)
        .where('roomId', isEqualTo: roomId)
        .get();

    final batch = _db.batch();
    for (final doc in channelSnap.docs) {
      batch.update(doc.reference, {'roomId': null});
    }
    batch.delete(_rooms(homeId).doc(roomId));
    await batch.commit();
  }

  Future<void> reorderRooms(
      String homeId, List<String> orderedRoomIds) async {
    final batch = _db.batch();
    for (var i = 0; i < orderedRoomIds.length; i++) {
      batch.update(
        _rooms(homeId).doc(orderedRoomIds[i]),
        {'order': i},
      );
    }
    await batch.commit();
  }
}
