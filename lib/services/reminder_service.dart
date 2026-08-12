import '../models/activity_definition.dart';
import '../models/activity_record.dart';
import '../models/bull_model.dart';
import '../models/reminder_item.dart';
import '../utils/app_date_utils.dart';
import 'activity_service_registry.dart';
import 'bull_service.dart';

class ReminderService {
  ReminderService({BullService? bullService})
      : _bullService = bullService ?? BullService();

  final BullService _bullService;

  Future<List<ReminderItem>> getReminders({List<BullModel>? bulls}) async {
    final DateTime now = DateTime.now();
    final DateTime today = AppDateUtils.startOfDay(now);
    final List<BullModel> reminderBulls =
        List<BullModel>.from(bulls ?? await _bullService.getBulls());

    final Set<String> pakanDone = await ActivityServiceRegistry
        .serviceFor('pemberian_pakan')
        .getBullIdsRecordedOn(today);

    final List<ActivityRecord> sanitasiRecords = await ActivityServiceRegistry
        .serviceFor('sanitasi')
        .getAll();
    final Map<String, ActivityRecord> latestSanitasiKandang =
        _latestSanitasiByBull(
      sanitasiRecords,
      fieldKey: 'sanitasi_kandang',
    );
    final Map<String, ActivityRecord> latestSanitasiTempatPakan =
        _latestSanitasiByBull(
      sanitasiRecords,
      fieldKey: 'sanitasi_tempat_pakan',
    );
    final Map<String, ActivityRecord> latestSanitasiPejantan =
        _latestSanitasiByBull(
      sanitasiRecords,
      fieldKey: 'sanitasi_pejantan',
    );

    Set<String> semenDone = <String>{};
    final bool semenDay = today.weekday == DateTime.monday ||
        today.weekday == DateTime.thursday;
    if (semenDay) {
      semenDone = await ActivityServiceRegistry
          .serviceFor('penampungan_semen')
          .getBullIdsRecordedOn(today);
    }

    final List<ReminderItem> reminders = <ReminderItem>[];
    for (final BullModel bull in reminderBulls) {
      if (!pakanDone.contains(bull.id)) {
        reminders.add(
          ReminderItem(
            bull: bull,
            definition: ActivityCatalog.byCollection('pemberian_pakan'),
            message: 'Pemberian pakan hari ini belum dicatat.',
            dueDate: today,
          ),
        );
      }

      final ReminderItem? sanitasiKandangReminder = _buildDailySanitasiReminder(
        bull: bull,
        latest: latestSanitasiKandang[bull.id],
        now: now,
        fieldKey: 'sanitasi_kandang',
        activityLabel: 'Sanitasi kandang',
      );
      if (sanitasiKandangReminder != null) {
        reminders.add(sanitasiKandangReminder);
      }

      final ReminderItem? sanitasiTempatMakanReminder =
          _buildDailySanitasiReminder(
        bull: bull,
        latest: latestSanitasiTempatPakan[bull.id],
        now: now,
        fieldKey: 'sanitasi_tempat_pakan',
        activityLabel: 'Sanitasi tempat makan',
      );
      if (sanitasiTempatMakanReminder != null) {
        reminders.add(sanitasiTempatMakanReminder);
      }

      final ReminderItem? sanitasiPejantanReminder =
          _buildMonthlySanitasiReminder(
        bull: bull,
        latest: latestSanitasiPejantan[bull.id],
        now: now,
        fieldKey: 'sanitasi_pejantan',
        activityLabel: 'Sanitasi pejantan',
      );
      if (sanitasiPejantanReminder != null) {
        reminders.add(sanitasiPejantanReminder);
      }

      if (semenDay && !semenDone.contains(bull.id)) {
        reminders.add(
          ReminderItem(
            bull: bull,
            definition: ActivityCatalog.byCollection('penampungan_semen'),
            message: 'Jadwal rutin penampungan semen Senin/Kamis.',
            dueDate: today,
          ),
        );
      }
    }

    reminders.sort((a, b) {
      final int dueComparison = a.dueDate.compareTo(b.dueDate);
      if (dueComparison != 0) return dueComparison;
      final int bullComparison = a.bull.nama.compareTo(b.bull.nama);
      if (bullComparison != 0) return bullComparison;
      final int definitionComparison =
          a.definition.label.compareTo(b.definition.label);
      if (definitionComparison != 0) return definitionComparison;
      return _sanitasiLabel(a).compareTo(_sanitasiLabel(b));
    });
    return reminders;
  }

