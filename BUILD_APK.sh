#!/usr/bin/env bash
set -euo pipefail

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter belum tersedia di PATH." >&2
  exit 1
fi

flutter pub get
flutter analyze
flutter test
flutter build apk --release

echo "APK berhasil dibuat di build/app/outputs/flutter-apk/app-release.apk"
