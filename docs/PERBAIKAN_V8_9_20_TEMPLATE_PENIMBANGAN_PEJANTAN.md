# Perbaikan V8.9.20 - Template Penimbangan Pejantan SOP-6.3b

Perubahan dibatasi pada fitur ekspor laporan **Penimbangan**. Sistem CRUD,
Firestore, autentikasi, reminder, data bull, sanitasi, pemberian pakan, dan
aktivitas lain tidak diubah.

## Implementasi

- Menambahkan template Word asli `SOP-6.3b FORMULIR PENIMBANGAN PEJANTAN`.
- Menambahkan render halaman SOP sebagai latar formulir PDF.
- Ekspor Penimbangan PDF dan Word sekarang memakai SOP-6.3b.
- Tahun pada formulir mengikuti periode laporan yang dipilih.
- Nama bull dan bangsa mengikuti data bull pada BullCare.
- Berat badan ditempatkan pada kolom Januari-Desember sesuai bulan pencatatan.
- Jika terdapat lebih dari satu penimbangan bull pada bulan yang sama, formulir
  utama memakai catatan penimbangan terbaru pada bulan tersebut.
- Baris `Paraf Petugas` diisi nama petugas yang tercatat pada bulan terkait.
- Halaman rincian ditambahkan setelah formulir utama agar tanggal penimbangan,
  keterangan, dan nama petugas tetap tersedia secara lengkap.
- Periode penimbangan tidak boleh melintasi tahun karena SOP-6.3b merupakan
  formulir tahunan.

## Isolasi perubahan

File sistem lama tidak diubah selain routing ekspor laporan dan keterangan UI
pada halaman Laporan. Template sanitasi SOP-6.3.l dan pemberian pakan SOP-6.3a
serta service masing-masing tetap digunakan seperti sebelumnya.
