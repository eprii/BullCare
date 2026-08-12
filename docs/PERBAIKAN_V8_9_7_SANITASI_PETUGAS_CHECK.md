# Perbaikan V8.9.7 - Nama Petugas & Tanda Checklist Sanitasi

Perubahan hanya pada export laporan sanitasi (Word/PDF):

- Kolom **Paraf Petugas** sekarang menggunakan `nama_petugas` lengkap dari record aktivitas sanitasi, tanpa diubah menjadi inisial/singkatan.
- Bila pada tanggal yang sama terdapat lebih dari satu nama petugas, nama unik ditampilkan lengkap dan dipisahkan dengan ` / `.
- Penanda aktivitas pada tabel SOP diubah dari `X` menjadi tanda checklist.
- Pada Word digunakan karakter checklist `✓`.
- Pada PDF checklist digambar sebagai vektor agar tidak bergantung pada font Unicode.
- Halaman rincian data sanitasi tetap menampilkan `Nama Petugas` lengkap seperti yang tersimpan pada aktivitas.

Tidak ada perubahan pada CRUD, Firestore, reminder, countdown, role, dashboard, maupun jenis aktivitas lainnya.
