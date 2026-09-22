# BullCare BIB

**BullCare — Manajemen Pemeliharaan Bull** adalah aplikasi Flutter untuk Android dan Web yang membantu digitalisasi manajemen pemeliharaan bull di Balai Inseminasi Buatan (BIB). Data menggunakan Firebase Authentication dan Cloud Firestore. Project **tidak menggunakan Firebase Storage**; foto bull disimpan sebagai Base64 pada data bull.

Versi source pada project ini: **1.6.0+7**.

## Konsep utama

BullCare berfokus pada:

**Profil Bull + Aktivitas + Riwayat + Reminder + Laporan**

Data aktivitas disimpan sebagai histori. Nilai terbaru dapat ditampilkan sebagai ringkasan pada profil bull, tetapi record lama tetap dipertahankan.

## Role

### Pengunjung

Pengunjung dapat melakukan registrasi mandiri dan mendapatkan akses view-only. Pengunjung tidak dapat melakukan perubahan data maupun export laporan.

### Petugas

Petugas dapat melihat data bull, mencatat dan mengelola aktivitas, serta melakukan export laporan. Petugas tidak memiliki akses CRUD Bull.

### Supervisor

Supervisor memiliki akses penuh untuk pengelolaan data Bull, aktivitas, dan laporan.

Role yang digunakan:

- `pengunjung`
- `petugas`
- `supervisor`

Registrasi mandiri membuat profil dengan role `pengunjung`. Role `petugas` dan `supervisor` ditetapkan sesuai kebutuhan administrasi.

## Struktur utama

```text
lib/
├── app.dart
├── firebase_options.dart
├── main.dart
├── constants/
├── models/
├── pages/
│   ├── activities/
│   ├── auth/
│   ├── bulls/
│   ├── dashboard/
│   ├── home/
│   ├── reminders/
│   ├── reports/
│   └── splash/
├── services/
├── theme/
├── utils/
└── widgets/
```

Arsitektur aktivitas memakai:

- `ActivityDefinition`
- `ActivityRecord`
- `ActivityServiceRegistry`
- `BaseActivityService`
- service masing-masing root collection aktivitas

## Collection Firestore

Semua collection berada pada root Cloud Firestore.

Collection utama saat ini:

- `users`
- `bulls`
- `pemberian_pakan`
- `sanitasi`
- `pemeriksaan_kesehatan`
- `penimbangan`
- `pengukuran`
- `pengobatan`
- `pemberian_obat_cacing`
- `pencegahan_ektoparasit`
- `bedah_bangkai`
- `pemotongan_bulu`
- `pemotongan_kuku`
- `penampungan_semen`
- `produksi_distribusi_semen_beku`
- `bio_security`
- `pengambilan_sample`

Detail field aktual tersedia pada `docs/FIRESTORE_SCHEMA.md`.

## Aktivitas saat ini

`ActivityCatalog`, `ActivityServiceRegistry`, constants, sumber Laporan, dan Firestore Rules telah disinkronkan untuk 15 jenis aktivitas:

1. Pemberian Pakan
2. Sanitasi
3. Pemeriksaan Kesehatan
4. Penimbangan
5. Pengukuran
6. Pengobatan
7. Pemberian Obat Cacing
8. Pencegahan Ektoparasit
9. Bedah Bangkai
10. Pemotongan Bulu
11. Pemotongan Kuku
12. Penampungan Semen
13. Produksi & Distribusi Semen Beku
14. Bio Security
15. Pengambilan Sample

> Catatan riwayat: pada pembaruan lama Pengambilan Sampel pernah dihapus. Pada source terkini fitur tersebut telah ditambahkan kembali dan terintegrasi ke registry, Firestore Rules, histori, serta laporan.

## Penampungan Semen

Form/input aktif menggunakan field terbaru:

- `kolektor`
- `volume`
- `p_tp`
- `jumlah_straw_yang_dihasilkan`
- `keterangan`

Laporan tetap menyediakan kompatibilitas terhadap record historis yang masih memakai schema lama seperti AV, Vaselin, Suhu AV, dan Volume Semen.

## Reminder

Reminder yang digunakan source saat ini:

- Pemberian pakan: harian bila belum dicatat pada hari berjalan.
- Sanitasi kandang: siklus harian berdasarkan aktivitas terakhir.
- Sanitasi tempat makan: siklus harian berdasarkan aktivitas terakhir.
- Sanitasi pejantan: siklus kalender bulanan berdasarkan aktivitas terakhir.
- Penampungan semen: Senin dan Kamis bila belum dicatat pada hari tersebut.

Jam sanitasi menggunakan pengaturan per bull melalui:

- `sanitasi_reminder_hour`
- `sanitasi_reminder_minute`

Default model adalah pukul 08:00.

## Laporan dan export

Halaman Laporan dapat memilih sumber aktivitas, periode, nama file, format, dan orientasi sesuai implementasi yang tersedia. Khusus sumber **Produksi & Distribusi Semen Beku**, pemilihan laporan menggunakan **bulan dan tahun** (bukan rentang tanggal) dan menyediakan export tambahan **Excel (.xlsx)** yang mengikuti template kantor serta tetap dapat diedit.

Export mendukung:

- PDF
- Word/DOCX

Template SOP resmi yang tersedia tetap digunakan untuk aktivitas yang mempunyai template pada `assets/templates/`.

Pengembangan lanjutan juga mencakup:

- laporan Pengambilan Sample,
- laporan Pencegahan Ektoparasit berdasarkan referensi formulir SOP-6.3 k,
- laporan Bedah Bangkai,
- laporan Produksi & Distribusi Semen Beku,
- Bio Security sebagai sumber laporan PDF/DOCX melalui generator laporan umum karena belum terdapat template SOP Bio Security pada `assets/templates/`,
- kompatibilitas laporan Penampungan Semen schema baru dan histori lama.

### Android

Android menggunakan MethodChannel:

`id.kalselprov.bib.bullcare/downloads`

Method:

`saveWithPicker`

Implementasi native menggunakan `Intent.ACTION_CREATE_DOCUMENT` sehingga user memilih lokasi penyimpanan melalui system document picker.

## Foto Bull

BullCare tidak menggunakan Firebase Storage.

Field foto pada Bull:

- `foto_base64`
- `foto_background_base64`

Foto dipilih melalui mekanisme aplikasi kemudian disimpan sebagai Base64 pada dokumen Bull.

## Menjalankan project

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Untuk build Android:

```bash
flutter build apk --release
```

Untuk Web:

```bash
flutter build web
```

Sebelum menjalankan aplikasi, pastikan Firebase Authentication dan Cloud Firestore pada project Firebase terkait sudah tersedia dan `firestore.rules` terbaru sudah dideploy.

## Dokumentasi perubahan

Riwayat perubahan teknis berada pada folder `docs/`. Dokumentasi lama tetap dipertahankan sebagai histori versi. Untuk kondisi aktual, gunakan source terbaru bersama:

- `docs/FIRESTORE_SCHEMA.md`
- `docs/PROJECT_ANALYSIS.md`
- `docs/PERBAIKAN_V10_SINKRONISASI_15_AKTIVITAS.md`
- `docs/PERBAIKAN_V9_PENGEMBANGAN_LANJUTAN.md` (riwayat tahap sebelumnya)
