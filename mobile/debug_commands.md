# Comandos de Depuración para TransporteRural

## 🚀 Ejecutar la App

### Web (Recomendado)
```bash
# Desarrollo con hot reload
flutter run -d chrome --web-port 8080

# Con modo debug
flutter run -d chrome --debug --web-port 8080

# Con modo release
flutter run -d chrome --release --web-port 8080
```

### Android (si tienes emulador)
```bash
# Listar dispositivos
flutter devices

# Ejecutar en Android
flutter run -d android

# Ejecutar en emulador específico
flutter run -d <device-id>
```

## 🔍 Comandos de Depuración

### Hot Reload
```bash
# Recargar cambios sin reiniciar
r

# Reiniciar completamente
R

# Salir
q
```

### Logs y Debugging
```bash
# Ver logs detallados
flutter run -d chrome --verbose

# Con profiling
flutter run -d chrome --profile

# Con análisis de rendimiento
flutter run -d chrome --trace-startup
```

## 🛠️ Herramientas de Debug

### Flutter Inspector
```bash
# Abrir inspector
flutter run -d chrome --debug
# Luego presiona 'i' en la consola
```

### Performance Overlay
```bash
# Mostrar overlay de rendimiento
flutter run -d chrome --show-performance-overlay
```

### Debug Paint
```bash
# Mostrar debug paint
flutter run -d chrome --debug-paint
```

## 📱 Dispositivos Disponibles

### Ver dispositivos conectados
```bash
flutter devices
```

### Web específico
```bash
# Chrome
flutter run -d chrome

# Edge
flutter run -d edge

# Safari (macOS)
flutter run -d safari
```

## 🐛 Debugging Específico

### Breakpoints en VS Code/Cursor
1. Abre `lib/main.dart`
2. Haz clic en el número de línea para agregar breakpoint
3. Presiona F5 para iniciar debug
4. Usa F10 (step over), F11 (step into), Shift+F11 (step out)

### Console Logs
```dart
// En tu código Dart
print('Debug: $variable');
debugPrint('Debug: $variable'); // Mejor para Flutter
```

### Network Debugging
```bash
# Ver requests HTTP
flutter run -d chrome --verbose
```

## 🔧 Configuración de Debug

### Variables de Entorno
```bash
# Para desarrollo
flutter run -d chrome --dart-define=ENVIRONMENT=development

# Para producción
flutter run -d chrome --dart-define=ENVIRONMENT=production
```

### Puertos Personalizados
```bash
# Backend en puerto 3000, Flutter en 8080
flutter run -d chrome --web-port 8080
```

## 📊 Análisis de Rendimiento

### Timeline
```bash
# Capturar timeline
flutter run -d chrome --trace-startup --verbose
```

### Memory
```bash
# Análisis de memoria
flutter run -d chrome --profile
```

## 🚨 Troubleshooting

### Limpiar cache
```bash
flutter clean
flutter pub get
```

### Reset Flutter
```bash
flutter doctor
flutter upgrade
```

### Problemas comunes
```bash
# Si no encuentra Chrome
flutter config --enable-web

# Si hay problemas de permisos
flutter run -d chrome --web-port 8080 --web-browser-flag="--disable-web-security"
```
