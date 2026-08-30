class BullBreedName {
  const BullBreedName._();

  /// Nama baku rumpun yang dipakai khusus untuk integrasi data produksi.
  ///
  /// PO adalah singkatan dari Peranakan Ongole sehingga keduanya harus
  /// dianggap satu rumpun. Kerbau Lumpur dan Kerbau Kalimantan sengaja
  /// tidak dinormalisasi karena merupakan dua rumpun yang berbeda.
  static String canonical(String? value) {
    final String trimmed = value?.trim() ?? '';
    final String normalized = trimmed.toLowerCase();
    if (normalized == 'po' || normalized == 'peranakan ongole') {
      return 'Peranakan Ongole';
    }
    return trimmed;
  }

  static bool same(String? a, String? b) {
    return canonical(a).toLowerCase() == canonical(b).toLowerCase();
  }
}
