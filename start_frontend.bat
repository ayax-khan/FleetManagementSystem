@echo off
echo 📱 Starting Fleet Management System Frontend...
echo.

REM Clean and get dependencies
echo Getting Flutter dependencies...
flutter clean
flutter pub get

REM Run the Flutter application
echo.
echo ✅ Starting Flutter app...
echo 🌐 Make sure the backend is running on localhost:8000
echo.
flutter run -d windows

pause