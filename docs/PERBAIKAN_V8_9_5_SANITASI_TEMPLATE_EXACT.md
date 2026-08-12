# BullCare V8.9.5 - Perbaikan Template Sanitasi

- Sumber laporan sanitasi digabung kembali menjadi satu pilihan `Sanitasi`.
- Sanitasi kandang, sanitasi tempat makan, dan sanitasi pejantan berada pada satu formulir.
- Layout Word/PDF mengikuti FORMULIR SANITASI KANDANG DAN PEJANTAN SOP-6.3.l:
  - 30 kolom bull tetap,
  - baris tanggal 1-31,
  - KETERANGAN,
  - PARAF PETUGAS,
  - header BIB, nomor dokumen, revisi, tanggal berlaku, dan teks waktu pelaksanaan.
- Semua bull dari database dimasukkan sebagai kolom, bukan hanya bull yang memiliki aktivitas.
- Sel aktivitas diberi tanda X berdasarkan data Firestore pada tanggal dan bull yang sesuai.
- Keterangan memuat jenis sanitasi yang tercatat dan keterangan aktivitas.
- Nama petugas pelaksana dimasukkan ke kolom PARAF PETUGAS.
- Formulir sanitasi dibatasi satu bulan per export agar sesuai struktur formulir 1-31.
- Sistem reminder/CRUD/Firebase di luar laporan tidak diubah.
