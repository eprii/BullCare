class BullSniStatus {
  static const String bersertifikasi = 'bersertifikasi';
  static const String belumBersertifikasi = 'belum_bersertifikasi';

  static const List<String> values = <String>[
    bersertifikasi,
    belumBersertifikasi,
  ];

  static String normalize(String? value) {
    final String normalized = value?.trim().toLowerCase() ?? '';

    switch (normalized) {
      case bersertifikasi:
      case 'bersertifikasi sni':
        return bersertifikasi;
      case belumBersertifikasi:
      case 'belum bersertifikasi sni':
        return belumBersertifikasi;
      default:
        return '';
    }
  }

  static String label(String? value) {
    switch (normalize(value)) {
      case bersertifikasi:
        return 'Bersertifikasi SNI';
      case belumBersertifikasi:
        return 'Belum Bersertifikasi SNI';
      default:
        return 'Status SNI belum diisi';
    }
  }

  static bool isValid(String? value) => normalize(value).isNotEmpty;
}
