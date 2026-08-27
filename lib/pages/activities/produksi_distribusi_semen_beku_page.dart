
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_feedback.dart';
import '../../widgets/app_page_container.dart';
import '../../services/produksi_distribusi_semen_beku_service.dart';

class ProduksiDistribusiSemenBekuPage extends StatefulWidget {
  const ProduksiDistribusiSemenBekuPage({super.key, required this.user});
  final UserModel user;

  @override
  State<ProduksiDistribusiSemenBekuPage> createState() =>
      _ProduksiDistribusiSemenBekuPageState();
}

class _ProduksiDistribusiSemenBekuPageState
    extends State<ProduksiDistribusiSemenBekuPage> {
  final Map<String, TextEditingController> c = {};
  late int year;
  bool loading = false;


  @override
  void initState() {
    super.initState();
    year = DateTime.now().year;

    final keys = [
      'i',
      'ii',
      'iii',
      'iv',
      'v',
      'jumlah_produksi',
      'afkir',
      'komandan',
      'non_sikomandan',
      'jumlah_distribusi',
      'stock_akhir',
    ];

    keys.addAll([
      'kategori',
      'bangsa',
      'jumlah_pejantan',
      'stock_tahun',
    ]);

    for (final k in keys) {
      c[k] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final e in c.values) {
      e.dispose();
    }
    super.dispose();
  }

  Widget input(String label, String key, {double width = 120, bool number = true}) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: TextFormField(
          controller: c[key],
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label),
        ),
      ),
    );
  }

  Widget section(String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> save() async {
    if (!widget.user.isPetugas) return;

    setState(() => loading = true);

    final service = ProduksiDistribusiSemenBekuService();

    try {
      await service.saveData(
        tahun: year,
        kategori: c['kategori']?.text ?? '',
        bangsa: c['bangsa']?.text ?? '',
        jumlahPejantan:
            int.tryParse(c['jumlah_pejantan']?.text ?? '') ?? 0,
        stockTahun: int.tryParse(c['stock_tahun']?.text ?? '') ?? 0,
        namaPetugas: widget.user.nama,
        dataBulan: {
          'januari': {
            'produksi_mingguan': {
              'i': int.tryParse(c['i']?.text ?? '') ?? 0,
              'ii': int.tryParse(c['ii']?.text ?? '') ?? 0,
              'iii': int.tryParse(c['iii']?.text ?? '') ?? 0,
              'iv': int.tryParse(c['iv']?.text ?? '') ?? 0,
              'v': int.tryParse(c['v']?.text ?? '') ?? 0,
              'jumlah': int.tryParse(c['jumlah_produksi']?.text ?? '') ?? 0,
            },
            'afkir': int.tryParse(c['afkir']?.text ?? '') ?? 0,
            'distribusi_bulanan': {
              'komandan': int.tryParse(c['komandan']?.text ?? '') ?? 0,
              'non_sikomandan':
                  int.tryParse(c['non_sikomandan']?.text ?? '') ?? 0,
              'jumlah':
                  int.tryParse(c['jumlah_distribusi']?.text ?? '') ?? 0,
            },
            'stock': int.tryParse(c['stock_akhir']?.text ?? '') ?? 0,
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => loading = false);
        AppFeedback.showError(context, 'Gagal menyimpan data.');
      }
      return;
    }

    if (mounted) {
      setState(() => loading = false);
      AppFeedback.showSuccess(context, 'Data tersimpan.');
    }
  }

  Widget tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Produksi & Distribusi Semen Beku')),
      body: AppPageContainer(
        maxWidth: 1000,
        child: ListView(
          children: [
            section(
              'Data Pejantan / Stock',
              Column(
                children: [
                  input('Kategori', 'kategori', width: double.infinity, number: false),
                  input('Bangsa', 'bangsa', width: double.infinity, number: false),
                  input('Jumlah Pejantan', 'jumlah_pejantan'),
                  input('Stock $year', 'stock_tahun'),
                ],
              ),
            ),
            section(
              'Januari $year - Produksi Mingguan',
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    input('I', 'i'),
                    input('II', 'ii'),
                    input('III', 'iii'),
                    input('IV', 'iv'),
                    input('V', 'v'),
                    input('Jumlah', 'jumlah_produksi'),
                  ],
                ),
              ),
            ),
            section(
              'Afkir',
              input('Afkir', 'afkir'),
            ),
            section(
              'Distribusi Bulanan',
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    input('Komandan', 'komandan'),
                    input('Non Sikomandan', 'non_sikomandan'),
                    input('Jumlah', 'jumlah_distribusi'),
                  ],
                ),
              ),
            ),
            section(
              'Stock',
              input('Stock', 'stock_akhir'),
            ),
            FilledButton(
              onPressed: loading ? null : save,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
