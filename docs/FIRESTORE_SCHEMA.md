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
- `role` string (`pengunjung`, `petugas`, atau `supervisor`)
- `created_at` timestamp
- `updated_at` timestamp

### Permission

- User yang login dapat membaca data user.
- Saat registrasi, user hanya dapat membuat profilnya sendiri dengan role `pengunjung`.
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

## bedah_bangkai

- `tanggal_mati` timestamp
- `peralatan` string
- `pemeriksaan_organ` string
- `tanggal_pengiriman_laboratorium` timestamp/null
- `tanggal_jawaban` timestamp/null
- `keterangan` string

`pemeriksaan_organ` menyimpan pasangan Organ dan Hasil Pemeriksaan sesuai format input yang digunakan source.

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

## produksi_distribusi_semen_beku

Collection ini menggunakan record bulanan dan tetap berada pada root Firestore. Field khusus yang digunakan source saat ini:

- `record_type` string (`monthly`)
- `kategori` string
- `bangsa` string
- `status_sni` string
- `jumlah_pejantan` number/integer
- `tahun` number/integer
- `bulan` number/integer
- `stock_tahun` number/integer/null
- `stock_awal` number/integer/null (alias kompatibilitas data/laporan lama)
- `produksi_minggu_i` number/integer/null
- `produksi_minggu_ii` number/integer/null
- `produksi_minggu_iii` number/integer/null
- `produksi_minggu_iv` number/integer/null
- `produksi_minggu_v` number/integer/null
- `jumlah_produksi` number/integer/null
- `afkir` number/integer/null
- `distribusi_komandan` number/integer/null
- `distribusi_non_sikomandan` number/integer/null
- `jumlah_distribusi` number/integer/null
- `stock_akhir` number/integer/null

Catatan implementasi:

- `tanggal` digunakan sebagai periode produksi (tanggal 1 pada bulan/tahun terkait).
- `created_at` dan `updated_at` menyimpan waktu pencatatan/audit sebenarnya.
- `bull_id` tetap tersedia untuk kompatibilitas struktur aktivitas tetapi bernilai string kosong karena data ini bersifat agregat produksi bulanan, bukan aktivitas satu bull tertentu.

## bio_security

- `bahan` string
- `alat` string
- `keterangan` string

Bio Security sudah terdaftar pada katalog, registry, Firestore Rules, dan sumber Laporan. Karena belum ada template SOP Bio Security pada `assets/templates/`, export memakai generator laporan umum PDF/DOCX yang sudah tersedia.

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
9. `bedah_bangkai`
10. `pemotongan_bulu`
11. `pemotongan_kuku`
12. `penampungan_semen`
13. `produksi_distribusi_semen_beku`
14. `bio_security`
15. `pengambilan_sample`

## Firestore Rules

Kondisi rules saat ini:

- Semua data Bull dan aktivitas dapat dibaca oleh user yang sudah login.
- Create/update/delete Bull hanya untuk role `supervisor`.
- Create/update/delete seluruh 15 collection aktivitas dapat dilakukan oleh role `petugas` dan `supervisor`.
- Role `pengunjung` bersifat read-only. Role `petugas` memiliki akses pengelolaan aktivitas dan export sesuai permission. Role `supervisor` memiliki akses penuh sesuai permission.

Perubahan schema atau permission berikutnya harus mengikuti implementasi source aktual dan tidak boleh mengubah konsep role tanpa kebutuhan eksplisit.
