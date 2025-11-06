# 🚀 Guía de Configuración - TransporteRural

## 📋 Paso 1: Configurar Supabase

### 1.1 Crear Proyecto en Supabase

1. Ve a [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Clic en **"New Project"**
3. Configura:
   - **Name**: TransporteRural
   - **Database Password**: (guarda esta contraseña)
   - **Region**: South America (o la más cercana)
4. Espera 1-2 minutos

### 1.2 Ejecutar Schema SQL

1. En Supabase, ve a **"SQL Editor"**
2. Clic en **"New Query"**
3. Copia TODO el contenido de `database/supabase_schema.sql`
4. Pégalo y clic en **"Run"**
5. Verifica: ✅ **"Success"**

### 1.3 Obtener Credenciales

1. Ve a **"Settings"** > **"API"**
2. Copia:
   - **Project URL**: `https://[tu-proyecto].supabase.co`
   - **anon public key**: `eyJ...`

### 1.4 Habilitar Realtime (Importante!)

1. Ve a **"Database"** > **"Replication"**
2. Activa "Realtime" para estas tablas:
   - ✅ `bus_locations`
   - ✅ `routes`
   - ✅ `users`
3. Clic en **"Save"**

---

## 📦 Paso 2: Configurar Backend

### 2.1 Crear archivo `.env`

Crea el archivo `backend/.env` con:

```env
# Supabase
SUPABASE_URL=https://aghbbmbbfcgtpipnrjev.supabase.co
SUPABASE_KEY=TU_ANON_KEY_AQUI

# Backend
PORT=3000
NODE_ENV=development
```

**⚠️ Reemplaza `SUPABASE_KEY` con tu clave real!**

### 2.2 Instalar Dependencias

```bash
cd backend
npm install
```

### 2.3 Ejecutar Backend

```bash
npm run dev
```

Deberías ver:
```
🚌 TransporteRural API ejecutándose en puerto 3000
✅ Conexión a Supabase establecida
```

---

## 📱 Paso 3: Configurar App Móvil

### 3.1 Instalar Dependencias

```bash
cd mobile
flutter pub get
```

### 3.2 Ejecutar App Móvil

**En Web (para pruebas):**
```bash
flutter run -d chrome
```

**En Android/iOS:**
```bash
flutter run
```

### 3.3 Login

```
Email: usuario@transporterural.com
Contraseña: usuario123
```

---

## 💻 Paso 4: Configurar Panel Admin

### 4.1 Instalar Dependencias

```bash
cd admin_web
flutter pub get
```

### 4.2 Ejecutar Admin Panel

```bash
flutter run -d chrome --web-port 8081
```

### 4.3 Login Admin

```
URL: http://localhost:8081
Email: admin@transporterural.com
Contraseña: admin123
```

---

## 🔄 Paso 5: Integrar Realtime (Tiempo Real)

### 5.1 Mobile App

El realtime ya está configurado en el código. Solo asegúrate de que:

1. Supabase Realtime esté **activado** para las tablas
2. La `SUPABASE_KEY` sea correcta en el backend

### 5.2 Admin Panel

El admin panel se actualizará automáticamente cada 5 segundos, pero también puedes:

1. Habilitar suscripciones de Supabase Realtime
2. Los cambios se reflejarán instantáneamente

---

## 🗂️ Estructura del Proyecto

```
TransporteRural/
├── backend/          # API REST (Node.js + Express + Supabase)
│   ├── src/
│   │   ├── config/
│   │   │   └── supabase.js      # ✅ Configuración Supabase
│   │   ├── routes/
│   │   │   ├── usuarios.js      # ✅ CRUD usuarios
│   │   │   ├── buses.js         # ✅ CRUD buses
│   │   │   └── rutas.js         # ✅ CRUD rutas
│   │   └── server.js
│   └── .env                      # ⚠️ CREAR ESTE ARCHIVO
│
├── mobile/           # App Móvil (Flutter)
│   └── lib/
│       ├── models/
│       ├── providers/
│       ├── screens/
│       └── services/
│
├── admin_web/        # Panel Admin (Flutter Web)
│   └── lib/
│       ├── models/
│       ├── providers/
│       └── screens/
│
└── database/
    ├── supabase_schema.sql      # ✅ Schema completo
    └── README.md                # Guía de Supabase
```

---

## ✅ Verificación

### Backend
```bash
curl http://localhost:3000/health
```

Respuesta esperada:
```json
{
  "status": "OK",
  "message": "TransporteRural API funcionando correctamente"
}
```

### Supabase
```bash
# En SQL Editor de Supabase:
SELECT * FROM users;
```

Deberías ver 2 usuarios (admin y usuario de prueba).

---

## 🎯 Primeros Pasos Después de la Configuración

### 1. Login en el Admin Panel
```
http://localhost:8081
admin@transporterural.com / admin123
```

### 2. Crear tu Primera Ruta
1. Ve a **"Rutas y Horarios"**
2. Clic en **"Agregar Ruta"**
3. Completa:
   - **ID Ruta**: RUTA-001
   - **Nombre**: Santiago Centro - Maipú
   - **Horarios**: 06:00, 12:00, 18:00
   - **Paradas**: Agrega al menos 2 paradas con coordenadas

### 3. Registrar un Conductor
1. Ve a **"Conductores"**
2. Clic en **"Agregar Conductor"**
3. Completa los datos del conductor

### 4. Crear un Bus
1. Ve a **"Gestión de Buses"**
2. Clic en **"Agregar Bus"**
3. Asigna:
   - ID del bus
   - Ruta
   - Conductor
   - Ubicación inicial

### 5. Ver el Mapa en Tiempo Real
1. Ve a **"Mapa en Tiempo Real"**
2. Verás todos los buses creados
3. Los buses se actualizarán automáticamente

---

## 🔧 Troubleshooting

### Backend no se conecta a Supabase
```bash
# Verifica que .env tenga las credenciales correctas
cat backend/.env

# Verifica que Supabase esté accesible
curl https://aghbbmbbfcgtpipnrjev.supabase.co
```

### "Error: No se pueden cargar buses"
1. Verifica que el backend esté corriendo: `http://localhost:3000/health`
2. Revisa la consola del backend para errores
3. Verifica que las tablas existan en Supabase

### App móvil no muestra datos
1. Verifica que el backend esté en `http://localhost:3000`
2. Si usas Android Emulator, usa `http://10.0.2.2:3000`
3. Revisa los logs: `flutter run --verbose`

### Admin panel en blanco
1. Limpia caché: `flutter clean`
2. Reinstala: `flutter pub get`
3. Ejecuta: `flutter run -d chrome --web-port 8081`

---

## 📚 Recursos Adicionales

- [Documentación Supabase](https://supabase.com/docs)
- [Flutter Docs](https://docs.flutter.dev/)
- [Express.js Guide](https://expressjs.com/)

---

## 🎉 ¡Listo!

Tu proyecto TransporteRural está configurado y listo para usar. 

**Credenciales:**
- **Admin**: admin@transporterural.com / admin123
- **Usuario**: usuario@transporterural.com / usuario123

**URLs:**
- **Backend**: http://localhost:3000
- **Admin Panel**: http://localhost:8081
- **Mobile App**: Ejecuta con `flutter run`

---

**¿Necesitas ayuda?** Revisa los logs de cada componente y el archivo `database/README.md` para más detalles sobre Supabase.

