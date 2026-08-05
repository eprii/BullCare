// TODO: tambahkan fromMap(), toMap(), copyWith(), dan fromDocument() secara seragam ke semua model setelah field database FIX.

class BullModel {
  final String id;
  final String kode_bull;
  final String nama;
  final String bangsa;
  final String nomor_kandang;
  final String warna_straw;
  final String status;

  final DateTime created_at;
  final DateTime updated_at;

  BullModel({
    required this.id,
    required this.kode_bull,
    required this.nama,
    required this.bangsa,
    required this.nomor_kandang,
    required this.warna_straw,
    required this.status,
    required this.created_at,
    required this.updated_at,
  });

  factory BullModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return BullModel(
      id: id,
      kode_bull: map['kode_bull'] ?? '',
      nama: map['nama'] ?? '',
      bangsa: map['bangsa'] ?? '',
      nomor_kandang: map['nomor_kandang'] ?? '',
      warna_straw: map['warna_straw'] ?? '',
      status: map['status'] ?? '',
      created_at: map['created_at'].toDate(),
      updated_at: map['updated_at'].toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kode_bull': kode_bull,
      'nama': nama,
      'bangsa': bangsa,
      'nomor_kandang': nomor_kandang,
      'warna_straw': warna_straw,
      'status': status,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }
}