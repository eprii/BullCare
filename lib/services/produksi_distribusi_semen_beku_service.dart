
import 'package:cloud_firestore/cloud_firestore.dart';

class ProduksiDistribusiSemenBekuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('produksi_distribusi_semen_beku');

  Future<void> saveData({
    required int tahun,
    required Map<String, dynamic> dataBulan,
    required String kategori,
    required String bangsa,
    required int jumlahPejantan,
    required int stockTahun,
    required String namaPetugas,
  }) async {
    await _collection.doc('$tahun').set({
      'tahun': tahun,
      'kategori': kategori,
      'bangsa': bangsa,
      'jumlah_pejantan': jumlahPejantan,
      'stock_tahun': stockTahun,
      'bulan': dataBulan,
      'nama_petugas': namaPetugas,
      'updated_at': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getByYear(int tahun) {
    return _collection.doc('$tahun').get();
  }
}
