# BullCare V8.9.18 - Template SOP Pemberian Pakan

Perubahan ini hanya memengaruhi hasil export PDF/Word untuk sumber data **Pemberian Pakan**.

- Pemberian Pakan menggunakan template resmi **SOP-6.3a** yang diberikan pengguna.
- Tiga halaman utama mengikuti formulir sumber:
  1. FORMULIR PEMBERIAN PAKAN HIJAUAN (Kg)
  2. FORMULIR PEMBERIAN KONSENTRAT (Kg)
  3. FORMULIR PEMBERIAN KECAMBAH (Kg)
- Data disusun per bulan, tanggal 1-31, maksimal 30 bull pada formulir utama.
- Nama bull diambil dari database BullCare dan dimasukkan ke slot bull pada formulir.
- Nilai Hijauan, Konsentrat, dan Kecambah ditempatkan pada halaman masing-masing sesuai tanggal dan bull.
- Kolom Total dihitung dari nilai numerik yang tercatat pada tanggal tersebut.
- Kolom Paraf diisi nama petugas pelaksana yang tercatat pada aktivitas.
- Halaman rincian tetap disertakan agar keterangan dan seluruh data aktivitas dapat dibaca lengkap.
- Periode export Pemberian Pakan dibatasi dalam satu bulan agar sesuai struktur SOP-6.3a.

## Batas perubahan

- Template Sanitasi tetap memakai `assets/templates/form_sanitasi_sop_6_3_l.docx` dan service Sanitasi yang sudah berjalan.
- Aktivitas selain Pemberian Pakan dan Sanitasi tetap memakai template laporan BullCare sebelumnya.
- Tidak ada perubahan pada CRUD aktivitas, Firestore schema/rules, reminder, autentikasi, role, data bull, maupun alur input aktivitas.
