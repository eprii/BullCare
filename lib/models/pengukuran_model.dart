import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class PengukuranModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final double tinggi_gumba;
  final double panjang_tubuh;
  final double lingkar_badan;
  final double lingkar_skrotum;
  final String keterangan;
  final String petugas_uid;
  final DateTime created_at;
  final DateTime updated_at;

  const PengukuranModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.tinggi_gumba,
    required this.panjang_tubuh,
    required this.lingkar_badan,
    required this.lingkar_skrotum,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });

  factory PengukuranModel.fromMap(String id, Map<String, dynamic> map) {
    return PengukuranModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      tinggi_gumba: doubleFromFirestore(map['tinggi_gumba']),
      panjang_tubuh: doubleFromFirestore(map['panjang_tubuh']),
      lingkar_badan: doubleFromFirestore(map['lingkar_badan']),
      lingkar_skrotum: doubleFromFirestore(map['lingkar_skrotum']),
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
      'tinggi_gumba': tinggi_gumba,
      'panjang_tubuh': panjang_tubuh,
      'lingkar_badan': lingkar_badan,
      'lingkar_skrotum': lingkar_skrotum,
      'keterangan': keterangan,
      'petugas_uid': petugas_uid,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  PengukuranModel copyWith({
    String? id,
    String? bull_id,
    DateTime? tanggal,
    double? tinggi_gumba,
    double? panjang_tubuh,
    double? lingkar_badan,
    double? lingkar_skrotum,
    String? keterangan,
    String? petugas_uid,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return PengukuranModel(
      id: id ?? this.id,
      bull_id: bull_id ?? this.bull_id,
      tanggal: tanggal ?? this.tanggal,
      tinggi_gumba: tinggi_gumba ?? this.tinggi_gumba,
      panjang_tubuh: panjang_tubuh ?? this.panjang_tubuh,
      lingkar_badan: lingkar_badan ?? this.lingkar_badan,
      lingkar_skrotum: lingkar_skrotum ?? this.lingkar_skrotum,
      keterangan: keterangan ?? this.keterangan,
      petugas_uid: petugas_uid ?? this.petugas_uid,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
