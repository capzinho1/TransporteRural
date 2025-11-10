# 🚌 GeoRu - Sistema de Transporte Rural

Sistema completo de gestión y seguimiento de transporte rural con localización de buses en tiempo real, desarrollado con Node.js, Flutter y Supabase (PostgreSQL).

## 📋 Descripción

**GeoRu** es una aplicación integral que permite gestionar y monitorear el transporte rural, conectando pasajeros, conductores y administradores de empresas de transporte. El sistema ofrece seguimiento en tiempo real, gestión de rutas, reportes de usuarios y análisis de datos.

### Características Principales

- 🗺️ **Seguimiento en tiempo real** de buses con mapas interactivos
- 📍 **Gestión de rutas** con paradas y polilíneas
- 👥 **Multi-empresa** con administración independiente
- ⭐ **Sistema de calificaciones** de conductores por pasajeros
- 📊 **Reportes de usuarios** con alertas predefinidas
- 📱 **Aplicaciones multiplataforma** (Web y Móvil)
- 🔐 **Sistema de roles** con permisos diferenciados
- 📈 **Dashboard administrativo** con estadísticas en tiempo real

## 🏗️ Arquitectura

```
TransporteRural/
├── backend/              # API REST con Node.js + Express
│   ├── src/
│   │   ├── routes/      # Endpoints de la API
│   │   ├── services/    # Servicios de Supabase
│   │   ├── middleware/  # Autenticación y validación
│   │   └── server.js    # Servidor principal
│   └── package.json
├── mobile/              # App Flutter para Pasajeros (Web/Móvil)
│   ├── lib/
│   │   ├── models/      # Modelos de datos
│   │   ├── screens/     # Pantallas de la app
│   │   ├── widgets/     # Componentes reutilizables
│   │   ├── services/    # Servicios API
│   │   ├── providers/   # Gestión de estado (Provider)
│   │   └── utils/       # Utilidades (colores, alertas)
│   └── pubspec.yaml
├── admin_web/           # Panel Administrativo Flutter (Web)
│   ├── lib/
│   │   ├── models/      # Modelos de datos
│   │   ├── screens/     # Pantallas administrativas
│   │   ├── widgets/     # Componentes reutilizables
│   │   ├── services/    # Servicios API
│   │   └── providers/   # Gestión de estado
│   └── pubspec.yaml
├── database/            # Scripts de migración y esquema
│   ├── supabase_schema.sql
│   ├── migration_add_features.sql
│   ├── migration_add_companies.sql
│   └── migration_add_bus_alerts.sql
├── nginx/              # Configuración de proxy reverso
├── docker-compose.yml
└── README.md
```

## 🚀 Tecnologías

### Backend
- **Node.js 20** + Express
- **Supabase** (PostgreSQL con PostGIS)
- **JWT** para autenticación
- **CORS** habilitado
- **Middleware** de autenticación y autorización

### Frontend
- **Flutter 3.x** con Dart
- **OpenStreetMap** (flutter_map) para visualización de mapas
- **Provider** para gestión de estado
- **HTTP/Dio** para comunicación con API
- **Geolocator** para ubicación GPS
- **Material Design** para UI

### Base de Datos
- **Supabase** (PostgreSQL 15) con PostGIS
- **Row Level Security (RLS)** para seguridad
- **Índices GIN** para búsquedas eficientes

### Infraestructura
- **Docker Compose** para orquestación (opcional)
- **Nginx** como proxy reverso (producción)

## 👥 Roles del Sistema

### 🔴 Super Administrador (`super_admin`)
- Gestión global del sistema
- Crear, modificar y eliminar empresas
- Gestionar todos los usuarios del sistema
- Acceso a todas las funcionalidades
- Estadísticas globales

### 🟠 Administrador de Empresa (`company_admin`)
- **Protegido**: No se puede editar ni eliminar
- Gestionar conductores de su empresa
- Gestionar buses de su empresa
- Gestionar rutas de su empresa
- Ver reportes y calificaciones
- Estadísticas de su empresa
- Asignar conductores a buses y rutas

