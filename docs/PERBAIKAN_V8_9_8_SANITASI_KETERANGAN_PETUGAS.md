# Perbaikan V8.9.8 — Keterangan dan Petugas Laporan Sanitasi

Perubahan hanya pada export laporan sanitasi:

- Kolom KETERANGAN tidak lagi menampilkan kode `P`, `K`, atau `TM`.
- Jika aktivitas memiliki keterangan, kolom menampilkan isi keterangan tersebut.
- Jika tidak ada keterangan, kolom menampilkan `-`.
- Nama default `Petugas BullCare` diperlakukan sebagai fallback.
- Jika pada tanggal yang sama terdapat nama petugas pelaksana yang diisi secara nyata, nama tersebut diprioritaskan dan `Petugas BullCare` tidak ikut ditampilkan.
- Jika tidak ada nama petugas lain pada tanggal tersebut, fallback `Petugas BullCare` tetap dapat ditampilkan.
- Tanda centang pada tabel sanitasi tetap dipertahankan.

Tidak ada perubahan pada CRUD, reminder, countdown, Firestore, role, atau fitur BullCare lainnya.
