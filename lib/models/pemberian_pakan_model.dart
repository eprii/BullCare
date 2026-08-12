import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class PemberianPakanModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final String hijauan;
  final String konsentrat;
  final String kecambah;
  final String keterangan;
  final String petugas_uid;
  final DateTime created_at;
  final DateTime updated_at;

  const PemberianPakanModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.hijauan,
    required this.konsentrat,
    required this.kecambah,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });

  factory PemberianPakanModel.fromMap(String id, Map<String, dynamic> map) {
    return PemberianPakanModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      hijauan: map['hijauan']?.toString() ?? '',
      konsentrat: map['konsentrat']?.toString() ?? '',
      kecambah: map['kecambah']?.toString() ?? '',
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
      'hijauan': hijauan,
      'konsentrat': konsentrat,
      'kecambah': kecambah,
      'keterangan': keterangan,
      'petugas_uid': petugas_uid,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  PemberianPakanModel copyWith({
    String? id,
    String? bull_id,
    DateTime? tanggal,
    String? hijauan,
    String? konsentrat,
    String? kecambah,
    String? keterangan,
    String? petugas_uid,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return PemberianPakanModel(
      id: id ?? this.id,
      bull_id: bull_id ?? this.bull_id,
      tanggal: tanggal ?? this.tanggal,
      hijauan: hijauan ?? this.hijauan,
      konsentrat: konsentrat ?? this.konsentrat,
      kecambah: kecambah ?? this.kecambah,
      keterangan: keterangan ?? this.keterangan,
      petugas_uid: petugas_uid ?? this.petugas_uid,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
