import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class PemberianObatCacingModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final String nama_obat;
  final String dosis;
  final String keterangan;
  final String petugas_uid;
  final DateTime created_at;
  final DateTime updated_at;

  const PemberianObatCacingModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.nama_obat,
    required this.dosis,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });

  factory PemberianObatCacingModel.fromMap(String id, Map<String, dynamic> map) {
    return PemberianObatCacingModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      nama_obat: map['nama_obat']?.toString() ?? '',
      dosis: map['dosis']?.toString() ?? '',
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
      'nama_obat': nama_obat,
      'dosis': dosis,
      'keterangan': keterangan,
      'petugas_uid': petugas_uid,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  PemberianObatCacingModel copyWith({
    String? id,
    String? bull_id,
    DateTime? tanggal,
    String? nama_obat,
    String? dosis,
    String? keterangan,
    String? petugas_uid,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return PemberianObatCacingModel(
      id: id ?? this.id,
      bull_id: bull_id ?? this.bull_id,
      tanggal: tanggal ?? this.tanggal,
      nama_obat: nama_obat ?? this.nama_obat,
      dosis: dosis ?? this.dosis,
      keterangan: keterangan ?? this.keterangan,
      petugas_uid: petugas_uid ?? this.petugas_uid,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
