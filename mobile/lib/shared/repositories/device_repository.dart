import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/device_model.dart';

class DeviceRepository {
  final FirebaseFirestore _db;
  DeviceRepository(this._db);

  CollectionReference _devices(String homeId) =>
      _db.collection('homes').doc(homeId).collection('devices');

  Future<String> registerDevice(String homeId, DeviceModel device) async {
    final ref = _devices(homeId).doc();
    final data = device.toFirestore();
    data['id'] = ref.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  Future<DeviceModel?> getDevice(String homeId, String deviceId) async {
    final doc = await _devices(homeId).doc(deviceId).get();
    if (!doc.exists) return null;
    return DeviceModel.fromFirestore(doc);
  }

  Stream<DeviceModel?> watchDevice(String homeId, String deviceId) {
    return _devices(homeId).doc(deviceId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DeviceModel.fromFirestore(doc);
    });
  }

  Stream<List<DeviceModel>> getHomeDevices(String homeId) {
    return _devices(homeId)
        .snapshots()
        .map((snap) => snap.docs.map(DeviceModel.fromFirestore).toList());
  }

  Future<void> updateDevice(String homeId, DeviceModel device) async {
    await _devices(homeId).doc(device.id).update({
      'name': device.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeDevice(String homeId, String deviceId) async {
    await _devices(homeId).doc(deviceId).delete();
  }

  Future<void> updateDeviceLastSeen(String homeId, String deviceId) async {
    await _devices(homeId).doc(deviceId).update({
      'lastSeenAt': FieldValue.serverTimestamp(),
      'status': 'online',
    });
  }
}
