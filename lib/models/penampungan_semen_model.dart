import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class PenampunganSemenModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final double volume_semen;
  final double suhu_av;
  final String petugas_uid;
  final String keterangan;
  final DateTime created_at;
  final DateTime updated_at;

  const PenampunganSemenModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.volume_semen,
    required this.suhu_av,
    required this.petugas_uid,
    required this.keterangan,
    required this.created_at,
    required this.updated_at,
  });

  factory PenampunganSemenModel.fromMap(String id, Map<String, dynamic> map) {
    return PenampunganSemenModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      volume_semen: doubleFromFirestore(map['volume_semen']),
      suhu_av: doubleFromFirestore(map['suhu_av']),
      petugas_uid: map['petugas_uid']?.toString() ?? '',
      keterangan: map['keterangan']?.toString() ?? '',
      created_at: dateTimeFromFirestore(map['created_at']),
      updated_at: dateTimeFromFirestore(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bull_id': bull_id,
      'tanggal': Timestamp.fromDate(tanggal),
      'volume_semen': volume_semen,
      'suhu_av': suhu_av,
      'petugas_uid': petugas_uid,
      'keterangan': keterangan,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  PenampunganSemenModel copyWith({
    String? id,
    String? bull_id,
    DateTime? tanggal,
    double? volume_semen,
    double? suhu_av,
    String? petugas_uid,
    String? keterangan,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return PenampunganSemenModel(
      id: id ?? this.id,
      bull_id: bull_id ?? this.bull_id,
      tanggal: tanggal ?? this.tanggal,
      volume_semen: volume_semen ?? this.volume_semen,
      suhu_av: suhu_av ?? this.suhu_av,
      petugas_uid: petugas_uid ?? this.petugas_uid,
      keterangan: keterangan ?? this.keterangan,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
