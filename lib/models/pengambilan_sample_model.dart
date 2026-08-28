import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';

class PengambilanSampleModel {
  final String id;
  final String bull_id;
  final DateTime tanggal;
  final String petugas_uid;
  final String nama_petugas;
  final bool darah;
  final bool serum;
  final bool ulas_darah;
  final bool swab;
  final bool feses;
  final String keterangan;
  final DateTime created_at;
  final DateTime updated_at;

  const PengambilanSampleModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.petugas_uid,
    required this.nama_petugas,
    required this.darah,
    required this.serum,
    required this.ulas_darah,
    required this.swab,
    required this.feses,
    required this.keterangan,
    required this.created_at,
    required this.updated_at,
  });

  factory PengambilanSampleModel.fromMap(String id, Map<String, dynamic> map) {
    return PengambilanSampleModel(
      id: id,
      bull_id: map['bull_id']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      petugas_uid: map['petugas_uid']?.toString() ?? '',
      nama_petugas: map['nama_petugas']?.toString() ?? '',
      darah: map['darah'] == true,
      serum: map['serum'] == true,
      ulas_darah: map['ulas_darah'] == true,
      swab: map['swab'] == true,
      feses: map['feses'] == true,
      keterangan: map['keterangan']?.toString() ?? '',
      created_at: dateTimeFromFirestore(map['created_at']),
      updated_at: dateTimeFromFirestore(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'bull_id': bull_id,
      'tanggal': Timestamp.fromDate(tanggal),
      'petugas_uid': petugas_uid,
      'nama_petugas': nama_petugas,
      'darah': darah,
      'serum': serum,
      'ulas_darah': ulas_darah,
      'swab': swab,
      'feses': feses,
      'keterangan': keterangan,
      'created_at': Timestamp.fromDate(created_at),
      'updated_at': Timestamp.fromDate(updated_at),
    };
  }

  PengambilanSampleModel copyWith({
    String? id,
    String? bull_id,
    DateTime? tanggal,
    String? petugas_uid,
    String? nama_petugas,
    bool? darah,
    bool? serum,
    bool? ulas_darah,
    bool? swab,
    bool? feses,
    String? keterangan,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return PengambilanSampleModel(
      id: id ?? this.id,
      bull_id: bull_id ?? this.bull_id,
      tanggal: tanggal ?? this.tanggal,
      petugas_uid: petugas_uid ?? this.petugas_uid,
      nama_petugas: nama_petugas ?? this.nama_petugas,
      darah: darah ?? this.darah,
      serum: serum ?? this.serum,
      ulas_darah: ulas_darah ?? this.ulas_darah,
      swab: swab ?? this.swab,
      feses: feses ?? this.feses,
      keterangan: keterangan ?? this.keterangan,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}