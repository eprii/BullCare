import 'package:flutter/material.dart';

import '../../models/activity_definition.dart';
import '../../models/activity_record.dart';
import '../../models/bull_model.dart';
import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_date_utils.dart';
import '../../utils/bull_sni_status.dart';
import '../../utils/firestore_utils.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/bull_avatar.dart';

class ActivityDetailPage extends StatefulWidget {
  const ActivityDetailPage({
    super.key,
    required this.record,
    this.bull,
    this.onEdit,
  });

  final ActivityRecord record;
  final BullModel? bull;
  final Future<bool> Function()? onEdit;

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late final Future<UserModel?> _petugasFuture;

  @override
  void initState() {
    super.initState();
    final String namaPetugas =
        widget.record.data['nama_petugas']?.toString().trim() ?? '';
    _petugasFuture = namaPetugas.isNotEmpty || widget.record.petugas_uid.isEmpty
        ? Future<UserModel?>.value()
        : UserService().getUser(widget.record.petugas_uid);
  }

  @override
  Widget build(BuildContext context) {
    final ActivityRecord record = widget.record;
    final bool isProduction =
        record.collectionName == 'produksi_distribusi_semen_beku';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Detail Aktivitas')),
      body: AppPageContainer(
        maxWidth: 720,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 28),
          children: isProduction
              ? _productionChildren(record)
              : _standardChildren(record, widget.bull),
        ),
      ),
    );
  }

  List<Widget> _productionChildren(ActivityRecord record) {
    final int year = _asInt(record.data['tahun']);
    final int month = _asInt(record.data['bulan']);
    return <Widget>[
      _ActivityHeader(record: record, bull: null),
      const SizedBox(height: 14),
      _SectionCard(
        title: 'Data Produksi Semen Beku',
        icon: Icons.inventory_2_outlined,
        children: <Widget>[
          _DetailRow(
            label: 'Kategori',
            value: record.data['kategori']?.toString() ?? '-',
          ),
          _DetailRow(
            label: 'Bangsa',
            value: record.data['bangsa']?.toString() ?? '-',
          ),
          if (_normalize(record.data['kategori']) == 'sexing')
            _DetailRow(
              label: 'Status SNI',
              value: _sniLabel(record.data['status_sni']),
            ),
          _DetailRow(
            label: 'Periode',
            value: '${_monthName(month)} $year',
          ),
          _DetailRow(
            label: 'Jumlah pejantan',
            value: '${_asInt(record.data['jumlah_pejantan'])} ekor',
          ),
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
          ),
          _DetailRow(
            label: 'Total Stock',
            value: _displayNumber(record.data['stock_akhir']),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _petugasCard(record),
      const SizedBox(height: 14),
      _SectionCard(
        title: 'Informasi Pencatatan',
        icon: Icons.info_outline,
        children: <Widget>[
          _DetailRow(
            label: 'Periode produksi',
            value: '${_monthName(month)} $year',
          ),
          _DetailRow(
            label: 'Dibuat',
            value: AppDateUtils.formatDateTime(record.created_at),
          ),
          _DetailRow(
            label: 'Terakhir diperbarui',
            value: AppDateUtils.formatDateTime(record.updated_at),
          ),
          const _DetailRow(
            label: 'Akses perubahan',
            value: 'Kelola dari halaman Produksi Semen Beku',
          ),
          _DetailRow(label: 'ID aktivitas', value: record.id),
        ],
      ),
    ];
  }

  List<Widget> _standardChildren(ActivityRecord record, BullModel? bull) {
    return <Widget>[
      _ActivityHeader(record: record, bull: bull),
      const SizedBox(height: 14),
      _SectionCard(
        title: 'Data Bull',
        icon: Icons.pets_outlined,
        children: <Widget>[
          _DetailRow(
            label: 'Nama bull',
            value: bull?.nama ?? 'Bull tidak ditemukan',
          ),
          _DetailRow(
            label: 'Kode bull',
            value: bull?.kode_bull ?? record.bull_id,
          ),
          if (bull != null) ...<Widget>[
            _DetailRow(label: 'Bangsa', value: bull.bangsa),
            _DetailRow(label: 'Nomor kandang', value: bull.nomor_kandang),
            _DetailRow(label: 'Status', value: bull.status),
          ],
        ],
      ),
      const SizedBox(height: 14),
      _SectionCard(
        title: 'Pekerjaan yang Dilakukan',
        icon: Icons.assignment_turned_in_outlined,
        children: record.definition.fields.map((field) {
          return _DetailRow(
            label: field.label,
            value: _displayValue(field, record.data[field.key]),
          );
        }).toList(growable: false),
      ),
      const SizedBox(height: 14),
      _petugasCard(record),
      const SizedBox(height: 14),
      if (_hasAttachment(record)) ...<Widget>[
        const SizedBox(height: 14),
        _attachmentCard(record),
      ],
      const SizedBox(height: 14),
      _SectionCard(
        title: 'Informasi Pencatatan',
        icon: Icons.info_outline,
        children: <Widget>[
          _DetailRow(
            label: 'Tanggal aktivitas',
            value: AppDateUtils.formatDateTime(record.tanggal),
          ),
          _DetailRow(
            label: 'Dibuat',
            value: AppDateUtils.formatDateTime(record.created_at),
          ),
          _DetailRow(
            label: 'Terakhir diperbarui',
            value: AppDateUtils.formatDateTime(record.updated_at),
          ),
          _DetailRow(label: 'ID aktivitas', value: record.id),
        ],
      ),
    ];
  }


  bool _hasAttachment(ActivityRecord record) {
    final String attachment =
        record.data['attachment_name']?.toString().trim() ?? '';
    return attachment.isNotEmpty;
  }

  Widget _attachmentCard(ActivityRecord record) {
    return _SectionCard(
      title: 'Dokumentasi Lampiran',
      icon: Icons.attach_file_outlined,
      children: <Widget>[
        _DetailRow(
          label: 'Nama file',
          value: record.data['attachment_name']?.toString() ?? '-',
        ),
        const _DetailRow(
          label: 'Penyimpanan',
          value: 'Lampiran tersimpan sebagai Base64',
        ),
      ],
    );
  }

  Widget _petugasCard(ActivityRecord record) {
    return _SectionCard(
      title: 'Petugas Pelaksana',
      icon: Icons.badge_outlined,
      children: <Widget>[
        FutureBuilder<UserModel?>(
          future: _petugasFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: LinearProgressIndicator(),
              );
            }
            final UserModel? petugas = snapshot.data;
            final String namaPetugas =
                record.data['nama_petugas']?.toString().trim() ?? '';
            return _DetailRow(
              label: 'Nama petugas',
              value: namaPetugas.isNotEmpty
                  ? namaPetugas
                  : petugas?.nama.trim().isNotEmpty == true
                      ? petugas!.nama
                      : 'Nama petugas belum dicatat',
            );
          },
        ),
      ],
    );
  }

  String _displayValue(ActivityFieldDefinition field, dynamic value) {
    if (field.type == ActivityFieldType.boolean) {
      return value == true ? 'Ya' : 'Tidak';
    }
    if (field.type == ActivityFieldType.date) {
      if (value == null) return '-';
      return AppDateUtils.formatDate(dateTimeFromFirestore(value));
    }
    if (value == null || value.toString().trim().isEmpty) return '-';

    String display = value.toString();
    if (value is double && value == value.roundToDouble()) {
      display = value.toInt().toString();
    }
    if (field.suffix != null) return '$display ${field.suffix}';
    return display;
  }
}

