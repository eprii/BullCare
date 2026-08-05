// TODO: tambahkan fromMap(), toMap(), copyWith(), dan fromDocument() secara seragam ke semua model setelah field database FIX.

class PenimbanganModel {
  final String id;

  final String bull_id;

  final DateTime tanggal;

  final double berat_badan;

  final String keterangan;

  final String petugas_uid;

  final DateTime created_at;

  final DateTime updated_at;

  PenimbanganModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.berat_badan,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });
}