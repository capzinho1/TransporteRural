# 🔄 Guía Completa: Recrear Clientes OAuth de Google Cloud Console

## 📋 Resumen

Necesitas **DOS clientes OAuth** diferentes:
1. **Cliente Web** (para Supabase Auth)
2. **Cliente Android** (para la app móvil)

## 🗑️ Paso 1: Eliminar Clientes Existentes

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto (o créalo si no existe)
3. Ve a **APIs & Services** → **Credentials**
4. En la lista de **OAuth 2.0 Client IDs**, **ELIMINA** todos los clientes existentes:
   - Haz clic en el cliente que quieres eliminar
   - Haz clic en **DELETE** (o **ELIMINAR**)
   - Confirma la eliminación
5. Repite para todos los clientes OAuth existentes

## 🔧 Paso 2: Habilitar Google+ API (si es necesario)

1. Ve a **APIs & Services** → **Library** (o **Biblioteca**)
2. Busca "Google+ API" o "People API"
3. Si no está habilitada, haz clic en **ENABLE** (o **HABILITAR**)
4. Esto puede tardar unos minutos

## 🌐 Paso 3: Crear Cliente Web (para Supabase)

Este es el cliente que **Supabase usa** para autenticación OAuth.

### 3.1 Crear el Cliente

1. Ve a **APIs & Services** → **Credentials**
2. Haz clic en **+ CREATE CREDENTIALS** (o **+ CREAR CREDENCIALES**)
3. Selecciona **OAuth client ID**
4. Si es la primera vez, te pedirá configurar la **OAuth consent screen**:
   - Selecciona **External** (o **Externo**)
   - Haz clic en **CREATE**
   - Completa:
     - **App name**: `GeoRu` (o el nombre que prefieras)
     - **User support email**: Tu email
     - **Developer contact information**: Tu email
   - Haz clic en **SAVE AND CONTINUE**
   - En **Scopes**, haz clic en **SAVE AND CONTINUE** (sin cambios)
   - En **Test users**, haz clic en **SAVE AND CONTINUE** (sin cambios)
   - Haz clic en **BACK TO DASHBOARD**

### 3.2 Configurar el Cliente Web

1. En **Application type**, selecciona **Web application**
2. Completa:
   - **Name**: `GeoRu Web (Supabase)`
   
3. En **Authorized JavaScript origins**, haz clic en **+ ADD URI** y agrega:
   ```
   https://aghbbmbbfcgtpipnrjev.supabase.co
   ```
   ⚠️ **IMPORTANTE**: Sin trailing slash (`/`), sin espacios

4. En **Authorized redirect URIs**, haz clic en **+ ADD URI** y agrega **SOLO**:
   ```
   https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback
   ```
   ⚠️ **IMPORTANTE**: 
   - Sin trailing slash (`/`)
   - Sin espacios
   - **NO agregar** el deep link de la app aquí

5. Haz clic en **CREATE** (o **CREAR**)

### 3.3 Guardar Credenciales del Cliente Web

Una vez creado, verás:
- **Your Client ID**: `XXXXX-XXXXX.apps.googleusercontent.com`
- **Your Client Secret**: `GOCSPX-XXXXX`

📝 **COPIA ESTAS CREDENCIALES**:
- Client ID: `_________________________`
- Client Secret: `_________________________`

## 📱 Paso 4: Crear Cliente Android (para la App Móvil)

Este es el cliente que la **app móvil usa** para autenticación OAuth.

### 4.1 Obtener SHA-1 Certificate Fingerprint

Primero necesitas obtener el SHA-1 del certificado de debug de Android:

**En Windows (PowerShell)**:
```powershell
cd C:\Users\lalol\Desktop\ProyectoDeTitulo\mobile\android
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

**O en CMD**:
```cmd
cd C:\Users\lalol\Desktop\ProyectoDeTitulo\mobile\android
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Busca la línea que dice **SHA1**:
```
SHA1: AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD
```

📝 **COPIA EL SHA-1** (sin espacios, con dos puntos `:`):
```
_________________________
```

### 4.2 Crear el Cliente Android

1. Ve a **APIs & Services** → **Credentials**
2. Haz clic en **+ CREATE CREDENTIALS** (o **+ CREAR CREDENCIALES**)
3. Selecciona **OAuth client ID**
4. En **Application type**, selecciona **Android**
5. Completa:
   - **Name**: `GeoRu Android`
   - **Package name**: `com.georu.app`
     ⚠️ **IMPORTANTE**: Debe coincidir exactamente con el package name de la app
   - **SHA-1 certificate fingerprint**: Pega el SHA-1 que copiaste arriba
     ⚠️ **IMPORTANTE**: Con formato `AA:BB:CC:DD:...`