### 🟡 Conductor (`driver`)
- Actualizar ubicación del bus en tiempo real
- Iniciar y finalizar recorridos
- Ver ruta asignada
- Recibir notificaciones
- Ver estado del bus

### 🟢 Usuario Pasajero (`user`)
- Ver buses en tiempo real en el mapa
- Consultar rutas disponibles
- Ver historial de viajes
- Calificar conductores
- Reportar problemas con buses
- Ver alertas activas de buses
- Filtrar buses por empresa, ruta o bus específico

## 🛠️ Instalación y Configuración

### Prerrequisitos
- Node.js 20+
- Flutter 3.x
- Cuenta de Supabase (gratuita)
- Git

### 1. Clonar el repositorio
```bash
git clone <repository-url>
cd TransporteRural
```

### 2. Configurar Supabase

1. Crear un proyecto en Supabase
2. Ejecutar las migraciones SQL en el orden indicado:
   - `database/supabase_schema.sql`
   - `database/migration_add_companies.sql`
   - `database/migration_add_features.sql`
   - `database/migration_add_bus_alerts.sql`
3. Configurar las credenciales en `backend/.env`

Ver documentación completa en `SUPABASE_SETUP.md`

### 3. Configurar variables de entorno

#### Backend (`backend/.env`)
```env
SUPABASE_URL=tu_supabase_url
SUPABASE_ANON_KEY=tu_anon_key
SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key
PORT=3000
NODE_ENV=development
```

#### Frontend
Configurar la URL del backend en los archivos de servicio correspondientes.

### 4. Instalar dependencias

#### Backend
```bash
cd backend
npm install
```

#### Mobile App
```bash
cd mobile
flutter pub get
```

#### Admin Web
```bash
cd admin_web
flutter pub get
```

### 5. Ejecutar el sistema

#### Terminal 1 - Backend
```bash
cd backend
npm run dev
```
Espera ver: `🚌 TransporteRural API ejecutándose en puerto 3000`

#### Terminal 2 - App Móvil
```bash
cd mobile
flutter run -d chrome --web-port 8080
```

#### Terminal 3 - Panel Administrativo
```bash
cd admin_web
flutter run -d chrome --web-port 8081
```

## 🌐 Acceso a los Servicios

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **Backend API** | http://localhost:3000 | API REST |
| **App Móvil (Web)** | http://localhost:8080 | App para pasajeros |
| **Panel Admin (Web)** | http://localhost:8081 | Dashboard administrativo |
| **Health Check** | http://localhost:3000/health | Estado del sistema |

## 📡 Endpoints de la API

### Autenticación
- `POST /api/usuarios/login` - Iniciar sesión
- `GET /api/usuarios` - Listar usuarios (requiere autenticación)
- `POST /api/usuarios` - Crear usuario
- `PUT /api/usuarios/:id` - Actualizar usuario
- `DELETE /api/usuarios/:id` - Eliminar usuario

### Buses
- `GET /api/buses` - Listar todas las ubicaciones de buses
- `GET /api/buses/active` - Obtener buses activos
- `GET /api/buses/:busId` - Obtener ubicación de un bus específico
- `PUT /api/buses/:busId/location` - Actualizar ubicación del bus
- `POST /api/buses` - Crear nuevo bus
- `PUT /api/buses/:id` - Actualizar bus
- `DELETE /api/buses/:id` - Eliminar bus

### Rutas
- `GET /api/rutas` - Listar todas las rutas
- `GET /api/rutas/:routeId` - Obtener ruta específica
- `POST /api/rutas` - Crear nueva ruta
- `PUT /api/rutas/:routeId` - Actualizar ruta
- `DELETE /api/rutas/:routeId` - Eliminar ruta
- `POST /api/rutas/:routeId/reverse` - Crear ruta inversa

### Viajes (Trips)
- `GET /api/trips` - Listar todos los viajes
- `GET /api/trips/active` - Obtener viajes activos
- `GET /api/trips/:id` - Obtener viaje específico
- `POST /api/trips` - Crear nuevo viaje
- `PUT /api/trips/:id/start` - Iniciar viaje
- `PUT /api/trips/:id/end` - Finalizar viaje
- `PUT /api/trips/:id/cancel` - Cancelar viaje

