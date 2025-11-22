# 🚀 Despliegue del Panel Administrativo en Vercel

## 📋 Requisitos Previos

- [ ] Cuenta en Vercel (gratis): https://vercel.com
- [ ] Proyecto conectado a GitHub (recomendado)
- [ ] Backend API desplegado y funcionando
- [ ] Flutter SDK instalado localmente

---

## 🔧 Paso 1: Configurar la URL del Backend

Antes de desplegar, necesitas actualizar la URL del backend en el código del admin.

### Archivo a modificar: `admin_web/lib/services/admin_api_service.dart`

**Línea 13** actualmente tiene:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

**Cambiar a** (usando tu dominio de backend):
```dart
static const String baseUrl = 'https://api.georu.cl/api';  // O tu dominio real
```

**⚠️ IMPORTANTE**: 
- Usa `https://` (no `http://`)
- No uses `localhost` en producción
- Asegúrate de que el backend tenga CORS configurado para permitir requests desde Vercel

---

## 🔧 Paso 2: Configurar CORS en el Backend

En tu backend (`backend/src/server.js` o donde configures CORS), asegúrate de incluir el dominio de Vercel:

```javascript
const cors = require('cors');

app.use(cors({
  origin: [
    'https://tu-proyecto.vercel.app',  // URL de Vercel
    'https://admin.georu.cl',            // Si tienes dominio personalizado
    // ... otros orígenes permitidos
  ],
  credentials: true
}));
```

---

## 🏗️ Paso 3: Build Local del Proyecto Flutter

Antes de desplegar en Vercel, necesitas hacer el build de Flutter:

```bash
cd admin_web
flutter clean
flutter pub get
flutter build web --release
```

Esto generará los archivos en `admin_web/build/web/`

---

## 📦 Paso 4: Configurar Vercel

### Opción A: Despliegue desde GitHub (Recomendado)

1. **Conectar repositorio a Vercel:**
   - Ve a https://vercel.com
   - Haz clic en "Add New Project"
   - Conecta tu repositorio de GitHub
   - Selecciona el repositorio `TransporteRural`

2. **Configurar el proyecto:**
   - **Framework Preset**: Otro (o "Other")
   - **Root Directory**: `admin_web`
   - **Build Command**: `flutter build web --release`
   - **Output Directory**: `build/web`
   - **Install Command**: `flutter pub get`

3. **Variables de entorno** (si las necesitas):
   - En la configuración del proyecto, ve a "Environment Variables"
   - Agrega variables si tu app las necesita (normalmente no necesitas ninguna para Flutter web)

4. **Desplegar:**
   - Haz clic en "Deploy"
   - Vercel construirá y desplegará automáticamente

### Opción B: Despliegue Manual (CLI)

1. **Instalar Vercel CLI:**
```bash
npm install -g vercel
```

2. **Login en Vercel:**
```bash
vercel login
```

3. **Navegar al directorio del admin:**
```bash
cd admin_web
```

4. **Desplegar:**
```bash
# Primera vez (configuración interactiva)
vercel

# Despliegues siguientes
vercel --prod
```

**Nota**: Con Flutter, necesitas hacer el build primero y luego desplegar la carpeta `build/web`:

```bash
# Build primero
flutter build web --release

# Luego desplegar la carpeta build/web
cd build/web
vercel --prod
```

---

## ⚙️ Paso 5: Configuración de Vercel (vercel.json)

Crea un archivo `vercel.json` en la raíz de `admin_web/`:

```json
{
  "version": 2,
  "buildCommand": "flutter build web --release",
  "outputDirectory": "build/web",
  "installCommand": "flutter pub get",
  "framework": null,
  "rewrites": [
    {
      "source": "/(.*)",
      "destination": "/index.html"
    }
  ],
  "headers": [
    {
      "source": "/(.*)",
      "headers": [
        {
          "key": "X-Content-Type-Options",
          "value": "nosniff"
        },
        {
          "key": "X-Frame-Options",
          "value": "DENY"
        },
        {
          "key": "X-XSS-Protection",
          "value": "1; mode=block"
        }
      ]
    }
  ]
}
```

**⚠️ IMPORTANTE**: Vercel no tiene soporte nativo para Flutter. Necesitas hacer el build localmente y desplegar los archivos estáticos.

---

## 🔄 Paso 6: Despliegue Automático (CI/CD)

### Usando GitHub Actions (Recomendado)

