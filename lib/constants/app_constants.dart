class AppConstants {
  AppConstants._();

  static const String appName = 'BullCare';
  static const String appSubtitle = 'Manajemen Pemeliharaan Bull';
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
    'pemotongan_bulu',
    'pemotongan_kuku',
    'penampungan_semen',
  ];
}
