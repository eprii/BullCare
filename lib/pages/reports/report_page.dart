import 'package:flutter/material.dart';

import '../../models/report_export_data.dart';
import '../../models/user_model.dart';
import '../../services/report_export_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_date_utils.dart';
import '../../utils/app_feedback.dart';
import '../../widgets/app_page_container.dart';

const String _pdfReportIconAsset = 'assets/report/report_pdf_icon.png';
const String _wordReportIconAsset = 'assets/report/report_word_icon.png';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key, required this.user});

  final UserModel user;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final ReportExportService _service = const ReportExportService();
  final TextEditingController _fileNameController = TextEditingController();

  String? _selectedSourceId;
  late DateTimeRange _period;
  ReportFileFormat _format = ReportFileFormat.pdf;
  ReportPageOrientation _orientation = ReportPageOrientation.portrait;
  bool _exporting = false;

  static const List<_ReportSourceOption> _sourceOptions =
      <_ReportSourceOption>[
    _ReportSourceOption(
      id: 'pemberian_pakan',
      collectionName: 'pemberian_pakan',
      label: 'Pemberian Pakan',
      icon: Icons.grass_outlined,
    ),
    _ReportSourceOption(
      id: 'sanitasi',
      collectionName: 'sanitasi',
      label: 'Sanitasi',
      icon: Icons.cleaning_services_outlined,
    ),
    _ReportSourceOption(
      id: 'pemeriksaan_kesehatan',
      collectionName: 'pemeriksaan_kesehatan',
      label: 'Pemeriksaan Kesehatan',
      icon: Icons.health_and_safety_outlined,
    ),
    _ReportSourceOption(
      id: 'penimbangan',
      collectionName: 'penimbangan',
      label: 'Penimbangan',
      icon: Icons.monitor_weight_outlined,
    ),
    _ReportSourceOption(
      id: 'pengukuran',
      collectionName: 'pengukuran',
      label: 'Pengukuran',
      icon: Icons.straighten_outlined,
    ),
    _ReportSourceOption(
      id: 'pengobatan',
      collectionName: 'pengobatan',
      label: 'Pengobatan',
      icon: Icons.medication_outlined,
    ),
    _ReportSourceOption(
      id: 'pemberian_obat_cacing',
      collectionName: 'pemberian_obat_cacing',
      label: 'Pemberian Obat Cacing',
      icon: Icons.vaccines_outlined,
    ),
    _ReportSourceOption(
      id: 'pemotongan_bulu',
      collectionName: 'pemotongan_bulu',
      label: 'Pemotongan Bulu',
      icon: Icons.content_cut_outlined,
    ),
    _ReportSourceOption(
      id: 'pemotongan_kuku',
      collectionName: 'pemotongan_kuku',
      label: 'Pemotongan Kuku',
      icon: Icons.back_hand_outlined,
    ),
    _ReportSourceOption(
      id: 'penampungan_semen',
      collectionName: 'penampungan_semen',
      label: 'Penampungan Semen',
      icon: Icons.water_drop_outlined,
    ),
  ];

  _ReportSourceOption? get _selectedSource {
    final String? id = _selectedSourceId;
    if (id == null) return null;
    for (final _ReportSourceOption source in _sourceOptions) {
      if (source.id == id) return source;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final DateTime now = DateTime.now();
    _period = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
    _fileNameController.text =
        'Laporan BullCare ${_monthName(now.month)} ${now.year}';
  }

  @override
  void dispose() {
    _fileNameController.dispose();
    super.dispose();
  }

  Future<T?> _showBullCareDropdown<T>({
    required BuildContext anchorContext,
    required List<PopupMenuEntry<T>> Function(double width) itemBuilder,
  }) {
    final RenderBox? anchorBox =
        anchorContext.findRenderObject() as RenderBox?;
    final RenderBox? overlayBox =
        Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;
    if (anchorBox == null || overlayBox == null) {
      return Future<T?>.value(null);
    }

    final Offset topLeft =
        anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final Rect anchorRect = Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      anchorBox.size.width,
      anchorBox.size.height,
    );
    final double menuWidth =
        anchorBox.size.width.clamp(240.0, 520.0).toDouble();

    return showMenu<T>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(
          anchorRect.left,
          anchorRect.bottom + 6,
          anchorRect.width,
          1,
        ),
        Offset.zero & overlayBox.size,
      ),
      items: itemBuilder(menuWidth),
      color: Colors.white,
      elevation: 10,
      shadowColor: const Color(0x24000000),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppTheme.divider),
      ),
    );
  }

  Future<void> _chooseSource(BuildContext anchorContext) async {
    final String? result = await _showBullCareDropdown<String>(
      anchorContext: anchorContext,
      itemBuilder: (double menuWidth) {
        return _sourceOptions.map((source) {
          final bool selected = source.id == _selectedSourceId;
          return PopupMenuItem<String>(
            value: source.id,
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              width: menuWidth - 28,
              child: Row(
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primarySoft
                          : AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      source.icon,
                      size: 19,
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      source.label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected
                            ? AppTheme.primaryDark
                            : AppTheme.textPrimary,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 19,
                      color: AppTheme.primary,
                    ),
                ],
              ),
            ),
          );
        }).toList();
      },
    );
    if (result == null || !mounted) return;
    setState(() => _selectedSourceId = result);
  }

  Future<void> _chooseOrientation(BuildContext anchorContext) async {
    final ReportPageOrientation? result =
        await _showBullCareDropdown<ReportPageOrientation>(
      anchorContext: anchorContext,
      itemBuilder: (double menuWidth) {
        return <PopupMenuEntry<ReportPageOrientation>>[
          _orientationMenuItem(
            value: ReportPageOrientation.portrait,
            label: 'Potret',
            subtitle: 'Halaman tegak',
            icon: Icons.stay_current_portrait_rounded,
            selected: _orientation == ReportPageOrientation.portrait,
            width: menuWidth,
          ),
          _orientationMenuItem(
            value: ReportPageOrientation.landscape,
            label: 'Lanskap',
            subtitle: 'Halaman mendatar',
            icon: Icons.stay_current_landscape_rounded,
            selected: _orientation == ReportPageOrientation.landscape,
            width: menuWidth,
          ),
        ];
      },
    );
    if (result == null || !mounted) return;
    setState(() => _orientation = result);
  }

  PopupMenuItem<ReportPageOrientation> _orientationMenuItem({
    required ReportPageOrientation value,
    required String label,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required double width,
  }) {
    return PopupMenuItem<ReportPageOrientation>(
      value: value,
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        width: width - 28,
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primarySoft
                    : AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 20,
                color:
                    selected ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? AppTheme.primaryDark
                          : AppTheme.textPrimary,
                      fontWeight:
                          selected ? FontWeight.w800 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                size: 19,
                color: AppTheme.primary,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _choosePeriod() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _period,
      helpText: 'Pilih periode laporan',
      saveText: 'Gunakan',
    );
    if (result == null || !mounted) return;
    setState(() => _period = result);
  }

  Future<void> _export() async {
    if (_exporting) return;
    final _ReportSourceOption? source = _selectedSource;
    if (source == null) {
      AppFeedback.showError(context, 'Pilih sumber data aktivitas terlebih dahulu.');
      return;
    }
    if (_fileNameController.text.trim().isEmpty) {
      AppFeedback.showError(context, 'Nama file tidak boleh kosong.');
      return;
    }
    final bool spansMultipleMonths =
        _period.start.year != _period.end.year ||
            _period.start.month != _period.end.month;
    if (source.collectionName == 'sanitasi' && spansMultipleMonths) {
      AppFeedback.showError(
        context,
        'Formulir sanitasi dibuat per bulan. Pilih periode dalam bulan yang sama.',
      );
      return;
    }
    if (source.collectionName == 'pemberian_pakan' && spansMultipleMonths) {
      AppFeedback.showError(
        context,
        'Formulir pemberian pakan SOP-6.3a dibuat per bulan. Pilih periode dalam bulan yang sama.',
      );
      return;
    }
    if (source.collectionName == 'penimbangan' &&
        _period.start.year != _period.end.year) {
      AppFeedback.showError(
        context,
        'Formulir penimbangan pejantan SOP-6.3b dibuat per tahun. Pilih periode dalam tahun yang sama.',
      );
      return;
    }
    setState(() => _exporting = true);
    try {
      final ReportExportData data = await _service.loadData(
        collections: <String>{source.collectionName},
        periodStart: _period.start,
        periodEnd: _period.end,
        sourceLabel: source.label,
      );
      if (!mounted) return;
      if (data.records.isEmpty) {
        AppFeedback.showError(
          context,
          'Tidak ada data ${source.label.toLowerCase()} pada periode yang dipilih.',
        );
        return;
      }

      await _service.export(
        data: data,
        exportedBy: widget.user,
        fileName: _fileNameController.text,
        format: _format,
        orientation: _orientation,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        'Berhasil mengekspor ${data.records.length} data ${source.label} ke ${_format == ReportFileFormat.pdf ? 'PDF' : 'Word'}.',
      );
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, 'Gagal mengekspor laporan: $error');
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = _format == ReportFileFormat.pdf
        ? AppTheme.primary
        : const Color(0xFF2D6BD3);
    final _ReportSourceOption? selectedSource = _selectedSource;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Laporan')),
      body: AppPageContainer(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: <Widget>[
            _FormatHero(
              format: _format,
              onFormatChanged: (format) => setState(() => _format = format),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Pilih Sumber Data',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Builder(
                    builder: (BuildContext dropdownContext) {
                      return _CustomSelectorField(
                        label: 'Jenis aktivitas',
                        value: selectedSource?.label,
                        placeholder: 'Pilih aktivitas yang akan dilaporkan',
                        leadingIcon:
                            selectedSource?.icon ?? Icons.fact_check_outlined,
                        onTap: () => _chooseSource(dropdownContext),
                      );
                    },
                  ),
                  if (selectedSource != null) ...<Widget>[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            selectedSource.icon,
                            color: AppTheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedSource.collectionName == 'sanitasi'
                                  ? 'Laporan Sanitasi menggunakan template FORMULIR SANITASI KANDANG DAN PEJANTAN (SOP-6.3.l). Formulir utama tetap mengikuti format SOP, lalu dilengkapi halaman rincian data sanitasi agar isi setiap aktivitas terlihat lengkap.'
                                  : selectedSource.collectionName == 'pemberian_pakan'
                                      ? 'Laporan Pemberian Pakan menggunakan template SOP-6.3a: FORMULIR PEMBERIAN PAKAN HIJAUAN, KONSENTRAT, dan KECAMBAH. Formulir dibuat per bulan dan dilengkapi halaman rincian agar data aktivitas tetap terlihat lengkap.'
                                      : selectedSource.collectionName == 'penimbangan'
                                          ? 'Laporan Penimbangan menggunakan template FORMULIR PENIMBANGAN PEJANTAN (SOP-6.3b). Berat badan ditempatkan per bull dan per bulan dalam satu tahun, lalu dilengkapi halaman rincian agar tanggal, keterangan, dan nama petugas tetap terbaca.'
                                          : selectedSource.collectionName == 'penampungan_semen'
                                              ? 'Laporan Penampungan Semen menggunakan template FORMULIR PENAMPUNGAN SEMEN (SOP-7.5.1f) dengan kolom AV, Vaselin, Suhu, Volume Semen, dan Paraf. Jika periode mencakup beberapa tanggal, setiap Hari/Tanggal dibuat pada lembar formulir tersendiri.'
                                              : 'Laporan akan mengambil data ${selectedSource.label} sesuai periode yang dipilih.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Pilih Periode',
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _choosePeriod,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceMuted,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.calendar_month_outlined),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${AppDateUtils.formatDate(_period.start)} - ${AppDateUtils.formatDate(_period.end)}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _SectionCard(
              title: 'Pengaturan File',
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _fileNameController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Nama file',
                      prefixIcon: Icon(Icons.insert_drive_file_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (BuildContext dropdownContext) {
                      return _CustomSelectorField(
                        label: 'Orientasi',
                        value: _orientation == ReportPageOrientation.portrait
                            ? 'Potret'
                            : 'Lanskap',
                        placeholder: 'Pilih orientasi laporan',
                        leadingIcon:
                            _orientation == ReportPageOrientation.portrait
                                ? Icons.stay_current_portrait_rounded
                                : Icons.stay_current_landscape_rounded,
                        onTap: () => _chooseOrientation(dropdownContext),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _exporting ? null : _export,
                icon: _exporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Image.asset(
                        _format == ReportFileFormat.pdf
                            ? _pdfReportIconAsset
                            : _wordReportIconAsset,
                        width: 26,
                        height: 26,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                label: Text(
                  _exporting
                      ? 'Menyiapkan laporan...'
                      : 'Export ke ${_format == ReportFileFormat.pdf ? 'PDF' : 'Word'}',
                ),
              ),
            ),
            const SizedBox(height: 14),
            _SafetyInfo(format: _format),
          ],
        ),
      ),
    );
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
    return months[month - 1];
  }
}

