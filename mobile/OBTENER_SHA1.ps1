# Script para obtener el SHA-1 del certificado de debug de Android
# Ejecutar: .\OBTENER_SHA1.ps1

Write-Host "🔍 Obteniendo SHA-1 del certificado de debug de Android..." -ForegroundColor Cyan
Write-Host ""

$keystorePath = "$env:USERPROFILE\.android\debug.keystore"
$alias = "androiddebugkey"
$storepass = "android"
$keypass = "android"

if (Test-Path $keystorePath) {
    Write-Host "✅ Keystore encontrado: $keystorePath" -ForegroundColor Green
    Write-Host ""
    
    $result = keytool -list -v -keystore $keystorePath -alias $alias -storepass $storepass -keypass $keypass 2>&1
    
    $sha1Line = $result | Select-String "SHA1"
    
    if ($sha1Line) {
        Write-Host "📋 SHA-1 Certificate Fingerprint:" -ForegroundColor Yellow
        Write-Host $sha1Line -ForegroundColor White
        Write-Host ""
        
        # Extraer solo el SHA-1 (formato AA:BB:CC:DD:...)
        $sha1 = ($sha1Line -split ":")[-1].Trim()
        Write-Host "✅ SHA-1 (para copiar):" -ForegroundColor Green
        Write-Host $sha1 -ForegroundColor White -BackgroundColor DarkGreen
        Write-Host ""
        Write-Host "📝 Copia este SHA-1 y úsalo al crear el Cliente Android en Google Cloud Console" -ForegroundColor Cyan
    } else {
        Write-Host "❌ No se pudo encontrar el SHA-1 en la salida" -ForegroundColor Red
        Write-Host ""
        Write-Host "Salida completa:" -ForegroundColor Yellow
        Write-Host $result
    }
} else {
    Write-Host "❌ No se encontró el keystore en: $keystorePath" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Si es la primera vez que usas Android, el keystore se creará automáticamente" -ForegroundColor Cyan
    Write-Host "   al ejecutar la app por primera vez." -ForegroundColor Cyan
}

Write-Host ""
Write-Host "Presiona cualquier tecla para continuar..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

