import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_event_model.dart';

class ActivityRepository {
  final FirebaseFirestore _db;
  ActivityRepository(this._db);

  CollectionReference _activity(String homeId) =>
      _db.collection('homes').doc(homeId).collection('activity');

  Future<void> addEvent(String homeId, ActivityEventModel event) async {
    final ref = _activity(homeId).doc();
    final data = event.toFirestore();
    data['id'] = ref.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
  }

  Stream<List<ActivityEventModel>> watchEvents(String homeId, {int limit = 20}) {
    return _activity(homeId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(ActivityEventModel.fromFirestore).toList());
  }

  Future<List<ActivityEventModel>> loadMoreEvents(
    String homeId,
    DocumentSnapshot lastDoc, {
    int limit = 20,
  }) async {
    final snap = await _activity(homeId)
        .orderBy('createdAt', descending: true)
        .startAfterDocument(lastDoc)
        .limit(limit)
        .get();
    return snap.docs.map(ActivityEventModel.fromFirestore).toList();
  }

  Future<void> markEventRead(String homeId, String eventId) async {
    await _activity(homeId).doc(eventId).update({'read': true});
  }

  Future<void> markAllRead(String homeId) async {
    final snap = await _activity(homeId)
        .where('read', isEqualTo: false)
        .limit(100)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }

  Stream<int> getUnreadCount(String homeId) {
    return _activity(homeId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}
