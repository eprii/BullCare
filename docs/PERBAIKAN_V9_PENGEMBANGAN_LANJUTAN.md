# BullCare — Pengembangan Lanjutan V9

Dokumen ini mencatat rangkaian perubahan lanjutan yang dilakukan setelah audit source BullCare terbaru. Tujuan rangkaian ini adalah menyelesaikan fitur yang sudah mulai dibuat dan menyinkronkan komponen terkait **tanpa melakukan refactor besar atau mengubah fitur stabil lain**.

## Prinsip perubahan

- Project terbaru menjadi source of truth.
- Tidak mengubah Login, Register, Splash, Dashboard, Bull CRUD, navigation utama, reminder stabil, atau tema global tanpa kebutuhan.
- Tidak memperkenalkan Firebase Storage.
- Seluruh aktivitas tetap menggunakan root collection Firestore.
- Field Firestore tetap `snake_case`.
- Role tetap `petugas` dan `supervisor`.

## Step 1 — Integrasi Pengambilan Sample

### Tujuan

Menyelesaikan wiring aktivitas Pengambilan Sample yang sebelumnya sudah mempunyai model/service/definition tetapi belum terintegrasi penuh.

### Perubahan

- `PengambilanSampleService` didaftarkan ke `ActivityServiceRegistry`.
- Firestore Rules ditambahkan untuk root collection `pengambilan_sample`.
- Permission mengikuti pola collection lain:
  - authenticated user dapat membaca,
  - hanya `petugas` dapat create/update/delete.
- Pembacaan gabungan aktivitas diberi proteksi terhadap `permission-denied` agar collection baru yang belum dideploy tidak menjatuhkan seluruh histori.

### Schema

Field spesifik:

- `darah`
- `serum`
- `ulas_darah`
- `swab`
- `feses`
- `keterangan`

## Step 2 — Laporan Pengambilan Sample

### Tujuan

Menyelesaikan export Pengambilan Sample berdasarkan field aktual.

### Implementasi

- PDF dan DOCX menggunakan field Sample aktual.
- Data ringkasan dan rincian histori tersedia pada export.
- Generator tidak boleh gagal hanya karena aset `logo_disbunnak.jpeg` pada project belum valid/kosong.
- Tidak mengambil logo pengganti sembarang dari luar project.

### Catatan aset

Pada baseline yang diaudit, `assets/templates/logo_disbunnak.jpeg` berukuran 0 byte. File logo resmi perlu diganti dengan aset valid bila logo tersebut diwajibkan pada output final.

## Step 3 — Sinkronisasi Penampungan Semen

### Kondisi source terbaru

Input terbaru menggunakan:

- `kolektor`
- `volume`
- `p_tp`
- `jumlah_straw_yang_dihasilkan`
- `keterangan`

Schema terbaru dipertahankan dan tidak dikembalikan ke field lama.

### Laporan

Report Penampungan Semen dibuat adaptif:

- record schema baru menggunakan informasi Kolektor, Volume, P/TP, Jumlah Straw, dan Paraf,
- record historis dengan AV, Vaselin, Suhu, dan Volume Semen tetap dapat diekspor.

Tujuannya menjaga histori lama tanpa mengorbankan schema terbaru.

## Step 4 — Laporan Pencegahan Ektoparasit

### Referensi

Format mengikuti referensi formulir kantor:

**FORMULIR PENCEGAHAN EKTOPARASIT**  
**WAKTU PELAKSANAAN: 3 BULAN SEKALI**

Metadata referensi:

- No Dok: `SOP-6.3 k`
- Revisi: `3`
- Tgl Berlaku: `1 April 2019`

Kolom:

- No
- Nama Bull
- Bangsa
- Bahan
- Alat
- Tindakan
- Keterangan

### Implementasi

- Pencegahan Ektoparasit ditambahkan sebagai sumber Laporan.
- Dibuat `PencegahanEktoparasitReportTemplateService` untuk PDF dan DOCX.
- Data dikelompokkan per tanggal pelaksanaan.
- Tidak ada perubahan schema Firestore atau CRUD aktivitas.

## Step 5 — Test dan konsistensi

### Masalah sebelumnya

`ActivityCatalog` sudah memiliki 12 aktivitas, tetapi `AppConstants.activityCollections` dan test lama masih mengacu pada 10 aktivitas.

### Perubahan

- `AppConstants.activityCollections` disinkronkan menjadi 12 collection.
- Test tidak hanya memeriksa jumlah, tetapi membandingkan daftar collection agar ketidaksesuaian lebih mudah terdeteksi.

### Kondisi konsisten

Daftar 12 aktivitas sekarang disinkronkan antara:

- `ActivityCatalog`
- `AppConstants.activityCollections`
- `ActivityServiceRegistry`
- halaman Laporan
- Firestore Rules

## Step 6 — Dokumentasi

Dokumentasi diperbarui agar kondisi aktual tidak bertentangan dengan README/schema lama:

- `README.md`
- `docs/FIRESTORE_SCHEMA.md`
- `docs/PROJECT_ANALYSIS.md`
- dokumen perubahan ini

Dokumen versi lama tetap dipertahankan sebagai histori dan tidak dianggap sebagai source of truth bila bertentangan dengan source terbaru.

## File aplikasi yang tidak sengaja diubah

Tidak ada redesign atau perubahan sengaja terhadap:

- Login
- Register
- Splash
- Dashboard
- Bull CRUD
- profil Bull
- navigation utama
- reminder yang sudah berjalan
- global theme
- Android native export

## Verifikasi yang diperlukan di environment development

Setelah seluruh patch diterapkan pada project utama, jalankan:

```bash
flutter pub get
flutter analyze
flutter test
```

Lalu uji Android dan Web bila environment tersedia.

Untuk perubahan Firestore Rules, deploy rules terbaru:

```bash
firebase deploy --only firestore:rules
```

Regression check minimal:

- Login/Register/Logout
- role Petugas/Supervisor
- Dashboard
- Bull CRUD dan search
- seluruh activity CRUD/histori
- Reminder
- Laporan PDF/DOCX
- Android document picker
- Web export
- Firestore permission
