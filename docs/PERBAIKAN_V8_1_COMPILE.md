# Perbaikan V8.1 — Compile Chrome

Perbaikan dilakukan pada lima halaman yang menggunakan `const AppBar(...)`.
Pada versi Flutter yang digunakan pengguna, konstruktor `AppBar` bukan konstruktor const.

Perubahan:

- `appBar: const AppBar(title: Text(...))`
- menjadi `appBar: AppBar(title: const Text(...))`

File yang diperbarui:

- `lib/pages/auth/register_page.dart`
- `lib/pages/activities/activity_list_page.dart`
- `lib/pages/activities/activity_detail_page.dart`
- `lib/pages/activities/activity_type_page.dart`
- `lib/pages/reminders/reminder_page.dart`

Tidak ada perubahan pada fitur, Firebase, Firestore, model, service, routing, atau alur aplikasi.
