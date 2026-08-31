import 'dart:convert';

import 'package:flutter/material.dart';

import '../../models/activity_definition.dart';
import '../../models/activity_record.dart';
import '../../models/bull_model.dart';
import '../../models/user_model.dart';
import '../../services/activity_service_registry.dart';
import '../../services/bull_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/bull_sni_status.dart';
import '../../utils/bull_status.dart';
import '../../utils/app_date_utils.dart';
import '../../utils/app_feedback.dart';
import '../../utils/confirmation_dialog.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/section_header.dart';
import '../activities/activity_detail_page.dart';
import '../activities/activity_form_page.dart';
import '../activities/activity_type_page.dart';
import 'bull_form_page.dart';

class BullProfilePage extends StatefulWidget {
  const BullProfilePage({
    super.key,
    required this.bullId,
    required this.user,
    this.onDataChanged,
  });

  final String bullId;
  final UserModel user;
  final VoidCallback? onDataChanged;

  @override
  State<BullProfilePage> createState() => _BullProfilePageState();
}

class _BullProfilePageState extends State<BullProfilePage> {
  final BullService _bullService = BullService();
  late Future<List<ActivityRecord>> _history;
  String _historyFilter = '';

  @override
  void initState() {
    super.initState();
    _reloadHistory();
  }

  void _reloadHistory() {
    _history = ActivityServiceRegistry.getHistoryForBull(widget.bullId);
  }