### Calificaciones (Ratings)
- `GET /api/ratings` - Listar calificaciones
- `GET /api/ratings/driver/:driverId` - Calificaciones de un conductor
- `POST /api/ratings` - Crear calificación (solo pasajeros)

### Reportes de Usuarios
- `GET /api/user-reports` - Listar reportes
- `GET /api/user-reports/bus/:busId` - Reportes de un bus específico
- `POST /api/user-reports` - Crear reporte

### Empresas
- `GET /api/empresas` - Listar empresas (solo super_admin)
- `POST /api/empresas` - Crear empresa (solo super_admin)
- `PUT /api/empresas/:id` - Actualizar empresa
- `DELETE /api/empresas/:id` - Eliminar empresa

### Notificaciones
- `GET /api/notifications` - Obtener notificaciones del usuario
- `POST /api/notifications` - Crear notificación
- `PUT /api/notifications/:id/read` - Marcar como leída

### Health Check
- `GET /health` - Estado del sistema

## 📱 Funcionalidades por Rol

### Para Pasajeros (App Móvil)

#### 🗺️ Mapa Interactivo
- Ver todos los buses en tiempo real
- Filtrar por empresa, ruta o bus específico
- Ver rutas con polilíneas
- Ver paradas marcadas en el mapa
- Ver alertas activas de buses
- Centrar mapa en ubicación actual
- Ver detalles de buses al hacer clic

#### 📋 Gestión de Viajes
- Ver historial de viajes realizados
- Ver detalles de viajes (fecha, ruta, conductor)

#### ⭐ Calificaciones
- Calificar conductores después de un viaje
- Ver calificaciones promedio de conductores

#### 📢 Reportes
- Reportar problemas con buses
- Seleccionar alertas predefinidas:
  - Bus sucio
  - Bus en mal estado
  - Chofer mal humorado
  - No acepta TNE
  - Y más...
- Ver alertas activas de otros usuarios

### Para Conductores (App Móvil)

#### 🚌 Gestión de Recorridos
- Ver ruta asignada
- Iniciar recorrido
- Actualizar ubicación en tiempo real
- Finalizar recorrido
- Ver estado del bus

#### 📍 Seguimiento
- Ver ubicación actual en el mapa
- Ver ruta completa con paradas
- Actualización automática de ubicación

### Para Administradores de Empresa (Panel Web)

#### 👥 Gestión de Conductores
- Crear, editar y desactivar conductores
- Asignar conductores a buses
- Ver estado de conductores (disponible, en ruta, fuera de servicio)
- Ver historial de conductores

#### 🚌 Gestión de Buses
- Crear, editar y eliminar buses
- Asociar buses a rutas
- Ver ubicación en tiempo real
- Ver estado de buses (activo/inactivo)
- Ver información de conductor asignado

#### 🛣️ Gestión de Rutas
- Crear rutas manualmente o desde plantilla
- Agregar paradas (inicio, final y paradas intermedias)
- Crear ruta inversa automáticamente
- Editar y eliminar rutas
- Ver rutas en el mapa
- Asignar buses a rutas

#### 📊 Dashboard
- Estadísticas en tiempo real
- Número de buses activos
- Número de conductores disponibles
- Rutas activas
- Viajes del día

#### 📈 Reportes y Calificaciones
- Ver reportes de usuarios sobre buses
- Ver calificaciones de conductores
- Responder a reportes
- Analizar tendencias

#### 🗺️ Mapa en Tiempo Real
- Ver todos los buses de la empresa
- Ver rutas activas
- Seguimiento en tiempo real

#### 📝 Historial de Viajes
- Ver todos los viajes realizados
- Filtrar por fecha, ruta, conductor
- Ver detalles de viajes
- Cancelar viajes programados

### Para Super Administrador (Panel Web)

#### 🏢 Gestión de Empresas
- Crear, editar y eliminar empresas
- Activar/desactivar empresas
- Ver todas las empresas del sistema

