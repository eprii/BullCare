# Perbaikan BullCare V5

Perubahan pada versi ini dilakukan tanpa mengubah struktur collection atau alur utama aplikasi.

## Detail aktivitas

- UID petugas tidak lagi ditampilkan pada halaman detail aktivitas.
- Nama collection Firestore tidak lagi ditampilkan.
- Data internal tetap disimpan dan digunakan oleh aplikasi.

## Reminder sanitasi kandang

- Sanitasi kandang memiliki siklus 20 hari setelah pencatatan pertama.
- Setelah aktivitas dengan pilihan `sanitasi_kandang` disimpan, tanggal jatuh tempo berikutnya dihitung dari tanggal aktivitas ditambah 20 hari.
- Setelah sanitasi kandang dicatat, reminder langsung menampilkan hitung mundur mulai dari 20 hari lagi, besok, hari H, sampai status terlambat apabila belum dicatat kembali.
- Aktivitas sanitasi pejantan dan sanitasi tempat pakan tidak mengubah jadwal sanitasi kandang.
- Ketika tombol Catat Sekarang ditekan dari reminder sanitasi kandang, pilihan sanitasi kandang otomatis aktif pada form.
- Reminder pakan harian dan penampungan semen Senin/Kamis tetap berjalan.
