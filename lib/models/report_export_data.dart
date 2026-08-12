import 'activity_record.dart';
import 'bull_model.dart';

class ReportExportData {
  const ReportExportData({
    required this.records,
    required this.bulls,
    required this.periodStart,
    required this.periodEnd,
    required this.sourceLabel,
    this.sanitasiField,
  });

  final List<ActivityRecord> records;
  final Map<String, BullModel> bulls;
  final DateTime periodStart;
  final DateTime periodEnd;
  final String sourceLabel;
  final String? sanitasiField;
}
