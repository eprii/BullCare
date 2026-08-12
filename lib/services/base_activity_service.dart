import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_record.dart';

class BaseActivityService {
  BaseActivityService(this.collectionName, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String collectionName;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get collection =>
      _firestore.collection(collectionName);

  Future<String> addActivity({
    required String bullId,
    required String petugasUid,
    required DateTime tanggal,
    required Map<String, dynamic> values,
  }) async {
    final DateTime now = DateTime.now();
    final DocumentReference<Map<String, dynamic>> ref = await collection.add(<String, dynamic>{
      ...values,
      'bull_id': bullId,
      'petugas_uid': petugasUid,
      'tanggal': Timestamp.fromDate(tanggal),
      'created_at': Timestamp.fromDate(now),
      'updated_at': Timestamp.fromDate(now),
    });
    return ref.id;
  }

  Future<void> updateActivity({
    required String id,
    required DateTime tanggal,
    required Map<String, dynamic> values,
  }) {
    return collection.doc(id).update(<String, dynamic>{
      ...values,
      'tanggal': Timestamp.fromDate(tanggal),
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<void> deleteActivity(String id) {
    if (id.trim().isEmpty) {
      throw ArgumentError('ID aktivitas tidak boleh kosong.');
    }
    return collection.doc(id).delete();
  }

  Future<List<ActivityRecord>> getAll() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await collection.get();
    final List<ActivityRecord> records = snapshot.docs
        .map((doc) => ActivityRecord.fromMap(doc.id, collectionName, doc.data()))
        .toList();
    records.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return records;
  }

  Future<List<ActivityRecord>> getForBull(String bullId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await collection.where('bull_id', isEqualTo: bullId).get();
    final List<ActivityRecord> records = snapshot.docs
        .map((doc) => ActivityRecord.fromMap(doc.id, collectionName, doc.data()))
        .toList();
    records.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return records;
  }

  Future<ActivityRecord?> getLatestForBull(String bullId) async {
    final List<ActivityRecord> records = await getForBull(bullId);
    return records.isEmpty ? null : records.first;
  }

  Future<List<ActivityRecord>> getRecent({int limit = 10}) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await collection
        .orderBy('tanggal', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => ActivityRecord.fromMap(doc.id, collectionName, doc.data()))
        .toList(growable: false);
  }

  Future<Set<String>> getBullIdsRecordedOn(DateTime day) async {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));
    final QuerySnapshot<Map<String, dynamic>> snapshot = await collection
        .where('tanggal', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('tanggal', isLessThan: Timestamp.fromDate(end))
        .get();
    return snapshot.docs
        .map((doc) => doc.data()['bull_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  }
}
