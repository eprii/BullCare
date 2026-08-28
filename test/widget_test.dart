import 'package:bullcare_bib/constants/app_constants.dart';
import 'package:bullcare_bib/models/activity_definition.dart';
import 'package:bullcare_bib/utils/validators.dart';
import 'package:bullcare_bib/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Katalog aktivitas sesuai ruang lingkup BullCare', () {
    expect(ActivityCatalog.all.length, 15);
    expect(AppConstants.activityCollections.length, 15);

    final List<String> catalogCollections = ActivityCatalog.all
        .map((activity) => activity.collectionName)
        .toList();

    expect(
      catalogCollections,
      AppConstants.activityCollections,
    );
  });

  test('Katalog Penampungan Semen tersedia', () {
    expect(
      ActivityCatalog.byCollection('penampungan_semen').label,
      'Penampungan Semen',
    );
  });

  test('Katalog Pencegahan Ektoparasit tersedia', () {
    expect(
      ActivityCatalog.byCollection('pencegahan_ektoparasit').label,
      'Pencegahan Ektoparasit',
    );
  });

  test('Katalog Pengambilan Sample tersedia', () {
    expect(
      ActivityCatalog.byCollection('pengambilan_sample').label,
      'Pengambilan Sample',
    );
  });

  test('Katalog Bedah Bangkai tersedia', () {
    expect(
      ActivityCatalog.byCollection('bedah_bangkai').label,
      'Bedah Bangkai',
    );
  });

  test('Katalog Bio Security tersedia', () {
    expect(
      ActivityCatalog.byCollection('bio_security').label,
      'Bio Security',
    );
  });

  test('Katalog Produksi dan Distribusi Semen Beku tersedia', () {
    expect(
      ActivityCatalog.byCollection('produksi_distribusi_semen_beku').label,
      'Produksi & Distribusi Semen Beku',
    );
  });

  test('Validasi angka menerima koma desimal', () {
    expect(Validators.decimal('12,5'), isNull);
    expect(Validators.decimal('abc'), isNotNull);
  });

  testWidgets(
    'EmptyState menampilkan judul dan pesan',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.pets,
              title: 'Belum ada data',
              message: 'Tambahkan data bull.',
            ),
          ),
        ),
      );

      expect(find.text('Belum ada data'), findsOneWidget);
      expect(find.text('Tambahkan data bull.'), findsOneWidget);
    },
  );
}
