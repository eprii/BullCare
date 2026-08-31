# PERBAIKAN V10.3 — Hapus Kategori dari Form Bull

## Tujuan
Menghilangkan input **Kategori Bull** pada halaman Tambah/Edit Data Bull karena kategori tersebut tidak digunakan sebagai atribut individu bull.

## Perubahan
- Field dropdown `Kategori Bull` dihapus dari `BullFormPage`.
- Pemilihan `Bangsa` tidak lagi bergantung pada kategori; daftar bangsa diambil dari seluruh data bull yang sudah ada.
- Opsi `Buat Bangsa Baru` tetap tersedia.
- Data bull lama yang masih memiliki field `kategori` tetap dapat dibaca dan, saat diedit, nilai lama tetap dipertahankan secara internal untuk kompatibilitas data.
- Bull baru disimpan dengan nilai kategori kosong menggunakan schema yang sudah ada, sehingga tidak ada perubahan Firestore schema maupun rules.

## Tidak Diubah
- `BullModel` dan `BullService` tetap kompatibel dengan field `kategori` lama.
- Profil bull, daftar bull, aktivitas, laporan, reminder, role, Firebase, dan Firestore Rules tidak diubah.
- Kategori pada fitur Produksi & Distribusi Semen Beku tetap digunakan karena merupakan kategori laporan/produksi, bukan kategori individu bull.
