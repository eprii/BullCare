import 'package:cloud_firestore/cloud_firestore.dart';

DateTime dateTimeFromFirestore(dynamic value, {DateTime? fallback}) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
  return fallback ?? DateTime.now();
}

double doubleFromFirestore(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
