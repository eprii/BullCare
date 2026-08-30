import 'package:flutter/material.dart';

import '../models/activity_record.dart';
import '../theme/app_theme.dart';
import '../utils/app_date_utils.dart';
import '../utils/bull_sni_status.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.record,
    required this.bullName,
    this.onTap,
    this.trailing,
    this.compact = false,
  });

  final ActivityRecord record;
  final String bullName;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color accent = _accentFor(record.collectionName);
    return Container(
      margin: EdgeInsets.only(bottom: compact ? 8 : 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.divider),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0C000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 11 : 13,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: compact ? 42 : 48,
                height: compact ? 42 : 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  record.definition.icon,
                  color: accent,
                  size: compact ? 22 : 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      record.definition.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      record.collectionName == 'produksi_distribusi_semen_beku'
                          ? _productionSummary(record)
                          : '$bullName • ${record.summary}',
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _dateLabel(record),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 6),
                trailing!,
              ] else if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF9AA39C),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _productionSummary(ActivityRecord record) {
    final String category = record.data['kategori']?.toString().trim() ?? '';
    final String breed = record.data['bangsa']?.toString().trim() ?? '';
    final List<String> parts = <String>[
      if (category.isNotEmpty) category,
      if (breed.isNotEmpty) breed,
    ];
    if (category.toLowerCase() == 'sexing') {
      final String status =
          BullSniStatus.normalize(record.data['status_sni']?.toString());
      if (status == BullSniStatus.bersertifikasi) {
        parts.add('SNI');
      } else if (status == BullSniStatus.belumBersertifikasi) {
        parts.add('NON SNI');
      } else {
        parts.add('Belum terklasifikasi');
      }
    }
    return parts.isEmpty ? 'Produksi semen beku' : parts.join(' • ');
  }

  String _dateLabel(ActivityRecord record) {
    if (record.collectionName != 'produksi_distribusi_semen_beku') {
      return AppDateUtils.formatDateTime(record.tanggal);
    }
    final int month = _asInt(record.data['bulan']);
    final int year = _asInt(record.data['tahun']);
    return 'Periode ${_monthName(month)} $year • diperbarui ${AppDateUtils.formatDateTime(record.updated_at)}';
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _monthName(int month) {
    const List<String> months = <String>[
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
    ];
    if (month < 1 || month > 12) return 'Bulan';
    return months[month - 1];
  }

  Color _accentFor(String collection) {
    switch (collection) {
      case 'pemberian_pakan':
        return const Color(0xFF3C9B45);
      case 'sanitasi':
        return const Color(0xFF1D8CC9);
      case 'pemeriksaan_kesehatan':
        return const Color(0xFF168A63);
      case 'penimbangan':
        return const Color(0xFF8B5CF6);
      case 'pengukuran':
        return const Color(0xFF0F766E);
      case 'pengobatan':
        return const Color(0xFFE26A2C);
      case 'pemberian_obat_cacing':
        return const Color(0xFFE89B18);
      case 'pemotongan_bulu':
        return const Color(0xFF7C6F64);
      case 'pemotongan_kuku':
        return const Color(0xFF8A4F7D);
      case 'penampungan_semen':
        return const Color(0xFF2684D8);
      default:
        return AppTheme.primary;
    }
  }
}
