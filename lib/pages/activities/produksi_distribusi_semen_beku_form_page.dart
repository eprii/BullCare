import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/activity_record.dart';
import '../../models/user_model.dart';
import '../../services/produksi_distribusi_semen_beku_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_feedback.dart';
import '../../utils/bull_breed_name.dart';
import '../../utils/bull_sni_status.dart';
import '../../widgets/app_page_container.dart';

class ProduksiDistribusiSemenBekuFormPage extends StatefulWidget {
  const ProduksiDistribusiSemenBekuFormPage({
    super.key,
    required this.user,
    required this.record,
  });

  final UserModel user;
  final ActivityRecord record;

  @override
  State<ProduksiDistribusiSemenBekuFormPage> createState() =>
      _ProduksiDistribusiSemenBekuFormPageState();
}

class _ProduksiDistribusiSemenBekuFormPageState
    extends State<ProduksiDistribusiSemenBekuFormPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ProduksiDistribusiSemenBekuService _service =
      ProduksiDistribusiSemenBekuService();

  late final TextEditingController _stockTahun;
  late final TextEditingController _weekI;
  late final TextEditingController _weekII;
  late final TextEditingController _weekIII;
  late final TextEditingController _weekIV;
  late final TextEditingController _weekV;
  late final TextEditingController _afkir;
  late final TextEditingController _komandan;
  late final TextEditingController _nonSikomandan;

  int? _suggestedStock;
  bool _loadingSuggestion = true;
  bool _saving = false;

  int get _tahun => _asInt(widget.record.data['tahun']);
  int get _bulan => _asInt(widget.record.data['bulan']);
  String get _kategori => widget.record.data['kategori']?.toString() ?? '-';
  String get _bangsa {
    final String value =
        BullBreedName.canonical(widget.record.data['bangsa']?.toString());
    return value.isEmpty ? '-' : value;
  }
  String get _statusSni =>
      BullSniStatus.normalize(widget.record.data['status_sni']?.toString());
  bool get _isSexing => _kategori.trim().toLowerCase() == 'sexing';
  int get _jumlahPejantan => _asInt(widget.record.data['jumlah_pejantan']);

  @override
  void initState() {
    super.initState();
    final Map<String, dynamic> data = widget.record.data;
    _stockTahun = TextEditingController(
      text: _optionalInitialFromAny(data, <String>['stock_tahun', 'stock_awal']),
    );
    _weekI = TextEditingController(
      text: _optionalInitial(data, 'produksi_minggu_i'),
    );
    _weekII = TextEditingController(
      text: _optionalInitial(data, 'produksi_minggu_ii'),
    );
    _weekIII = TextEditingController(
      text: _optionalInitial(data, 'produksi_minggu_iii'),
    );
    _weekIV = TextEditingController(
      text: _optionalInitial(data, 'produksi_minggu_iv'),
    );
    _weekV = TextEditingController(
      text: _optionalInitial(data, 'produksi_minggu_v'),
    );
    _afkir = TextEditingController(text: _optionalInitial(data, 'afkir'));
    _komandan = TextEditingController(
      text: _optionalInitial(data, 'distribusi_komandan'),
    );
    _nonSikomandan = TextEditingController(
      text: _optionalInitial(data, 'distribusi_non_sikomandan'),
    );
    _loadStockSuggestion();
  }

  @override
  void dispose() {
    _stockTahun.dispose();
    _weekI.dispose();
    _weekII.dispose();
    _weekIII.dispose();
    _weekIV.dispose();
    _weekV.dispose();
    _afkir.dispose();
    _komandan.dispose();
    _nonSikomandan.dispose();
    super.dispose();
  }

  Future<void> _loadStockSuggestion() async {
    try {
      final int? stock = await _service.getPreviousMonthStock(
        kategori: _kategori,
        bangsa: _bangsa,
        statusSni: _statusSni,
        tahun: _tahun,
        bulan: _bulan,
      );
      if (!mounted) return;
      setState(() {
        _suggestedStock = stock;
        _loadingSuggestion = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSuggestion = false);
    }
  }

  int get _jumlahProduksi =>
      _value(_weekI) +
      _value(_weekII) +
      _value(_weekIII) +
      _value(_weekIV) +
      _value(_weekV);

  int get _jumlahDistribusi => _value(_komandan) + _value(_nonSikomandan);

  int? get _stockAkhir {
    final int? stock = _optionalValue(_stockTahun);
    if (stock == null) return null;
    return stock + _jumlahProduksi - _value(_afkir) - _jumlahDistribusi;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Input Produksi Semen Beku')),
      body: AppPageContainer(
        maxWidth: 760,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 12, 0, 30),
            children: <Widget>[
              _section(
                'Data Produksi',
                Column(
                  children: <Widget>[
                    _readOnly('Kategori', _kategori),
                    const SizedBox(height: 12),
                    _readOnly('Bangsa', _bangsa),
                    if (_isSexing) ...<Widget>[
                      const SizedBox(height: 12),
                      _readOnly('Status SNI', _sniLabel(_statusSni)),
                    ],
                    const SizedBox(height: 12),
                    _readOnly('Periode', '${_monthName(_bulan)} $_tahun'),
                    const SizedBox(height: 12),
                    _readOnly('Jumlah Pejantan', '$_jumlahPejantan ekor'),
                  ],
                ),
              ),
              _section(
                'Stock $_tahun',
                TextFormField(
                  controller: _stockTahun,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    labelText: 'Stock $_tahun',
                    hintText: _stockHint,
                    hintStyle: const TextStyle(
                      color: Color(0xFF9AA09B),
                      fontWeight: FontWeight.w700,
                    ),
                    helperText: _stockHelper,
                  ),
                  validator: _requiredNonNegativeValidator,
                  onFieldSubmitted: (_) => _acceptSuggestedStock(),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              _section(
                'Produksi Mingguan',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: <Widget>[
                        _compactNumber(_weekI, 'I'),
                        _compactNumber(_weekII, 'II'),
                        _compactNumber(_weekIII, 'III'),
                        _compactNumber(_weekIV, 'IV'),
                        _compactNumber(_weekV, 'V'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Minggu I–V boleh dikosongkan bila datanya belum tersedia. Angka 0 berarti hasil produksi memang nol.',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _calculatedRow(
                      'Jumlah Produksi',
                      _hasAnyWeeklyValue ? _jumlahProduksi : null,
                    ),
                  ],
                ),
              ),
              _section(
                'Afkir',
                _optionalNumberField(
                  controller: _afkir,
                  label: 'Afkir',
                ),
              ),
              _section(
                'Distribusi Bulanan',
                Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _optionalNumberField(
                            controller: _komandan,
                            label: 'Komandan',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _optionalNumberField(
                            controller: _nonSikomandan,
                            label: 'Non Sikomandan',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _calculatedRow(
                      'Jumlah Distribusi',
                      _hasAnyDistributionValue ? _jumlahDistribusi : null,
                    ),
                  ],
                ),
              ),
              _section(
                'Total Stock',
                _calculatedRow(
                  'Total Stock',
                  _stockAkhir,
                  emphasized: true,
                ),
              ),
              const SizedBox(height: 4),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
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
                label: Text(_saving ? 'Menyimpan...' : 'Simpan Data'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _sniLabel(String status) {
    if (status == BullSniStatus.bersertifikasi) return 'SNI';
    if (status == BullSniStatus.belumBersertifikasi) return 'NON SNI';
    return 'Belum terklasifikasi';
  }

  String get _stockHint {
    if (_loadingSuggestion) return 'Memuat stock bulan sebelumnya...';
    final int? suggested = _suggestedStock;
    if (suggested == null) return 'Masukkan stock $_tahun';
    return 'Stock $_tahun ${_formatNumber(suggested)}';
  }

  String get _stockHelper {
    if (_suggestedStock == null) {
      return 'Belum ada Total Stock bulan sebelumnya. Isi stock secara manual.';
    }
    return 'Nilai abu-abu berasal dari Total Stock bulan sebelumnya. Jika ingin memakainya, biarkan field kosong lalu tekan Enter. Nilai tetap dapat diedit.';
  }

  void _acceptSuggestedStock() {
    if (_stockTahun.text.trim().isNotEmpty) return;
    final int? suggested = _suggestedStock;
    if (suggested == null) return;
    setState(() => _stockTahun.text = suggested.toString());
  }

  Future<void> _save() async {
    if (!widget.user.canManageActivity || _saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final int? stockTahun = _optionalValue(_stockTahun);
    if (stockTahun == null) return;
    final int? stockAkhir = _stockAkhir;
    if (stockAkhir == null || stockAkhir < 0) {
      AppFeedback.showError(
        context,
        'Total stock tidak valid karena hasil perhitungan menjadi negatif.',
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await _service.updateProductionData(
        record: widget.record,
        petugasUid: widget.user.uid,
        namaPetugas: widget.user.nama,
        stockTahun: stockTahun,
        produksiMingguI: _optionalValue(_weekI),
        produksiMingguII: _optionalValue(_weekII),
        produksiMingguIII: _optionalValue(_weekIII),
        produksiMingguIV: _optionalValue(_weekIV),
        produksiMingguV: _optionalValue(_weekV),
        afkir: _optionalValue(_afkir),
        distribusiKomandan: _optionalValue(_komandan),
        distribusiNonSikomandan: _optionalValue(_nonSikomandan),
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, 'Data produksi semen beku diperbarui.');
      Navigator.of(context).pop(true);
    } on StateError catch (error) {
      if (mounted) AppFeedback.showError(context, error.message);
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(context, 'Gagal menyimpan data: $error');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  bool get _hasAnyWeeklyValue => <TextEditingController>[
        _weekI,
        _weekII,
        _weekIII,
        _weekIV,
        _weekV,
      ].any((controller) => controller.text.trim().isNotEmpty);

  bool get _hasAnyDistributionValue =>
      _komandan.text.trim().isNotEmpty ||
      _nonSikomandan.text.trim().isNotEmpty;

  Widget _section(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _readOnly(String label, String value) {
    return InputDecorator(
      decoration: InputDecoration(labelText: label),
      child: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _optionalNumberField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(labelText: label),
      validator: _optionalNonNegativeValidator,
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _compactNumber(TextEditingController controller, String label) {
    return SizedBox(
      width: 120,
      child: _optionalNumberField(controller: controller, label: label),
    );
  }

  Widget _calculatedRow(
    String label,
    int? value, {
    bool emphasized = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: emphasized ? AppTheme.primarySoft : AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          Text(
            value == null ? '-' : _formatNumber(value),
            style: TextStyle(
              color: emphasized ? AppTheme.primaryDark : AppTheme.textPrimary,
              fontSize: emphasized ? 18 : 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  String? _requiredNonNegativeValidator(String? value) {
    final int? parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) return 'Masukkan angka 0 atau lebih.';
    return null;
  }

  String? _optionalNonNegativeValidator(String? value) {
    final String text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final int? parsed = int.tryParse(text);
    if (parsed == null || parsed < 0) return 'Masukkan angka 0 atau lebih.';
    return null;
  }

  int _value(TextEditingController controller) =>
      int.tryParse(controller.text.trim()) ?? 0;

  int? _optionalValue(TextEditingController controller) {
    final String text = controller.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  String _optionalInitial(Map<String, dynamic> data, String key) {
    final dynamic value = data[key];
    if (value == null || value.toString().trim().isEmpty) return '';
    return _asInt(value).toString();
  }

  String _optionalInitialFromAny(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];
      if (value == null || value.toString().trim().isEmpty) continue;
      return _asInt(value).toString();
    }
    return '';
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatNumber(int value) {
    final String digits = value.abs().toString();
    final StringBuffer buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return value < 0 ? '-$buffer' : buffer.toString();
  }

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
