# PERBAIKAN V8.9.28 - Supervisor Read-Only

## Tujuan
Memastikan role `supervisor` dapat melihat seluruh halaman utama BullCare dan tetap dapat mengunduh laporan, tetapi tidak dapat melakukan operasi tambah, ubah, atau hapus data bull maupun aktivitas.

## Perubahan
- Tombol tambah bull tetap hanya muncul untuk `petugas`.
- Tombol kelola/edit/hapus bull tetap hanya muncul untuk `petugas`.
- Tombol tambah/edit/hapus aktivitas tetap hanya muncul untuk `petugas`.
- Pengaturan jam reminder sanitasi tetap hanya dapat diubah oleh `petugas`.
- Form Bull dan form Aktivitas diberi guard tambahan sehingga supervisor tidak mendapatkan kontrol CRUD walaupun route form terpanggil secara tidak sengaja.
- Handler CRUD diberi guard tambahan `isPetugas` sebagai pertahanan di lapisan UI.
- Pesan empty state untuk supervisor tidak lagi mengarahkan pengguna untuk menambah data.
- Halaman Laporan tidak dibatasi karena supervisor memang tetap diperbolehkan melihat dan mengunduh laporan.

## Firestore Rules
Tidak diubah. Rules yang sudah ada telah menerapkan:
- user login: read
- `petugas`: create/update/delete
- `supervisor`: read-only

## Database
Tidak ada perubahan schema, collection, field, maupun tipe data.

## Navigation
Tidak ada perubahan pada bottom navigation atau struktur halaman utama.
