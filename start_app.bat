@echo off
echo Starting Fleet Management System...
echo.

echo Starting Python Backend...
start "Backend Server" cmd /k "python backend/main.py"

echo Waiting for backend to start...
timeout /t 5 /nobreak > nul

echo Starting Flutter Frontend...
start "Flutter App" cmd /k "flutter run -d windows"

echo.
echo Both services are starting...
echo Backend: http://127.0.0.1:8000
echo Frontend: Flutter Windows App
echo.
pause