6. Haz clic en **CREATE** (o **CREAR**)

### 4.3 Guardar Credenciales del Cliente Android

Una vez creado, verás:
- **Your Client ID**: `XXXXX-XXXXX.apps.googleusercontent.com`

📝 **COPIA EL CLIENT ID**:
```
_________________________
```

⚠️ **Nota**: El cliente Android NO tiene Client Secret (es normal)

## 📝 Paso 5: Actualizar Credenciales en Supabase

1. Ve a [Supabase Dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto
3. Ve a **Authentication** → **Providers**
4. Haz clic en **Google**
5. Actualiza con las credenciales del **Cliente Web**:
   - **Client ID (for OAuth)**: Pega el Client ID del Cliente Web
   - **Client Secret (for OAuth)**: Pega el Client Secret del Cliente Web
6. Haz clic en **SAVE** (o **GUARDAR**)
7. Asegúrate de que el **toggle esté ACTIVADO** (verde/azul)

## 🔧 Paso 6: Verificar Configuración en Supabase Dashboard

1. Ve a **Authentication** → **URL Configuration**
2. Verifica que **Site URL** sea:
   ```
   https://aghbbmbbfcgtpipnrjev.supabase.co
   ```
   ⚠️ **IMPORTANTE**: 
   - Sin espacios
   - Sin trailing slash (`/`)
   - Copia y pega exactamente

3. En **Redirect URLs**, asegúrate de tener **EXACTAMENTE**:
   ```
   https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback
   com.georu.app://login-callback
   ```
   ⚠️ **IMPORTANTE**: 
   - Una URL por línea
   - Sin espacios
   - Sin trailing slash (`/`)
   - El deep link debe ser exactamente `com.georu.app://login-callback`

4. Haz clic en **SAVE** (o **GUARDAR**)

## ✅ Paso 7: Verificar Configuración en Google Cloud Console

### Cliente Web

1. Ve a **APIs & Services** → **Credentials**
2. Haz clic en tu **Cliente Web** (`GeoRu Web (Supabase)`)
3. Verifica:
   - **Authorized JavaScript origins**: 
     - ✅ `https://aghbbmbbfcgtpipnrjev.supabase.co`
   - **Authorized redirect URIs**: 
     - ✅ `https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback`
     - ❌ NO debe tener `com.georu.app://login-callback`

### Cliente Android

1. Ve a **APIs & Services** → **Credentials**
2. Haz clic en tu **Cliente Android** (`GeoRu Android`)
3. Verifica:
   - **Package name**: ✅ `com.georu.app`
   - **SHA-1 certificate fingerprint**: ✅ El SHA-1 que copiaste

## 🧪 Paso 8: Probar la Autenticación

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

3. **En la app, presiona "Continuar con Google"**

4. **Verifica los logs**:
   - Backend: Debe mostrar la generación de URL OAuth
   - Móvil: Debe mostrar la obtención de URL y la apertura del navegador

5. **Autentica con Google** en el navegador

6. **Verifica que la app capture el deep link** y autentique al usuario

## 🔍 Troubleshooting

### Si Google redirige a la raíz de Supabase (`/?code=...`)

1. Verifica que el **Site URL** en Supabase Dashboard esté configurado correctamente (sin espacios)
2. Verifica que las **Redirect URLs** incluyan el callback de Supabase
3. Verifica que el **Cliente Web** en Google Cloud Console tenga el redirect URI correcto
4. **Espera 5-10 minutos** después de hacer cambios (pueden tardar en propagarse)

### Si la app no captura el deep link

1. Verifica que `AndroidManifest.xml` tenga el intent-filter configurado
2. Verifica que el package name sea `com.georu.app`
3. **Reinicia la app completamente** después de instalar
4. **Desinstala y reinstala** la app si es necesario

### Si el SHA-1 no coincide

1. Verifica que estés usando el keystore correcto:
   - Debug: `~/.android/debug.keystore`
   - Release: Tu keystore de release
2. Si cambiaste el keystore, actualiza el SHA-1 en Google Cloud Console

## 📋 Checklist Final

- [ ] Clientes OAuth antiguos eliminados
- [ ] Cliente Web creado con redirect URI correcto
- [ ] Cliente Android creado con SHA-1 correcto
- [ ] Credenciales del Cliente Web copiadas
- [ ] Credenciales actualizadas en Supabase Dashboard
- [ ] Site URL configurado en Supabase Dashboard
- [ ] Redirect URLs configuradas en Supabase Dashboard
- [ ] Google Provider habilitado en Supabase Dashboard
- [ ] Backend ejecutándose
- [ ] App móvil lista para probar

¡Listo para probar! 🚀

