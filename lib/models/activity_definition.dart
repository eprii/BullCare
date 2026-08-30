import 'package:flutter/material.dart';

enum ActivityFieldType { text, multiline, decimal, boolean, date }

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
      collectionName: 'pencegahan_ektoparasit',
      label: 'Pencegahan Ektoparasit',
      icon: Icons.bug_report_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'bahan', label: 'Bahan', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'alat', label: 'Alat', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'tindakan', label: 'Tindakan', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
    ActivityDefinition(
      collectionName: 'bedah_bangkai',
      label: 'Bedah Bangkai',
      icon: Icons.biotech_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'tanggal_mati', label: 'Tanggal mati', type: ActivityFieldType.date),
        ActivityFieldDefinition(key: 'peralatan', label: 'Peralatan', type: ActivityFieldType.multiline),
        ActivityFieldDefinition(key: 'pemeriksaan_organ', label: 'Sampel/Organ dan Hasil Pemeriksaan (Organ | Hasil)', type: ActivityFieldType.multiline),
        ActivityFieldDefinition(key: 'tanggal_pengiriman_laboratorium', label: 'Tanggal pengiriman ke laboratorium', type: ActivityFieldType.date, required: false),
        ActivityFieldDefinition(key: 'tanggal_jawaban', label: 'Tanggal jawaban', type: ActivityFieldType.date, required: false),
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
        ActivityFieldDefinition(key: 'kolektor', label: 'Kolektor', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'volume', label: 'Volume', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'p_tp', label: 'P/TP', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'jumlah_straw_yang_dihasilkan', label: 'Jumlah straw yang dihasilkan', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
    ActivityDefinition(
      collectionName: 'produksi_distribusi_semen_beku',
      label: 'Produksi & Distribusi Semen Beku',
      icon: Icons.inventory_2_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'kategori', label: 'Kategori', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'bangsa', label: 'Bangsa', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'jumlah_pejantan', label: 'Jumlah Pejantan', type: ActivityFieldType.text, suffix: 'ekor'),
        ActivityFieldDefinition(key: 'tahun', label: 'Tahun', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'bulan', label: 'Bulan', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'stock_tahun', label: 'Stock Tahun', type: ActivityFieldType.text, required: false),
        ActivityFieldDefinition(key: 'produksi_minggu_i', label: 'Produksi Minggu I', type: ActivityFieldType.text, required: false),
        ActivityFieldDefinition(key: 'produksi_minggu_ii', label: 'Produksi Minggu II', type: ActivityFieldType.text, required: false),
        ActivityFieldDefinition(key: 'produksi_minggu_iii', label: 'Produksi Minggu III', type: ActivityFieldType.text, required: false),
        ActivityFieldDefinition(key: 'produksi_minggu_iv', label: 'Produksi Minggu IV', type: ActivityFieldType.text, required: false),
        ActivityFieldDefinition(key: 'produksi_minggu_v', label: 'Produksi Minggu V', type: ActivityFieldType.text, required: false),
        ActivityFieldDefinition(key: 'jumlah_produksi', label: 'Jumlah Produksi', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'afkir', label: 'Afkir', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'distribusi_komandan', label: 'Distribusi Komandan', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'distribusi_non_sikomandan', label: 'Distribusi Non Sikomandan', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'jumlah_distribusi', label: 'Jumlah Distribusi', type: ActivityFieldType.text),
        ActivityFieldDefinition(key: 'stock_akhir', label: 'Total Stock', type: ActivityFieldType.text),
      ],
    ),
    ActivityDefinition(
      collectionName: 'bio_security',
      label: 'Bio Security',
      icon: Icons.health_and_safety_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(
          key: 'bahan',
          label: 'Bahan',
          type: ActivityFieldType.text,
        ),
        ActivityFieldDefinition(
          key: 'alat',
          label: 'Alat',
          type: ActivityFieldType.text,
        ),
        ActivityFieldDefinition(
          key: 'keterangan',
          label: 'Keterangan',
          type: ActivityFieldType.multiline,
          required: false,
        ),
      ],
    ),
    ActivityDefinition(
      collectionName: 'pengambilan_sample',
      label: 'Pengambilan Sample',
      icon: Icons.science_outlined,
      fields: <ActivityFieldDefinition>[
        ActivityFieldDefinition(key: 'darah', label: 'Darah', type: ActivityFieldType.boolean),
        ActivityFieldDefinition(key: 'serum', label: 'Serum', type: ActivityFieldType.boolean),
        ActivityFieldDefinition(key: 'ulas_darah', label: 'Ulas Darah', type: ActivityFieldType.boolean),
        ActivityFieldDefinition(key: 'swab', label: 'Swab', type: ActivityFieldType.boolean),
        ActivityFieldDefinition(key: 'feses', label: 'Feses', type: ActivityFieldType.boolean),
        ActivityFieldDefinition(key: 'keterangan', label: 'Keterangan', type: ActivityFieldType.multiline, required: false),
      ],
    ),
  ];

  static ActivityDefinition byCollection(String collectionName) {
    return all.firstWhere((item) => item.collectionName == collectionName);
  }
}