class _ReportSourceOption {
  const _ReportSourceOption({
    required this.id,
    required this.collectionName,
    required this.label,
    required this.icon,
  });

  final String id;
  final String collectionName;
  final String label;
  final IconData icon;
}

class _FormatHero extends StatelessWidget {
  const _FormatHero({required this.format, required this.onFormatChanged});

  final ReportFileFormat format;
  final ValueChanged<ReportFileFormat> onFormatChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.divider),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 18,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 118,
            height: 104,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Image.asset(
              format == ReportFileFormat.pdf
                  ? _pdfReportIconAsset
                  : _wordReportIconAsset,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Export Laporan BullCare',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih aktivitas dan periode, lalu simpan laporan dalam format PDF atau Word.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _FormatChoice(
                  label: 'PDF',
                  assetPath: _pdfReportIconAsset,
                  selected: format == ReportFileFormat.pdf,
                  color: AppTheme.primary,
                  onTap: () => onFormatChanged(ReportFileFormat.pdf),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FormatChoice(
                  label: 'Word (.docx)',
                  assetPath: _wordReportIconAsset,
                  selected: format == ReportFileFormat.word,
                  color: const Color(0xFF2D6BD3),
                  onTap: () => onFormatChanged(ReportFileFormat.word),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormatChoice extends StatelessWidget {
  const _FormatChoice({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.10) : AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Image.asset(
              assetPath,
              width: 30,
              height: 30,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? color : AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _CustomSelectorField extends StatelessWidget {
  const _CustomSelectorField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.leadingIcon,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String placeholder;
  final IconData leadingIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.trim().isNotEmpty;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppTheme.surfaceMuted,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasValue
                ? AppTheme.primary.withValues(alpha: 0.22)
                : AppTheme.divider,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: hasValue
                    ? AppTheme.primarySoft
                    : Colors.white,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                leadingIcon,
                size: 21,
                color: hasValue ? AppTheme.primary : AppTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasValue ? value! : placeholder,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: hasValue
                              ? AppTheme.textPrimary
                              : AppTheme.textSecondary,
                          fontWeight: hasValue ? FontWeight.w800 : FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 22,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafetyInfo extends StatelessWidget {
  const _SafetyInfo({required this.format});

  final ReportFileFormat format;

  @override
  Widget build(BuildContext context) {
    final bool pdf = format == ReportFileFormat.pdf;
    final Color color = pdf ? AppTheme.primary : const Color(0xFF2D6BD3);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.shield_outlined, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              pdf
                  ? 'Laporan PDF dibuat langsung dari data BullCare dan disimpan ke perangkat Anda.'
                  : 'File Word (.docx) dapat dibuka dan diedit menggunakan Microsoft Word atau aplikasi sejenis.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
