import 'package:flutter/material.dart';

import '../../models/activity_definition.dart';
import '../../models/activity_record.dart';
import '../../models/bull_model.dart';
import '../../models/user_model.dart';
import '../../services/activity_service_registry.dart';
import '../../services/bull_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_date_utils.dart';
import '../../utils/app_feedback.dart';
import '../../utils/confirmation_dialog.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';
import '../bulls/bull_list_page.dart';
import 'activity_detail_page.dart';
import 'activity_form_page.dart';
import 'activity_type_page.dart';

class ActivityListData {
  const ActivityListData({required this.records, required this.bulls});

  final List<ActivityRecord> records;
  final Map<String, BullModel> bulls;
}

class ActivityListPage extends StatefulWidget {
  const ActivityListPage({
    super.key,
    required this.user,
    this.revision = 0,
    this.onDataChanged,
  });

  final UserModel user;
  final int revision;
  final VoidCallback? onDataChanged;

  @override
  State<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends State<ActivityListPage> {
  late Future<ActivityListData> _future;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant ActivityListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _reload();
    }
  }

  void _reload() {
    _future = _load();
  }

  Future<ActivityListData> _load() async {
    final List<dynamic> results = await Future.wait<dynamic>(
      <Future<dynamic>>[
        ActivityServiceRegistry.getAll(),
        BullService().getBulls(),
      ],
    );
    final List<ActivityRecord> records = results[0] as List<ActivityRecord>;
    final List<BullModel> bulls = results[1] as List<BullModel>;
    return ActivityListData(
      records: records,
      bulls: <String, BullModel>{
        for (final BullModel bull in bulls) bull.id: bull,
      },
    );
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _add() async {
    if (!widget.user.isPetugas) return;

    final BullModel? bull = await Navigator.of(context).push<BullModel>(
      MaterialPageRoute<BullModel>(
        builder: (_) => BullListPage(
          user: widget.user,
          selectionMode: true,
        ),
      ),
    );
    if (bull == null || !mounted) return;

    final String? activityLabel = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ActivityTypePage(bull: bull, user: widget.user),
      ),
    );
    if (activityLabel != null && mounted) {
      setState(_reload);
      widget.onDataChanged?.call();
      AppFeedback.showSuccess(
        context,
        'Berhasil menambah aktivitas $activityLabel.',
      );
    }
  }

  Future<void> _edit(BullModel bull, ActivityRecord record) async {
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
      setState(_reload);
      widget.onDataChanged?.call();
      AppFeedback.showSuccess(
        context,
        'Berhasil memperbarui aktivitas ${record.definition.label}.',
      );
    }
  }

  Future<void> _delete(ActivityRecord record, BullModel? bull) async {
    if (!widget.user.isPetugas) return;

    final bool confirmed = await showConfirmationDialog(
      context,
      title: 'Hapus aktivitas?',
      message: 'Aktivitas ${record.definition.label} untuk '
          '${bull?.nama ?? 'bull ini'} akan dihapus permanen. '
          'Tindakan ini tidak dapat dibatalkan.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      icon: Icons.delete_outline_rounded,
    );

    if (!confirmed || !mounted) return;

    try {
      await ActivityServiceRegistry.serviceFor(
        record.collectionName,
      ).deleteActivity(record.id);

      if (!mounted) return;
      setState(_reload);
      widget.onDataChanged?.call();
      AppFeedback.showSuccess(
        context,
        'Berhasil menghapus aktivitas ${record.definition.label}.',
      );
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(
        context,
        'Gagal menghapus aktivitas: $error',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Riwayat Aktivitas')),
      body: FutureBuilder<ActivityListData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final ActivityListData data = snapshot.data!;
          final Map<String, int> categoryCounts = <String, int>{};
          for (final ActivityRecord record in data.records) {
            categoryCounts.update(
              record.collectionName,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
          }

          final List<ActivityRecord> filteredRecords = data.records
              .where(
                (record) =>
                    _filter.isEmpty || record.collectionName == _filter,
              )
              .toList(growable: false);
          final String selectedLabel = _filter.isEmpty
              ? 'Semua Aktivitas'
              : ActivityCatalog.byCollection(_filter).label;

          return AppPageContainer(
            child: Column(
              children: <Widget>[
                _ActivityCategoryFilter(
                  selectedCollection: _filter,
                  totalCount: data.records.length,
                  categoryCounts: categoryCounts,
                  onSelected: (collectionName) {
                    setState(() => _filter = collectionName);
                  },
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filteredRecords.isEmpty
                      ? EmptyState(
                          icon: Icons.history_toggle_off,
                          title: 'Belum ada $selectedLabel',
                          message: _filter.isEmpty
                              ? widget.user.isPetugas
                                  ? 'Pilih bull dan catat aktivitas pemeliharaan.'
                                  : 'Belum ada aktivitas pemeliharaan yang dapat ditampilkan.'
                              : 'Belum ada aktivitas pada kategori yang dipilih.',
                          action: widget.user.isPetugas
                              ? FilledButton.icon(
                                  onPressed: _add,
                                  icon: const Icon(Icons.add_rounded),
                                  label: const Text('Tambah Aktivitas'),
                                )
                              : null,
                        )
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: _ActivityTimeline(
                            records: filteredRecords,
                            bulls: data.bulls,
                            canEdit: widget.user.isPetugas,
                            onEdit: _edit,
                            onDelete: _delete,
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: widget.user.isPetugas
          ? FloatingActionButton(
              onPressed: _add,
              tooltip: 'Tambah Aktivitas',
              child: const Icon(Icons.add_rounded, size: 30),
            )
          : null,
    );
  }
}

class _ActivityTimeline extends StatelessWidget {
  const _ActivityTimeline({
    required this.records,
    required this.bulls,
    required this.canEdit,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ActivityRecord> records;
  final Map<String, BullModel> bulls;
  final bool canEdit;
  final void Function(BullModel bull, ActivityRecord record) onEdit;
  final void Function(ActivityRecord record, BullModel? bull) onDelete;

  @override
  Widget build(BuildContext context) {
    final Map<DateTime, List<ActivityRecord>> groups =
        <DateTime, List<ActivityRecord>>{};
    for (final ActivityRecord record in records) {
      final DateTime key = DateTime(
        record.tanggal.year,
        record.tanggal.month,
        record.tanggal.day,
      );
      groups.putIfAbsent(key, () => <ActivityRecord>[]).add(record);
    }

    final List<DateTime> dates = groups.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
      itemCount: dates.length,
      itemBuilder: (context, groupIndex) {
        final DateTime date = dates[groupIndex];
        final List<ActivityRecord> dailyRecords = groups[date]!;
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  _dateHeading(date),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              ...dailyRecords.map((record) {
                final BullModel? bull = bulls[record.bull_id];
                return ActivityTile(
                  record: record,
                  bullName: bull?.nama ?? 'Bull tidak ditemukan',
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
                  trailing: canEdit
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            if (bull != null)
                              IconButton(
                                onPressed: () => onEdit(bull, record),
                                icon: const Icon(Icons.edit_outlined, size: 21),
                                tooltip: 'Edit aktivitas',
                                visualDensity: VisualDensity.compact,
                              ),
                            IconButton(
                              onPressed: () => onDelete(record, bull),
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                size: 21,
                              ),
                              tooltip: 'Hapus aktivitas',
                              color: Theme.of(context).colorScheme.error,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        )
                      : null,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _dateHeading(DateTime date) {
    final DateTime today = DateTime.now();
    final DateTime day = DateTime(date.year, date.month, date.day);
    final DateTime current = DateTime(today.year, today.month, today.day);
    if (day == current) return 'Hari Ini • ${AppDateUtils.formatDate(date)}';
    if (day == current.subtract(const Duration(days: 1))) {
      return 'Kemarin • ${AppDateUtils.formatDate(date)}';
    }
    return AppDateUtils.formatDate(date);
  }
}

class _ActivityCategoryFilter extends StatelessWidget {
  const _ActivityCategoryFilter({
    required this.selectedCollection,
    required this.totalCount,
    required this.categoryCounts,
    required this.onSelected,
  });

  final String selectedCollection;
  final int totalCount;
  final Map<String, int> categoryCounts;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 53,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('Semua ($totalCount)'),
              selected: selectedCollection.isEmpty,
              onSelected: (_) => onSelected(''),
            ),
          ),
          ...ActivityCatalog.all.map((definition) {
            final int count = categoryCounts[definition.collectionName] ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Icon(definition.icon, size: 17),
                label: Text('${definition.label} ($count)'),
                selected: selectedCollection == definition.collectionName,
                onSelected: (_) => onSelected(definition.collectionName),
              ),
            );
          }),
        ],
      ),
    );
  }
}
