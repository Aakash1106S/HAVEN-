import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';
import '../models/schedule_execution_model.dart';

class ScheduleRepository {
  final FirebaseFirestore _db;
  ScheduleRepository(this._db);

  CollectionReference _schedules(String homeId) =>
      _db.collection('homes').doc(homeId).collection('schedules');

  Future<String> createSchedule(String homeId, ScheduleModel schedule) async {
    final ref = _schedules(homeId).doc();
    final data = schedule.toFirestore();
    data['id'] = ref.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  Stream<List<ScheduleModel>> watchSchedules(String homeId) {
    return _schedules(homeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ScheduleModel.fromFirestore).toList());
  }

  Stream<List<ScheduleModel>> watchChannelSchedules(
      String homeId, String channelId) {
    return _schedules(homeId)
        .where('channelId', isEqualTo: channelId)
        .snapshots()
        .map((snap) => snap.docs.map(ScheduleModel.fromFirestore).toList());
  }

  Future<void> updateSchedule(String homeId, ScheduleModel schedule) async {
    final data = schedule.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _schedules(homeId).doc(schedule.id).update(data);
  }

  Future<void> deleteSchedule(String homeId, String scheduleId) async {
    await _schedules(homeId).doc(scheduleId).delete();
  }

  Future<void> toggleSchedule(
      String homeId, String scheduleId, bool enabled) async {
    await _schedules(homeId).doc(scheduleId).update({
      'isEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ScheduleExecutionModel>> getExecutionHistory(
    String homeId,
    String scheduleId, {
    int limit = 20,
  }) {
    return _schedules(homeId)
        .doc(scheduleId)
        .collection('executions')
        .orderBy('scheduledAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) =>
            snap.docs.map(ScheduleExecutionModel.fromFirestore).toList());
  }

  Future<void> addExecutionRecord(
    String homeId,
    String scheduleId,
    ScheduleExecutionModel record,
  ) async {
    await _schedules(homeId)
        .doc(scheduleId)
        .collection('executions')
        .doc(record.id)
        .set(record.toFirestore());
  }
}
