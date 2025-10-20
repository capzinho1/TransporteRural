# 🗄️ Configuración de Supabase para TransporteRural

## 📋 Pasos para Configurar Supabase

### 1. 🔑 Obtener Claves de Supabase

1. Ve a tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard)
2. Ve a **Settings** → **API**
3. Copia las siguientes claves:
   - **Project URL**: `https://aghbbmbbfcgtpipnrjev.supabase.co`
   - **anon public key**: `eyJ...` (clave pública)
   - **service_role key**: `eyJ...` (clave de servicio)

### 2. 🔧 Configurar Variables de Entorno

Crea el archivo `backend/.env` con:

```env
# Supabase Configuration
SUPABASE_URL=https://aghbbmbbfcgtpipnrjev.supabase.co
SUPABASE_ANON_KEY=tu_anon_key_aqui
SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key_aqui

# Database
DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/transporterural

# Server
PORT=3000
JWT_SECRET=tu_jwt_secret_aqui
```

### 3. 🗄️ Ejecutar Script SQL

1. Ve a **SQL Editor** en Supabase Dashboard
2. Copia y pega el contenido de `database/supabase_schema.sql`
3. Ejecuta el script para crear las tablas

### 4. 📦 Instalar Dependencias

```bash
cd backend
npm install
```

### 5. 🚀 Ejecutar Backend

```bash
npm run dev
```

## 📊 Estructura de la Base de Datos

### Tablas Creadas:

1. **`users`** - Usuarios del sistema
   - `uid` (UUID, PK)
   - `email` (TEXT, UNIQUE)
   - `role` (user/driver/admin)
   - `name` (TEXT)
   - `fcm_tokens` (TEXT[])

2. **`routes`** - Rutas de buses
   - `route_id` (TEXT, PK)
   - `name` (TEXT)
   - `schedule` (TEXT[])
   - `stops` (JSONB)
   - `polyline` (TEXT)

3. **`bus_locations`** - Ubicaciones de buses
   - `bus_id` (TEXT, PK)
   - `route_id` (TEXT, FK)
   - `driver_id` (UUID, FK)
   - `latitude` (DOUBLE PRECISION)
   - `longitude` (DOUBLE PRECISION)
   - `location` (GEOGRAPHY, auto-generado)
   - `status` (en_ruta/finalizado/inactive)
   - `last_update` (TIMESTAMP)

### Vistas Creadas:

1. **`active_buses`** - Buses activos con información de ruta y conductor
2. **`route_stats`** - Estadísticas de rutas

## 🔒 Seguridad (Row Level Security)

- **Usuarios**: Solo pueden ver/editar sus propios datos
- **Rutas**: Públicas (cualquiera puede ver)
- **Ubicaciones de buses**: Públicas (cualquiera puede ver)
- **Solo usuarios autenticados**: Pueden insertar ubicaciones
- **Solo conductores**: Pueden actualizar sus propias ubicaciones

## 🌐 Endpoints Disponibles

### Usuarios:
- `GET /api/users` - Obtener todos los usuarios
- `GET /api/users/:uid` - Obtener usuario por ID
- `POST /api/users` - Crear usuario
- `PUT /api/users/:uid` - Actualizar usuario
- `DELETE /api/users/:uid` - Eliminar usuario
- `POST /api/users/login` - Iniciar sesión

### Rutas:
- `GET /api/routes` - Obtener todas las rutas
- `GET /api/routes/:routeId` - Obtener ruta por ID
- `POST /api/routes` - Crear ruta
- `PUT /api/routes/:routeId` - Actualizar ruta
- `DELETE /api/routes/:routeId` - Eliminar ruta

### Ubicaciones de Buses:
- `GET /api/bus-locations` - Obtener todas las ubicaciones
- `GET /api/bus-locations/active` - Obtener buses activos
- `GET /api/bus-locations/:busId` - Obtener ubicación por bus ID
- `GET /api/bus-locations/route/:routeId` - Obtener buses por ruta
- `GET /api/bus-locations/driver/:driverId` - Obtener buses por conductor
- `GET /api/bus-locations/nearby/:lat/:lng/:radius` - Obtener buses cercanos
- `PUT /api/bus-locations/:busId` - Actualizar ubicación
- `POST /api/bus-locations/:busId/update` - Actualizar ubicación (alternativo)

### Tiempo Real:
- `GET /api/bus-locations/realtime/subscribe` - Suscribirse a cambios de ubicaciones
- `GET /api/routes/realtime/subscribe` - Suscribirse a cambios de rutas

## 🧪 Datos de Prueba

El script incluye datos de ejemplo:

### Usuarios:
- `usuario@transporterural.com` (user)
- `conductor1@transporterural.com` (driver)
- `conductor2@transporterural.com` (driver)

### Rutas:
- R001: "Ruta Centro - Norte"
- R002: "Ruta Sur - Este"

### Buses:
- BUS001: Ruta R001, Conductor Juan, Estado: en_ruta
- BUS002: Ruta R002, Conductor María, Estado: en_ruta
- BUS003: Ruta R001, Conductor Juan, Estado: finalizado

## 🔍 Consultas Geoespaciales

Ejemplos de consultas PostGIS:

```sql
-- Buses dentro de 5km de un punto
SELECT * FROM bus_locations 
WHERE ST_DWithin(
  location, 
  ST_Point(-70.6693, -33.4489), 
  5000
);

-- Distancia entre dos puntos
SELECT ST_Distance(
  ST_Point(-70.6693, -33.4489),
  ST_Point(-70.6000, -33.4000)
) * 111000; -- Convertir a metros
```

## 🚀 Próximos Pasos

1. Configurar autenticación real con Supabase Auth
2. Implementar notificaciones push con FCM
3. Agregar más consultas geoespaciales
4. Configurar backups automáticos
5. Implementar métricas y analytics

¡Tu base de datos está lista para usar! 🎉

