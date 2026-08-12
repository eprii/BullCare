import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class PengobatanModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final String gejala_klinis;
  final String diagnosa;
  final String terapi;
  final String keterangan;
  final String petugas_uid;
  final DateTime created_at;
  final DateTime updated_at;

  const PengobatanModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.gejala_klinis,
    required this.diagnosa,
    required this.terapi,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });

  factory PengobatanModel.fromMap(String id, Map<String, dynamic> map) {
    return PengobatanModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      gejala_klinis: map['gejala_klinis']?.toString() ?? '',
      diagnosa: map['diagnosa']?.toString() ?? '',
      terapi: map['terapi']?.toString() ?? '',
      keterangan: map['keterangan']?.toString() ?? '',
      petugas_uid: map['petugas_uid']?.toString() ?? '',
      created_at: dateTimeFromFirestore(map['created_at']),
      updated_at: dateTimeFromFirestore(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bull_id': bull_id,
      'tanggal': Timestamp.fromDate(tanggal),
      'gejala_klinis': gejala_klinis,
      'diagnosa': diagnosa,
      'terapi': terapi,
      'keterangan': keterangan,
      'petugas_uid': petugas_uid,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  PengobatanModel copyWith({
    String? id,
    String? bull_id,
    DateTime? tanggal,
    String? gejala_klinis,
    String? diagnosa,
    String? terapi,
    String? keterangan,
    String? petugas_uid,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return PengobatanModel(
      id: id ?? this.id,
      bull_id: bull_id ?? this.bull_id,
      tanggal: tanggal ?? this.tanggal,
      gejala_klinis: gejala_klinis ?? this.gejala_klinis,
      diagnosa: diagnosa ?? this.diagnosa,
      terapi: terapi ?? this.terapi,
      keterangan: keterangan ?? this.keterangan,
      petugas_uid: petugas_uid ?? this.petugas_uid,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
