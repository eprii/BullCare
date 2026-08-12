import '../models/activity_record.dart';
import '../models/bull_model.dart';
import '../models/reminder_item.dart';
import 'activity_service_registry.dart';
import 'bull_service.dart';
import 'reminder_service.dart';

class DashboardData {
  final List<BullModel> bulls;
  final List<ReminderItem> reminders;
  final List<ActivityRecord> recentActivities;

  const DashboardData({
    required this.bulls,
    required this.reminders,
    required this.recentActivities,
  });

  Map<String, String> get bullNames => <String, String>{
        for (final BullModel bull in bulls) bull.id: bull.nama,
      };

  Map<String, BullModel> get bullById => <String, BullModel>{
        for (final BullModel bull in bulls) bull.id: bull,
      };
}

class DashboardService {
  DashboardService({BullService? bullService, ReminderService? reminderService})
      : _bullService = bullService ?? BullService(),
        _reminderService = reminderService ?? ReminderService();

  final BullService _bullService;
  final ReminderService _reminderService;

  Future<DashboardData> load() async {
    final List<BullModel> bulls = await _bullService.getBulls();
    final List<ReminderItem> reminders = await _reminderService.getReminders(bulls: bulls);
    final List<ActivityRecord> recent = await ActivityServiceRegistry.getRecent(perCollection: 3);
    return DashboardData(
      bulls: bulls,
      reminders: reminders,
      recentActivities: recent.take(8).toList(),
    );
  }
}