class _ActivityHeader extends StatelessWidget {
  const _ActivityHeader({required this.record, required this.bull});

  final ActivityRecord record;
  final BullModel? bull;

  @override
  Widget build(BuildContext context) {
    final bool isProduction =
        record.collectionName == 'produksi_distribusi_semen_beku';
    final int year = _asInt(record.data['tahun']);
    final int month = _asInt(record.data['bulan']);
    final String productionOwner = <String>[
      record.data['kategori']?.toString().trim() ?? '',
      record.data['bangsa']?.toString().trim() ?? '',
    ].where((value) => value.isNotEmpty).join(' • ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF0B8A36), Color(0xFF05702B)],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: <Widget>[
          bull == null
              ? Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    record.definition.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                )
              : BullAvatar(name: bull!.nama, size: 64),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  record.definition.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  isProduction
                      ? (productionOwner.isEmpty
                          ? 'Produksi semen beku'
                          : productionOwner)
                      : bull?.nama ?? 'Bull tidak ditemukan',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isProduction
                      ? 'Periode ${_monthName(month)} $year • diperbarui ${AppDateUtils.formatDateTime(record.updated_at)}'
                      : AppDateUtils.formatDateTime(record.tanggal),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: SelectableText(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
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

bool _hasValue(dynamic value) =>
    value != null && value.toString().trim().isNotEmpty;

String _displayNumber(dynamic value) =>
    _hasValue(value) ? _formatNumber(_asInt(value)) : '-';

String _normalize(dynamic value) =>
    value?.toString().trim().toLowerCase() ?? '';

String _sniLabel(dynamic value) {
  final String normalized = BullSniStatus.normalize(value?.toString());
  if (normalized == BullSniStatus.bersertifikasi) return 'SNI';
  if (normalized == BullSniStatus.belumBersertifikasi) return 'NON SNI';
  return 'Belum terklasifikasi';
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
