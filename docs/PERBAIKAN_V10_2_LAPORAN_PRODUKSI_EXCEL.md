# PERBAIKAN V10.2 — Laporan Produksi & Distribusi Semen Beku

## Tujuan

Revisi halaman Laporan khusus sumber **Produksi & Distribusi Semen Beku** berdasarkan kebutuhan laporan bulanan kantor.

## Perubahan

1. Pemilihan periode untuk Produksi & Distribusi Semen Beku diubah menjadi **Bulan** dan **Tahun**, bukan rentang tanggal.
2. PDF dan Word tetap tersedia seperti implementasi sebelumnya.
3. Ditambahkan format export **Excel (.xlsx)** khusus Produksi & Distribusi Semen Beku.
4. Excel menggunakan template contoh kantor `assets/templates/form_produksi_distribusi_semen_beku.xlsx` sehingga warna, border, ukuran kolom, header, dan area tanda tangan mengikuti form contoh.
5. Data tabel Excel diisi dari collection `produksi_distribusi_semen_beku` untuk bulan+tahun yang dipilih.
6. Kolom jumlah produksi, jumlah distribusi, stock akhir, dan total menggunakan formula Excel agar file tetap dapat diedit setelah diunduh.
7. Export Excel menggunakan sistem penyimpanan yang sudah ada; Android tetap melalui MethodChannel `saveWithPicker`, Web melalui `file_saver`.

## Tidak diubah

- Firestore schema dan collection.
- Firestore Rules.
- Activity registry.
- Role Petugas/Supervisor.
- Halaman atau laporan aktivitas lain.
- Sistem PDF/Word yang sudah berjalan.
- Dependency project; implementasi XLSX memanfaatkan package `archive` yang sudah ada.
