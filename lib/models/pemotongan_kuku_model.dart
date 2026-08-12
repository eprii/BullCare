import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class PemotonganKukuModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final bool dipotong;
  final String keterangan;
  final String petugas_uid;
  final DateTime created_at;
  final DateTime updated_at;

  const PemotonganKukuModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.dipotong,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });

  factory PemotonganKukuModel.fromMap(String id, Map<String, dynamic> map) {
    return PemotonganKukuModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      dipotong: map['dipotong'] == true,
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
      'dipotong': dipotong,
      'keterangan': keterangan,
      'petugas_uid': petugas_uid,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  PemotonganKukuModel copyWith({
    String? id,
    String? bull_id,
    DateTime? tanggal,
    bool? dipotong,
    String? keterangan,
    String? petugas_uid,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return PemotonganKukuModel(
      id: id ?? this.id,
      bull_id: bull_id ?? this.bull_id,
      tanggal: tanggal ?? this.tanggal,
      dipotong: dipotong ?? this.dipotong,
      keterangan: keterangan ?? this.keterangan,
      petugas_uid: petugas_uid ?? this.petugas_uid,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
