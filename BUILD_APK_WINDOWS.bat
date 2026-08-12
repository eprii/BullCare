@echo off
setlocal
where flutter >nul 2>nul
if errorlevel 1 (
  echo Flutter belum tersedia di PATH.
  echo Pasang Flutter Stable terlebih dahulu, lalu jalankan file ini kembali.
  pause
  exit /b 1
)

call flutter pub get
if errorlevel 1 exit /b 1

call flutter analyze
if errorlevel 1 exit /b 1

call flutter test
if errorlevel 1 exit /b 1

call flutter build apk --release
if errorlevel 1 exit /b 1

echo.
echo APK berhasil dibuat di build\app\outputs\flutter-apk\app-release.apk
pause
