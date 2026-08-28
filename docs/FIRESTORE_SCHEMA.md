# Skema Cloud Firestore BullCare

Dokumen ini menggambarkan **schema yang digunakan source BullCare saat ini** setelah pengembangan lanjutan. Seluruh collection berada pada **root Cloud Firestore** dan tidak menggunakan subcollection.

## Prinsip umum

- Nama collection dan field Firestore menggunakan `snake_case`.
- ID dokumen Firestore digunakan sebagai `id` model dan tidak disimpan ulang sebagai field wajib.
- Aktivitas terhubung ke bull melalui `bull_id`.
- Aktivitas terhubung ke akun pencatat melalui `petugas_uid`.
- `nama_petugas` disimpan pada dokumen aktivitas dari form aktivitas agar nama pelaksana tetap terbaca pada histori/laporan.
- Histori aktivitas tidak digantikan oleh nilai terbaru pada profil bull.

## users

Collection: `users`

Field utama:

- `uid` string
- `nama` string
- `email` string
- `role` string (`petugas` atau `supervisor`)
- `created_at` timestamp
- `updated_at` timestamp

### Permission

- User yang login dapat membaca data user.
- Saat registrasi, user hanya dapat membuat profilnya sendiri dengan role `petugas`.
- User hanya dapat memperbarui dokumennya sendiri tanpa mengubah role.
- Delete user melalui Firestore Rules tidak diizinkan.

## bulls

Collection: `bulls`

Field yang digunakan source saat ini:

- `kode_bull` string
- `nama` string
- `bangsa` string
- `nomor_kandang` string
- `warna_straw` string
- `umur` string
- `foto_base64` string
- `foto_background_base64` string
- `status` string
- `status_sni` string
- `sanitasi_reminder_hour` number/integer
- `sanitasi_reminder_minute` number/integer
- `created_at` timestamp
- `updated_at` timestamp

Catatan:

- Foto disimpan sebagai Base64. BullCare tidak menggunakan Firebase Storage.
- Jam reminder sanitasi default pada model adalah pukul `08:00` bila field tidak tersedia/tidak valid.

## Field umum aktivitas

Seluruh root collection aktivitas menggunakan field sistem berikut:

- `bull_id` string
- `petugas_uid` string
- `nama_petugas` string
- `tanggal` timestamp
- `created_at` timestamp
- `updated_at` timestamp

Field spesifik setiap aktivitas dijelaskan di bawah.

## pemberian_pakan

- `hijauan` string
- `konsentrat` string
- `kecambah` string
- `keterangan` string

## sanitasi

- `sanitasi_kandang` boolean
- `sanitasi_pejantan` boolean
- `sanitasi_tempat_pakan` boolean
- `keterangan` string

Catatan implementasi reminder saat ini:

- Sanitasi kandang: siklus harian setelah tersedia aktivitas sanitasi kandang terakhir.
- Sanitasi tempat makan: siklus harian setelah tersedia aktivitas sanitasi tempat makan terakhir.
- Sanitasi pejantan: siklus kalender bulanan berdasarkan aktivitas terakhir.
- Jam reminder mengikuti `sanitasi_reminder_hour` dan `sanitasi_reminder_minute` pada bull.

## pemeriksaan_kesehatan

- `kondisi` string
- `diagnosa` string
- `tindakan` string
- `keterangan` string

## penimbangan

- `berat_badan` number
- `keterangan` string

## pengukuran

- `tinggi_gumba` number
- `panjang_tubuh` number
- `lingkar_badan` number
- `lingkar_skrotum` number
- `keterangan` string

## pengobatan

- `gejala_klinis` string
- `diagnosa` string
- `terapi` string
- `keterangan` string

## pemberian_obat_cacing

- `nama_obat` string
- `dosis` string
- `keterangan` string

## pencegahan_ektoparasit

- `bahan` string
- `alat` string
- `tindakan` string
- `keterangan` string

Aktivitas ini sudah terdaftar pada `ActivityCatalog`, `ActivityServiceRegistry`, Firestore Rules, dan sumber Laporan.

## pemotongan_bulu

- `dipotong` boolean
- `keterangan` string

## pemotongan_kuku

- `dipotong` boolean
- `keterangan` string

## penampungan_semen

Schema **aktif/terbaru**:

- `kolektor` string
- `volume` string
- `p_tp` string
- `jumlah_straw_yang_dihasilkan` string
- `keterangan` string

Catatan kompatibilitas histori:

Service laporan Penampungan Semen tetap dapat membaca record historis yang memakai field lama seperti `av`, `vaselin`, `suhu_av`, dan `volume_semen`. Dukungan ini hanya untuk kompatibilitas laporan histori dan tidak mengubah schema input terbaru.

## pengambilan_sample

- `darah` boolean
- `serum` boolean
- `ulas_darah` boolean
- `swab` boolean
- `feses` boolean
- `keterangan` string

Aktivitas ini sudah terdaftar pada `ActivityCatalog`, `ActivityServiceRegistry`, Firestore Rules, dan sumber Laporan.

## Daftar root collection aktivitas saat ini

1. `pemberian_pakan`
2. `sanitasi`
3. `pemeriksaan_kesehatan`
4. `penimbangan`
5. `pengukuran`
6. `pengobatan`
7. `pemberian_obat_cacing`
8. `pencegahan_ektoparasit`
9. `pemotongan_bulu`
10. `pemotongan_kuku`
11. `penampungan_semen`
12. `pengambilan_sample`

## Firestore Rules

Kondisi rules saat ini:

- Semua data Bull dan aktivitas dapat dibaca oleh user yang sudah login.
- Create/update/delete Bull hanya untuk role `petugas`.
- Create/update/delete seluruh 12 collection aktivitas hanya untuk role `petugas`.
- Role `supervisor` bersifat read-only terhadap Bull dan aktivitas.

Perubahan schema atau permission berikutnya harus mengikuti implementasi source aktual dan tidak boleh mengubah konsep role tanpa kebutuhan eksplisit.
