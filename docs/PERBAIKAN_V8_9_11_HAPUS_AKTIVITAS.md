# BullCare V8.9.11 — Hapus Aktivitas

Perubahan:

- Menambahkan operasi `deleteActivity` pada `BaseActivityService`.
- Petugas dapat menghapus aktivitas dari halaman Riwayat Aktivitas.
- Sebelum penghapusan tampil dialog konfirmasi.
- Setelah berhasil tampil notifikasi `Berhasil menghapus aktivitas ...`.
- Setelah penghapusan, data aktivitas dimuat ulang dan dashboard/reminder ikut mendapat sinyal perubahan melalui `onDataChanged`.
- Supervisor tetap tidak dapat menghapus aktivitas.
- Firestore Rules diperbarui agar penghapusan collection aktivitas hanya diizinkan untuk role `petugas`.
- Fitur laporan, reminder, sanitasi, countdown, dan CRUD lain tidak diubah.
