class SanitasiModel {
// TODO: tambahkan fromMap(), toMap(), copyWith(), dan fromDocument() secara seragam ke semua model setelah field database FIX.

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

  SanitasiModel({
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
}