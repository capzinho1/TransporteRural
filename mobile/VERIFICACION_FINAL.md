# ✅ Verificación Final - Configuración Google OAuth

## 🔐 Credenciales Configuradas

**Client ID:**
```
[CONFIGURAR EN .env.credentials]
```

**Client Secret:**
```
[CONFIGURAR EN .env.credentials]
```

## ✅ Checklist de Configuración

### Google Cloud Console
- [x] Cliente Web OAuth creado
- [x] Client ID obtenido
- [x] Client Secret obtenido
- [x] Authorized JavaScript origins: `https://aghbbmbbfcgtpipnrjev.supabase.co`
- [x] Authorized redirect URIs: `https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback`

### Supabase Dashboard
- [x] Google Provider habilitado
- [x] Client ID configurado
- [x] Client Secret configurado
- [ ] Redirect URLs configurados (verificar abajo)

### Base de Datos
- [ ] Migración SQL ejecutada (verificar abajo)

### Flutter App
- [x] Supabase inicializado en `main.dart`
- [x] `AuthService` implementado
- [x] Pantallas de login y registro creadas

## 🔍 Verificaciones Adicionales

### 1. Verificar Redirect URLs en Supabase

En Supabase Dashboard → Authentication → URL Configuration:

**Para desarrollo web (localhost con puerto dinámico):**
- Agrega: `http://localhost:*/**` (acepta cualquier puerto)
- O específicamente: `http://localhost:53712/**`, `http://localhost:59548/**`, etc.
- **Importante:** El código usa `Uri.base.origin` que detecta automáticamente el puerto actual

**Para producción:**
- Debe tener: `https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback`

**Para móvil (deep links):**
- Opcional: `com.transporterural://login-callback`

### 2. Ejecutar Migración SQL

Si aún no lo has hecho, ejecuta en Supabase SQL Editor:
```sql
-- Archivo: database/migration_add_passenger_auth.sql
```

Esta migración agrega los campos:
- `auth_provider` (VARCHAR)
- `supabase_auth_id` (UUID)
- `region` (VARCHAR)

### 3. Probar la Autenticación

1. Ejecuta la app: `flutter run`
2. Ve a la pantalla de login
3. Haz clic en "Continuar con Google"
4. Deberías ser redirigido a Google para autenticación
5. Después de autenticarte, deberías volver a la app

## 🐛 Solución de Problemas

### Si el redirect no funciona:
- Verifica que las URLs en Google Cloud Console coincidan exactamente
- Verifica que las URLs en Supabase estén configuradas
- Asegúrate de que el Client ID y Secret en Supabase sean del cliente Web (no del Android)

### Si hay error de "redirect_uri_mismatch":
- Verifica que la URL en Supabase sea exactamente: `https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback`
- No debe tener trailing slash ni caracteres extra

### Si la autenticación funciona pero no crea el usuario:
- Verifica que la migración SQL se haya ejecutado
- Verifica que el endpoint `/api/usuarios/sync-supabase` esté funcionando
- Revisa los logs del backend

## 📝 Próximos Pasos

1. Ejecutar migración SQL si no lo has hecho
2. Probar autenticación con Google
3. Probar registro con email/password
4. Verificar que los usuarios se creen correctamente en la BD

