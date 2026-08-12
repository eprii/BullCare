# Pembaruan BullCare V8 — Modern Green UI

## Tujuan

Pembaruan ini hanya mengubah lapisan UI/UX. Seluruh alur bisnis, role, service, model, collection Firestore, validasi CRUD, notifikasi, reminder bulanan, countdown sanitasi kandang, dan pencatatan nama petugas tetap menggunakan sistem yang sudah berjalan pada V7.

## Tampilan yang diperbarui

- Splash screen.
- Login dan registrasi.
- Bottom navigation.
- Dashboard.
- Daftar dan pencarian bull.
- Profil bull dan ringkasan kondisi terbaru.
- Form tambah dan edit bull.
- Daftar, filter kategori, dan timeline aktivitas.
- Pemilihan jenis aktivitas.
- Form dan detail aktivitas.
- Jadwal reminder dan countdown sanitasi kandang.
- Empty state, error state, loading state, snackbar, button, input, card, dan dialog.

## Karakter visual

- Warna utama hijau BullCare.
- Latar putih dan abu-abu sangat muda.
- Rounded corner konsisten.
- Kartu dengan border dan shadow lembut.
- Ikon outline dan solid yang konsisten.
- Whitespace lebih luas.
- Hierarki judul, label, nilai, dan status lebih jelas.
- Layout responsif dengan lebar konten maksimum untuk tampilan web.

## File baru

- `lib/widgets/app_page_container.dart`
- `lib/widgets/bull_visual.dart`
- `lib/widgets/section_header.dart`

## Catatan

Tidak ada perubahan pada Firestore Rules dan tidak diperlukan deploy ulang rules untuk pembaruan UI ini.
