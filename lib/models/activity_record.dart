import '../utils/firestore_utils.dart';
import 'activity_definition.dart';

class ActivityRecord {
  final String id;
  final String collectionName;
  final String bull_id;
  final String petugas_uid;
  final DateTime tanggal;
  final DateTime created_at;
  final DateTime updated_at;
  final Map<String, dynamic> data;

  const ActivityRecord({
    required this.id,
    required this.collectionName,
    required this.bull_id,
    required this.petugas_uid,
    required this.tanggal,
    required this.created_at,
    required this.updated_at,
    required this.data,
  });

  ActivityDefinition get definition => ActivityCatalog.byCollection(collectionName);

  factory ActivityRecord.fromMap(
    String id,
    String collectionName,
    Map<String, dynamic> map,
  ) {
    return ActivityRecord(
      id: id,
      collectionName: collectionName,
      bull_id: map['bull_id']?.toString() ?? '',
      petugas_uid: map['petugas_uid']?.toString() ?? '',
      tanggal: dateTimeFromFirestore(map['tanggal']),
      created_at: dateTimeFromFirestore(map['created_at']),
      updated_at: dateTimeFromFirestore(map['updated_at']),
      data: Map<String, dynamic>.from(map),
    );
  }

  String get summary {
    final List<String> parts = <String>[];
    for (final ActivityFieldDefinition field in definition.fields) {
      if (field.key == 'keterangan') continue;
      final dynamic value = data[field.key];
      if (value == null || value.toString().trim().isEmpty) continue;
      if (field.type == ActivityFieldType.boolean) {
        if (value == true) parts.add(field.label);
      } else {
        parts.add('${field.label}: $value${field.suffix == null ? '' : ' ${field.suffix}'}');
      }
      if (parts.length == 2) break;
    }
    return parts.isEmpty ? 'Aktivitas tercatat' : parts.join(' • ');
  }
}
