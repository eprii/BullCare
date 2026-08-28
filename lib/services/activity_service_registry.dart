import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_record.dart';
import 'base_activity_service.dart';
import 'bedah_bangkai_service.dart';
import 'bio_security_service.dart';
import 'pemberian_obat_cacing_service.dart';
import 'pemberian_pakan_service.dart';
import 'pencegahan_ektoparasit_service.dart';
import 'pemeriksaan_kesehatan_service.dart';
import 'pemotongan_bulu_service.dart';
import 'pemotongan_kuku_service.dart';
import 'penampungan_semen_service.dart';
import 'pengambilan_sample_service.dart';
import 'pengobatan_service.dart';
import 'pengukuran_service.dart';
import 'penimbangan_service.dart';
import 'sanitasi_service.dart';

class ActivityServiceRegistry {
  ActivityServiceRegistry._();

  static final Map<String, BaseActivityService> _services =
      <String, BaseActivityService>{
    'pemberian_pakan': PemberianPakanService(),
    'sanitasi': SanitasiService(),
    'pemeriksaan_kesehatan': PemeriksaanKesehatanService(),
    'penimbangan': PenimbanganService(),
    'pengukuran': PengukuranService(),
    'pengobatan': PengobatanService(),
    'pemberian_obat_cacing': PemberianObatCacingService(),
    'pencegahan_ektoparasit': PencegahanEktoparasitService(),
    'bedah_bangkai': BedahBangkaiService(),
    'pemotongan_bulu': PemotonganBuluService(),
    'pemotongan_kuku': PemotonganKukuService(),
    'penampungan_semen': PenampunganSemenService(),
    'pengambilan_sample': PengambilanSampleService(),
    'bio_security': BioSecurityService(),
  };

  static BaseActivityService serviceFor(String collectionName) {
    final BaseActivityService? service = _services[collectionName];

    if (service == null) {
      throw ArgumentError(
        'Collection aktivitas tidak dikenal: $collectionName',
      );
    }

    return service;
  }

  static List<BaseActivityService> get allServices =>
      _services.values.toList(growable: false);

  static Future<List<ActivityRecord>> _readSafely(
    BaseActivityService service,
    Future<List<ActivityRecord>> Function() read,
  ) async {
    try {
      return await read();
    } on FirebaseException catch (error) {
      if ((service.collectionName == 'pencegahan_ektoparasit' ||
              service.collectionName == 'bio_security' ||
              service.collectionName == 'pengambilan_sample' ||
              service.collectionName == 'bedah_bangkai') &&
          error.code == 'permission-denied') {
        return <ActivityRecord>[];
      }

      rethrow;
    }
  }

  static Future<List<ActivityRecord>> getHistoryForBull(
    String bullId,
  ) async {
    final List<List<ActivityRecord>> groups = await Future.wait(
      allServices.map(
        (service) => _readSafely(
          service,
          () => service.getForBull(bullId),
        ),
      ),
    );

    final List<ActivityRecord> records =
        groups.expand((items) => items).toList();

    records.sort(
      (a, b) => b.tanggal.compareTo(a.tanggal),
    );

    return records;
  }

  static Future<List<ActivityRecord>> getAll() async {
    final List<List<ActivityRecord>> groups = await Future.wait(
      allServices.map(
        (service) => _readSafely(
          service,
          service.getAll,
        ),
      ),
    );

    final List<ActivityRecord> records =
        groups.expand((items) => items).toList();

    records.sort(
      (a, b) => b.tanggal.compareTo(a.tanggal),
    );

    return records;
  }

  static Future<List<ActivityRecord>> getRecent({
    int perCollection = 4,
  }) async {
    final List<List<ActivityRecord>> groups = await Future.wait(
      allServices.map(
        (service) => _readSafely(
          service,
          () => service.getRecent(limit: perCollection),
        ),
      ),
    );

    final List<ActivityRecord> records =
        groups.expand((items) => items).toList();

    records.sort(
      (a, b) => b.tanggal.compareTo(a.tanggal),
    );

    return records;
  }
}