#### 👥 Gestión Global de Usuarios
- Ver todos los usuarios del sistema
- Crear usuarios de cualquier rol
- Editar usuarios (excepto company_admin)
- Eliminar usuarios (excepto company_admin)
- Asignar roles

#### 📊 Estadísticas Globales
- Estadísticas de todas las empresas
- Número total de usuarios
- Número total de buses
- Número total de rutas
- Análisis de uso del sistema

## 🗄️ Base de Datos

### Tablas Principales

#### `users`
- Usuarios del sistema con roles y permisos
- Campos: `id`, `email`, `name`, `role`, `company_id`, `active`, `driver_status`

#### `companies`
- Empresas de transporte
- Campos: `id`, `name`, `email`, `phone`, `active`

#### `routes`
- Rutas de transporte con paradas
- Campos: `route_id`, `name`, `schedule`, `stops`, `polyline`, `active`

#### `buses`
- Vehículos del sistema
- Campos: `id`, `bus_id`, `company_id`, `capacity`, `active`

#### `bus_locations`
- Ubicaciones en tiempo real de buses
- Campos: `id`, `bus_id`, `route_id`, `driver_id`, `latitude`, `longitude`, `status`

#### `trips`
- Viajes/recorridos realizados
- Campos: `id`, `bus_id`, `route_id`, `driver_id`, `status`, `scheduled_start`, `actual_start`, `actual_end`

#### `ratings`
- Calificaciones de conductores por pasajeros
- Campos: `id`, `trip_id`, `user_id`, `driver_id`, `rating`, `comment`

#### `user_reports`
- Reportes de usuarios sobre buses
- Campos: `id`, `user_id`, `bus_id`, `report_type`, `description`, `tags[]`

### Índices y Optimizaciones
- Índices en campos de búsqueda frecuente
- Índices GIN para arrays (tags en reportes)
- Índices espaciales para consultas de ubicación

## 🎨 Características de UI/UX

