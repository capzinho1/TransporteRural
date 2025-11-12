# 📝 Guía Paso a Paso: Crear Cliente Web OAuth en Google Cloud Console

## 🎯 Objetivo
Crear un cliente OAuth de tipo "Web application" para usar con Supabase Auth.

## 📋 Pasos Detallados

### Paso 1: Acceder a Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Inicia sesión con tu cuenta de Google
3. Selecciona tu proyecto: **supabase-auth-478005**
   - Si no lo ves, búscalo en el selector de proyectos (arriba a la izquierda)

### Paso 2: Ir a Credenciales

1. En el menú lateral izquierdo, busca **"APIs & Services"**
2. Haz clic en **"Credentials"** (Credenciales)
3. Verás una lista de tus credenciales existentes

### Paso 3: Crear Nuevo Cliente OAuth

1. Haz clic en el botón **"+ CREATE CREDENTIALS"** (arriba)
2. Selecciona **"OAuth client ID"** del menú desplegable

### Paso 4: Configurar Pantalla de Consentimiento (si es la primera vez)

Si es la primera vez que creas un cliente OAuth, Google te pedirá configurar la pantalla de consentimiento:

1. Selecciona **"External"** (si no es para uso interno de tu organización)
2. Haz clic en **"CREATE"**
3. Completa la información:
   - **App name**: `TransporteRural`
   - **User support email**: Tu email
   - **Developer contact information**: Tu email
4. Haz clic en **"SAVE AND CONTINUE"**
5. En "Scopes", haz clic en **"SAVE AND CONTINUE"** (puedes usar los scopes por defecto)
6. En "Test users", agrega tu email si es necesario, luego **"SAVE AND CONTINUE"**
7. Revisa y haz clic en **"BACK TO DASHBOARD"**

### Paso 5: Crear el Cliente OAuth Web

1. Ahora deberías estar de vuelta en "Credentials"
2. Haz clic en **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
3. En **"Application type"**, selecciona: **"Web application"**
4. En **"Name"**, escribe: `TransporteRural Web (Supabase)`

### Paso 6: Configurar URIs

1. En **"Authorized JavaScript origins"**, haz clic en **"+ ADD URI"** y agrega:
   ```
   https://aghbbmbbfcgtpipnrjev.supabase.co
   ```

2. En **"Authorized redirect URIs"**, haz clic en **"+ ADD URI"** y agrega:
   ```
   https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback
   ```

### Paso 7: Crear y Copiar Credenciales

1. Haz clic en **"CREATE"**
2. **¡IMPORTANTE!** Se abrirá un popup con tus credenciales:
   - **Your Client ID**: Copia este valor (ejemplo: `388250008889-xxxxx.apps.googleusercontent.com`)
   - **Your Client Secret**: Copia este valor (ejemplo: `GOCSPX-xxxxxxxxxxxxx`)
3. **Guarda estas credenciales** - el Client Secret solo se muestra una vez
4. Haz clic en **"OK"**

## ✅ Verificación

Deberías ver en la lista de credenciales:
- Tu cliente Android (installed) - el que ya tenías
- Tu nuevo cliente Web (web application) - el que acabas de crear

## 📝 Siguiente Paso

Ahora que tienes el **Client ID** y **Client Secret** del cliente Web:

1. Ve a [Supabase Dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto
3. Ve a **Authentication** → **Providers**
4. Habilita **Google**
5. Pega:
   - **Client ID (for OAuth)**: El Client ID del cliente Web
   - **Client Secret (for OAuth)**: El Client Secret del cliente Web
6. Guarda los cambios

## ⚠️ Notas Importantes

- El **Client Secret** solo se muestra **una vez** al crear el cliente
- Si lo pierdes, tendrás que crear un nuevo cliente OAuth
- Guarda las credenciales en un lugar seguro
- El cliente Web es diferente del cliente Android - ambos pueden coexistir

