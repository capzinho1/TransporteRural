# 🔐 Flujo Completo de OAuth con Google - Implementación

## ✅ Implementación Completada

Se ha implementado el flujo completo de autenticación con Google usando un proxy en el backend para controlar mejor el proceso.

## 🔄 Flujo Completo

### 1. **App Móvil** → **Backend Proxy**
- La app móvil llama a `/api/auth/oauth/google/authorize?platform=mobile&finalRedirectTo=com.georu.app://login-callback`
- El backend genera una URL OAuth de Supabase con el `redirectTo` configurado como el deep link de la app

### 2. **App Móvil** → **Navegador**
- La app móvil abre la URL OAuth en el navegador del dispositivo usando `url_launcher`

### 3. **Usuario** → **Google**
- El usuario autentica con su cuenta de Google en el navegador

### 4. **Google** → **Supabase Callback**
- Google redirige a `https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback` con el código de autorización

### 5. **Supabase** → **App Móvil (Deep Link)**
- Supabase procesa el callback de Google
- Supabase intercambia el código por tokens
- Supabase redirige al deep link configurado: `com.georu.app://login-callback?access_token=...&refresh_token=...`

### 6. **App Móvil**
- La app captura el deep link
- La app procesa la sesión y autentica al usuario

## 📝 Archivos Modificados

### Backend
- ✅ `backend/src/routes/auth.js`
  - Endpoint `/api/auth/oauth/google/authorize` - Genera URL OAuth
  - Endpoint `/api/auth/oauth/google/callback` - Maneja callback (no se usa en el flujo actual)

### Móvil
- ✅ `mobile/pubspec.yaml` - Agregado `url_launcher: ^6.2.5`
- ✅ `mobile/lib/services/api_service.dart` - Agregado método `getGoogleOAuthUrl()`
- ✅ `mobile/lib/services/auth_service.dart` - Modificado para usar proxy del backend en móvil

## ⚙️ Configuración Necesaria

### 1. Supabase Dashboard

Ve a **Authentication** → **URL Configuration**:

- **Site URL**: 
  ```
  https://aghbbmbbfcgtpipnrjev.supabase.co
  ```
  (Sin espacios, sin trailing slash)

- **Redirect URLs**: Debe incluir:
  ```
  https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback
  com.georu.app://login-callback
  ```

### 2. Google Cloud Console

Ve a **APIs & Services** → **Credentials** → Tu cliente OAuth Web:

- **Authorized JavaScript origins**:
  ```
  https://aghbbmbbfcgtpipnrjev.supabase.co
  ```

- **Authorized redirect URIs**:
  ```
  https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback
  ```
  ⚠️ **NO agregar** `com.georu.app://login-callback` aquí (Google no acepta deep links en redirect URIs)

### 3. AndroidManifest.xml (Ya configurado)

El deep link ya está configurado en:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.georu.app" />
</intent-filter>
```

## 🧪 Probar el Flujo

1. **Asegúrate de que el backend esté ejecutándose**:
   ```bash
   cd backend
   npm start
   ```

2. **Ejecuta la app móvil**:
   ```bash
   cd mobile
   flutter run
   ```

3. **En la app, toca "Continuar con Google"**

4. **Verifica los logs**:
   - Backend: Debe mostrar la generación de URL OAuth
   - Móvil: Debe mostrar la obtención de URL y la apertura del navegador

5. **Autentica con Google** en el navegador

6. **Verifica que la app capture el deep link** y autentique al usuario

## 🔍 Troubleshooting

### Si Google redirige a la raíz de Supabase (`/?code=...`)
- Verifica que el Site URL en Supabase Dashboard esté configurado correctamente (sin espacios)
- Verifica que las Redirect URLs incluyan el callback de Supabase

### Si la app no captura el deep link
- Verifica que AndroidManifest.xml tenga el intent-filter configurado
- Verifica que el package name sea `com.georu.app`
- Reinicia la app completamente después de instalar

### Si el backend no responde
- Verifica que el backend esté ejecutándose en el puerto 3000
- Verifica que la IP del backend en `mobile/lib/services/api_service.dart` sea correcta (`192.168.56.1`)

## 📋 Checklist Final

- [ ] Backend ejecutándose en puerto 3000
- [ ] Supabase Dashboard configurado correctamente (Site URL y Redirect URLs)
- [ ] Google Cloud Console configurado correctamente (JavaScript origins y Redirect URIs)
- [ ] AndroidManifest.xml tiene el deep link configurado
- [ ] App móvil tiene `url_launcher` instalado (`flutter pub get`)
- [ ] IP del backend correcta en `api_service.dart`

¡Listo para probar! 🚀

