import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_record.dart';
import '../utils/bull_breed_name.dart';
import '../utils/bull_sni_status.dart';
import 'base_activity_service.dart';

class ProduksiDistribusiSemenBekuService extends BaseActivityService {
  ProduksiDistribusiSemenBekuService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super('produksi_distribusi_semen_beku', firestore: firestore);

  final FirebaseFirestore _firestore;

  static const String recordTypeMonthly = 'monthly';

  // Periode aktif dipilih dari halaman Produksi & Distribusi Semen Beku.
  // Dashboard menggunakan periode ini agar angka yang ditampilkan konsisten
  // dengan bulan+tahun yang sedang dilihat petugas dalam sesi aplikasi.
  static int? _activeMonth;
  static int? _activeYear;

  void setActivePeriod({required int tahun, required int bulan}) {
    _activeYear = tahun;
    _activeMonth = bulan;
  }

  DateTime? getActivePeriod() {
    final int? year = _activeYear;
    final int? month = _activeMonth;
    if (year == null || month == null) return null;
    return DateTime(year, month, 1);
  }

  // Dipertahankan untuk kompatibilitas pemanggil lama. Dashboard tidak lagi
  // memakai fallback bulan berjalan karena angka harus mengikuti periode
  // yang secara eksplisit dipilih petugas pada modul produksi.
  DateTime getActivePeriodOrCurrent() {
    final DateTime? active = getActivePeriod();
    if (active != null) return active;
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  Future<String> registerMonthlyRecord({
    required String petugasUid,
    required String namaPetugas,
    required String kategori,
    required String bangsa,
    String statusSni = '',
    required int jumlahPejantan,
    required int tahun,
    required int bulan,
  }) async {
    final String normalizedStatusSni = _productionSniStatus(
      kategori: kategori,
      statusSni: statusSni,
      requireForSexing: true,
    );
    final String canonicalBangsa = BullBreedName.canonical(bangsa);
    final ActivityRecord? legacyExisting = await findMonthlyRecord(
      kategori: kategori,
      bangsa: canonicalBangsa,
      statusSni: normalizedStatusSni,
      tahun: tahun,
      bulan: bulan,
    );
    if (legacyExisting != null) {
      throw StateError(
        'Data ${_monthName(bulan)} $tahun untuk $kategori - $canonicalBangsa${_sniSuffix(kategori, normalizedStatusSni)} sudah tersedia. Buka data tersebut untuk melanjutkan pencatatan produksi.',
      );
    }

    final String id = _monthlyDocumentId(
      kategori: kategori,
      bangsa: canonicalBangsa,
      statusSni: normalizedStatusSni,
      tahun: tahun,
      bulan: bulan,
    );
    final DocumentReference<Map<String, dynamic>> ref = collection.doc(id);
    final DateTime now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> existing =
          await transaction.get(ref);
      if (existing.exists) {
        throw StateError(
          'Data ${_monthName(bulan)} $tahun untuk $kategori - $canonicalBangsa${_sniSuffix(kategori, normalizedStatusSni)} sudah tersedia.',
        );
      }

      transaction.set(ref, <String, dynamic>{
        'record_type': recordTypeMonthly,
        'kategori': kategori.trim(),
        'bangsa': canonicalBangsa,
        'status_sni': normalizedStatusSni,
        'jumlah_pejantan': jumlahPejantan,
        'tahun': tahun,
        'bulan': bulan,
        'stock_tahun': null,
        // Dipertahankan agar data lama dan template lama tetap kompatibel.
        'stock_awal': null,
        'produksi_minggu_i': null,
        'produksi_minggu_ii': null,
        'produksi_minggu_iii': null,
        'produksi_minggu_iv': null,
        'produksi_minggu_v': null,
        'jumlah_produksi': null,
        'afkir': null,
        'distribusi_komandan': null,
        'distribusi_non_sikomandan': null,
        'jumlah_distribusi': null,
        'stock_akhir': null,
        'nama_petugas': namaPetugas.trim(),
        'petugas_uid': petugasUid,
        'bull_id': '',
        // tanggal adalah periode produksi. Waktu input sebenarnya berada di
        // created_at / updated_at untuk kebutuhan audit.
        'tanggal': Timestamp.fromDate(DateTime(tahun, bulan, 1)),
        'created_at': Timestamp.fromDate(now),
        'updated_at': Timestamp.fromDate(now),
      });
    });

