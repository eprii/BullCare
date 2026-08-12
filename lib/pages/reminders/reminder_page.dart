import 'package:flutter/material.dart';

import '../../models/reminder_item.dart';
import '../../models/user_model.dart';
import '../../services/bull_service.dart';
import '../../services/reminder_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_date_utils.dart';
import '../../widgets/app_page_container.dart';
import '../../widgets/countdown_timer.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_view.dart';

class ReminderPage extends StatefulWidget {
  const ReminderPage({
    super.key,
    required this.user,
    this.onDataChanged,
    this.revision = 0,
  });

  final UserModel user;
  final VoidCallback? onDataChanged;
  final int revision;

  @override
  State<ReminderPage> createState() => _ReminderPageState();
}

class _ReminderPageState extends State<ReminderPage> {
  final ReminderService _service = ReminderService();
  final BullService _bullService = BullService();
  final Set<String> _savingReminderTimes = <String>{};
  late Future<List<ReminderItem>> _future;
  String _selectedBullId = _allBullsFilter;
  String _selectedSanitasiFilter = 'sanitasi_all';

  static const String _allBullsFilter = '__all_bulls__';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void didUpdateWidget(covariant ReminderPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.revision != widget.revision) {
      _future = _service.getReminders();
    }
  }

  void _reload() {
    _future = _service.getReminders();
  }

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  Future<void> _editSanitasiReminderTime(ReminderItem reminder) async {
    if (!widget.user.isPetugas ||
        _savingReminderTimes.contains(reminder.bull.id)) {
      return;
    }

    final DateTime anchor = reminder.recurrenceAnchor ?? reminder.dueDate;
    final TimeOfDay? selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: anchor.hour, minute: anchor.minute),
      helpText: 'Pilih jam pelaksanaan sanitasi',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );

    if (!mounted || selected == null) return;
    if (selected.hour == anchor.hour && selected.minute == anchor.minute) {
      return;
    }

    final String formattedTime =
        '${selected.hour.toString().padLeft(2, '0')}.'
        '${selected.minute.toString().padLeft(2, '0')}';
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Ubah jam reminder?'),
          content: Text(
            'Jam pelaksanaan sanitasi ${reminder.bull.nama} '
            'akan diubah menjadi $formattedTime. Jam ini berlaku untuk seluruh reminder sanitasi pada bull ini.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    setState(() => _savingReminderTimes.add(reminder.bull.id));
    try {
      await _bullService.updateSanitasiReminderTime(
        bullId: reminder.bull.id,
        hour: selected.hour,
        minute: selected.minute,
      );
      if (!mounted) return;
      setState(() {
        _savingReminderTimes.remove(reminder.bull.id);
        _reload();
      });
      widget.onDataChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Jam reminder sanitasi berhasil diubah menjadi '
            '$formattedTime.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingReminderTimes.remove(reminder.bull.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah jam reminder: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Jadwal Pemeliharaan')),
      body: FutureBuilder<List<ReminderItem>>(
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

          final List<ReminderItem> reminders =
              snapshot.data ?? <ReminderItem>[];
          final Map<String, String> bullNames = <String, String>{
            for (final ReminderItem reminder in reminders)
              reminder.bull.id: reminder.bull.nama,
          };
          final List<MapEntry<String, String>> bullOptions =
              bullNames.entries.toList()
                ..sort((a, b) => a.value.toLowerCase().compareTo(
                      b.value.toLowerCase(),
                    ));

          final bool selectedBullStillExists =
              _selectedBullId == _allBullsFilter ||
                  bullNames.containsKey(_selectedBullId);
          final String effectiveBullId = selectedBullStillExists
              ? _selectedBullId
              : _allBullsFilter;

          final List<ReminderItem> filteredReminders = reminders.where((item) {
            final bool matchesBull = effectiveBullId == _allBullsFilter ||
                item.bull.id == effectiveBullId;
            if (!matchesBull) return false;

            switch (_selectedSanitasiFilter) {
              case 'sanitasi_all':
                return item.definition.collectionName == 'sanitasi';
              case 'sanitasi_kandang':
              case 'sanitasi_tempat_pakan':
              case 'sanitasi_pejantan':
                return item.definition.collectionName == 'sanitasi' &&
                    item.initialValues[_selectedSanitasiFilter] == true;
              default:
                return true;
            }
          }).toList();

          return AppPageContainer(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
                children: <Widget>[
                  _ReminderFilters(
                    bullOptions: bullOptions,
                    selectedBullId: effectiveBullId,
                    selectedSanitasiFilter: _selectedSanitasiFilter,
                    onBullChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedBullId = value);
                    },
                    onSanitasiChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedSanitasiFilter = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  if (reminders.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text(
                        'Menampilkan ${filteredReminders.length} dari ${reminders.length} reminder',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (reminders.isEmpty)
                    const Card(
                      child: EmptyState(
                        icon: Icons.task_alt,
                        title: 'Tidak ada reminder aktif',
                        message: 'Semua aktivitas terjadwal sudah tercatat.',
                      ),
                    )
                  else if (filteredReminders.isEmpty)
                    const Card(
                      child: EmptyState(
                        icon: Icons.filter_alt_off_outlined,
                        title: 'Reminder tidak ditemukan',
                        message: 'Tidak ada reminder yang sesuai dengan filter.',
                      ),
                    )
                  else
                    ...filteredReminders.map((reminder) {
                      final bool isSanitasiBerulang =
                          reminder.definition.collectionName == 'sanitasi' &&
                              reminder.recurrence != ReminderRecurrence.none;
                      return _ReminderCard(
                        reminder: reminder,
                        showCountdown: isSanitasiBerulang,
                        canEditTime:
                            isSanitasiBerulang && widget.user.isPetugas,
                        isSavingTime:
                            _savingReminderTimes.contains(reminder.bull.id),
                        onEditTime: isSanitasiBerulang
                            ? () => _editSanitasiReminderTime(reminder)
                            : null,
                      );
                    }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReminderFilters extends StatelessWidget {
  const _ReminderFilters({
    required this.bullOptions,
    required this.selectedBullId,
    required this.selectedSanitasiFilter,
    required this.onBullChanged,
    required this.onSanitasiChanged,
  });

  final List<MapEntry<String, String>> bullOptions;
  final String selectedBullId;
  final String selectedSanitasiFilter;
  final ValueChanged<String?> onBullChanged;
  final ValueChanged<String?> onSanitasiChanged;

  @override
  Widget build(BuildContext context) {
    final Widget bullFilter = _FilterDropdown(
      icon: Icons.pets_outlined,
      label: 'Nama Bull',
      value: selectedBullId,
      items: <DropdownMenuItem<String>>[
        const DropdownMenuItem<String>(
          value: _ReminderPageState._allBullsFilter,
          child: Text('Semua Bull'),
        ),
        ...bullOptions.map(
          (entry) => DropdownMenuItem<String>(
            value: entry.key,
            child: Text(
              entry.value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: onBullChanged,
    );

    final Widget sanitasiFilter = _FilterDropdown(
      icon: Icons.cleaning_services_outlined,
      label: 'Jenis Sanitasi',
      value: selectedSanitasiFilter,
      items: const <DropdownMenuItem<String>>[
        DropdownMenuItem<String>(
          value: 'sanitasi_all',
          child: Text('Semua Sanitasi'),
        ),
        DropdownMenuItem<String>(
          value: 'sanitasi_kandang',
          child: Text('Sanitasi Kandang'),
        ),
        DropdownMenuItem<String>(
          value: 'sanitasi_tempat_pakan',
          child: Text('Sanitasi Tempat Makan'),
        ),
        DropdownMenuItem<String>(
          value: 'sanitasi_pejantan',
          child: Text('Sanitasi Pejantan'),
        ),
      ],
      onChanged: onSanitasiChanged,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool stackFilters = constraints.maxWidth < 520;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.divider),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: stackFilters
              ? Column(
                  children: <Widget>[
                    bullFilter,
                    const SizedBox(height: 10),
                    sanitasiFilter,
                  ],
                )
              : Row(
                  children: <Widget>[
                    Expanded(child: bullFilter),
                    const SizedBox(width: 10),
                    Expanded(child: sanitasiFilter),
                  ],
                ),
        );
      },
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 7, 10, 7),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 21, color: AppTheme.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    isDense: true,
                    borderRadius: BorderRadius.circular(14),
                    dropdownColor: Colors.white,
                    menuMaxHeight: 320,
                    focusColor: AppTheme.primarySoft,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppTheme.primary,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                    items: items,
                    onChanged: onChanged,
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

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.reminder,
    required this.showCountdown,
    required this.canEditTime,
    required this.isSavingTime,
    this.onEditTime,
  });

  final ReminderItem reminder;
  final bool showCountdown;
  final bool canEditTime;
  final bool isSavingTime;
  final VoidCallback? onEditTime;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0B000000),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  reminder.definition.icon,
                  color: AppTheme.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      reminder.definition.label,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      reminder.bull.nama,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      reminder.message,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (showCountdown)
            CountdownTimer(
              targetDate: reminder.dueDate,
              recurrenceAnchor: reminder.recurrenceAnchor,
              recurrence: reminder.recurrence,
              title: reminder.initialValues['reminder_label']?.toString() ??
                  reminder.definition.label,
              canEditTime: canEditTime,
              isSavingTime: isSavingTime,
              onEditTime: onEditTime,
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.calendar_month_outlined,
                    size: 19,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Jatuh tempo ${AppDateUtils.formatDate(reminder.dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
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
