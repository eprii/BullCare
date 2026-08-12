# Skema Cloud Firestore BullCare

Semua collection berada pada root database. Tidak digunakan subcollection.

## users

- `uid` string
- `nama` string
- `email` string
- `role` string, nilai `petugas` atau `supervisor`
- `created_at` timestamp
- `updated_at` timestamp

## bulls

- `kode_bull` string
- `nama` string
- `bangsa` string
- `nomor_kandang` string
- `warna_straw` string
- `status` string
- `created_at` timestamp
- `updated_at` timestamp

## Field umum aktivitas

Seluruh collection aktivitas mempunyai field berikut:

- `bull_id` string
- `petugas_uid` string
- `nama_petugas` string, nama petugas yang menjalankan aktivitas
- `tanggal` timestamp
- `created_at` timestamp
- `updated_at` timestamp

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

## pemotongan_bulu

- `dipotong` boolean
- `keterangan` string

## pemotongan_kuku

- `dipotong` boolean
- `keterangan` string

## penampungan_semen

- `volume_semen` number
- `suhu_av` number
- `keterangan` string
