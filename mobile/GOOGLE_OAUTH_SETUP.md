# 🔐 Configuración de Google OAuth para TransporteRural

## 📦 Nombre del Paquete (Package Name)

Para configurar Google OAuth, necesitas usar el siguiente **Package Name**:

```
com.transporterural
```

## 🔧 Pasos para Configurar Google OAuth

### 1. Crear ID de Cliente OAuth en Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto (o crea uno nuevo)
3. Ve a **APIs & Services** → **Credentials**
4. Clic en **+ CREATE CREDENTIALS** → **OAuth client ID**
5. Si es la primera vez, configura la pantalla de consentimiento OAuth
6. Selecciona **Application type**: **Android**
7. Ingresa:
   - **Name**: TransporteRural Android
   - **Package name**: `com.transporterural`
   - **SHA-1 certificate fingerprint**: (ver instrucciones abajo)

### 2. Obtener SHA-1 Certificate Fingerprint

**Para desarrollo (debug):**
```bash
cd mobile/android
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

**Para Windows:**
```bash
cd mobile\android
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copia el **SHA-1** (formato: `AA:BB:CC:DD:...`)

### 3. Configurar en Supabase

1. Ve a tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard)
2. Ve a **Authentication** → **Providers**
3. Habilita **Google**
4. Ingresa:
   - **Client ID (for OAuth)**: El Client ID que obtuviste de Google Cloud Console
   - **Client Secret (for OAuth)**: El Client Secret que obtuviste de Google Cloud Console
5. En **Redirect URLs**, agrega:
   - `com.transporterural://login-callback`
   - `https://[tu-proyecto].supabase.co/auth/v1/callback`

### 4. Configurar Package Name en Flutter (si no está configurado)

Si el package name no está configurado, necesitas crear/actualizar `mobile/android/app/build.gradle`:

```gradle
android {
    namespace "com.transporterural"
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.transporterural"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    // ... resto de la configuración
}
```

## 📝 Notas Importantes

- El package name debe ser **exactamente igual** en:
  - Google Cloud Console (OAuth Client ID)
  - `build.gradle` (applicationId)
  - Supabase (Redirect URL)
  
- Para iOS, el Bundle ID sería: `com.transporterural`

- El SHA-1 es necesario para que Google valide que la app es legítima

## ✅ Verificación

Después de configurar todo:
1. Ejecuta la app: `flutter run`
2. Intenta iniciar sesión con Google
3. Deberías ser redirigido a Google para autenticación
4. Después de autenticarte, deberías volver a la app

