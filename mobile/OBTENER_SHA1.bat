@echo off
REM Script para obtener el SHA-1 del certificado de debug de Android
REM Ejecutar: OBTENER_SHA1.bat

echo.
echo ========================================
echo Obteniendo SHA-1 del certificado
echo ========================================
echo.

set KEYSTORE_PATH=%USERPROFILE%\.android\debug.keystore
set ALIAS=androiddebugkey
set STOREPASS=android
set KEYPASS=android

if exist "%KEYSTORE_PATH%" (
    echo [OK] Keystore encontrado: %KEYSTORE_PATH%
    echo.
    
    keytool -list -v -keystore "%KEYSTORE_PATH%" -alias %ALIAS% -storepass %STOREPASS% -keypass %KEYPASS% | findstr "SHA1"
    
    echo.
    echo ========================================
    echo Copia el SHA-1 que aparece arriba
    echo (formato: AA:BB:CC:DD:EE:FF:...)
    echo ========================================
    echo.
) else (
    echo [ERROR] No se encontró el keystore en: %KEYSTORE_PATH%
    echo.
    echo Si es la primera vez que usas Android, el keystore
    echo se creará automáticamente al ejecutar la app.
    echo.
)

pause

