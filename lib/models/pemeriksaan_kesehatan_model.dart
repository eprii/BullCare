import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class PemeriksaanKesehatanModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final String kondisi;
  final String diagnosa;
  final String tindakan;
  final String keterangan;
  final String petugas_uid;
  final DateTime created_at;
  final DateTime updated_at;

  const PemeriksaanKesehatanModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.kondisi,
    required this.diagnosa,
    required this.tindakan,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });

  factory PemeriksaanKesehatanModel.fromMap(String id, Map<String, dynamic> map) {
    return PemeriksaanKesehatanModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      kondisi: map['kondisi']?.toString() ?? '',
      diagnosa: map['diagnosa']?.toString() ?? '',
      tindakan: map['tindakan']?.toString() ?? '',
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
      'kondisi': kondisi,
      'diagnosa': diagnosa,
      'tindakan': tindakan,
      'keterangan': keterangan,
      'petugas_uid': petugas_uid,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  PemeriksaanKesehatanModel copyWith({
    String? id,
    String? bull_id,
    DateTime? tanggal,
    String? kondisi,
    String? diagnosa,
    String? tindakan,
    String? keterangan,
    String? petugas_uid,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return PemeriksaanKesehatanModel(
      id: id ?? this.id,
      bull_id: bull_id ?? this.bull_id,
      tanggal: tanggal ?? this.tanggal,
      kondisi: kondisi ?? this.kondisi,
      diagnosa: diagnosa ?? this.diagnosa,
      tindakan: tindakan ?? this.tindakan,
      keterangan: keterangan ?? this.keterangan,
      petugas_uid: petugas_uid ?? this.petugas_uid,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
