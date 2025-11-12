# 🔧 Solución Error 500 en OAuth de Supabase

## ❌ Problema

Error 500 al intentar autenticarse con Google:
```
{"code":500,"error_code":"unexpected_failure","msg":"Unexpected failure, please check server logs for more information"}
```

El error ocurre en:
```
GET https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback?... 500 (Internal Server Error)
```

## 🔍 Causa

El problema es que **Supabase NO acepta wildcards (`*`) en las Redirect URLs**. 

Cuando usas `http://localhost:*/**` en la configuración de Supabase, el JWT que se genera incluye esta URL con wildcards, y Supabase no puede procesarla correctamente.

## ✅ Solución

### Opción 1: Usar el puerto exacto (Recomendado)

1. **Ejecuta la app y anota el puerto:**
   ```bash
   flutter run -d chrome
   ```
   Verás algo como: `http://localhost:53712`

2. **Agrega esa URL exacta en Supabase:**
   - Ve a Supabase Dashboard → Authentication → URL Configuration
   - Agrega: `http://localhost:53712/**`
   - (Reemplaza `53712` con el puerto que veas)

3. **Si el puerto cambia, agrega el nuevo:**
   - Cada vez que el puerto cambie, agrega la nueva URL
   - O usa la Opción 2

### Opción 2: Usar un puerto fijo (Mejor para desarrollo)

1. **Ejecuta siempre con el mismo puerto:**
   ```bash
   flutter run -d chrome --web-port 8080
   ```

2. **Agrega en Supabase:**
   - `http://localhost:8080/**`

3. **Ventaja:** No necesitas cambiar la configuración cada vez

### Opción 3: Usar ngrok o similar (Para testing)

1. **Instala ngrok:**
   ```bash
   # Windows (con Chocolatey)
   choco install ngrok
   
   # O descarga de https://ngrok.com/
   ```

2. **Ejecuta ngrok:**
   ```bash
   ngrok http 8080
   ```

3. **Usa la URL de ngrok en Supabase:**
   - Ejemplo: `https://abc123.ngrok.io/**`
   - Esta URL es estable y no cambia

## 🔧 Verificación

1. **Verifica que la URL NO tenga wildcards:**
   - ❌ `http://localhost:*/**` (NO funciona)
   - ✅ `http://localhost:53712/**` (Funciona)
   - ✅ `http://localhost:8080/**` (Funciona)

2. **Verifica en los logs:**
   ```
   🌐 [AUTH_SERVICE] Redirect URL para web: http://localhost:53712/
   ```
   Esta URL debe coincidir EXACTAMENTE con una de las URLs en Supabase (sin el trailing slash final).

## 📝 Notas Importantes

- **Supabase procesa el redirect URL antes de redirigir**, por eso no acepta wildcards
- **El código ya detecta automáticamente el puerto** usando `Uri.base.origin`
- **Solo necesitas agregar la URL exacta en Supabase**

## 🚀 Próximos Pasos

1. Ejecuta la app y anota el puerto
2. Agrega `http://localhost:PUERTO/**` en Supabase
3. Intenta autenticarte con Google nuevamente
4. Si funciona, considera usar un puerto fijo para desarrollo

