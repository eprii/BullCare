import 'package:flutter/material.dart';

import '../../models/activity_record.dart';
import '../../models/user_model.dart';
import '../../services/produksi_distribusi_semen_beku_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_date_utils.dart';
import '../../utils/bull_breed_name.dart';
import '../../utils/bull_sni_status.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import 'produksi_distribusi_semen_beku_form_page.dart';

class ProduksiDistribusiSemenBekuDetailPage extends StatefulWidget {
  const ProduksiDistribusiSemenBekuDetailPage({
    super.key,
    required this.user,
    required this.recordId,
  });

  final UserModel user;
  final String recordId;

  @override
  State<ProduksiDistribusiSemenBekuDetailPage> createState() =>
      _ProduksiDistribusiSemenBekuDetailPageState();
}

class _ProduksiDistribusiSemenBekuDetailPageState
    extends State<ProduksiDistribusiSemenBekuDetailPage> {
  final ProduksiDistribusiSemenBekuService _service =
      ProduksiDistribusiSemenBekuService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Detail Produksi Semen Beku')),
      body: AppPageContainer(
        maxWidth: 760,
        child: StreamBuilder<ActivityRecord?>(
          stream: _service.watchRecord(widget.recordId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const LoadingView(message: 'Memuat detail produksi...');
            }
            if (snapshot.hasError) {
              return ErrorView(message: snapshot.error.toString());
            }
            final ActivityRecord? record = snapshot.data;
            if (record == null) {
              return const Center(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'Data produksi tidak ditemukan',
                  message: 'Data mungkin sudah tidak tersedia.',
                ),
              );
            }

            final int? periodStock = _hasValue(record.data['stock_akhir'])
                ? _asInt(record.data['stock_akhir'])
                : null;

            return ListView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 32),
              children: <Widget>[
                _HeaderCard(
                  record: record,
                  periodStock: periodStock,
                ),
                const SizedBox(height: 14),
                _DataCard(record: record),
                const SizedBox(height: 14),
                _AuditCard(record: record),
                if (widget.user.isPetugas) ...<Widget>[
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: () => _edit(record),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      _hasProductionData(record)
                          ? 'Edit Data Produksi'
                          : 'Input Data Produksi',
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _edit(ActivityRecord record) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ProduksiDistribusiSemenBekuFormPage(
          user: widget.user,
          record: record,
        ),
      ),
    );
  }

  bool _hasProductionData(ActivityRecord record) =>
      _hasValue(record.data['stock_tahun']) ||
      _hasValue(record.data['stock_awal']) ||
      _hasValue(record.data['produksi_minggu_i']) ||
      _hasValue(record.data['produksi_minggu_ii']) ||
      _hasValue(record.data['produksi_minggu_iii']) ||
      _hasValue(record.data['produksi_minggu_iv']) ||
      _hasValue(record.data['produksi_minggu_v']);
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.record, required this.periodStock});

  final ActivityRecord record;
  final int? periodStock;

  @override
  Widget build(BuildContext context) {
    final String kategori = record.data['kategori']?.toString() ?? '-';
    final String canonicalBangsa =
        BullBreedName.canonical(record.data['bangsa']?.toString());
    final String bangsa = canonicalBangsa.isEmpty ? '-' : canonicalBangsa;
    final String statusSni =
        BullSniStatus.normalize(record.data['status_sni']?.toString());
    final bool isSexing = _normalize(kategori) == 'sexing';
    final int tahun = _asInt(record.data['tahun']);
    final int bulan = _asInt(record.data['bulan']);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0B8A36), Color(0xFF06742C)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            kategori,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            bangsa,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (isSexing) ...<Widget>[
            const SizedBox(height: 7),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _sniLabel(statusSni),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '${_monthName(bulan)} $tahun',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: _HeaderMetric(
                  label: 'Pejantan produksi',
                  value: '${_asInt(record.data['jumlah_pejantan'])} ekor',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeaderMetric(
                  label: 'Total Stock Periode',
                  value: periodStock == null
                      ? '-'
                      : _formatNumber(periodStock!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  const _HeaderMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({required this.record});

  final ActivityRecord record;

  @override
  Widget build(BuildContext context) {
    final int year = _asInt(record.data['tahun']);
    return _SectionCard(
      title: 'Data Produksi',
      icon: Icons.inventory_2_outlined,
      children: <Widget>[
        _DetailRow(
          label: 'Stock $year',
          value: _displayNumber(
            _firstValue(record.data, <String>['stock_tahun', 'stock_awal']),
          ),
        ),
        _DetailRow(
          label: 'Minggu I',
          value: _displayNumber(record.data['produksi_minggu_i']),
        ),
        _DetailRow(
          label: 'Minggu II',
          value: _displayNumber(record.data['produksi_minggu_ii']),
        ),
        _DetailRow(
          label: 'Minggu III',
          value: _displayNumber(record.data['produksi_minggu_iii']),
        ),
        _DetailRow(
          label: 'Minggu IV',
          value: _displayNumber(record.data['produksi_minggu_iv']),
        ),
        _DetailRow(
          label: 'Minggu V',
          value: _displayNumber(record.data['produksi_minggu_v']),
        ),
        _DetailRow(
          label: 'Jumlah Produksi',
          value: _displayNumber(record.data['jumlah_produksi']),
          emphasized: true,
        ),
        _DetailRow(
          label: 'Afkir',
          value: _displayNumber(record.data['afkir']),
        ),
        _DetailRow(
          label: 'Distribusi Komandan',
          value: _displayNumber(record.data['distribusi_komandan']),
        ),
        _DetailRow(
          label: 'Distribusi Non Sikomandan',
          value: _displayNumber(record.data['distribusi_non_sikomandan']),
        ),
        _DetailRow(
          label: 'Jumlah Distribusi',
          value: _displayNumber(record.data['jumlah_distribusi']),
          emphasized: true,
        ),
        _DetailRow(
          label: 'Total Stock',
          value: _displayNumber(record.data['stock_akhir']),
          emphasized: true,
          primary: true,
        ),
      ],
    );
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({required this.record});

  final ActivityRecord record;

  @override
  Widget build(BuildContext context) {
    final String namaPetugas =
        record.data['nama_petugas']?.toString().trim() ?? '';
    return _SectionCard(
      title: 'Pencatatan',
      icon: Icons.history_outlined,
      children: <Widget>[
        _DetailRow(
          label: 'Dibuat',
          value: AppDateUtils.formatDateTime(record.created_at),
        ),
        _DetailRow(
          label: 'Terakhir diperbarui',
          value: AppDateUtils.formatDateTime(record.updated_at),
        ),
        _DetailRow(
          label: 'Petugas terakhir',
          value: namaPetugas.isEmpty ? '-' : namaPetugas,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppTheme.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.primary = false,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: emphasized
          ? BoxDecoration(
              color: primary ? AppTheme.primarySoft : AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: emphasized
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: TextStyle(
              color: primary ? AppTheme.primaryDark : AppTheme.textPrimary,
              fontSize: primary ? 18 : 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

dynamic _firstValue(Map<String, dynamic> data, List<String> keys) {
  for (final String key in keys) {
    final dynamic value = data[key];
    if (_hasValue(value)) return value;
  }
  return null;
}

String _sniLabel(String status) {
  if (status == BullSniStatus.bersertifikasi) return 'SNI';
  if (status == BullSniStatus.belumBersertifikasi) return 'NON SNI';
  return 'BELUM TERKLASIFIKASI';
}

String _normalize(dynamic value) =>
    value?.toString().trim().toLowerCase() ?? '';

bool _hasValue(dynamic value) =>
    value != null && value.toString().trim().isNotEmpty;

String _displayNumber(dynamic value) =>
    _hasValue(value) ? _formatNumber(_asInt(value)) : '-';

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
