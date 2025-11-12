# 🔐 Configuración de Google OAuth en Supabase

## 📋 Información de tu Cliente OAuth

**Client ID (installed):**
```
[CONFIGURAR EN .env.credentials]
```

**Project ID:**
```
supabase-auth-478005
```

## ⚠️ Importante: Tipo de Cliente OAuth

Tienes un cliente de tipo **"installed"** (aplicación instalada), que es correcto para Android, pero **Supabase requiere un cliente de tipo "Web application"** que tenga un **Client Secret**.

## 🔧 Solución: Crear Cliente Web Adicional

Necesitas crear **un segundo cliente OAuth** en Google Cloud Console:

### Pasos:

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto: `supabase-auth-478005`
3. Ve a **APIs & Services** → **Credentials**
4. Clic en **+ CREATE CREDENTIALS** → **OAuth client ID**
5. Selecciona **Application type**: **Web application**
6. Configura:
   - **Name**: TransporteRural Web (para Supabase)
   - **Authorized JavaScript origins**: 
     - `https://aghbbmbbfcgtpipnrjev.supabase.co`
   - **Authorized redirect URIs**:
     - `https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback`
     - ⚠️ **NO agregues** `com.transporterural://login-callback` aquí (Google no lo acepta)
7. Clic en **CREATE**
8. **Copia el Client ID y Client Secret** (este es el que usarás en Supabase)

## 📝 Configuración en Supabase

1. Ve a tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard)
2. Ve a **Authentication** → **Providers**
3. Habilita **Google**
4. Ingresa:
   - **Client ID (for OAuth)**: El Client ID del cliente **Web** que acabas de crear
   - **Client Secret (for OAuth)**: El Client Secret del cliente **Web** que acabas de crear
5. Guarda los cambios

## ✅ Resumen

- **Cliente Android (installed)**: Ya lo tienes - se usa para la app móvil
- **Cliente Web**: Necesitas crearlo - se usa para Supabase Auth
- Ambos pueden coexistir en el mismo proyecto de Google Cloud

## 🔍 Verificación

Después de configurar:
1. En la app, intenta iniciar sesión con Google
2. Deberías ser redirigido a Google para autenticación
3. Después de autenticarte, deberías volver a la app

