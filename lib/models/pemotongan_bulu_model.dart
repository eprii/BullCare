// TODO: tambahkan fromMap(), toMap(), copyWith(), dan fromDocument() secara seragam ke semua model setelah field database FIX.

class PemotonganBuluModel {
  final String id;

  final String bull_id;

  final DateTime tanggal;

  final bool dipotong;

  final String keterangan;

  final String petugas_uid;

  final DateTime created_at;

  final DateTime updated_at;

  PemotonganBuluModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.dipotong,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });
}