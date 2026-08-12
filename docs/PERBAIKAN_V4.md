# Perbaikan BullCare V4

## Filter riwayat aktivitas

Pada halaman Profil Bull, bagian Riwayat Aktivitas sekarang memiliki filter kategori berbentuk chip horizontal. Pengguna dapat memilih Semua, Pemberian Pakan, Sanitasi, Pemeriksaan Kesehatan, Penimbangan, Pengukuran, Pengobatan, Pemberian Obat Cacing, Pemotongan Bulu, Pemotongan Kuku, atau Penampungan Semen. Setiap chip menampilkan jumlah riwayat pada kategori tersebut.

## Validasi CRUD dan notifikasi

- Data bull wajib lengkap dan dibatasi panjang karakternya.
- Kode bull divalidasi agar tidak digunakan oleh bull lain.
- Sebelum tambah atau edit bull, aplikasi menampilkan konfirmasi akhir.
- Sebelum tambah atau edit aktivitas, aplikasi menampilkan konfirmasi akhir.
- Nilai angka aktivitas wajib lebih besar dari nol.
- Tanggal aktivitas tidak boleh melewati tanggal hari ini.
- Aktivitas dengan pilihan tindakan wajib memiliki minimal satu tindakan yang dipilih.
- Penghapusan bull tetap menggunakan dialog konfirmasi.
- Setelah operasi berhasil, aplikasi menampilkan notifikasi tambah, edit, atau hapus yang sesuai.

## Penghapusan Pengambilan Sampel

Jenis aktivitas Pengambilan Sampel telah dihapus dari katalog aktivitas, registry service, konstanta collection, aturan Firestore, dokumentasi schema, model, dan service. Data lama pada collection Firestore tidak dihapus otomatis, tetapi tidak lagi dibaca atau ditampilkan oleh aplikasi.
