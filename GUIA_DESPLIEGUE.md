# 🚀 Guía Completa de Despliegue - GeoRu TransporteRural

## 📋 Índice
1. [Componentes a Desplegar](#componentes-a-desplegar)
2. [Requisitos Previos](#requisitos-previos)
3. [Configuraciones Necesarias](#configuraciones-necesarias)
4. [Opciones de Hosting](#opciones-de-hosting)
5. [Checklist Pre-Despliegue](#checklist-pre-despliegue)
6. [Consideraciones de Seguridad](#consideraciones-de-seguridad)
7. [Variables de Entorno](#variables-de-entorno)
8. [URLs y Dominios](#urls-y-dominios)
9. [Base de Datos](#base-de-datos)
10. [Autenticación OAuth](#autenticación-oauth)

---

## 🏗️ Componentes a Desplegar

Tu proyecto tiene **3 componentes principales** que necesitan ser desplegados:

### 1. **Backend API** (Node.js/Express)
- **Ubicación**: `backend/`
- **Puerto**: 3000 (desarrollo) / Variable en producción
- **Tecnologías**: Node.js 20, Express, Supabase Client
- **Funcionalidad**: API REST que maneja toda la lógica de negocio

### 2. **App Móvil (Flutter Web)** 
- **Ubicación**: `mobile/`
- **Puerto**: 8080 (desarrollo) / Variable en producción
- **Tecnologías**: Flutter 3.x, Dart
- **Funcionalidad**: Aplicación para pasajeros (ver buses, rutas, reportes)

### 3. **Panel Administrativo (Flutter Web)**
- **Ubicación**: `admin_web/`
- **Puerto**: 8081 (desarrollo) / Variable en producción
- **Tecnologías**: Flutter 3.x, Dart
- **Funcionalidad**: Dashboard para administradores y super administradores

### 4. **Base de Datos (Supabase)**
- **Tipo**: PostgreSQL con PostGIS (ya desplegado en Supabase Cloud)
- **Estado**: ✅ Ya configurado y funcionando
- **Nota**: No requiere despliegue adicional, solo verificar configuración

---

## ✅ Requisitos Previos

### Infraestructura
- [ ] **Dominio propio** (opcional pero recomendado, ej: `georu.cl` o `transporterural.com`)
- [ ] **Certificado SSL/HTTPS** (obligatorio para OAuth de Google)
- [ ] **Servidor/VPS** o servicio de hosting (ver opciones más abajo)
- [ ] **Cuenta de Supabase** (ya tienes una)

### Credenciales Necesarias
- [ ] **Supabase URL y Keys** (ya configuradas)
- [ ] **Google OAuth Client ID y Secret** (ya configurados)
- [ ] **JWT Secret** para el backend (generar uno seguro para producción)

### Conocimientos Técnicos
- [ ] Acceso SSH al servidor
- [ ] Conocimiento básico de Docker (opcional pero recomendado)
- [ ] Conocimiento de Nginx (para proxy reverso)
- [ ] Conocimiento de Git

---

## ⚙️ Configuraciones Necesarias

### 1. **Backend - Variables de Entorno**

Archivo: `backend/.env` (crear en producción)

```env
# Entorno
NODE_ENV=production
PORT=3000

# Supabase (ya tienes estos valores)
SUPABASE_URL=https://aghbbmbbfcgtpipnrjev.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aqui
SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key_aqui

# JWT Secret (GENERAR UNO NUEVO Y SEGURO)
JWT_SECRET=generar_un_secreto_muy_largo_y_aleatorio_aqui

# CORS - IMPORTANTE: Actualizar con tus dominios de producción
CORS_ORIGIN=https://app.georu.cl,https://admin.georu.cl,https://api.georu.cl
```

**⚠️ IMPORTANTE**: 
- El `JWT_SECRET` debe ser diferente en producción
- `CORS_ORIGIN` debe incluir TODOS los dominios donde estarán tus apps
- No usar `localhost` en producción

### 2. **App Móvil - Configuración de API**

Archivo: `mobile/lib/services/api_service.dart`

**Línea 12** actualmente tiene:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

**Debe cambiar a**:
```dart
static const String baseUrl = 'https://api.georu.cl/api';  // O tu dominio
```

### 3. **App Móvil - Configuración de Supabase**

Archivo: `mobile/lib/main.dart`

**Líneas 27-29** ya tienen las credenciales, pero verificar que sean correctas:
```dart
const supabaseUrl = 'https://aghbbmbbfcgtpipnrjev.supabase.co';
const supabaseAnonKey = 'tu_anon_key_aqui';
```

### 4. **Admin Web - Configuración de API**

Buscar archivo similar a `admin_web/lib/services/admin_api_service.dart` y actualizar la URL del backend.

---

## 🌐 Opciones de Hosting - DECISIÓN TOMADA

### ✅ **Panel Administrativo** → **Vercel**
- **Plataforma**: Vercel (https://vercel.com)
- **Costo**: Gratis (plan Hobby) o $20/mes (Pro)
- **Ventajas**: SSL automático, CDN global, despliegue automático desde GitHub
- **Guía específica**: Ver `DESPLIEGUE_VERCEL_ADMIN.md`

### ✅ **App Móvil** → **Android (APK/AAB)**
- **Plataforma**: Google Play Store
- **Costo**: $25 USD (pago único para cuenta de desarrollador)
- **Distribución**: Play Store (recomendado) o distribución directa (APK)
- **Guía específica**: Ver `DESPLIEGUE_ANDROID.md`

### ⚠️ **Backend API** → **PENDIENTE DE DECISIÓN**
Necesitas elegir dónde desplegar el backend. Opciones recomendadas:

#### Opción 1: **PaaS (Recomendado para empezar)**
- **Railway** (https://railway.app) - $5-20/mes, fácil configuración
- **Render** (https://render.com) - Gratis/Plan pago, similar a Heroku
- **Fly.io** (https://fly.io) - Pago por uso, buena para Node.js
- **Ventajas**: Configuración simple, SSL automático, menos mantenimiento

#### Opción 2: **VPS/Cloud Server**
- **DigitalOcean** ($6-12/mes)
- **Vultr** ($6-12/mes)
- **AWS EC2** (pago por uso)
- **Ventajas**: Control total, más económico a largo plazo
- **Desventajas**: Requiere más configuración manual

#### Opción 3: **Docker + Servicio de Contenedores**
- **AWS ECS/Fargate**
- **Google Cloud Run**
- **Azure Container Instances**

---

## 📋 Checklist Pre-Despliegue

### Seguridad
- [ ] Cambiar todas las credenciales de desarrollo por las de producción
- [ ] Generar nuevo `JWT_SECRET` seguro (mínimo 32 caracteres aleatorios)
- [ ] Verificar que `.env` esté en `.gitignore`
- [ ] Revisar que no haya credenciales hardcodeadas en el código
- [ ] Configurar CORS correctamente (solo dominios permitidos)
- [ ] Habilitar HTTPS/SSL en todos los servicios
- [ ] Configurar firewall del servidor (solo puertos necesarios)

### Base de Datos
- [ ] Verificar que todas las migraciones estén aplicadas en Supabase
- [ ] Hacer backup de la base de datos antes de desplegar
- [ ] Verificar que las credenciales de Supabase sean correctas
- [ ] Probar conexión desde el backend de producción

### Google OAuth
- [ ] Actualizar Redirect URIs en Google Cloud Console:
  - `https://app.georu.cl/` (o tu dominio)
  - `https://app.georu.cl/auth/callback`
  - `https://admin.georu.cl/` (si aplica)
- [ ] Verificar que Client ID y Secret sean correctos
- [ ] Probar flujo de autenticación completo

### Código
- [ ] Cambiar todas las URLs de `localhost` a dominios de producción
- [ ] Verificar que no haya `print()` o `console.log()` con información sensible
- [ ] Configurar modo producción en Flutter (`--release`)
- [ ] Optimizar builds (minificar, comprimir)
- [ ] Probar todas las funcionalidades en entorno de staging primero

### Testing
- [ ] Probar login/registro con email
- [ ] Probar login con Google OAuth
- [ ] Probar todas las funcionalidades principales
- [ ] Probar en diferentes navegadores
- [ ] Probar en dispositivos móviles
- [ ] Verificar que las notificaciones funcionen
- [ ] Probar carga de mapas y ubicaciones

### Monitoreo
- [ ] Configurar logs del servidor
- [ ] Configurar alertas de errores (opcional: Sentry, LogRocket)
- [ ] Configurar monitoreo de uptime (UptimeRobot, Pingdom)
- [ ] Configurar analytics (opcional: Google Analytics, Mixpanel)

---

## 🔒 Consideraciones de Seguridad

### 1. **Variables de Entorno**
- ✅ Nunca commitear `.env` a Git
- ✅ Usar diferentes credenciales en desarrollo y producción
- ✅ Rotar credenciales periódicamente
- ✅ Usar servicios de gestión de secretos (AWS Secrets Manager, HashiCorp Vault)

### 2. **HTTPS/SSL**
- ✅ **OBLIGATORIO** para OAuth de Google
- ✅ Usar certificados válidos (Let's Encrypt es gratis)
- ✅ Configurar redirección HTTP → HTTPS
- ✅ Usar HSTS headers

### 3. **CORS**
- ✅ Configurar solo dominios permitidos
- ✅ No usar `*` (wildcard) en producción
- ✅ Incluir protocolo completo (`https://`)

### 4. **Rate Limiting**
- ⚠️ Considerar implementar rate limiting en el backend
- ⚠️ Proteger endpoints de autenticación
- ⚠️ Limitar requests por IP

### 5. **Backups**
- ✅ Configurar backups automáticos de base de datos
- ✅ Backup de código (Git ya lo hace)
- ✅ Plan de recuperación ante desastres

---

## 🔑 Variables de Entorno Detalladas

### Backend (`backend/.env`)

```env
# ============================================
# ENTORNO
# ============================================
NODE_ENV=production
PORT=3000

# ============================================
# SUPABASE
# ============================================
SUPABASE_URL=https://aghbbmbbfcgtpipnrjev.supabase.co
SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# ============================================
# JWT
# ============================================
# Generar con: openssl rand -base64 32
JWT_SECRET=tu_secreto_super_largo_y_aleatorio_aqui_minimo_32_caracteres

# ============================================
# CORS
# ============================================
# Separar múltiples orígenes con comas
CORS_ORIGIN=https://app.georu.cl,https://admin.georu.cl,https://api.georu.cl
```

### Flutter (Hardcodeado en código - considerar usar env vars)

**Archivos a modificar:**
- `mobile/lib/services/api_service.dart` - URL del backend
- `mobile/lib/main.dart` - Credenciales de Supabase

**Alternativa**: Usar paquetes como `flutter_dotenv` para variables de entorno.

---

## 🌍 URLs y Dominios

### Estructura Recomendada

```
api.georu.cl          → Backend API (puerto 3000)
app.georu.cl          → App Móvil Flutter Web
admin.georu.cl        → Panel Administrativo
```

O si prefieres subdirectorios:
```
georu.cl/api          → Backend API
georu.cl/app          → App Móvil
georu.cl/admin        → Panel Administrativo
```

### Configuración de Nginx (Ejemplo)

```nginx
# Backend API
server {
    listen 80;
    server_name api.georu.cl;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}

# App Móvil
server {
    listen 80;
    server_name app.georu.cl;
    root /var/www/georu-app/build/web;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}

# Panel Admin
server {
    listen 80;
    server_name admin.georu.cl;
    root /var/www/georu-admin/build/web;
    index index.html;
    
    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

---

## 🗄️ Base de Datos

### Supabase (Ya Configurado)

**Estado Actual:**
- ✅ Proyecto creado
- ✅ Migraciones aplicadas
- ✅ Credenciales configuradas

**Verificaciones Pre-Despliegue:**
- [ ] Verificar que todas las tablas existan
- [ ] Verificar que los índices estén creados
- [ ] Verificar que RLS (Row Level Security) esté configurado
- [ ] Hacer backup de la base de datos
- [ ] Verificar límites del plan de Supabase (gratis tiene límites)

**Límites del Plan Gratuito de Supabase:**
- 500 MB de base de datos
- 2 GB de ancho de banda
- 50,000 usuarios activos mensuales
- 2 millones de requests por mes

**Si necesitas más:**
- Plan Pro: $25/mes
- Plan Team: $599/mes

---

## 🔐 Autenticación OAuth

### Google OAuth - Configuración Post-Despliegue

**Pasos obligatorios después de desplegar:**

1. **Ir a Google Cloud Console**
   - https://console.cloud.google.com/apis/credentials

2. **Editar el Cliente OAuth Web**
   - Agregar **Authorized redirect URIs**:
     ```
     https://app.georu.cl/
     https://app.georu.cl/auth/callback
     https://admin.georu.cl/
     https://admin.georu.cl/auth/callback
     ```

3. **Verificar en Supabase**
   - Ir a Authentication → Providers → Google
   - Verificar que las credenciales estén correctas
   - El redirect URI de Supabase debe ser: `https://aghbbmbbfcgtpipnrjev.supabase.co/auth/v1/callback`

4. **Probar el flujo completo**
   - Intentar login con Google desde la app desplegada
   - Verificar que redirija correctamente
   - Verificar que cree el usuario en Supabase

---

## 📱 Builds de Flutter

### Panel Administrativo (Vercel)

```bash
cd admin_web
flutter clean
flutter pub get
flutter build web --release
```

**Output**: `admin_web/build/web/`

**Nota**: Vercel puede hacer el build automáticamente, pero Flutter requiere configuración especial. Ver `DESPLIEGUE_VERCEL_ADMIN.md` para detalles.

### App Móvil (Android)

#### Build APK (para testing)
```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
```

**Output**: `mobile/build/app/outputs/flutter-apk/app-release.apk`

#### Build App Bundle (para Play Store) - RECOMENDADO
```bash
cd mobile
flutter clean
flutter pub get
flutter build appbundle --release
```

**Output**: `mobile/build/app/outputs/bundle/release/app-release.aab`

**Nota**: Ver `DESPLIEGUE_ANDROID.md` para guía completa de configuración, keystore, y subida a Play Store.

---

## 🐳 Docker (Opcional pero Recomendado)

### Backend Dockerfile

Ya existe en `backend/Dockerfile`, pero verificar que use `npm start` en producción:

```dockerfile
# Cambiar última línea de:
CMD ["npm", "run", "dev"]
# A:
CMD ["npm", "start"]
```

### Docker Compose para Producción

Crear `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    environment:
      - NODE_ENV=production
      - PORT=3000
      # ... otras variables
    ports:
      - "3000:3000"
    restart: unless-stopped
```

---

## 📊 Monitoreo y Logs

### Logs del Backend

- Configurar rotación de logs
- Usar servicios como:
  - **PM2** (para Node.js) con logs
  - **Winston** o **Pino** para logging estructurado
  - **Sentry** para tracking de errores

### Health Checks

El backend ya tiene un endpoint `/health`:
```
GET https://api.georu.cl/health
```

Configurar monitoreo para verificar este endpoint cada minuto.

---

## 🚨 Plan de Rollback

**Si algo sale mal:**

1. **Tener backups listos**
   - Código: Git (ya lo tienes)
   - Base de datos: Exportar desde Supabase

2. **Mantener versión anterior funcionando**
   - No eliminar servidor de desarrollo inmediatamente
   - Tener un entorno de staging

3. **Documentar cambios**
   - Anotar qué se cambió en cada despliegue
   - Facilita el rollback

---

## ✅ Checklist Final Pre-Despliegue

### Código
- [ ] Todos los cambios commiteados a Git
- [ ] Branch de producción preparado
- [ ] Tests pasando (si los hay)
- [ ] Sin `console.log` con información sensible

### Configuración
- [ ] Variables de entorno configuradas
- [ ] URLs actualizadas (sin localhost)
- [ ] CORS configurado correctamente
- [ ] SSL/HTTPS configurado

### Base de Datos
- [ ] Migraciones aplicadas
- [ ] Backup realizado
- [ ] Credenciales verificadas

### OAuth
- [ ] Redirect URIs actualizados en Google Cloud
- [ ] Credenciales verificadas en Supabase
- [ ] Flujo de OAuth probado

### Infraestructura
- [ ] Servidor/hosting configurado
- [ ] Dominio apuntando correctamente
- [ ] Firewall configurado
- [ ] Monitoreo configurado

### Testing
- [ ] Login/registro funciona
- [ ] OAuth funciona
- [ ] API responde correctamente
- [ ] Mapas cargan
- [ ] Todas las funcionalidades principales probadas

---

## 📞 Siguiente Paso

Una vez que tengas:
1. ✅ Servidor/hosting elegido
2. ✅ Dominio configurado
3. ✅ SSL/HTTPS configurado
4. ✅ Todas las credenciales listas

**Entonces podemos proceder con:**
- Configuración específica del hosting elegido
- Scripts de despliegue automatizado
- Configuración de CI/CD (opcional)
- Optimizaciones de rendimiento

---

## 📚 Recursos Útiles

- **Supabase Docs**: https://supabase.com/docs
- **Flutter Web Deployment**: https://docs.flutter.dev/deployment/web
- **Node.js Production Best Practices**: https://nodejs.org/en/docs/guides/nodejs-docker-webapp/
- **Let's Encrypt (SSL Gratis)**: https://letsencrypt.org/
- **Nginx Configuration**: https://nginx.org/en/docs/

---

**¿Listo para desplegar?** 🚀

Una vez que tengas el hosting y dominio, podemos proceder con la configuración específica.

