# 🔄 Guía: Recrear Cliente Web OAuth en Google Cloud Console

## 📋 Paso a Paso Completo

### Paso 1: Eliminar el Cliente Web Actual

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona tu proyecto: **supabase-auth-478005**
3. Ve a **APIs & Services** → **Credentials**
4. Busca el cliente **"TransporteRural"** (tipo: Aplicación web)
5. Haz clic en el cliente para abrirlo
6. Haz clic en **DELETE** o **ELIMINAR** (arriba a la derecha)
7. Confirma la eliminación

### Paso 2: Crear Nuevo Cliente Web OAuth

1. En la misma página de **Credentials**, haz clic en **+ CREATE CREDENTIALS** → **OAuth client ID**
2. Si es la primera vez, te pedirá configurar la pantalla de consentimiento OAuth - completa eso primero
3. Selecciona **Application type**: **Web application**
4. Configura los siguientes campos:

   **Name:**
   ```
   TransporteRural Web (Supabase)
   ```

   **Authorized JavaScript origins:**
   ```
   https://aghbbmbbfcgtpipnrjev.supabase.co
   ```
   (Agrega exactamente esta URL, sin espacios, sin trailing slash)

   **Authorized redirect URIs:**
   ```
   https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback
   ```
   (Agrega exactamente esta URL, sin espacios, sin trailing slash)

5. Haz clic en **CREATE** o **CREAR**

### Paso 3: Copiar las Credenciales

Después de crear el cliente, verás:
- **Client ID**: Copia este valor
- **Client Secret**: Copia este valor (solo se muestra una vez)

**⚠️ IMPORTANTE**: Guarda el Client Secret de forma segura. Si lo pierdes, tendrás que crear uno nuevo.

### Paso 4: Actualizar en Supabase Dashboard

1. Ve a [Supabase Dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto
3. Ve a **Authentication** → **Providers**
4. Busca **Google** y haz clic en él
5. Actualiza los siguientes campos con las nuevas credenciales:

   **Client ID (for OAuth):**
   ```
   [Pega el nuevo Client ID aquí]
   ```

   **Client Secret (for OAuth):**
   ```
   [Pega el nuevo Client Secret aquí]
   ```

6. **IMPORTANTE**: Haz clic en **Save** o **Guardar**
7. Espera unos segundos para que se guarde

### Paso 5: Verificar Configuración de URLs en Supabase

1. En Supabase Dashboard, ve a **Authentication** → **URL Configuration**
2. Verifica **Site URL** (sin espacios al inicio ni al final):
   ```
   https://aghbbmbbfcgtpipnrjev.supabase.co
   ```
3. Verifica **Redirect URLs** (debe tener):
   ```
   https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback
   ```
   (Solo esta URL, sin espacios, sin wildcards)

### Paso 6: Esperar Propagación

- Los cambios en Google Cloud Console pueden tardar entre 5 minutos y algunas horas en aplicarse
- Los cambios en Supabase Dashboard deberían aplicarse inmediatamente

### Paso 7: Probar la Autenticación

1. Cierra completamente la app móvil si está abierta
2. Vuelve a abrir la app
3. Intenta registrarte/iniciar sesión con Google nuevamente
4. Verifica los logs en la consola para ver qué está pasando

## ✅ Checklist Final

- [ ] Cliente Web OAuth creado con nombre "TransporteRural Web (Supabase)"
- [ ] Authorized JavaScript origins: `https://aghbbmbbfcgtpipnrjev.supabase.co`
- [ ] Authorized redirect URIs: `https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback`
- [ ] Client ID copiado
- [ ] Client Secret copiado y guardado de forma segura
- [ ] Credenciales actualizadas en Supabase Dashboard
- [ ] Cambios guardados en Supabase Dashboard
- [ ] Site URL verificado en Supabase (sin espacios)
- [ ] Redirect URLs verificado en Supabase (solo el callback)
- [ ] Esperado tiempo de propagación (5 min - algunas horas)

## 🔍 Verificación Adicional

Si después de recrear todo el error persiste, verifica:

1. **En Google Cloud Console**:
   - ¿El Redirect URI es exactamente `https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback`?
   - ¿No hay espacios o caracteres adicionales?
   - ¿El Client ID y Secret coinciden con los de Supabase?

2. **En Supabase Dashboard**:
   - ¿El Site URL es exactamente `https://aghbbmbbfcgtpipnrjev.supabase.co` (sin espacios)?
   - ¿Las Redirect URLs solo tienen el callback?
   - ¿Google Provider está habilitado?

3. **En el código**:
   - El código ya está configurado para usar el callback de Supabase
   - No necesitas cambiar nada en el código

## 📝 Notas Importantes

- **NO** agregues el deep link (`com.georu.app://login-callback`) en Google Cloud Console - Google no acepta deep links allí
- **SÍ** puedes agregar el deep link en Supabase Dashboard → Redirect URLs si quieres, pero no es necesario - el SDK lo maneja automáticamente
- El cliente Android puede quedarse como está (no necesitas cambiarlo para que funcione el Web)
- Mantén ambos clientes (Android y Web) - ambos son necesarios
