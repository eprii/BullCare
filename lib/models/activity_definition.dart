import 'package:flutter/material.dart';

enum ActivityFieldType { text, multiline, decimal, boolean }

class ActivityFieldDefinition {
  final String key;
  final String label;
  final ActivityFieldType type;
  final bool required;
  final String? suffix;

  const ActivityFieldDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.required = true,
    this.suffix,
  });
}

class ActivityDefinition {
  final String collectionName;
  final String label;
  final IconData icon;
  final List<ActivityFieldDefinition> fields;

  const ActivityDefinition({
    required this.collectionName,
    required this.label,
    required this.icon,
    required this.fields,
  });
}

class ActivityCatalog {
  ActivityCatalog._();

  static const List<ActivityDefinition> all = <ActivityDefinition>[
    ActivityDefinition(
      collectionName: 'pemberian_pakan',
      label: 'Pemberian Pakan',
      icon: Icons.grass_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'hijauan', label: 'Hijauan', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'konsentrat', label: 'Konsentrat', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'kecambah', label: 'Kecambah', type: ActivityFieldType.text, required: false),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
    ActivityDefinition(
      collectionName: 'sanitasi',
      label: 'Sanitasi',
      icon: Icons.cleaning_services_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'sanitasi_kandang', label: 'Sanitasi kandang', type: ActivityFieldType.boolean),
        ActivityFieldDefinition(key: 'sanitasi_pejantan', label: 'Sanitasi pejantan', type: ActivityFieldType.boolean),
        ActivityFieldDefinition(key: 'sanitasi_tempat_pakan', label: 'Sanitasi tempat makan', type: ActivityFieldType.boolean),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
    ActivityDefinition(
      collectionName: 'pemeriksaan_kesehatan',
      label: 'Pemeriksaan Kesehatan',
      icon: Icons.health_and_safety_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'kondisi', label: 'Kondisi', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'diagnosa', label: 'Diagnosis', type: ActivityFieldType.text, required: false),
        ActivityFieldDefinition(key: 'tindakan', label: 'Tindakan', type: ActivityFieldType.multiline, required: false),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
    ActivityDefinition(
      collectionName: 'penimbangan',
      label: 'Penimbangan',
      icon: Icons.monitor_weight_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'berat_badan', label: 'Berat badan', type: ActivityFieldType.decimal, suffix: 'kg'),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
    ActivityDefinition(
      collectionName: 'pengukuran',
      label: 'Pengukuran',
      icon: Icons.straighten_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'tinggi_gumba', label: 'Tinggi gumba', type: ActivityFieldType.decimal, suffix: 'cm'),
        ActivityFieldDefinition(key: 'panjang_tubuh', label: 'Panjang tubuh', type: ActivityFieldType.decimal, suffix: 'cm'),
        ActivityFieldDefinition(key: 'lingkar_badan', label: 'Lingkar badan', type: ActivityFieldType.decimal, suffix: 'cm'),
        ActivityFieldDefinition(key: 'lingkar_skrotum', label: 'Lingkar skrotum', type: ActivityFieldType.decimal, suffix: 'cm'),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
    ActivityDefinition(
      collectionName: 'pengobatan',
      label: 'Pengobatan',
      icon: Icons.medication_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'gejala_klinis', label: 'Gejala klinis', type: ActivityFieldType.multiline),
        ActivityFieldDefinition(key: 'diagnosa', label: 'Diagnosis', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'terapi', label: 'Terapi', type: ActivityFieldType.multiline),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
    ActivityDefinition(
      collectionName: 'pemberian_obat_cacing',
      label: 'Pemberian Obat Cacing',
      icon: Icons.vaccines_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'nama_obat', label: 'Nama obat', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'dosis', label: 'Dosis', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
    ActivityDefinition(
      collectionName: 'pemotongan_bulu',
      label: 'Pemotongan Bulu',
      icon: Icons.content_cut_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'dipotong', label: 'Pemotongan telah dilakukan', type: ActivityFieldType.boolean),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
    ActivityDefinition(
      collectionName: 'pemotongan_kuku',
      label: 'Pemotongan Kuku',
      icon: Icons.back_hand_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'dipotong', label: 'Pemotongan telah dilakukan', type: ActivityFieldType.boolean),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
    ActivityDefinition(
      collectionName: 'penampungan_semen',
      label: 'Penampungan Semen',
      icon: Icons.water_drop_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'av', label: 'AV', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'vaselin', label: 'Vaselin', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'suhu_av', label: 'Suhu', type: ActivityFieldType.decimal, suffix: '°C'),
        ActivityFieldDefinition(key: 'volume_semen', label: 'Volume semen', type: ActivityFieldType.decimal, suffix: 'ml'),
      ],
    ),
  ];

  static ActivityDefinition byCollection(String collectionName) {
    return all.firstWhere((item) => item.collectionName == collectionName);
  }
}
