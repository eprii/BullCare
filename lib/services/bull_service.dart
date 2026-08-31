import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/bull_model.dart';

class BullService {
  BullService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _bulls => _firestore.collection('bulls');

  Stream<List<BullModel>> watchBulls() {
    return _bulls.orderBy('nama').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => BullModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);
    });
  }

  Stream<BullModel?> watchBull(String id) {
    return _bulls.doc(id).snapshots().map((doc) {
      final Map<String, dynamic>? data = doc.data();
      return data == null ? null : BullModel.fromMap(doc.id, data);
    });
  }

  Future<List<BullModel>> getBulls() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _bulls.orderBy('nama').get();
    return snapshot.docs.map((doc) => BullModel.fromMap(doc.id, doc.data())).toList();
  }

  Future<bool> isKodeBullInUse(
    String kodeBull, {
    String? excludeBullId,
  }) async {
    final String normalizedCode = kodeBull.trim().toLowerCase();
    if (normalizedCode.isEmpty) return false;

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _bulls.get();
    return snapshot.docs.any((doc) {
      if (doc.id == excludeBullId) return false;
      final String existingCode =
          doc.data()['kode_bull']?.toString().trim().toLowerCase() ?? '';
      return existingCode == normalizedCode;
    });
  }

  Future<String> addBull({
    required String kodeBull,
    required String nama,
    required String bangsa,
    required String nomorKandang,
    required String warnaStraw,
    required String umur,
    required String fotoBase64,
    String fotoBackgroundBase64 = '',
    required String status,
    required String statusSni,
  }) async {
    final DateTime now = DateTime.now();
    final DocumentReference<Map<String, dynamic>> ref = await _bulls.add(<String, dynamic>{
      'kode_bull': kodeBull.trim(),
      'nama': nama.trim(),
      'bangsa': bangsa.trim(),
      'nomor_kandang': nomorKandang.trim(),
      'warna_straw': warnaStraw.trim(),
      'umur': umur.trim(),
      'foto_base64': fotoBase64.trim(),
      'foto_background_base64': fotoBackgroundBase64.trim(),
      'status': status,
      'status_sni': statusSni.trim(),
      'sanitasi_reminder_hour': 8,
      'sanitasi_reminder_minute': 0,
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
    });
    return ref.id;
  }

  Future<void> updateBull(BullModel bull) {
    return _bulls.doc(bull.id).update(<String, dynamic>{
      'kode_bull': bull.kode_bull.trim(),
      'nama': bull.nama.trim(),
      'bangsa': bull.bangsa.trim(),
      'nomor_kandang': bull.nomor_kandang.trim(),
      'warna_straw': bull.warna_straw.trim(),
      'umur': bull.umur.trim(),
      'foto_base64': bull.foto_base64.trim(),
      'foto_background_base64': bull.foto_background_base64.trim(),
      'status': bull.status,
      'status_sni': bull.status_sni.trim(),
      'sanitasi_reminder_hour': bull.sanitasi_reminder_hour,
      'sanitasi_reminder_minute': bull.sanitasi_reminder_minute,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }


  Future<void> updateSanitasiReminderTime({
    required String bullId,
    required int hour,
    required int minute,
  }) {
    if (hour < 0 || hour > 23) {
      throw ArgumentError.value(hour, 'hour', 'Jam harus antara 0 dan 23.');
    }
    if (minute < 0 || minute > 59) {
      throw ArgumentError.value(
        minute,
        'minute',
        'Menit harus antara 0 dan 59.',
      );
    }

    return _bulls.doc(bullId).update(<String, dynamic>{
      'sanitasi_reminder_hour': hour,
      'sanitasi_reminder_minute': minute,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteBull(String id) => _bulls.doc(id).delete();
}
