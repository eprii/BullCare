import 'package:flutter/material.dart';

import '../models/activity_record.dart';
import '../theme/app_theme.dart';
import '../utils/app_date_utils.dart';

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
                      '$bullName • ${record.summary}',
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      AppDateUtils.formatDateTime(record.tanggal),
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
