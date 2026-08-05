// TODO: tambahkan fromMap(), toMap(), copyWith(), dan fromDocument() secara seragam ke semua model setelah field database FIX.

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

  PengukuranModel({
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
}