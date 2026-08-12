class AppDateUtils {
  AppDateUtils._();

  static const List<String> _months = <String>[
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

  static String formatDate(DateTime value) {
    return '${value.day} ${_months[value.month - 1]} ${value.year}';
  }

  static String formatDateTime(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '${formatDate(value)} • $hour.$minute';
  }

  static DateTime startOfDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime endOfDay(DateTime value) =>
      startOfDay(value).add(const Duration(days: 1));

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Menghasilkan jadwal harian berikutnya berdasarkan tanggal aktivitas awal.
  ///
  /// Jadwal pertama selalu dimulai satu hari setelah tanggal aktivitas awal.
  /// Jam, menit, dan detik mengikuti [anchor]. Setelah waktu terlewati,
  /// jadwal otomatis bergeser ke hari berikutnya.
  static DateTime nextDailyOccurrence(
    DateTime anchor,
    DateTime reference,
  ) {
    DateTime candidate = DateTime(
      anchor.year,
      anchor.month,
      anchor.day,
      anchor.hour,
      anchor.minute,
      anchor.second,
      anchor.millisecond,
      anchor.microsecond,
    ).add(const Duration(days: 1));

    if (candidate.isAfter(reference)) return candidate;

    final DateTime candidateDay = startOfDay(candidate);
    final DateTime referenceDay = startOfDay(reference);
    final int elapsedDays = referenceDay.difference(candidateDay).inDays;
    candidate = candidate.add(Duration(days: elapsedDays));
    if (!candidate.isAfter(reference)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  /// Menghasilkan jadwal bulanan berikutnya berdasarkan tanggal aktivitas awal.
  ///
  /// Hari, jam, menit, dan detik dipertahankan. Apabila bulan tujuan tidak
  /// memiliki tanggal yang sama, jadwal menggunakan hari terakhir bulan itu.
  /// Contoh: 31 Januari -> 28/29 Februari -> 31 Maret.
  static DateTime nextMonthlyOccurrence(
    DateTime anchor,
    DateTime reference,
  ) {
    int monthOffset =
        (reference.year - anchor.year) * 12 + reference.month - anchor.month;
    if (monthOffset < 1) monthOffset = 1;

    DateTime candidate = _occurrenceFromAnchor(anchor, monthOffset);
    while (!candidate.isAfter(reference)) {
      monthOffset++;
      candidate = _occurrenceFromAnchor(anchor, monthOffset);
    }
    return candidate;
  }

  static DateTime _occurrenceFromAnchor(DateTime anchor, int monthOffset) {
    final int absoluteMonth = anchor.year * 12 + (anchor.month - 1) + monthOffset;
    final int year = absoluteMonth ~/ 12;
    final int month = absoluteMonth % 12 + 1;
    final int lastDay = _daysInMonth(year, month);
    final int day = anchor.day > lastDay ? lastDay : anchor.day;

    return DateTime(
      year,
      month,
      day,
      anchor.hour,
      anchor.minute,
      anchor.second,
      anchor.millisecond,
      anchor.microsecond,
    );
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
