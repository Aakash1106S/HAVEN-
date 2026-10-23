import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/home_model.dart';

class HomeRepository {
  final FirebaseFirestore _db;
  HomeRepository(this._db);

  CollectionReference get _homes => _db.collection('homes');

  Future<String> createHome(HomeModel home) async {
    final ref = _homes.doc();
    final data = home.toFirestore();
    data['id'] = ref.id;
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await ref.set(data);
    return ref.id;
  }

  Future<HomeModel?> getHome(String homeId) async {
    final doc = await _homes.doc(homeId).get();
    if (!doc.exists) return null;
    return HomeModel.fromFirestore(doc);
  }

  Stream<HomeModel?> watchHome(String homeId) {
    return _homes.doc(homeId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return HomeModel.fromFirestore(doc);
    });
  }

  Future<void> updateHome(HomeModel home) async {
    final data = home.toFirestore();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _homes.doc(home.id).update(data);
  }

  Future<void> deleteHome(String homeId) async {
    await _homes.doc(homeId).delete();
  }

  Stream<List<HomeModel>> getUserHomes(String userId) {
    return _homes
        .where('ownerId', isEqualTo: userId)
        .snapshots()
        .map((snap) => snap.docs.map(HomeModel.fromFirestore).toList());
  }

  Future<void> setHomeTimezone(String homeId, String timezone) async {
    await _homes.doc(homeId).update({
      'timezone': timezone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
