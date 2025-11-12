# 🔧 Configuración de Redirect URLs para Localhost Dinámico

## 📋 Problema

En desarrollo, Flutter web asigna un puerto diferente cada vez que ejecutas la app:
- Primera ejecución: `http://localhost:53712`
- Segunda ejecución: `http://localhost:59548`
- Tercera ejecución: `http://localhost:62341`
- etc.

Esto puede causar problemas con OAuth porque Supabase necesita saber a qué URL redirigir después de la autenticación.

## ✅ Solución Implementada

El código ya está configurado para usar **dinámicamente** el puerto actual:

```dart
// En auth_service.dart
String redirectUrl;
if (kIsWeb) {
  // Usa Uri.base.origin que incluye el puerto actual
  redirectUrl = '${Uri.base.origin}/';
  print('🌐 [AUTH_SERVICE] Redirect URL para web: $redirectUrl');
}
```

Esto significa que **automáticamente** detecta el puerto actual y lo usa en el redirect.

## 🔧 Configuración en Supabase

### Opción 1: Wildcard (Recomendado para desarrollo)

En Supabase Dashboard → Authentication → URL Configuration, agrega:

```
http://localhost:*/**
```

Esto acepta **cualquier puerto** de localhost.

### Opción 2: Múltiples puertos específicos

Si el wildcard no funciona, agrega cada puerto que uses:

```
http://localhost:53712/**
http://localhost:59548/**
http://localhost:62341/**
http://localhost:8080/**
```

### Opción 3: Solo el puerto por defecto

Si siempre usas el mismo puerto (por ejemplo, con `--web-port 8080`):

```
http://localhost:8080/**
```

## 🚀 Cómo Ejecutar con Puerto Fijo

Si quieres usar siempre el mismo puerto:

```bash
# Windows
flutter run -d chrome --web-port 8080

# Linux/Mac
flutter run -d chrome --web-port 8080
```

Luego en Supabase, agrega solo:
```
http://localhost:8080/**
```

## 📝 Verificación

1. Ejecuta la app: `flutter run -d chrome`
2. Abre la consola del navegador (F12)
3. Haz clic en "Continuar con Google"
4. Deberías ver en los logs: `🌐 [AUTH_SERVICE] Redirect URL para web: http://localhost:XXXXX/`
5. Verifica que esa URL esté en Supabase (o usa el wildcard)

## ⚠️ Notas Importantes

- **Para producción:** Usa tu dominio real, no localhost
- **Para desarrollo:** El wildcard `http://localhost:*/**` es la opción más flexible
- **El código ya maneja esto automáticamente:** No necesitas cambiar nada en el código, solo configurar Supabase

## 🔍 Troubleshooting

### Error: "redirect_uri_mismatch"

**Causa:** La URL de redirect no está en la lista de Supabase.

**Solución:**
1. Verifica los logs: `🌐 [AUTH_SERVICE] Redirect URL para web: ...`
2. Copia esa URL exacta
3. Agrega esa URL (o el wildcard) en Supabase Dashboard

### El redirect no funciona

**Causa:** Puede ser un problema de CORS o configuración.

**Solución:**
1. Verifica que el redirect URL en Supabase tenga `/**` al final (wildcard)
2. Asegúrate de que la URL en los logs coincida con la configurada
3. Prueba con un puerto fijo primero para aislar el problema

