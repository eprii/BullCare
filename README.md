# BullCare BIB

**BullCare — Manajemen Pemeliharaan Bull** adalah aplikasi Flutter untuk Android dan Web yang membantu digitalisasi manajemen pemeliharaan bull di Balai Inseminasi Buatan (BIB). Data menggunakan Firebase Authentication dan Cloud Firestore. Project **tidak menggunakan Firebase Storage**; foto bull disimpan sebagai Base64 pada data bull.

Versi source pada project ini: **1.6.0+7**.

## Konsep utama

BullCare berfokus pada:

**Profil Bull + Aktivitas + Riwayat + Reminder + Laporan**

Data aktivitas disimpan sebagai histori. Nilai terbaru dapat ditampilkan sebagai ringkasan pada profil bull, tetapi record lama tetap dipertahankan.

## Role

### Petugas

Petugas dapat membaca data dan melakukan perubahan sesuai fitur aplikasi, termasuk CRUD Bull dan aktivitas serta export laporan.

### Supervisor

Supervisor bersifat **read-only** untuk data operasional. Supervisor dapat melihat dashboard, Bull, profil, aktivitas, histori, reminder, dan laporan, tetapi tidak mendapatkan akses perubahan data.

Role yang digunakan tetap:

- `petugas`
- `supervisor`

Registrasi aplikasi membuat profil dengan role `petugas`. Role `supervisor` ditetapkan secara administratif pada data user.

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
- `pemotongan_bulu`
- `pemotongan_kuku`
- `penampungan_semen`
- `pengambilan_sample`

Detail field aktual tersedia pada `docs/FIRESTORE_SCHEMA.md`.

## Aktivitas saat ini

`ActivityCatalog`, `ActivityServiceRegistry`, constants, sumber Laporan, dan Firestore Rules telah disinkronkan untuk 12 jenis aktivitas:

1. Pemberian Pakan
2. Sanitasi
3. Pemeriksaan Kesehatan
4. Penimbangan
5. Pengukuran
6. Pengobatan
7. Pemberian Obat Cacing
8. Pencegahan Ektoparasit
9. Pemotongan Bulu
10. Pemotongan Kuku
11. Penampungan Semen
12. Pengambilan Sample

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

Halaman Laporan dapat memilih sumber aktivitas, periode, nama file, format, dan orientasi sesuai implementasi yang tersedia.

Export mendukung:

- PDF
- Word/DOCX

Template SOP resmi yang tersedia tetap digunakan untuk aktivitas yang mempunyai template pada `assets/templates/`.

Pengembangan lanjutan juga mencakup:

- laporan Pengambilan Sample,
- laporan Pencegahan Ektoparasit berdasarkan referensi formulir SOP-6.3 k,
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
- `docs/PERBAIKAN_V9_PENGEMBANGAN_LANJUTAN.md`
