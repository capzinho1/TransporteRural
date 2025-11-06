# 🚌 TransporteRural

Sistema completo de transporte rural con localización de buses en tiempo real, desarrollado con Node.js, Flutter y PostgreSQL usando Docker Compose.

## 📋 Descripción

TransporteRural es una aplicación que permite:
- **Localizar buses rurales en tiempo real** para pasajeros
- **Gestionar recorridos** desde un panel administrativo
- **Seguimiento de ubicación** con mapas interactivos
- **API REST** para integración con aplicaciones móviles

## 🏗️ Arquitectura

```
TransporteRural/
├── backend/           # API REST con Node.js + Express
├── mobile/           # App Flutter (Pasajeros - Web/Móvil)
├── admin_web/        # Panel Administrativo Flutter (Web)
├── database/         # Scripts de inicialización PostgreSQL
├── nginx/           # Configuración de proxy reverso
├── docker-compose.yml
└── README.md
```

## 🚀 Tecnologías

### Backend
- **Node.js 20** + Express
- **PostgreSQL 15** con PostGIS
- **JWT** para autenticación
- **CORS** habilitado

### Frontend
- **Flutter 3.x** con Dart
- **Google Maps** para visualización
- **Provider** para gestión de estado
- **HTTP/Dio** para comunicación con API

### Infraestructura
- **Docker Compose** para orquestación
- **Nginx** como proxy reverso
- **PostgreSQL** con persistencia de datos

## 🛠️ Instalación y Configuración

### Prerrequisitos
- Docker y Docker Compose
- Git

### 1. Clonar el repositorio
```bash
git clone <repository-url>
cd TransporteRural
```

### 2. Configurar variables de entorno
```bash
# Copiar archivo de ejemplo
cp env.example .env

# Editar variables según necesidad
nano .env
```

### 3. Levantar los servicios
```bash
# Levantar todos los servicios
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Levantar solo servicios específicos
docker-compose up -d db backend
```

### 4. Verificar servicios
```bash
# Verificar estado de contenedores
docker-compose ps

# Verificar logs de un servicio específico
docker-compose logs backend
docker-compose logs flutter
```

## 🌐 Acceso a los Servicios

| Servicio | URL | Descripción |
|----------|-----|-------------|
| **Backend API** | http://localhost:3000 | API REST |
| **App Móvil (Web)** | http://localhost:8080 | App para pasajeros |
| **Panel Admin (Web)** | http://localhost:8081 | Dashboard administrativo |
| **Base de Datos** | localhost:5432 | PostgreSQL |
| **Nginx** | http://localhost:80 | Proxy (producción) |

### Endpoints de la API

#### Autenticación
- `POST /api/usuarios/login` - Iniciar sesión
- `GET /api/usuarios` - Listar usuarios
- `POST /api/usuarios` - Crear usuario

#### Buses
- `GET /api/buses` - Listar buses
- `GET /api/buses/:id` - Obtener bus específico
- `GET /api/buses/ubicacion/:id` - Ubicación actual del bus
- `POST /api/buses` - Crear nuevo bus
- `PUT /api/buses/:id/ubicacion` - Actualizar ubicación

#### Rutas
- `GET /api/rutas` - Listar rutas
- `GET /api/rutas/:id` - Obtener ruta específica
- `POST /api/rutas` - Crear nueva ruta
- `PUT /api/rutas/:id` - Actualizar ruta

#### Recorridos
- `GET /api/recorridos` - Listar recorridos
- `GET /api/recorridos/activos` - Recorridos en progreso
- `POST /api/recorridos` - Crear recorrido
- `PUT /api/recorridos/:id/iniciar` - Iniciar recorrido
- `PUT /api/recorridos/:id/finalizar` - Finalizar recorrido

#### Health Check
- `GET /health` - Estado del sistema

## 📱 Uso de la Aplicación

### Credenciales de Prueba

**Usuario Normal (App Móvil):**
```
Email: usuario@transporterural.com
Contraseña: usuario123
```

**Administrador (Panel Admin):**
```
Email: admin@transporterural.com
Contraseña: admin123
```

### Funcionalidades Principales

#### Para Pasajeros
1. **Ver buses en tiempo real** en el mapa
2. **Consultar rutas** disponibles
3. **Seguir buses** específicos
4. **Obtener información** de conductores

#### Para Conductores
1. **Actualizar ubicación** del bus
2. **Iniciar/finalizar** recorridos
3. **Ver pasajeros** en el bus
4. **Comunicarse** con administración

