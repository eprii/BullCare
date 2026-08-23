import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class PencegahanEktoparasitModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final String bahan;
  final String alat;
  final String tindakan;
  final String keterangan;
  final String petugas_uid;
  final String nama_petugas;
  final DateTime created_at;
  final DateTime updated_at;

  const PencegahanEktoparasitModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.bahan,
    required this.alat,
    required this.tindakan,
    required this.keterangan,
    required this.petugas_uid,
    required this.nama_petugas,
    required this.created_at,
    required this.updated_at,
  });

  factory PencegahanEktoparasitModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return PencegahanEktoparasitModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      bahan: map['bahan']?.toString() ?? '',
      alat: map['alat']?.toString() ?? '',
      tindakan: map['tindakan']?.toString() ?? '',
      keterangan: map['keterangan']?.toString() ?? '',
      petugas_uid: map['petugas_uid']?.toString() ?? '',
      nama_petugas: map['nama_petugas']?.toString() ?? '',
      created_at: dateTimeFromFirestore(map['created_at']),
      updated_at: dateTimeFromFirestore(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bull_id': bull_id,
      'tanggal': Timestamp.fromDate(tanggal),
      'bahan': bahan,
      'alat': alat,
      'tindakan': tindakan,
      'keterangan': keterangan,
      'petugas_uid': petugas_uid,
      'nama_petugas': nama_petugas,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  PencegahanEktoparasitModel copyWith({
    String? id,
    String? bull_id,
    DateTime? tanggal,
    String? bahan,
    String? alat,
    String? tindakan,
    String? keterangan,
    String? petugas_uid,
    String? nama_petugas,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return PencegahanEktoparasitModel(
      id: id ?? this.id,
      bull_id: bull_id ?? this.bull_id,
      tanggal: tanggal ?? this.tanggal,
      bahan: bahan ?? this.bahan,
      alat: alat ?? this.alat,
      tindakan: tindakan ?? this.tindakan,
      keterangan: keterangan ?? this.keterangan,
      petugas_uid: petugas_uid ?? this.petugas_uid,
      nama_petugas: nama_petugas ?? this.nama_petugas,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}
