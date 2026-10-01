@echo off
title Learnova Backend Server
color 0A

echo =================================================================
echo                 LEARNOVA DJANGO BACKEND SERVER
echo =================================================================
echo.

:: Show active Wi-Fi IPv4 address
echo Detecting your current Wi-Fi IPv4 address...
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4 Address"') do (
    set IP=%%a
)
echo.
echo =================================================================
echo  YOUR SERVER IP ADDRESS (Type this in the APK):
echo  http:%IP%:8000/api
echo =================================================================
echo.
echo Starting Django server on 0.0.0.0:8000 (accessible to phones on Wi-Fi)...
echo Keep this window open while using the mobile app!
echo To stop the server, press Ctrl + C.
echo.

cd /d "%~dp0backend"

if exist "venv\Scripts\activate.bat" (
    call venv\Scripts\activate.bat
    python manage.py runserver 0.0.0.0:8000
) else (
    python manage.py runserver 0.0.0.0:8000
)

pause
