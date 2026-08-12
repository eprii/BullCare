# Perbaikan V8.5 - Reminder Sanitasi Harian

Perubahan ini hanya mengubah mekanisme reminder sanitasi dan mempertahankan fitur BullCare lainnya.

## Sanitasi kandang
- Jadwal berubah menjadi setiap hari.
- Countdown maksimal satu hari menuju jadwal berikutnya.
- Setelah countdown selesai, jadwal otomatis bergeser ke hari berikutnya.
- Jam pelaksanaan mengikuti pengaturan reminder bull, default 08.00.

## Sanitasi tempat makan
- Menggunakan field Firestore yang sudah ada: `sanitasi_tempat_pakan`.
- Ditambahkan sebagai reminder harian tersendiri.
- Countdown maksimal satu hari dan otomatis berulang setiap hari.
- Menggunakan jam pelaksanaan yang sama dengan reminder sanitasi kandang, default 08.00.

## Pengaturan jam
Petugas dapat mengubah jam pelaksanaan dari kartu countdown. Perubahan jam berlaku untuk kedua reminder sanitasi harian pada bull tersebut dan disimpan pada dokumen `bulls` melalui field `sanitasi_reminder_hour` dan `sanitasi_reminder_minute`.

Sanitasi pejantan tidak dibuat sebagai reminder harian.
