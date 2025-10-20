@echo off
echo 🚀 Iniciando TransporteRural en modo DEBUG...
echo.

echo 📋 Verificando Flutter Doctor...
flutter doctor

echo.
echo 🧹 Limpiando cache...
flutter clean
flutter pub get

echo.
echo 🌐 Iniciando app en Chrome con debug...
flutter run -d chrome --web-port 8080 --debug --verbose

pause
