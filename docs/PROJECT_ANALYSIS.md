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

---

# Kondisi Aktual Setelah Pengembangan Lanjutan

Bagian di atas tetap dipertahankan sebagai **analisis kondisi awal proyek**. Bagian ini mencatat kondisi source terbaru setelah rangkaian pengembangan lanjutan.

## Arsitektur aktual

BullCare sekarang merupakan aplikasi Flutter yang sudah mempunyai alur lengkap Android/Web dengan Firebase Authentication dan root Cloud Firestore. Struktur utama tetap menggunakan pemisahan Models → Services → Pages → Widgets dan tidak diganti dengan arsitektur baru.

Sistem aktivitas menggunakan `ActivityCatalog`, `ActivityRecord`, `BaseActivityService`, dan `ActivityServiceRegistry`. Seluruh aktivitas tetap berada pada root collection Firestore.

## Aktivitas terintegrasi

Source saat ini mempunyai 12 jenis aktivitas yang konsisten antara katalog, registry, constants, sumber laporan, dan Firestore Rules:

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

Pengambilan Sample yang pada versi lama pernah dihapus telah ditambahkan kembali pada source terkini. Pencegahan Ektoparasit juga telah menjadi aktivitas resmi di katalog aplikasi.

## Data Bull aktual

Model Bull saat ini menyimpan identitas dasar serta field tambahan yang telah digunakan aplikasi, termasuk:

- umur,
- foto Base64,
- background foto Base64,
- status,
- status SNI,
- jam dan menit reminder sanitasi.

Firebase Storage tetap tidak digunakan.

## Reminder aktual

Reminder saat ini mencakup:

- pemberian pakan harian,
- sanitasi kandang harian,
- sanitasi tempat makan harian,
- sanitasi pejantan bulanan,
- penampungan semen setiap Senin dan Kamis.

Siklus sanitasi menggunakan data aktivitas terakhir sebagai anchor dan jam reminder yang tersimpan pada data Bull.

## Laporan/export aktual

Fitur laporan mendukung PDF dan Word/DOCX. Template SOP pada `assets/templates/` tetap digunakan untuk laporan yang sudah mempunyai aset resmi.

Pengembangan lanjutan menambahkan/menyelesaikan:

- integrasi laporan Pengambilan Sample,
- laporan Pencegahan Ektoparasit berdasarkan referensi formulir SOP-6.3 k,
- penyesuaian Penampungan Semen agar field terbaru tidak dipetakan ke kolom schema lama,
- kompatibilitas export terhadap record Penampungan Semen historis.

Android tetap menggunakan `MethodChannel('id.kalselprov.bib.bullcare/downloads')` dengan method `saveWithPicker` dan `Intent.ACTION_CREATE_DOCUMENT`.

## Role dan Firestore Rules

Konsep role tidak berubah:

- `petugas`: dapat melakukan operasi perubahan data sesuai fitur.
- `supervisor`: read-only untuk Bull dan seluruh aktivitas.

Firestore Rules sekarang memiliki rule eksplisit untuk seluruh 12 root collection aktivitas, termasuk `pencegahan_ektoparasit` dan `pengambilan_sample`.

## Prinsip pengembangan berikutnya

Source project terbaru tetap menjadi source of truth. Perubahan berikutnya harus dilakukan secara minimal dan terkontrol. Fitur yang sudah berjalan tidak boleh di-refactor, didesain ulang, atau diubah schema-nya hanya untuk alasan kerapian bila tidak diminta.
