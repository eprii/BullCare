import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/bull_model.dart';
import '../../models/user_model.dart';
import '../../services/bull_service.dart';
import '../../services/produksi_distribusi_semen_beku_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_feedback.dart';
import '../../utils/bull_breed_name.dart';
import '../../utils/bull_sni_status.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class ProduksiDistribusiSemenBekuRegisterPage extends StatefulWidget {
  const ProduksiDistribusiSemenBekuRegisterPage({
    super.key,
    required this.user,
    required this.tahun,
    required this.bulan,
  });

  final UserModel user;
  final int tahun;
  final int bulan;

  @override
  State<ProduksiDistribusiSemenBekuRegisterPage> createState() =>
      _ProduksiDistribusiSemenBekuRegisterPageState();
}

class _ProduksiDistribusiSemenBekuRegisterPageState
    extends State<ProduksiDistribusiSemenBekuRegisterPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final BullService _bullService = BullService();
  final ProduksiDistribusiSemenBekuService _service =
      ProduksiDistribusiSemenBekuService();
  final TextEditingController _jumlahPejantan = TextEditingController();

  String? _kategori;
  String? _statusSni;
  String? _bangsa;
  bool _saving = false;

  @override
  void dispose() {
    _jumlahPejantan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.user.isPetugas) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Tambah Data Produksi')),
        body: const AppPageContainer(
          maxWidth: 680,
          child: Center(
            child: EmptyState(
              icon: Icons.visibility_outlined,
              title: 'Mode Supervisor',
              message: 'Supervisor hanya dapat melihat data produksi.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Tambah Data Produksi')),
      body: AppPageContainer(
        maxWidth: 680,
        child: StreamBuilder<List<BullModel>>(
          stream: _bullService.watchBulls(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const LoadingView(message: 'Memuat data bull...');
            }
            if (snapshot.hasError) {
              return ErrorView(message: snapshot.error.toString());
            }

            final List<BullModel> bulls = snapshot.data ?? <BullModel>[];
            final List<String> categories = _categories();
            final List<String> breeds = _breeds(bulls);
            final bool isSexing = _isSexing(_kategori);
            final List<String> sniOptions = _sniOptions(bulls, _bangsa);
            final int available = _availablePejantan(bulls);

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 30),
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Periode Produksi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_monthName(widget.bulan)} ${widget.tahun}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Periode mengikuti pilihan pada halaman Produksi & Distribusi Semen Beku.',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Text(
                          'Data Pejantan Produksi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _bangsa,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Bangsa / Rumpun',
                            prefixIcon: Icon(Icons.category_outlined),
                          ),
                          items: breeds
                              .map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(growable: false),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Pilih bangsa / rumpun.'
                              : null,
                          onChanged: (value) {
                            setState(() {
                              _bangsa = value;
                              _statusSni = null;
                              _jumlahPejantan.clear();
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _jumlahPejantan,
                          enabled: _bangsa != null,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Jumlah Pejantan',
                            prefixIcon: const Icon(Icons.pets_outlined),
                            helperText: _bangsa == null
                                ? 'Pilih bangsa / rumpun terlebih dahulu.'
                                : isSexing && _statusSni != null
                                    ? 'Pejantan ${_sniLabel(_statusSni)} tersedia untuk rumpun ini: $available ekor'
                                    : 'Pejantan tersedia untuk rumpun ini: $available ekor',
                          ),
                          validator: (value) {
                            final int? parsed =
                                int.tryParse(value?.trim() ?? '');
                            if (parsed == null || parsed <= 0) {
                              return 'Jumlah pejantan harus lebih dari 0.';
                            }
                            if (_bangsa != null && parsed > available) {
                              return 'Maksimal $available pejantan tersedia.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _kategori,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Kategori Produksi',
                            prefixIcon: Icon(Icons.label_outline_rounded),
                          ),
                          items: categories
                              .map(
                                (value) => DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(growable: false),
                          validator: (value) => value == null || value.isEmpty
                              ? 'Pilih kategori produksi.'
                              : null,
                          onChanged: _bangsa == null
                              ? null
                              : (value) {
                                  setState(() {
                                    _kategori = value;
                                    _statusSni = null;
                                  });
                                },
                        ),
                        if (isSexing) ...<Widget>[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            key: ValueKey<String>(
                              '${_bangsa ?? ''}|${_kategori ?? ''}',
                            ),
                            initialValue: _statusSni,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Status SNI',
                              prefixIcon: Icon(Icons.verified_outlined),
                            ),
                            items: sniOptions
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(_sniLabel(value)),
                                  ),
                                )
                                .toList(growable: false),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Pilih status SNI.'
                                : null,
                            onChanged: (value) {
                              setState(() => _statusSni = value);
                            },
                          ),
                          if (_bangsa != null && sniOptions.isEmpty) ...<Widget>[
                            const SizedBox(height: 8),
                            const Text(
                              'Belum ada status sertifikasi SNI pada Bull untuk rumpun ini. Perbarui Data Bull terlebih dahulu.',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  FilledButton.icon(
                    onPressed: _saving || categories.isEmpty ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Menyimpan...' : 'Simpan'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_saving || !widget.user.isPetugas) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String? kategori = _kategori;
    final String? bangsa = _bangsa;
    if (kategori == null || bangsa == null) return;

    setState(() => _saving = true);
    try {
      final String id = await _service.registerMonthlyRecord(
        petugasUid: widget.user.uid,
        namaPetugas: widget.user.nama,
        kategori: kategori,
        bangsa: bangsa,
        statusSni: _isSexing(kategori) ? (_statusSni ?? '') : '',
        jumlahPejantan: int.parse(_jumlahPejantan.text.trim()),
        tahun: widget.tahun,
        bulan: widget.bulan,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        'Data $bangsa${_isSexing(kategori) ? ' (${_sniLabel(_statusSni)})' : ''} untuk ${_monthName(widget.bulan)} ${widget.tahun} berhasil ditambahkan.',
      );
      Navigator.of(context).pop(id);
    } on StateError catch (error) {
      if (mounted) AppFeedback.showError(context, error.message);
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(context, 'Gagal menambahkan data produksi: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _categories() {
    return const <String>[
      'Sapi Potong',
      'Kerbau',
      'Sexing',
      'Non-LSPro',
    ];
  }

  List<String> _breeds(List<BullModel> bulls) {
    final Map<String, String> labels = <String, String>{};
    for (final BullModel bull in bulls) {
      final String breed = BullBreedName.canonical(bull.bangsa);
      if (breed.isEmpty) continue;
      labels.putIfAbsent(_normalize(breed), () => breed);
    }
    final List<String> values = labels.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return values;
  }

  List<String> _sniOptions(List<BullModel> bulls, String? breed) {
    if (breed == null || breed.trim().isEmpty) return <String>[];
    final Set<String> available = <String>{};
    for (final BullModel bull in bulls) {
      if (!BullBreedName.same(bull.bangsa, breed)) continue;
      final String status = BullSniStatus.normalize(bull.status_sni);
      if (status.isNotEmpty) available.add(status);
    }
    return <String>[
      if (available.contains(BullSniStatus.bersertifikasi))
        BullSniStatus.bersertifikasi,
      if (available.contains(BullSniStatus.belumBersertifikasi))
        BullSniStatus.belumBersertifikasi,
    ];
  }

  int _availablePejantan(List<BullModel> bulls) {
    final String? breed = _bangsa;
    if (breed == null) return 0;
    final bool isSexing = _isSexing(_kategori);
    final String selectedSni = BullSniStatus.normalize(_statusSni);
    return bulls.where((bull) {
      if (!BullBreedName.same(bull.bangsa, breed)) return false;
      if (!isSexing || selectedSni.isEmpty) return true;
      return BullSniStatus.normalize(bull.status_sni) == selectedSni;
    }).length;
  }

  bool _isSexing(String? category) =>
      _normalize(_canonicalCategory(category ?? '')) == 'sexing';

  String _sniLabel(String? status) {
    final String normalized = BullSniStatus.normalize(status);
    if (normalized == BullSniStatus.bersertifikasi) return 'SNI';
    if (normalized == BullSniStatus.belumBersertifikasi) return 'NON SNI';
    return '-';
  }

  String _canonicalCategory(String value) {
    final String normalized = _normalize(value);
    if (normalized == 'sapi potong') return 'Sapi Potong';
    if (normalized == 'kerbau') return 'Kerbau';
    if (normalized == 'sexing') return 'Sexing';
    if (normalized == 'non-lspro') return 'Non-LSPro';
    return value.trim();
  }

  String _normalize(dynamic value) =>
      value?.toString().trim().toLowerCase() ?? '';

  String _monthName(int month) {
    const List<String> months = <String>[
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
    if (month < 1 || month > 12) return 'Bulan';
    return months[month - 1];
  }
}