    return id;
  }

  Future<void> updateProductionData({
    required ActivityRecord record,
    required String petugasUid,
    required String namaPetugas,
    required int stockTahun,
    required int? produksiMingguI,
    required int? produksiMingguII,
    required int? produksiMingguIII,
    required int? produksiMingguIV,
    required int? produksiMingguV,
    required int? afkir,
    required int? distribusiKomandan,
    required int? distribusiNonSikomandan,
  }) async {
    if (record.id.trim().isEmpty) {
      throw StateError('Data produksi yang akan diedit tidak valid.');
    }

    final bool hasWeeklyData = <int?>[
      produksiMingguI,
      produksiMingguII,
      produksiMingguIII,
      produksiMingguIV,
      produksiMingguV,
    ].any((value) => value != null);
    final int? jumlahProduksi = hasWeeklyData
        ? (produksiMingguI ?? 0) +
            (produksiMingguII ?? 0) +
            (produksiMingguIII ?? 0) +
            (produksiMingguIV ?? 0) +
            (produksiMingguV ?? 0)
        : null;

    final bool hasDistributionData =
        distribusiKomandan != null || distribusiNonSikomandan != null;
    final int? jumlahDistribusi = hasDistributionData
        ? (distribusiKomandan ?? 0) + (distribusiNonSikomandan ?? 0)
        : null;

    final int stockAkhir = stockTahun +
        (jumlahProduksi ?? 0) -
        (afkir ?? 0) -
        (jumlahDistribusi ?? 0);
    if (stockAkhir < 0) {
      throw StateError(
        'Total stock tidak valid karena hasil perhitungan menjadi negatif.',
      );
    }

    await collection.doc(record.id).update(<String, dynamic>{
      'stock_tahun': stockTahun,
      // Alias kompatibilitas untuk data dan laporan versi sebelumnya.
      'stock_awal': stockTahun,
      'produksi_minggu_i': produksiMingguI,
      'produksi_minggu_ii': produksiMingguII,
      'produksi_minggu_iii': produksiMingguIII,
      'produksi_minggu_iv': produksiMingguIV,
      'produksi_minggu_v': produksiMingguV,
      'jumlah_produksi': jumlahProduksi,
      'afkir': afkir,
      'distribusi_komandan': distribusiKomandan,
      'distribusi_non_sikomandan': distribusiNonSikomandan,
      'jumlah_distribusi': jumlahDistribusi,
      'stock_akhir': stockAkhir,
      'nama_petugas': namaPetugas.trim(),
      'petugas_uid': petugasUid,
      'updated_at': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<int?> getPreviousMonthStock({
    required String kategori,
    required String bangsa,
    String statusSni = '',
    required int tahun,
    required int bulan,
  }) async {
    final DateTime previous = DateTime(tahun, bulan - 1, 1);
    final ActivityRecord? record = await findMonthlyRecord(
      kategori: kategori,
      bangsa: bangsa,
      statusSni: statusSni,
      tahun: previous.year,
      bulan: previous.month,
    );
    if (record == null || !_hasValue(record.data['stock_akhir'])) return null;
    return _asInt(record.data['stock_akhir']);
  }

  Stream<ActivityRecord?> watchRecord(String id) {
    return collection.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      final Map<String, dynamic> data = snapshot.data()!;
      if (data['record_type'] != recordTypeMonthly) return null;
      return ActivityRecord.fromMap(id, collectionName, data);
    });
  }

  Future<ActivityRecord?> findMonthlyRecord({
    required String kategori,
    required String bangsa,
    String statusSni = '',
    required int tahun,
    required int bulan,
  }) async {
    final List<ActivityRecord> records = await getAll();
    final String targetKategori = _normalize(kategori);
    final String targetBangsa = _normalize(BullBreedName.canonical(bangsa));
    final String targetStatusSni = _productionSniStatus(
      kategori: kategori,
      statusSni: statusSni,
    );
    for (final ActivityRecord record in records) {
      if (_normalize(record.data['kategori']) != targetKategori ||
          _normalize(BullBreedName.canonical(record.data['bangsa']?.toString())) != targetBangsa ||
          _asInt(record.data['tahun']) != tahun ||
          _asInt(record.data['bulan']) != bulan) {
        continue;
      }
      if (_isSexing(kategori)) {
        final String recordStatus =
            BullSniStatus.normalize(record.data['status_sni']?.toString());
        if (recordStatus != targetStatusSni) continue;
      }
      return record;
    }
    return null;
  }

  Stream<List<ActivityRecord>> watchMonthlyRecords() {
    return collection.snapshots().map((snapshot) {
      final List<ActivityRecord> records = snapshot.docs
          .where((doc) => doc.data()['record_type'] == recordTypeMonthly)
          .map(
            (doc) => ActivityRecord.fromMap(
              doc.id,
              collectionName,
              doc.data(),
            ),
          )
          .toList();
      records.sort((a, b) => b.tanggal.compareTo(a.tanggal));
      return records;
    });
  }

  @override
  Future<List<ActivityRecord>> getAll() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await collection.get();
    final List<ActivityRecord> records = snapshot.docs
        .where((doc) => doc.data()['record_type'] == recordTypeMonthly)
        .map(
          (doc) => ActivityRecord.fromMap(
            doc.id,
            collectionName,
            doc.data(),
          ),
        )
        .toList();
    records.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    return records;
  }

  @override
  Future<List<ActivityRecord>> getForBull(String bullId) async {
    return <ActivityRecord>[];
  }

  @override
  Future<ActivityRecord?> getLatestForBull(String bullId) async => null;

  @override
  Future<List<ActivityRecord>> getRecent({int limit = 10}) async {
    final List<ActivityRecord> records = await getAll();
    records.sort((a, b) => b.updated_at.compareTo(a.updated_at));
    return records.take(limit).toList(growable: false);
  }

  Future<int> getTotalLatestStock() async {
    final List<ActivityRecord> records = await getAll();
    final Map<String, ActivityRecord> latestByGroup = <String, ActivityRecord>{};

    for (final ActivityRecord record in records) {
      if (!_hasValue(record.data['stock_akhir'])) continue;
      final String kategori = _normalize(record.data['kategori']);
      final String bangsa =
          _normalize(BullBreedName.canonical(record.data['bangsa']?.toString()));
      if (kategori.isEmpty || bangsa.isEmpty) continue;
      final String statusSni = _isSexing(kategori)
          ? BullSniStatus.normalize(record.data['status_sni']?.toString())
          : '';
      final String key = '$kategori|$bangsa|$statusSni';
      final ActivityRecord? current = latestByGroup[key];
      if (current == null || record.tanggal.isAfter(current.tanggal)) {
        latestByGroup[key] = record;
      }
    }

    int total = 0;
    for (final ActivityRecord record in latestByGroup.values) {
      total += _asInt(record.data['stock_akhir']);
    }
    return total;
  }

  /// Menjumlahkan Total Stock untuk satu periode bulan+tahun saja.
  ///
  /// Record yang baru didaftarkan tetapi belum memiliki [stock_akhir]
  /// tidak ikut menambah total. Fungsi ini dipakai Dashboard agar angka
  /// tidak tercampur dengan stock historis dari bulan-bulan sebelumnya.
  Future<int> getTotalStockForPeriod({
    required int tahun,
    required int bulan,
  }) async {
    final List<ActivityRecord> records = await getAll();
    int total = 0;

    for (final ActivityRecord record in records) {
      if (_asInt(record.data['tahun']) != tahun ||
          _asInt(record.data['bulan']) != bulan ||
          !_hasValue(record.data['stock_akhir'])) {
        continue;
      }
      total += _asInt(record.data['stock_akhir']);
    }

    return total;
  }

  // Dipertahankan untuk kompatibilitas dengan struktur lama berbasis tahun.
  Future<DocumentSnapshot<Map<String, dynamic>>> getByYear(int tahun) {
    return collection.doc('$tahun').get();
  }

  String _monthlyDocumentId({
    required String kategori,
    required String bangsa,
    String statusSni = '',
    required int tahun,
    required int bulan,
  }) {
    final String normalizedStatusSni = _productionSniStatus(
      kategori: kategori,
      statusSni: statusSni,
    );
    final String sniPart =
        _isSexing(kategori) ? '__${_normalize(normalizedStatusSni)}' : '';
    final String raw =
        '${_normalize(kategori)}__${_normalize(BullBreedName.canonical(bangsa))}${sniPart}__${tahun}_${bulan.toString().padLeft(2, '0')}';
    return Uri.encodeComponent(raw);
  }

  bool _isSexing(String kategori) => _normalize(kategori) == 'sexing';

  String _productionSniStatus({
    required String kategori,
    required String statusSni,
    bool requireForSexing = false,
  }) {
    if (!_isSexing(kategori)) return '';
    final String normalized = BullSniStatus.normalize(statusSni);
    if (requireForSexing && normalized.isEmpty) {
      throw StateError(
        'Khusus kategori Sexing, pilih status SNI atau NON SNI terlebih dahulu.',
      );
    }
    return normalized;
  }

  String _sniSuffix(String kategori, String statusSni) {
    if (!_isSexing(kategori)) return '';
    if (statusSni == BullSniStatus.bersertifikasi) return ' - SNI';
    if (statusSni == BullSniStatus.belumBersertifikasi) return ' - NON SNI';
    return '';
  }

  bool _hasValue(dynamic value) =>
      value != null && value.toString().trim().isNotEmpty;

  String _normalize(dynamic value) =>
      value?.toString().trim().toLowerCase() ?? '';

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _monthName(int month) {
    const List<String> months = <String>[
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    if (month < 1 || month > 12) return 'Bulan';
    return months[month - 1];
  }
}
