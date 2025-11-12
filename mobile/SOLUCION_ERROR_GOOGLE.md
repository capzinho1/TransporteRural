# 🔧 Solución: Error "Unsupported provider: provider is not enabled"

## ❌ Error
```
{"code":400,"error_code":"validation_failed","msg":"Unsupported provider: provider is not enabled"}
```

Este error significa que **Google OAuth no está habilitado** en Supabase.

## ✅ Solución Paso a Paso

### 1. Verificar que Google esté Habilitado en Supabase

1. Ve a [Supabase Dashboard](https://supabase.com/dashboard)
2. Selecciona tu proyecto
3. Ve a **Authentication** → **Providers**
4. Busca **Google** en la lista
5. **Asegúrate de que el toggle esté ACTIVADO** (debe estar en verde/azul)

### 2. Verificar Credenciales en Supabase

En la misma página de Providers → Google, verifica:

- **Client ID (for OAuth)**: 
  ```
  [CONFIGURAR EN .env.credentials]
  ```

- **Client Secret (for OAuth)**: 
  ```
  [CONFIGURAR EN .env.credentials]
  ```

- **Ambos campos deben estar completos** (no vacíos)

### 3. Guardar Cambios

1. Después de verificar/ingresar las credenciales
2. **Haz clic en "Save"** o "Guardar" (muy importante)
3. Espera a que se guarde correctamente

### 4. Verificar Redirect URLs

En Supabase Dashboard → **Authentication** → **URL Configuration**:

- Debe tener en **Redirect URLs**:
  ```
  https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback
  ```

### 5. Verificar en Google Cloud Console

En [Google Cloud Console](https://console.cloud.google.com/):

1. Ve a **APIs & Services** → **Credentials**
2. Selecciona tu cliente Web OAuth
3. Verifica que en **Authorized redirect URIs** tenga:
   ```
   https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback
   ```

## 🔍 Verificación Adicional

### Verificar que el Provider esté Activo

En Supabase Dashboard → Authentication → Providers, deberías ver:

- ✅ **Google** con un toggle **ACTIVADO** (verde/azul)
- ✅ Las credenciales configuradas
- ✅ Un mensaje de "Enabled" o "Habilitado"

### Si el Toggle está Desactivado

1. Activa el toggle de Google
2. Ingresa las credenciales si no están
3. **Guarda los cambios**
4. Espera unos segundos para que se apliquen

## 🐛 Problemas Comunes

### Problema 1: Toggle no se activa
- **Solución**: Refresca la página y vuelve a intentar
- Asegúrate de tener permisos de administrador en el proyecto

### Problema 2: Credenciales no se guardan
- **Solución**: Verifica que el Client ID y Secret sean correctos
- No debe haber espacios extra al copiar/pegar

### Problema 3: Error persiste después de guardar
- **Solución**: 
  1. Desactiva Google
  2. Guarda
  3. Espera 5 segundos
  4. Activa Google de nuevo
  5. Guarda
  6. Espera 5 segundos
  7. Prueba de nuevo

## ✅ Checklist Final

- [ ] Google está habilitado en Supabase (toggle activado)
- [ ] Client ID está configurado correctamente
- [ ] Client Secret está configurado correctamente
- [ ] Se guardaron los cambios en Supabase
- [ ] Redirect URL está configurado en Google Cloud Console
- [ ] Redirect URL está configurado en Supabase

## 📝 Después de Verificar

1. Cierra completamente la app Flutter
2. Vuelve a ejecutar: `flutter run`
3. Intenta iniciar sesión con Google de nuevo

