# BullCare V8.9 - Navbar Laporan dan Export PDF/Word

Perubahan ini menambahkan fitur laporan tanpa mengubah CRUD, reminder, countdown, role, maupun alur aktivitas yang sudah berjalan.

## Fitur baru

- Navbar baru **Laporan** pada bottom navigation.
- Semua kategori aktivitas BullCare dipilih secara default sebagai sumber laporan.
- Pengguna dapat memilih sebagian kategori aktivitas apabila diperlukan.
- Filter periode menggunakan date range.
- Nama file dapat diedit.
- Orientasi dokumen dapat dipilih: Potret atau Lanskap.
- Export PDF (.pdf).
- Export Word (.docx) yang dapat dibuka dan diedit di Microsoft Word/aplikasi kompatibel.
- Laporan menampilkan tanggal aktivitas, bull, kategori aktivitas, nama petugas pelaksana, dan rincian aktivitas.
- UID dan nama collection internal Firestore tidak dicantumkan pada laporan.

## Dependency baru

- `pdf: ^3.12.0`
- `archive: ^4.0.9`
- `file_saver: ^0.3.1`

Versi dependency dipilih agar tetap kompatibel dengan constraint Dart project `^3.10.4`.

## File baru

- `lib/pages/reports/report_page.dart`
- `lib/services/report_export_service.dart`
- `lib/models/report_export_data.dart`

## File diubah

- `lib/pages/home/app_shell_page.dart`
- `pubspec.yaml`

## Menjalankan

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
```

Tidak ada perubahan Firestore Rules.
