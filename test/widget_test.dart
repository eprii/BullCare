import 'package:bullcare_bib/models/activity_definition.dart';
import 'package:bullcare_bib/utils/validators.dart';
import 'package:bullcare_bib/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Katalog aktivitas sesuai ruang lingkup BullCare', () {
    expect(ActivityCatalog.all.length, 10);
    expect(ActivityCatalog.byCollection('penampungan_semen').label, 'Penampungan Semen');
  });

  test('Validasi angka menerima koma desimal', () {
    expect(Validators.decimal('12,5'), isNull);
    expect(Validators.decimal('abc'), isNotNull);
  });

  testWidgets('EmptyState menampilkan judul dan pesan', (WidgetTester tester) async {
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
  });
}
