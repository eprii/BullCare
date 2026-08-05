// TODO: tambahkan fromMap(), toMap(), copyWith(), dan fromDocument() secara seragam ke semua model setelah field database FIX.

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

  PemberianObatCacingModel({
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
}