  Future<void> _addActivity(BullModel bull) async {
    if (!widget.user.isPetugas) return;

    final String? activityLabel = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ActivityTypePage(bull: bull, user: widget.user),
      ),
    );
    if (activityLabel != null && mounted) {
      setState(_reloadHistory);
      widget.onDataChanged?.call();
      AppFeedback.showSuccess(
        context,
        'Berhasil menambah aktivitas $activityLabel.',
      );
    }
  }

  Future<void> _showBullActions(BullModel bull) async {
    if (!widget.user.isPetugas) return;

    final String? action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x52000000),
      isScrollControlled: false,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x1F000000),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDDE3DE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Kelola data bull',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.25,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  bull.nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                _BullActionSheetTile(
                  icon: Icons.edit_rounded,
                  iconColor: AppTheme.primary,
                  iconBackground: AppTheme.primarySoft,
                  title: 'Edit data bull',
                  subtitle: 'Ubah identitas, umur, foto, atau status bull',
                  onTap: () => Navigator.of(sheetContext).pop('edit'),
                ),
                const SizedBox(height: 10),
                _BullActionSheetTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: const Color(0xFFD92D20),
                  iconBackground: const Color(0xFFFFE8E5),
                  title: 'Hapus bull',
                  subtitle: 'Hapus data master bull dari daftar',
                  isDestructive: true,
                  onTap: () => Navigator.of(sheetContext).pop('delete'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;
    if (action == 'edit') {
      await _editBull(bull);
    } else if (action == 'delete') {
      await _delete(bull);
    }
  }

  Future<void> _editBull(BullModel bull) async {
    if (!widget.user.isPetugas) return;

    final String? id = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => BullFormPage(user: widget.user, bull: bull),
      ),
    );
    if (id != null && mounted) {
      widget.onDataChanged?.call();
      AppFeedback.showSuccess(context, 'Berhasil memperbarui data bull.');
    }
  }

  Future<void> _delete(BullModel bull) async {
    if (!widget.user.isPetugas) return;

    final bool confirmed = await showConfirmationDialog(
      context,
      title: 'Hapus data bull?',
      message: 'Data master ${bull.nama} akan dihapus. Riwayat aktivitas '
          'tidak ikut dihapus agar arsip tetap tersimpan. Tindakan ini tidak '
          'dapat dibatalkan.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || !mounted) return;

    try {
      await _bullService.deleteBull(bull.id);
      if (mounted) {
        widget.onDataChanged?.call();
        Navigator.of(context).pop('deleted');
      }
    } catch (error) {
      if (mounted) {
        AppFeedback.showError(context, 'Penghapusan gagal: $error');
      }
    }
  }

  Future<void> _editActivity(BullModel bull, ActivityRecord record) async {
    if (!widget.user.isPetugas) return;

    final bool? saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ActivityFormPage(
          bull: bull,
          user: widget.user,
          definition: record.definition,
          existing: record,
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(_reloadHistory);
      widget.onDataChanged?.call();
      AppFeedback.showSuccess(
        context,
        'Berhasil memperbarui aktivitas ${record.definition.label}.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BullModel?>(
      stream: _bullService.watchBull(widget.bullId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: LoadingView());
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(message: snapshot.error.toString()),
          );
        }

        final BullModel? bull = snapshot.data;
        if (bull == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.agriculture_outlined,
              title: 'Data bull tidak ditemukan',
              message: 'Data mungkin telah dihapus.',
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: const Text('Detail Bull'),
            actions: widget.user.isPetugas
                ? <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        tooltip: 'Kelola data bull',
                        onPressed: () => _showBullActions(bull),
                        style: IconButton.styleFrom(
                          backgroundColor: AppTheme.surfaceMuted,
                          foregroundColor: AppTheme.textPrimary,
                          minimumSize: const Size(42, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: const BorderSide(color: AppTheme.divider),
                          ),
                        ),
                        icon: const Icon(Icons.more_horiz_rounded),
                      ),
                    ),
                  ]
                : null,
          ),
          body: FutureBuilder<List<ActivityRecord>>(
            future: _history,
            builder: (context, activitySnapshot) {
              if (activitySnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingView();
              }
              if (activitySnapshot.hasError) {
                return ErrorView(message: activitySnapshot.error.toString());
              }

              final List<ActivityRecord> history =
                  activitySnapshot.data ?? <ActivityRecord>[];

              return RefreshIndicator(
                onRefresh: () async {
                  setState(_reloadHistory);
                  await _history;
                },
                child: AppPageContainer(
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 110),
                    children: <Widget>[
                      _HeroCard(bull: bull),
                      const SizedBox(height: 14),
                      _ConditionGrid(history: history),
                      const SizedBox(height: 18),
                      _InformationCard(bull: bull),
                      const SizedBox(height: 24),
                      const SectionHeader(
                        title: 'Riwayat Aktivitas',
                        subtitle: 'Filter aktivitas berdasarkan kategori',
                      ),
                      const SizedBox(height: 10),
                      _HistoryContent(
                        bull: bull,
                        history: history,
                        selectedFilter: _historyFilter,
                        user: widget.user,
                        onFilterChanged: (value) {
                          setState(() => _historyFilter = value);
                        },
                        onEdit: (record) => _editActivity(bull, record),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          floatingActionButton: widget.user.isPetugas
              ? FloatingActionButton.extended(
                  onPressed: () => _addActivity(bull),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Tambah Aktivitas'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _BullActionSheetTile extends StatelessWidget {
  const _BullActionSheetTile({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDestructive ? const Color(0xFFFFFAF9) : AppTheme.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDestructive
                  ? const Color(0xFFFFD8D3)
                  : AppTheme.divider,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 23),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive
                            ? const Color(0xFFB42318)
                            : AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: isDestructive
                    ? const Color(0xFFD92D20)
                    : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.bull});

  final BullModel bull;

  @override
  Widget build(BuildContext context) {
    final String normalizedStatus = BullStatus.normalize(bull.status);
    final bool healthy = normalizedStatus == BullStatus.sehat;
    final bool needsVaccine = normalizedStatus == BullStatus.butuhVaksin;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          height: 190,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned.fill(child: _BullHeroBackground(bull: bull)),
              Positioned(
                right: 12,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: healthy
                        ? const Color(0xFFE5F6E9)
                        : needsVaccine
                            ? const Color(0xFFFFF1D6)
                            : const Color(0xFFFFE8E5),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    normalizedStatus,
                    style: TextStyle(
                      color: healthy
                          ? const Color(0xFF18713A)
                          : needsVaccine
                              ? const Color(0xFF9A5B00)
                              : const Color(0xFF9A3328),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          bull.kode_bull,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 2),
        Text(
          '${bull.nama} • ${bull.bangsa}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _BullHeroBackground extends StatelessWidget {
  const _BullHeroBackground({required this.bull});

  final BullModel bull;

  @override
  Widget build(BuildContext context) {
    final String encoded = bull.foto_background_base64.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (encoded.isNotEmpty)
            _MemoryImageOrFallback(
              encoded: encoded,
              fallback: const _BackgroundPlaceholder(),
            )
          else
            const _BackgroundPlaceholder(),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0x05000000),
                  Color(0x25000000),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryImageOrFallback extends StatelessWidget {
  const _MemoryImageOrFallback({
    required this.encoded,
    required this.fallback,
  });

  final String encoded;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    try {
      return Image.memory(
        base64Decode(encoded),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => fallback,
      );
    } catch (_) {
      return fallback;
    }
  }
}

class _BackgroundPlaceholder extends StatelessWidget {
  const _BackgroundPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFEAF7EC),
            Color(0xFFBFE6C7),
            Color(0xFFF7F2D4),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: EdgeInsets.only(left: 24),
          child: Icon(
            Icons.image_outlined,
            size: 42,
            color: Color(0x660B7A3D),
          ),
        ),
      ),
    );
  }
}

class _ConditionGrid extends StatelessWidget {
  const _ConditionGrid({required this.history});

  final List<ActivityRecord> history;

  ActivityRecord? _latest(String collection) {
    for (final ActivityRecord record in history) {
      if (record.collectionName == collection) return record;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ActivityRecord? weight = _latest('penimbangan');
    final ActivityRecord? health = _latest('pemeriksaan_kesehatan');
    final ActivityRecord? measurement = _latest('pengukuran');

    return Row(
      children: <Widget>[
        Expanded(
          child: _MetricCard(
            icon: Icons.monitor_weight_outlined,
            label: 'Berat',
            value: weight == null ? '-' : '${weight.data['berat_badan']} kg',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.health_and_safety_outlined,
            label: 'Kondisi',
            value: health?.data['kondisi']?.toString() ?? '-',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MetricCard(
            icon: Icons.straighten_outlined,
            label: 'Lingkar',
            value: measurement == null
                ? '-'
                : '${measurement.data['lingkar_badan']} cm',
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppTheme.primarySoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: AppTheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InformationCard extends StatelessWidget {
  const _InformationCard({required this.bull});

  final BullModel bull;

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
        children: <Widget>[
          _InfoRow(
            icon: Icons.cake_outlined,
            label: 'Umur',
            value: bull.umur.trim().isEmpty ? '-' : '${bull.umur} tahun',
          ),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.home_work_outlined,
            label: 'Nomor kandang',
            value: bull.nomor_kandang,
          ),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.color_lens_outlined,
            label: 'Warna straw',
            value: bull.warna_straw,
          ),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.verified_outlined,
            label: 'Status SNI',
            value: BullSniStatus.label(bull.status_sni),
          ),
          const Divider(height: 22),
          _InfoRow(
            icon: Icons.update_rounded,
            label: 'Terakhir diperbarui',
            value: AppDateUtils.formatDate(bull.updated_at),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.bull,
    required this.history,
    required this.selectedFilter,
    required this.user,
    required this.onFilterChanged,
    required this.onEdit,
  });

  final BullModel bull;
  final List<ActivityRecord> history;
  final String selectedFilter;
  final UserModel user;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<ActivityRecord> onEdit;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Card(
        child: EmptyState(
          icon: Icons.history,
          title: 'Riwayat masih kosong',
          message: 'Aktivitas baru akan membentuk timeline pemeliharaan bull.',
        ),
      );
    }

    final Map<String, int> categoryCounts = <String, int>{};
    for (final ActivityRecord record in history) {
      categoryCounts.update(
        record.collectionName,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final List<ActivityRecord> filteredHistory = selectedFilter.isEmpty
        ? history.take(5).toList(growable: false)
        : history
            .where((record) => record.collectionName == selectedFilter)
            .toList(growable: false);

    final String selectedLabel = selectedFilter.isEmpty
        ? 'Semua Aktivitas'
        : ActivityCatalog.byCollection(selectedFilter).label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: 43,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('Semua (${history.length})'),
                  selected: selectedFilter.isEmpty,
                  onSelected: (_) => onFilterChanged(''),
                ),
              ),
              ...ActivityCatalog.all.map((definition) {
                final int count =
                    categoryCounts[definition.collectionName] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(definition.icon, size: 17),
                    label: Text('${definition.label} ($count)'),
                    selected: selectedFilter == definition.collectionName,
                    onSelected: (_) =>
                        onFilterChanged(definition.collectionName),
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filteredHistory.isEmpty)
          EmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: 'Belum ada $selectedLabel',
            message: 'Belum ada aktivitas pada kategori yang dipilih.',
          )
        else
          ...filteredHistory.map((record) {
            return ActivityTile(
              record: record,
              bullName: bull.nama,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ActivityDetailPage(
                      record: record,
                      bull: bull,
                    ),
                  ),
                );
              },
              trailing: user.isPetugas
                  ? IconButton(
                      onPressed: () => onEdit(record),
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit aktivitas',
                    )
                  : null,
            );
          }),
      ],
    );
  }
}
