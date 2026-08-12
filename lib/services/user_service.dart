import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/app_constants.dart';
import '../models/user_model.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Future<UserModel?> getUser(String uid) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _users.doc(uid).get();
    final Map<String, dynamic>? data = doc.data();
    return data == null ? null : UserModel.fromMap(doc.id, data);
  }

  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final Map<String, dynamic>? data = doc.data();
      return data == null ? null : UserModel.fromMap(doc.id, data);
    });
  }

  Future<void> createPetugasProfile({required User user, required String nama}) async {
    final DateTime now = DateTime.now();
    await _users.doc(user.uid).set(<String, dynamic>{
      'uid': user.uid,
      'nama': nama,
      'email': user.email ?? '',
      'role': AppConstants.petugasRole,
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
    });
  }

  Future<void> ensureUserProfile(User user) async {
    final DocumentReference<Map<String, dynamic>> ref = _users.doc(user.uid);
    final DocumentSnapshot<Map<String, dynamic>> doc = await ref.get();
    if (doc.exists) return;
    await createPetugasProfile(
      user: user,
      nama: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email?.split('@').first ?? 'Petugas'),
    );
  }
}