#### Para Administradores
1. **Panel de control** con estadísticas en tiempo real
2. **Gestionar buses** (CRUD completo)
3. **Gestionar rutas** (CRUD completo)
4. **Administrar usuarios** (CRUD completo)
5. **Asignar roles** (Admin, Conductor, Usuario)
6. **Monitorear sistema** en tiempo real

## 🔧 Desarrollo

### Estructura del Backend
```
backend/
├── src/
│   ├── routes/          # Endpoints de la API
│   │   ├── buses.js
│   │   ├── rutas.js
│   │   ├── usuarios.js
│   │   └── recorridos.js
│   └── server.js        # Servidor principal
├── package.json
└── Dockerfile
```

### Estructura del Frontend
```
mobile/
├── lib/
│   ├── models/          # Modelos de datos
│   ├── services/        # Servicios API
│   ├── screens/         # Pantallas
│   ├── widgets/         # Componentes reutilizables
│   └── providers/       # Gestión de estado
├── pubspec.yaml
└── Dockerfile
```

### Comandos de Desarrollo

#### Backend
```bash
# Entrar al contenedor
docker-compose exec backend bash

# Instalar dependencias
npm install

# Ejecutar en modo desarrollo
npm run dev

# Ejecutar tests
npm test
```

#### Frontend (App Móvil)
```bash
# Navegar al directorio
cd mobile

# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo (Web)
flutter run -d chrome --web-port 8080

# Ejecutar tests
flutter test
```

#### Panel Administrativo
```bash
# Navegar al directorio
cd admin_web

# Instalar dependencias
flutter pub get

# Ejecutar en modo desarrollo
flutter run -d chrome --web-port 8081

# Ejecutar tests
flutter test
```

## 🗄️ Base de Datos

### Esquema Principal
- **usuarios** - Usuarios del sistema
- **rutas** - Rutas de transporte
- **paradas** - Paradas de las rutas
- **buses** - Vehículos del sistema
- **ubicaciones_buses** - Historial de ubicaciones
- **recorridos** - Viajes realizados
- **historial_ubicaciones** - Tracking de recorridos

### Conexión
```bash
# Conectar a PostgreSQL
docker-compose exec db psql -U transporterural -d transporterural

# Ver tablas
\dt

# Ver datos de ejemplo
SELECT * FROM buses;
SELECT * FROM rutas;
```

## 🚀 Despliegue en Producción

### 1. Configurar SSL
```bash
# Generar certificados SSL
mkdir -p nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nginx/ssl/key.pem \
  -out nginx/ssl/cert.pem
```

### 2. Levantar con perfil de producción
```bash
# Levantar con Nginx
docker-compose --profile production up -d

# Verificar servicios
docker-compose ps
```

### 3. Configurar dominio
Editar `nginx/nginx.conf` y cambiar `server_name` por tu dominio.

## 📊 Monitoreo

### Logs
```bash
# Ver logs de todos los servicios
docker-compose logs -f

# Logs específicos
docker-compose logs -f backend
docker-compose logs -f flutter
docker-compose logs -f db
```

### Health Checks
```bash
# Verificar API
curl http://localhost:3000/health

# Verificar base de datos
docker-compose exec db pg_isready -U transporterural
```

## 🐛 Solución de Problemas

### Problemas Comunes

#### Puerto ya en uso
```bash
# Verificar puertos ocupados
netstat -tulpn | grep :3000
netstat -tulpn | grep :5432

# Cambiar puertos en docker-compose.yml
```

#### Error de conexión a BD
```bash
# Verificar que PostgreSQL esté listo
docker-compose exec db pg_isready -U transporterural

# Reiniciar servicios
docker-compose restart db backend
```

#### Flutter no compila
```bash
# Limpiar cache de Flutter
docker-compose exec flutter flutter clean
docker-compose exec flutter flutter pub get

# Reconstruir contenedor
docker-compose up --build flutter
```

### Limpiar Todo
```bash
# Detener y eliminar contenedores
docker-compose down

# Eliminar volúmenes (¡CUIDADO! Elimina datos)
docker-compose down -v

# Limpiar imágenes no utilizadas
docker system prune -a
```

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
- Contactar al equipo de desarrollo
- Revisar la documentación de la API

---

**TransporteRural** - Conectando comunidades rurales 🚌✨




Terminal 1 - Backend:

cd backend
npm install
npm run dev

 Terminal 2 - Flutter:

 cd mobile
flutter run -d chrome --web-port 8080