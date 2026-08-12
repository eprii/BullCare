import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class SanitasiModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final bool sanitasi_kandang;
  final bool sanitasi_pejantan;
  final bool sanitasi_tempat_pakan;
  final String keterangan;
  final String petugas_uid;
  final DateTime created_at;
  final DateTime updated_at;

  const SanitasiModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.sanitasi_kandang,
    required this.sanitasi_pejantan,
    required this.sanitasi_tempat_pakan,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });

  factory SanitasiModel.fromMap(String id, Map<String, dynamic> map) {
    return SanitasiModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      sanitasi_kandang: map['sanitasi_kandang'] == true,
      sanitasi_pejantan: map['sanitasi_pejantan'] == true,
      sanitasi_tempat_pakan: map['sanitasi_tempat_pakan'] == true,
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
      'sanitasi_kandang': sanitasi_kandang,
      'sanitasi_pejantan': sanitasi_pejantan,
      'sanitasi_tempat_pakan': sanitasi_tempat_pakan,
      'keterangan': keterangan,
      'petugas_uid': petugas_uid,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  SanitasiModel copyWith({
    String? id,
    String? bull_id,
    DateTime? tanggal,
    bool? sanitasi_kandang,
    bool? sanitasi_pejantan,
    bool? sanitasi_tempat_pakan,
    String? keterangan,
    String? petugas_uid,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return SanitasiModel(
      id: id ?? this.id,
      bull_id: bull_id ?? this.bull_id,
      tanggal: tanggal ?? this.tanggal,
      sanitasi_kandang: sanitasi_kandang ?? this.sanitasi_kandang,
      sanitasi_pejantan: sanitasi_pejantan ?? this.sanitasi_pejantan,
      sanitasi_tempat_pakan: sanitasi_tempat_pakan ?? this.sanitasi_tempat_pakan,
      keterangan: keterangan ?? this.keterangan,
      petugas_uid: petugas_uid ?? this.petugas_uid,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
