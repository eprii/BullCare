# Pembaruan BullCare V7

## Reminder sanitasi kandang

- Jadwal berikutnya dihitung berdasarkan bulan kalender dan tanggal aktivitas sanitasi kandang terakhir.
- Contoh pencatatan 6 Agustus menghasilkan jadwal 6 September, kemudian 6 Oktober, dan seterusnya.
- Countdown menggunakan waktu perangkat secara real-time dan berpindah otomatis ke periode bulan berikutnya setelah mencapai nol.
- Untuk tanggal 29, 30, atau 31 yang tidak tersedia pada bulan tujuan, sistem memakai hari terakhir bulan tersebut tanpa mengubah tanggal acuan awal untuk bulan berikutnya.
- Tombol Catat Sekarang di halaman Reminder dihapus.

## Nama petugas aktivitas

- Setiap form aktivitas memiliki field wajib `nama_petugas`.
- Nilai awal menggunakan nama akun yang sedang login dan tetap dapat diubah sesuai petugas pelaksana.
- Detail aktivitas menampilkan nama petugas pelaksana.
- Aktivitas lama yang belum mempunyai `nama_petugas` tetap menggunakan nama profil akun pencatat sebagai fallback.

## Logout

- Logout meminta konfirmasi sebelum sesi diakhiri.
- Tombol logout menampilkan indikator proses.
- Setelah berhasil, notifikasi ditampilkan pada halaman login.
- Kegagalan logout menampilkan pesan kesalahan.
