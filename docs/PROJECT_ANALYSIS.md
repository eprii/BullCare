# Analisis Awal Proyek BullCare

## Kondisi proyek sebelum pengembangan

Proyek awal masih berupa template Flutter bawaan dengan halaman penghitung angka. Firebase Core dan berkas konfigurasi Firebase telah tersedia, sedangkan Firebase Authentication dan Cloud Firestore belum diintegrasikan ke alur aplikasi. Folder `lib` hanya berisi `main.dart`, `firebase_options.dart`, dan model awal.

Model domain yang telah tersedia mencakup data bull, pengguna, pemberian pakan, sanitasi, pemeriksaan kesehatan, penimbangan, pengukuran, pengobatan, pemberian obat cacing, pemotongan bulu, pemotongan kuku, dan penampungan semen. Sebagian besar model belum mempunyai `fromMap`, `toMap`, dan `copyWith`.

## Masalah yang ditemukan

1. UI dan navigasi BullCare belum dibuat.
2. Firebase hanya diinisialisasi pada level konfigurasi, belum digunakan oleh aplikasi.
3. Belum ada autentikasi, pengendalian role, service Firestore, halaman, widget reusable, reminder, dan riwayat aktivitas.
4. Model aktivitas belum seragam dalam proses serialisasi.
5. Tes masih menguji counter bawaan Flutter.
6. Nama aplikasi pada Android dan web masih menggunakan nama template.

## Struktur yang ditambahkan

- `constants` untuk konstanta aplikasi dan daftar collection.
- `theme` untuk tema Material 3 BullCare.
- `utils` untuk validasi, tanggal, dan konversi nilai Firestore.
- `services` untuk autentikasi, user, bull, setiap collection aktivitas, dashboard, dan reminder.
- `pages` untuk splash, autentikasi, dashboard, daftar bull, profil bull, aktivitas, dan reminder.
- `widgets` untuk komponen UI yang dipakai berulang.
- `docs` untuk dokumentasi implementasi dan skema Firestore.

Penambahan folder tidak mengganti konsep database atau nama collection yang telah ditetapkan. Semua collection tetap berada pada root Cloud Firestore dan aktivitas tetap terhubung melalui `bull_id` serta `petugas_uid`.

## Pemetaan flowchart ke aplikasi

- Splash → `SplashPage`.
- Input akun dan login → `LoginPage`, `RegisterPage`, `AuthGate`.
- Validasi login → Firebase Authentication.
- Data user → collection `users`.
- Dashboard → `DashboardPage`.
- Daftar dan pencarian bull → `BullListPage`.
- Profil, ringkasan terbaru, dan timeline → `BullProfilePage`.
- Tambah, edit, dan hapus bull → `BullFormPage` dan `BullService`.
- Pilih jenis aktivitas, isi form, validasi, dan simpan → `ActivityTypePage`, `ActivityFormPage`, serta service masing-masing collection.
- Reminder → `ReminderPage` dan `ReminderService`.
- Aktivitas terbaru → `ActivityListPage` dan `DashboardService`.

## Keputusan arsitektur

Form aktivitas dibuat dinamis berdasarkan `ActivityCatalog`, tetapi setiap collection tetap mempunyai class service sendiri. Seluruh service aktivitas memakai `BaseActivityService` untuk menghindari duplikasi operasi Firestore. Model spesifik yang sudah ada tetap dipertahankan dan dilengkapi metode serialisasi.