Crea `.github/workflows/deploy-admin-vercel.yml`:

```yaml
name: Deploy Admin to Vercel

on:
  push:
    branches:
      - main
    paths:
      - 'admin_web/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
          channel: 'stable'
      
      - name: Install dependencies
        run: |
          cd admin_web
          flutter pub get
      
      - name: Build Flutter Web
        run: |
          cd admin_web
          flutter build web --release
      
      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
          working-directory: admin_web/build/web
```

**Configurar secrets en GitHub:**
1. Ve a Settings → Secrets → Actions
2. Agrega:
   - `VERCEL_TOKEN`: Token de Vercel (obtener en Vercel Dashboard → Settings → Tokens)
   - `VERCEL_ORG_ID`: ID de tu organización (en la URL de Vercel)
   - `VERCEL_PROJECT_ID`: ID del proyecto (en Settings del proyecto)

---

## 🌐 Paso 7: Dominio Personalizado (Opcional)

1. **En Vercel Dashboard:**
   - Ve a tu proyecto
   - Settings → Domains
   - Agrega tu dominio (ej: `admin.georu.cl`)

2. **Configurar DNS:**
   - Agrega un registro CNAME en tu proveedor de DNS:
     ```
     Tipo: CNAME
     Nombre: admin (o @)
     Valor: cname.vercel-dns.com
     ```

3. **Esperar propagación DNS** (puede tardar hasta 24 horas)

---

## ✅ Paso 8: Verificar el Despliegue

1. **Probar la URL:**
   - Abre `https://tu-proyecto.vercel.app`
   - Verifica que la app carga correctamente

2. **Probar funcionalidades:**
   - [ ] Login funciona
   - [ ] Dashboard carga datos
   - [ ] API calls funcionan (verificar en DevTools → Network)
   - [ ] No hay errores de CORS

3. **Verificar en diferentes navegadores:**
   - Chrome
   - Firefox
   - Safari
   - Edge

---

## 🐛 Solución de Problemas

### Error: "Flutter command not found"
**Solución**: Vercel no tiene Flutter instalado. Necesitas hacer el build localmente y desplegar solo los archivos estáticos.

### Error: CORS
**Solución**: 
1. Verificar que el backend tenga CORS configurado para el dominio de Vercel
2. Verificar que uses `https://` en las URLs

### Error: "Cannot GET /ruta"
**Solución**: Flutter Web usa routing del lado del cliente. Asegúrate de que `vercel.json` tenga el rewrite configurado para redirigir todas las rutas a `index.html`.

### Build falla en Vercel
**Solución**: 
- Usa GitHub Actions para hacer el build
- O haz el build localmente y despliega solo `build/web`

### La app carga pero no se conecta al backend
**Solución**:
1. Verificar que la URL del backend en `admin_api_service.dart` sea correcta
2. Verificar que el backend esté desplegado y funcionando
3. Verificar CORS en el backend
4. Abrir DevTools → Network y ver qué errores aparecen

---

## 📊 Monitoreo

### Vercel Analytics (Opcional)
- Ve a tu proyecto en Vercel
- Habilita Analytics (gratis en plan Hobby)
- Monitorea visitas, rendimiento, etc.

### Logs
- En Vercel Dashboard → Deployments
- Haz clic en un deployment para ver logs
- Útil para debugging

---

## 🔄 Actualizaciones Futuras

Cada vez que hagas cambios:

1. **Si usas GitHub Actions:**
   - Simplemente haz push a `main`
   - El workflow desplegará automáticamente

2. **Si despliegas manualmente:**
   ```bash
   cd admin_web
   flutter build web --release
   cd build/web
   vercel --prod
   ```

---

## 📝 Checklist Final

- [ ] URL del backend actualizada en `admin_api_service.dart`
- [ ] CORS configurado en el backend para Vercel
- [ ] Build de Flutter realizado (`flutter build web --release`)
- [ ] Proyecto desplegado en Vercel
- [ ] Dominio personalizado configurado (opcional)
- [ ] Login funciona correctamente
- [ ] API calls funcionan
- [ ] Sin errores de CORS
- [ ] Probado en diferentes navegadores

---

## 🎉 ¡Listo!

Tu panel administrativo debería estar funcionando en Vercel. 

**URL típica**: `https://tu-proyecto.vercel.app`

**Próximo paso**: Configurar el backend (si aún no está desplegado) y luego la app Android.

