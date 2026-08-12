import 'package:bullcare_bib/utils/app_date_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDateUtils.nextMonthlyOccurrence', () {
    test('menggunakan tanggal yang sama pada bulan berikutnya', () {
      final DateTime anchor = DateTime(2026, 8, 6, 10, 30);
      final DateTime reference = DateTime(2026, 8, 20);

      expect(
        AppDateUtils.nextMonthlyOccurrence(anchor, reference),
        DateTime(2026, 9, 6, 10, 30),
      );
    });

    test('berulang ke bulan berikutnya setelah jadwal selesai', () {
      final DateTime anchor = DateTime(2026, 8, 6, 10, 30);
      final DateTime reference = DateTime(2026, 9, 6, 10, 30);

      expect(
        AppDateUtils.nextMonthlyOccurrence(anchor, reference),
        DateTime(2026, 10, 6, 10, 30),
      );
    });

    test('tanggal 31 memakai akhir bulan tanpa mengubah tanggal acuan', () {
      final DateTime anchor = DateTime(2026, 1, 31, 8);

      expect(
        AppDateUtils.nextMonthlyOccurrence(
          anchor,
          DateTime(2026, 1, 31, 9),
        ),
        DateTime(2026, 2, 28, 8),
      );
      expect(
        AppDateUtils.nextMonthlyOccurrence(
          anchor,
          DateTime(2026, 2, 28, 9),
        ),
        DateTime(2026, 3, 31, 8),
      );
    });
  });

  group('AppDateUtils.nextDailyOccurrence', () {
    test('jadwal pertama selalu satu hari setelah aktivitas', () {
      final DateTime anchor = DateTime(2026, 8, 8, 8);
      final DateTime reference = DateTime(2026, 8, 8, 21);

      expect(
        AppDateUtils.nextDailyOccurrence(anchor, reference),
        DateTime(2026, 8, 9, 8),
      );
    });

    test('setelah countdown selesai otomatis berulang ke hari berikutnya', () {
      final DateTime anchor = DateTime(2026, 8, 6, 8);
      final DateTime reference = DateTime(2026, 8, 8, 8);

      expect(
        AppDateUtils.nextDailyOccurrence(anchor, reference),
        DateTime(2026, 8, 9, 8),
      );
    });

    test('countdown selalu menuju jam pelaksanaan terdekat', () {
      final DateTime anchor = DateTime(2026, 8, 6, 8);
      final DateTime reference = DateTime(2026, 8, 8, 7, 30);

      expect(
        AppDateUtils.nextDailyOccurrence(anchor, reference),
        DateTime(2026, 8, 8, 8),
      );
    });
  });

}
