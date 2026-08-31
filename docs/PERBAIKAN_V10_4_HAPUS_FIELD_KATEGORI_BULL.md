# PERBAIKAN V10.4 — Hapus Field Kategori dari Data Bull

## Tujuan
Menindaklanjuti V10.3 dengan menghapus konsep `kategori` sepenuhnya dari data individu bull. Data kategori Bull sebelumnya hanya digunakan pada data uji dan tidak diperlukan untuk data Bull sebenarnya.

## Perubahan
- Properti `kategori` dihapus dari `BullModel`.
- `BullModel.fromMap()`, `toMap()`, dan `copyWith()` tidak lagi membaca/menulis `kategori`.
- `BullService.addBull()` tidak lagi menerima atau menyimpan field `kategori`.
- `BullService.updateBull()` tidak lagi menulis field `kategori`.
- `BullFormPage` tidak lagi mempertahankan nilai kategori secara internal.
- Baris informasi `Kategori` pada profil Bull dihapus karena bukan atribut individu Bull.
- Field `bangsa` tetap digunakan seperti sebelumnya.

## Data Lama
Dokumen Firestore lama yang kebetulan masih memiliki field `kategori` tidak lagi dibaca oleh aplikasi. Karena data tersebut merupakan data uji, tidak ditambahkan mekanisme kompatibilitas atau migrasi khusus. Data riil yang akan dimasukkan selanjutnya menggunakan schema Bull tanpa field `kategori`.

## Tidak Diubah
- Kategori pada **Produksi & Distribusi Semen Beku** tetap dipertahankan karena merupakan kategori laporan/produksi, bukan kategori individu Bull.
- Collection Firestore, Firestore Rules, role, authentication, navigation, reminder, laporan lain, dan struktur aktivitas tidak diubah.
