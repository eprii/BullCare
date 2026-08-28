import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_utils.dart';

class BedahBangkaiModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final DateTime tanggal_mati;
  final String peralatan;
  final String pemeriksaan_organ;
  final DateTime? tanggal_pengiriman_laboratorium;
  final DateTime? tanggal_jawaban;
  final String keterangan;
  final String petugas_uid;
  final String nama_petugas;
  final DateTime created_at;
  final DateTime updated_at;

  const BedahBangkaiModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.tanggal_mati,
    required this.peralatan,
    required this.pemeriksaan_organ,
    required this.tanggal_pengiriman_laboratorium,
    required this.tanggal_jawaban,
    required this.keterangan,
    required this.petugas_uid,
    required this.nama_petugas,
    required this.created_at,
    required this.updated_at,
  });

  factory BedahBangkaiModel.fromMap(String id, Map<String, dynamic> map) {
    return BedahBangkaiModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      tanggal_mati: dateTimeFromFirestore(map['tanggal_mati']),
      peralatan: map['peralatan']?.toString() ?? '',
      pemeriksaan_organ: map['pemeriksaan_organ']?.toString() ?? '',
      tanggal_pengiriman_laboratorium:
          _nullableDate(map['tanggal_pengiriman_laboratorium']),
      tanggal_jawaban: _nullableDate(map['tanggal_jawaban']),
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
      'tanggal_mati': Timestamp.fromDate(tanggal_mati),
      'peralatan': peralatan,
      'pemeriksaan_organ': pemeriksaan_organ,
      'tanggal_pengiriman_laboratorium':
          tanggal_pengiriman_laboratorium == null
              ? null
              : Timestamp.fromDate(tanggal_pengiriman_laboratorium!),
      'tanggal_jawaban': tanggal_jawaban == null
          ? null
          : Timestamp.fromDate(tanggal_jawaban!),
      'keterangan': keterangan,
      'petugas_uid': petugas_uid,
      'nama_petugas': nama_petugas,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }
}

DateTime? _nullableDate(dynamic value) {
  if (value == null) return null;
  return dateTimeFromFirestore(value);
}
