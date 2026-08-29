
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
  String? _selectedKategori;
  String? _selectedBangsa;


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

  Widget _dataPejantanSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('bulls').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        final Map<String, String> kategoriByNormalized = <String, String>{};
        for (final doc in docs) {
          final String kategori =
              doc.data()['kategori']?.toString().trim() ?? '';
          if (kategori.isEmpty) continue;
          kategoriByNormalized.putIfAbsent(
            kategori.toLowerCase(),
            () => kategori,
          );
        }

        final List<String> kategoriItems = kategoriByNormalized.values.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        final String selectedKategoriNormalized =
            _selectedKategori?.trim().toLowerCase() ?? '';
        final Map<String, String> bangsaByNormalized = <String, String>{};

        if (selectedKategoriNormalized.isNotEmpty) {
          for (final doc in docs) {
            final Map<String, dynamic> data = doc.data();
            final String kategori =
                data['kategori']?.toString().trim().toLowerCase() ?? '';
            if (kategori != selectedKategoriNormalized) continue;

            final String bangsa = data['bangsa']?.toString().trim() ?? '';
            if (bangsa.isEmpty) continue;
            bangsaByNormalized.putIfAbsent(
              bangsa.toLowerCase(),
              () => bangsa,
            );
          }
        }

        final List<String> bangsaItems = bangsaByNormalized.values.toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        final String selectedBangsaNormalized =
            _selectedBangsa?.trim().toLowerCase() ?? '';
        final int availablePejantan = selectedKategoriNormalized.isEmpty ||
                selectedBangsaNormalized.isEmpty
            ? 0
            : docs.where((doc) {
                final Map<String, dynamic> data = doc.data();
                final String kategori =
                    data['kategori']?.toString().trim().toLowerCase() ?? '';
                final String bangsa =
                    data['bangsa']?.toString().trim().toLowerCase() ?? '';
                return kategori == selectedKategoriNormalized &&
                    bangsa == selectedBangsaNormalized;
              }).length;

        final bool kategoriMasihAda = _selectedKategori == null ||
            kategoriItems.any(
              (item) =>
                  item.trim().toLowerCase() == selectedKategoriNormalized,
            );
        final bool bangsaMasihAda = _selectedBangsa == null ||
            bangsaItems.any(
              (item) => item.trim().toLowerCase() == selectedBangsaNormalized,
            );

        final String? kategoriValue =
            kategoriMasihAda ? _selectedKategori : null;
        final String? bangsaValue = bangsaMasihAda ? _selectedBangsa : null;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: DropdownButtonFormField<String>(
                key: ValueKey<String>(
                  'kategori-${kategoriValue ?? ''}-${kategoriItems.join('|')}',
                ),
                initialValue: kategoriValue,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  hintText: 'Pilih kategori',
                ),
                items: kategoriItems
                    .map(
                      (kategori) => DropdownMenuItem<String>(
                        value: kategori,
                        child: Text(kategori),
                      ),
                    )
                    .toList(),
                onChanged: kategoriItems.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedKategori = value;
                          _selectedBangsa = null;
                          c['kategori']?.text = value ?? '';
                          c['bangsa']?.clear();
                          c['jumlah_pejantan']?.clear();
                        });
                      },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: DropdownButtonFormField<String>(
                key: ValueKey<String>(
                  'bangsa-${bangsaValue ?? ''}-${bangsaItems.join('|')}',
                ),
                initialValue: bangsaValue,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Bangsa',
                  hintText: _selectedKategori == null
                      ? 'Pilih kategori terlebih dahulu'
                      : 'Pilih bangsa',
                ),
                items: bangsaItems
                    .map(
                      (bangsa) => DropdownMenuItem<String>(
                        value: bangsa,
                        child: Text(bangsa),
                      ),
                    )
                    .toList(),
                onChanged: _selectedKategori == null || bangsaItems.isEmpty
                    ? null
                    : (value) {
                        setState(() {
                          _selectedBangsa = value;
                          c['bangsa']?.text = value ?? '';
                          c['jumlah_pejantan']?.clear();
                        });
                      },
              ),
            ),
            SizedBox(
              width: 120,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: TextFormField(
                  controller: c['jumlah_pejantan'],
                  enabled:
                      _selectedKategori != null && _selectedBangsa != null,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Jumlah Pejantan',
                    helperText: _selectedKategori != null &&
                            _selectedBangsa != null
                        ? 'Tersedia: $availablePejantan pejantan'
                        : 'Pilih kategori dan bangsa',
                    errorText: _jumlahPejantanError(availablePejantan),
                  ),
                ),
              ),
            ),
            input('Stock $year', 'stock_tahun'),
            if (snapshot.connectionState == ConnectionState.waiting)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              )
            else if (snapshot.hasError)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Data kategori dan bangsa gagal dimuat dari data bull.',
                  style: TextStyle(color: Colors.red),
                ),
              )
            else if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Belum ada data bull untuk menentukan kategori dan bangsa.',
                ),
              ),
          ],
        );
      },
    );
  }

  String? _jumlahPejantanError(int availablePejantan) {
    final String raw = c['jumlah_pejantan']?.text.trim() ?? '';
    if (raw.isEmpty || _selectedKategori == null || _selectedBangsa == null) {
      return null;
    }

    final int? jumlah = int.tryParse(raw);
    if (jumlah == null) return 'Jumlah pejantan harus berupa angka.';
    if (jumlah <= 0) return 'Jumlah pejantan harus lebih dari 0.';
    if (jumlah > availablePejantan) {
      return 'Maksimal $availablePejantan pejantan tersedia.';
    }
    return null;
  }

  Future<bool> _validateDataPejantan() async {
    final String kategori = _selectedKategori?.trim() ?? '';
    final String bangsa = _selectedBangsa?.trim() ?? '';
    final String rawJumlah = c['jumlah_pejantan']?.text.trim() ?? '';

    if (kategori.isEmpty) {
      AppFeedback.showError(context, 'Pilih kategori pejantan terlebih dahulu.');
      return false;
    }
    if (bangsa.isEmpty) {
      AppFeedback.showError(context, 'Pilih bangsa pejantan terlebih dahulu.');
      return false;
    }

    final int? jumlah = int.tryParse(rawJumlah);
    if (jumlah == null || jumlah <= 0) {
      AppFeedback.showError(
        context,
        'Jumlah pejantan harus berupa angka lebih dari 0.',
      );
      return false;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>> snapshot =
          await FirebaseFirestore.instance.collection('bulls').get();
      final String kategoriNormalized = kategori.toLowerCase();
      final String bangsaNormalized = bangsa.toLowerCase();
      final int availablePejantan = snapshot.docs.where((doc) {
        final Map<String, dynamic> data = doc.data();
        final String bullKategori =
            data['kategori']?.toString().trim().toLowerCase() ?? '';
        final String bullBangsa =
            data['bangsa']?.toString().trim().toLowerCase() ?? '';
        return bullKategori == kategoriNormalized &&
            bullBangsa == bangsaNormalized;
      }).length;

      if (!mounted) return false;

      if (jumlah > availablePejantan) {
        AppFeedback.showError(
          context,
          'Data tidak valid. Pejantan tersedia untuk $kategori - $bangsa '
          'hanya $availablePejantan ekor.',
        );
        return false;
      }

      return true;
    } catch (_) {
      if (!mounted) return false;
      AppFeedback.showError(
        context,
        'Gagal memvalidasi jumlah pejantan dari data bull.',
      );
      return false;
    }
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

    final bool dataPejantanValid = await _validateDataPejantan();
    if (!dataPejantanValid || !mounted) return;

    setState(() => loading = true);

    final service = ProduksiDistribusiSemenBekuService();

    try {
      await service.saveData(
        tahun: year,
        kategori: _selectedKategori ?? '',
        bangsa: _selectedBangsa ?? '',
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
              _dataPejantanSection(),
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
