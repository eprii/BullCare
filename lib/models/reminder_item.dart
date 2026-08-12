import 'activity_definition.dart';
import 'bull_model.dart';

enum ReminderRecurrence { none, daily, monthly }

class ReminderItem {
  final BullModel bull;
  final ActivityDefinition definition;
  final String message;
  final DateTime dueDate;
  final DateTime? recurrenceAnchor;
  final ReminderRecurrence recurrence;
  final Map<String, dynamic> initialValues;

  const ReminderItem({
    required this.bull,
    required this.definition,
    required this.message,
    required this.dueDate,
    this.recurrenceAnchor,
    this.recurrence = ReminderRecurrence.none,
    this.initialValues = const <String, dynamic>{},
  });
}
