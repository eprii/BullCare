// TODO: tambahkan fromMap(), toMap(), copyWith(), dan fromDocument() secara seragam ke semua model setelah field database FIX.

class PengobatanModel {
  final String id;

  final String bull_id;

  final DateTime tanggal;

  final String gejala_klinis;

  final String diagnosa;

  final String terapi;

  final String keterangan;

  final String petugas_uid;

  final DateTime created_at;

  final DateTime updated_at;

  PengobatanModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.gejala_klinis,
    required this.diagnosa,
    required this.terapi,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });
}