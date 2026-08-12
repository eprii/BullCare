# BullCare BIB

BullCare adalah aplikasi mobile dan web berbasis Flutter untuk mendigitalisasi manajemen pemeliharaan bull di Balai Inseminasi Buatan. Data disimpan pada Firebase Authentication dan Cloud Firestore. Aplikasi tidak menggunakan Firebase Storage.

## Alur aplikasi

1. Splash screen.
2. Login atau pembuatan akun Petugas.
3. Validasi Firebase Authentication dan profil pada collection `users`.
4. Dashboard menampilkan total bull, reminder hari ini, dan aktivitas terbaru.
5. Daftar Bull menyediakan pencarian, profil, tambah, edit, dan hapus sesuai role.
6. Profil Bull menampilkan identitas, ringkasan kondisi terbaru, dan timeline aktivitas.
7. Petugas dapat memilih jenis aktivitas, mengisi formulir, memvalidasi, lalu menyimpan data ke root collection Cloud Firestore.
8. Setelah tersimpan, profil, timeline, dashboard, dan reminder membaca data terbaru.
9. Supervisor hanya memiliki akses baca.

## Role

- **Petugas** dapat melihat seluruh data, menambah/edit/hapus bull, menambah aktivitas, dan mengedit aktivitas.
- **Supervisor** dapat melihat dashboard, daftar bull, reminder, serta riwayat aktivitas tanpa tombol perubahan data.
- Registrasi dari aplikasi membuat akun dengan role `petugas`. Role `supervisor` ditetapkan secara manual oleh administrator pada dokumen `users/{uid}`.

## Struktur utama

```text
lib/
├── app.dart
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
│   └── splash/
├── services/
├── theme/
├── utils/
└── widgets/
```

Setiap collection aktivitas memiliki file service sendiri dan memakai `BaseActivityService` untuk mencegah duplikasi kode.


## Pembaruan V4

- Filter riwayat aktivitas per kategori pada Profil Bull.
- Validasi dan konfirmasi sebelum tambah atau edit data.
- Notifikasi berhasil setelah tambah, edit, dan hapus data.
- Validasi kode bull unik, angka positif, dan tanggal aktivitas.
- Aktivitas Pengambilan Sampel telah dihapus.

## Collection Firestore

`users`, `bulls`, `pemberian_pakan`, `sanitasi`, `pemeriksaan_kesehatan`, `penimbangan`, `pengukuran`, `pengobatan`, `pemberian_obat_cacing`, `pemotongan_bulu`, `pemotongan_kuku`, dan `penampungan_semen`.

Semua collection berada pada root Firestore. Data aktivitas terhubung dengan `bull_id` dan `petugas_uid`. Data dinamis tidak diduplikasi ke dokumen master bull.

## Menjalankan proyek

1. Pasang Flutter stable yang kompatibel dengan Dart 3.10 atau lebih baru.
2. Jalankan `flutter pub get`.
3. Aktifkan **Email/Password** pada Firebase Authentication.
4. Buat database Cloud Firestore.
5. Terapkan `firestore.rules` dengan `firebase deploy --only firestore:rules`.
6. Jalankan `flutter run`.
7. Buat APK dengan `flutter build apk --release`.

Konfigurasi Firebase Android, iOS, dan web yang sudah ada tetap dipertahankan.

## Reminder

Reminder dibuat berdasarkan data yang didukung rancangan proyek:

- Pemberian pakan harian yang belum dicatat.
- Sanitasi kandang setiap bulan pada tanggal yang sama dengan pencatatan sanitasi kandang terakhir.
- Penampungan semen setiap Senin dan Kamis yang belum dicatat.


## Pembaruan V5

- Informasi internal UID petugas dan nama collection disembunyikan dari detail aktivitas.
- Reminder sanitasi kandang menggunakan siklus kalender bulanan pada tanggal yang sama.
- Reminder menampilkan jadwal kalender dan countdown real-time yang otomatis berulang setiap bulan.

## Countdown Sanitasi Kandang

Setelah aktivitas **Sanitasi Kandang** disimpan, menu Reminder menampilkan countdown menuju tanggal yang sama pada bulan berikutnya. Countdown berubah setiap detik dan otomatis beralih ke bulan selanjutnya ketika satu periode selesai. Apabila tanggal awal tidak tersedia pada bulan tujuan, sistem menggunakan hari terakhir bulan tersebut, kemudian kembali ke tanggal awal pada bulan yang mendukungnya.


## Pembaruan V7

- Jadwal sanitasi kandang menggunakan tanggal kalender bulanan, bukan interval 20 hari.
- Countdown sanitasi kandang otomatis mengulang ke bulan berikutnya setelah mencapai nol.
- Tombol pencatatan aktivitas pada halaman Reminder dihapus.
- Form aktivitas menyediakan isian wajib nama petugas pelaksana.
- Detail aktivitas menampilkan nama petugas pelaksana yang disimpan pada aktivitas.
- Logout memiliki dialog konfirmasi, status proses, notifikasi berhasil, dan penanganan kegagalan.

## Pembaruan V8 — Modern Green UI

- Seluruh tampilan diperbarui mengikuti gaya modern minimalis berwarna hijau, putih, dan abu-abu lembut.
- Dashboard menggunakan greeting, hero banner, kartu ringkasan, dan daftar aktivitas terbaru yang lebih ringkas.
- Daftar bull, profil bull, form, riwayat aktivitas, detail aktivitas, dan reminder menggunakan kartu rounded dengan hierarki informasi yang lebih jelas.
- Bottom navigation diperbarui tanpa mengubah empat menu utama yang sudah ada.
- Login, registrasi, splash screen, empty state, error state, loading state, dan countdown sanitasi memakai bahasa visual yang sama.
- Seluruh fitur, role, validasi, CRUD, Firestore, reminder bulanan, countdown, dan nama petugas tetap menggunakan sistem V7.
