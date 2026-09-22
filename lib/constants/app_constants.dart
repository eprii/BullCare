class AppConstants {
  AppConstants._();

  static const String appName = 'BullCare';
  static const String appSubtitle = 'Manajemen Pemeliharaan Bull';
  static const String pengunjungRole = 'pengunjung';
  static const String petugasRole = 'petugas';
  static const String supervisorRole = 'supervisor';

  static const List<String> activityCollections = <String>[
    'pemberian_pakan',
    'sanitasi',
    'pemeriksaan_kesehatan',
    'penimbangan',
    'pengukuran',
    'pengobatan',
    'pemberian_obat_cacing',
    'pencegahan_ektoparasit',
    'bedah_bangkai',
    'pemotongan_bulu',
    'pemotongan_kuku',
    'penampungan_semen',
    'produksi_distribusi_semen_beku',
    'bio_security',
    'pengambilan_sample',
  ];
}
