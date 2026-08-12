# BullCare v8.9.22 - Template SOP-6.3d dan SOP-6.3e

Perubahan versi ini dibatasi pada mekanisme ekspor laporan untuk dua aktivitas berikut:

1. `pemberian_obat_cacing` -> FORMULIR PEMBERIAN OBAT CACING (SOP-6.3d)
2. `pengobatan` -> FORMULIR PENGOBATAN PEJANTAN (BULL) (SOP-6.3e)

## Batas perubahan

- CRUD aktivitas, Firestore, autentikasi, reminder, dashboard, data bull, dan modul aktivitas lain tidak diubah.
- Template Sanitasi, Pemberian Pakan, Penimbangan, dan Pengukuran tetap memakai implementasi versi sebelumnya.
- Routing template baru hanya aktif bila seluruh record yang diekspor berasal dari collection yang sesuai.
- Ekspor aktivitas lain tetap menggunakan mekanisme laporan umum yang telah ada.

## SOP-6.3d - Pemberian Obat Cacing

Dokumen sumber SOP-6.3d yang diberikan masih memuat header tabel `Pengukuran` dengan subkolom Tinggi Gumba, Panjang Tubuh, Lingkar Badan, dan Lingkar Skrotum. Header sumber tersebut tidak diubah oleh aplikasi.

Agar data pemberian obat cacing tidak ditempatkan pada kolom pengukuran yang salah secara semantik:

- Nama Bull dan Bangsa mengikuti database BullCare.
- Data utama terbaru per bull dirangkum pada kolom Keterangan sebagai Nama Obat dan Dosis.
- Semua data asli (Tanggal, Nama Obat, Dosis, Keterangan, Nama Petugas) tetap tersedia pada halaman rincian.
- Baris Paraf Petugas tetap digunakan sesuai template.

## SOP-6.3e - Pengobatan Pejantan

- Nama Bull dan Bangsa mengikuti database BullCare.
- Data terbaru per bull ditempatkan pada kolom Gejala Klinis, Diagnosa, Terapi, dan Keterangan.
- Semua histori pada periode ekspor tetap ditampilkan pada halaman rincian beserta Tanggal dan Nama Petugas.
- PDF mempertahankan dua halaman visual template sumber: bull 1-17 pada halaman pertama dan bull 18-30 pada halaman kedua.

