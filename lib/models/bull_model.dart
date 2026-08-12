import '../utils/bull_status.dart';
import '../utils/firestore_utils.dart';

class BullModel {
  final String id;
  final String kode_bull;
  final String nama;
  final String bangsa;
  final String nomor_kandang;
  final String warna_straw;
  final String umur;
  final String foto_base64;
  final String foto_background_base64;
  final String status;
  final int sanitasi_reminder_hour;
  final int sanitasi_reminder_minute;
  final DateTime created_at;
  final DateTime updated_at;

  const BullModel({
    required this.id,
    required this.kode_bull,
    required this.nama,
    required this.bangsa,
    required this.nomor_kandang,
    required this.warna_straw,
    this.umur = '',
    this.foto_base64 = '',
    this.foto_background_base64 = '',
    required this.status,
    this.sanitasi_reminder_hour = 8,
    this.sanitasi_reminder_minute = 0,
    required this.created_at,
    required this.updated_at,
  });

  factory BullModel.fromMap(String id, Map<String, dynamic> map) {
    return BullModel(
      id: id,
      kode_bull: map['kode_bull']?.toString() ?? '',
      nama: map['nama']?.toString() ?? '',
      bangsa: map['bangsa']?.toString() ?? '',
      nomor_kandang: map['nomor_kandang']?.toString() ?? '',
      warna_straw: map['warna_straw']?.toString() ?? '',
      umur: map['umur']?.toString() ?? '',
      foto_base64: map['foto_base64']?.toString() ?? '',
      foto_background_base64: map['foto_background_base64']?.toString() ?? '',
      status: BullStatus.normalize(map['status']?.toString()),
      sanitasi_reminder_hour: _parseReminderHour(map['sanitasi_reminder_hour']),
      sanitasi_reminder_minute: _parseReminderMinute(map['sanitasi_reminder_minute']),
      created_at: dateTimeFromFirestore(map['created_at']),
      updated_at: dateTimeFromFirestore(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'kode_bull': kode_bull,
      'nama': nama,
      'bangsa': bangsa,
      'nomor_kandang': nomor_kandang,
      'warna_straw': warna_straw,
      'umur': umur,
      'foto_base64': foto_base64,
      'foto_background_base64': foto_background_base64,
      'status': status,
      'sanitasi_reminder_hour': sanitasi_reminder_hour,
      'sanitasi_reminder_minute': sanitasi_reminder_minute,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }

  BullModel copyWith({
    String? id,
    String? kode_bull,
    String? nama,
    String? bangsa,
    String? nomor_kandang,
    String? warna_straw,
    String? umur,
    String? foto_base64,
    String? foto_background_base64,
    String? status,
    int? sanitasi_reminder_hour,
    int? sanitasi_reminder_minute,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return BullModel(
      id: id ?? this.id,
      kode_bull: kode_bull ?? this.kode_bull,
      nama: nama ?? this.nama,
      bangsa: bangsa ?? this.bangsa,
      nomor_kandang: nomor_kandang ?? this.nomor_kandang,
      warna_straw: warna_straw ?? this.warna_straw,
      umur: umur ?? this.umur,
      foto_base64: foto_base64 ?? this.foto_base64,
      foto_background_base64:
          foto_background_base64 ?? this.foto_background_base64,
      status: status ?? this.status,
      sanitasi_reminder_hour:
          sanitasi_reminder_hour ?? this.sanitasi_reminder_hour,
      sanitasi_reminder_minute:
          sanitasi_reminder_minute ?? this.sanitasi_reminder_minute,
      created_at: created_at ?? this.created_at,
      updated_at: updated_at ?? this.updated_at,
    );
  }
}

int _parseReminderHour(dynamic value) {
  final int parsed = int.tryParse(value?.toString() ?? '') ?? 8;
  return parsed >= 0 && parsed <= 23 ? parsed : 8;
}

int _parseReminderMinute(dynamic value) {
  final int parsed = int.tryParse(value?.toString() ?? '') ?? 0;
  return parsed >= 0 && parsed <= 59 ? parsed : 0;
}
