@echo off
echo =======================================================
echo          LEARNOVA - MOBILE APK BUILD SCRIPT
echo =======================================================
echo.

where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo [!] Flutter SDK was not found in your system PATH.
    echo.
    echo To build the Android APK:
    echo 1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows/mobile
    echo 2. Extract it to C:\flutter and add C:\flutter\bin to your Environment PATH.
    echo 3. Install Android Studio with Command-line Tools and Android SDK.
    echo 4. Run this script again: build_apk.bat
    echo.
    echo Press any key to exit...
    pause >nul
    exit /b 1
)

echo [*] Flutter detected! Fetching dependencies...
cd /d "%~dp0"
call flutter pub get

echo.
echo [*] Building Android APK (Release mode)...
call flutter build apk --release

if %errorlevel% equ 0 (
    echo.
    echo =======================================================
    echo [SUCCESS] APK built successfully!
    echo Located at:
    echo %~dp0build\app\outputs\flutter-apk\app-release.apk
    echo =======================================================
) else (
    echo.
    echo [ERROR] Build failed. Please check Android SDK and licenses.
    echo Run: flutter doctor
)

pause
