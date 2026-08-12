import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class PenimbanganModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final double berat_badan;
  final String keterangan;
  final String petugas_uid;
  final DateTime created_at;
  final DateTime updated_at;

  const PenimbanganModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.berat_badan,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });

  factory PenimbanganModel.fromMap(String id, Map<String, dynamic> map) {
    return PenimbanganModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      berat_badan: doubleFromFirestore(map['berat_badan']),
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
      'berat_badan': berat_badan,
      'keterangan': keterangan,
      'petugas_uid': petugas_uid,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  PenimbanganModel copyWith({
    String? id,
    String? bull_id,
    DateTime? tanggal,
    double? berat_badan,
    String? keterangan,
    String? petugas_uid,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return PenimbanganModel(
      id: id ?? this.id,
      bull_id: bull_id ?? this.bull_id,
      tanggal: tanggal ?? this.tanggal,
      berat_badan: berat_badan ?? this.berat_badan,
      keterangan: keterangan ?? this.keterangan,
      petugas_uid: petugas_uid ?? this.petugas_uid,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
