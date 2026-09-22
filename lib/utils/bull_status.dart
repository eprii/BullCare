class BullStatus {
  BullStatus._();

  static const String sehat = 'Sehat';
  static const String tidakSehat = 'Tidak Sehat';
  static const String butuhVaksin = 'Butuh Vaksin';
  static const String mati = 'Mati';
  static const String afkir = 'Afkir';

  static const List<String> values = <String>[
    sehat,
    tidakSehat,
    butuhVaksin,
    mati,
    afkir,
  ];

  static const List<String> activeValues = <String>[
    sehat,
    tidakSehat,
    butuhVaksin,
  ];

  static String normalize(String? value) {
    final String raw = (value ?? '').trim();
    switch (raw.toLowerCase()) {
      case 'sehat':
      case 'aktif':
        return sehat;
      case 'tidak sehat':
      case 'tidak aktif':
        return tidakSehat;
      case 'butuh vaksin':
        return butuhVaksin;
      case 'mati':
      case 'meninggal':
        return mati;
      case 'afkir':
        return afkir;
      default:
        return sehat;
    }
  }

  static bool isSehat(String? value) => normalize(value) == sehat;

  static bool isAktif(String? value) {
    final String normalized = normalize(value);
    return normalized != mati && normalized != afkir;
  }
}