  Map<String, ActivityRecord> _latestSanitasiByBull(
    List<ActivityRecord> records, {
    required String fieldKey,
  }) {
    final Map<String, ActivityRecord> latest = <String, ActivityRecord>{};
    for (final ActivityRecord record in records) {
      if (record.data[fieldKey] != true ||
          record.bull_id.isEmpty ||
          latest.containsKey(record.bull_id)) {
        continue;
      }
      latest[record.bull_id] = record;
    }
    return latest;
  }

  ReminderItem? _buildDailySanitasiReminder({
    required BullModel bull,
    required ActivityRecord? latest,
    required DateTime now,
    required String fieldKey,
    required String activityLabel,
  }) {
    if (latest == null) return null;

    // Jam pelaksanaan menggunakan pengaturan reminder bull. Default 08.00.
    // Tanggal anchor tetap tanggal aktivitas terakhir, tetapi siklus pertama
    // selalu jatuh pada hari berikutnya sehingga countdown maksimal 1 hari.
    final DateTime recurrenceAnchor = DateTime(
      latest.tanggal.year,
      latest.tanggal.month,
      latest.tanggal.day,
      bull.sanitasi_reminder_hour,
      bull.sanitasi_reminder_minute,
    );
    final DateTime dueDate = AppDateUtils.nextDailyOccurrence(
      recurrenceAnchor,
      now,
    );

    return ReminderItem(
      bull: bull,
      definition: ActivityCatalog.byCollection('sanitasi'),
      message:
          '$activityLabel dijadwalkan setiap hari pukul ${_formatTime(recurrenceAnchor)}.',
      dueDate: dueDate,
      recurrenceAnchor: recurrenceAnchor,
      recurrence: ReminderRecurrence.daily,
      initialValues: <String, dynamic>{
        fieldKey: true,
        'reminder_label': activityLabel,
      },
    );
  }

  ReminderItem? _buildMonthlySanitasiReminder({
    required BullModel bull,
    required ActivityRecord? latest,
    required DateTime now,
    required String fieldKey,
    required String activityLabel,
  }) {
    if (latest == null) return null;

    // Sanitasi pejantan tetap menggunakan siklus bulanan. Tanggal mengikuti
    // tanggal aktivitas sanitasi pejantan terakhir, sedangkan jam mengikuti
    // pengaturan reminder bull (default 08.00).
    final DateTime recurrenceAnchor = DateTime(
      latest.tanggal.year,
      latest.tanggal.month,
      latest.tanggal.day,
      bull.sanitasi_reminder_hour,
      bull.sanitasi_reminder_minute,
    );
    final DateTime dueDate = AppDateUtils.nextMonthlyOccurrence(
      recurrenceAnchor,
      now,
    );

    return ReminderItem(
      bull: bull,
      definition: ActivityCatalog.byCollection('sanitasi'),
      message:
          '$activityLabel dijadwalkan setiap 1 bulan pukul ${_formatTime(recurrenceAnchor)}.',
      dueDate: dueDate,
      recurrenceAnchor: recurrenceAnchor,
      recurrence: ReminderRecurrence.monthly,
      initialValues: <String, dynamic>{
        fieldKey: true,
        'reminder_label': activityLabel,
      },
    );
  }

  String _sanitasiLabel(ReminderItem reminder) =>
      reminder.initialValues['reminder_label']?.toString() ?? '';

  String _formatTime(DateTime value) {
    final String hour = value.hour.toString().padLeft(2, '0');
    final String minute = value.minute.toString().padLeft(2, '0');
    return '$hour.$minute';
  }
}
