class PenampunganSemenModel {
  final String id;

  final String bull_id;

  final DateTime tanggal;

  final double volume_semen;

  final double suhu_av;

  final String petugas_uid;

  final String keterangan;

  final DateTime created_at;

  final DateTime updated_at;

  PenampunganSemenModel({
    required this.id,
    required this.bull_id,
    required this.tanggal,
    required this.volume_semen,
    required this.suhu_av,
    required this.petugas_uid,
    required this.keterangan,
    required this.created_at,
    required this.updated_at,
  });
}