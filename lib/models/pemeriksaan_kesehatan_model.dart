// TODO: tambahkan fromMap(), toMap(), copyWith(), dan fromDocument() secara seragam ke semua model setelah field database FIX.

class PemeriksaanKesehatanModel {
  final String id;

  final String bull_id;

  final DateTime tanggal;

  final String kondisi;

  final String diagnosa;

  final String tindakan;

  final String keterangan;

  final String petugas_uid;

  final DateTime created_at;

  final DateTime updated_at;

  PemeriksaanKesehatanModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.kondisi,
    required this.diagnosa,
    required this.tindakan,
    required this.keterangan,
    required this.petugas_uid,
    required this.created_at,
    required this.updated_at,
  });
}