### Paleta de Colores
- **Verde primario** (#2E7D32) - Color principal del sistema
- **Colores de acento** - Indigo, teal, amber para diferenciación
- **Gradientes** - Para elementos visuales atractivos
- **Colores de estado** - Verde (activo), amarillo (advertencia), rojo (error)

### Componentes Reutilizables
- **GeoRuLogo** - Logo del sistema con fallback a CustomPainter
- **BusCard** - Tarjeta de información de bus
- **RutaCard** - Tarjeta de información de ruta
- **EnhancedMapWidget** - Widget de mapa avanzado con múltiples capas
- **OsmMapWidget** - Widget de mapa básico con OpenStreetMap

### Responsive Design
- Diseño adaptable para web y móvil
- Sidebars fijos en panel administrativo
- Navegación intuitiva con tabs y menús

## 🔒 Seguridad

### Autenticación
- JWT tokens para autenticación
- Middleware de autenticación en backend
- Validación de roles en endpoints

### Autorización
- Row Level Security (RLS) en Supabase
- Filtrado por `company_id` para administradores de empresa
- Protección de administradores de empresa (no editables/eliminables)

### Validación
- Validación de datos en frontend y backend
- Sanitización de inputs
- Manejo de errores consistente

## 🧪 Desarrollo

### Estructura del Backend
```
backend/
├── src/
│   ├── routes/          # Endpoints de la API
│   │   ├── buses.js
│   │   ├── rutas.js
│   │   ├── usuarios.js
│   │   ├── trips.js
│   │   ├── ratings.js
│   │   ├── user_reports.js
│   │   ├── empresas.js
│   │   └── notifications.js
│   ├── services/       # Servicios de Supabase
│   │   └── supabase.js
│   ├── middleware/     # Middleware de autenticación
│   │   └── auth.js
│   ├── config/         # Configuración
│   │   └── supabase.js
│   └── server.js       # Servidor principal
├── package.json
└── Dockerfile
```

### Estructura del Frontend (Mobile)
```
mobile/
├── lib/
│   ├── models/         # Modelos de datos
│   ├── screens/        # Pantallas
│   │   ├── login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── map_screen.dart
│   │   ├── driver_screen.dart
│   │   └── splash_screen.dart
│   ├── widgets/        # Componentes
│   │   ├── bus_card.dart
│   │   ├── ruta_card.dart
│   │   ├── enhanced_map_widget.dart
│   │   └── osm_map_widget.dart
│   ├── services/       # Servicios API
│   │   ├── api_service.dart
│   │   └── location_service.dart
│   ├── providers/      # Estado (Provider)
│   │   └── app_provider.dart
│   └── utils/          # Utilidades
│       ├── app_colors.dart
│       └── bus_alerts.dart
└── pubspec.yaml
```

### Comandos de Desarrollo

#### Backend
```bash
# Instalar dependencias
npm install

# Ejecutar en desarrollo
npm run dev

# Ejecutar en producción
npm start
```

#### Frontend (Mobile)
```bash
# Instalar dependencias
flutter pub get

# Ejecutar en web
flutter run -d chrome --web-port 8080

# Ejecutar en Android
flutter run -d android

# Ejecutar tests
flutter test
```

#### Frontend (Admin Web)
```bash
# Instalar dependencias
flutter pub get

# Ejecutar en web
flutter run -d chrome --web-port 8081

# Ejecutar tests
flutter test
```

## 🐛 Solución de Problemas

### Problemas Comunes

#### Error de conexión a Supabase
- Verificar que las credenciales en `backend/.env` sean correctas
- Verificar que el proyecto de Supabase esté activo
- Verificar que las migraciones se hayan ejecutado

#### Flutter no compila
```bash
# Limpiar cache
flutter clean
flutter pub get

# Verificar versión de Flutter
flutter --version
```

#### Puerto ya en uso
```bash
# Verificar puertos ocupados
netstat -ano | findstr :3000
netstat -ano | findstr :8080

# Cambiar puertos en código o variables de entorno
```

#### Error de tipos en Flutter
- Verificar que todos los modelos estén actualizados
- Ejecutar `flutter pub get` después de cambios en dependencias
- Verificar que los tipos coincidan entre frontend y backend

## 📊 Monitoreo

### Logs
```bash
# Backend (si está en Docker)
docker-compose logs -f backend

# Backend (desarrollo)
# Los logs aparecen en la consola donde se ejecuta `npm run dev`
```

### Health Check
```bash
curl http://localhost:3000/health
```

## 🚀 Despliegue en Producción

### 1. Configurar variables de entorno de producción
- Actualizar URLs de Supabase
- Configurar CORS para dominio de producción
- Configurar SSL/HTTPS

### 2. Build de aplicaciones Flutter
```bash
# Mobile App
cd mobile
flutter build web --release

# Admin Web
cd admin_web
flutter build web --release
```

### 3. Configurar Nginx
- Editar `nginx/nginx.conf`
- Configurar rutas para frontend y backend
- Configurar SSL si es necesario

### 4. Usar Docker Compose (Opcional)
```bash
docker-compose --profile production up -d
```

## 📝 Migraciones de Base de Datos

Las migraciones se ejecutan en el SQL Editor de Supabase:

1. `database/supabase_schema.sql` - Esquema base
2. `database/migration_add_companies.sql` - Tabla de empresas
3. `database/migration_add_features.sql` - Viajes, calificaciones, reportes
4. `database/migration_add_bus_alerts.sql` - Sistema de alertas

## 🤝 Contribución

1. Fork el proyecto
2. Crear rama para feature (`git checkout -b feature/AmazingFeature`)
3. Commit cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abrir Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## 📞 Soporte

Para soporte técnico o preguntas:
- Crear un issue en GitHub
- Revisar la documentación en `SETUP.md` y `SUPABASE_SETUP.md`
- Contactar al equipo de desarrollo

## 🎯 Roadmap

### Funcionalidades Futuras
- [ ] Notificaciones push
- [ ] Integración con sistemas de pago
- [ ] Análisis predictivo de demanda
- [ ] App móvil nativa (Android/iOS)
- [ ] Sistema de reservas
- [ ] Integración con sistemas de transporte público

---

**GeoRu** - Conectando comunidades rurales 🚌✨

Desarrollado con ❤️ usando Flutter, Node.js y Supabase
