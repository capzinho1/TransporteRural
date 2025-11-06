# 🎛️ TransporteRural - Panel Administrativo

Panel de administración web desarrollado con Flutter para gestionar buses, rutas y usuarios del sistema TransporteRural.

## 🚀 Características

- ✅ **Dashboard** con estadísticas en tiempo real
- ✅ **Gestión de Buses** (CRUD completo)
- ✅ **Gestión de Rutas** (CRUD completo)
- ✅ **Gestión de Usuarios** (CRUD completo)
- ✅ **Interfaz intuitiva** y responsive
- ✅ **Autenticación** de administradores

## 📋 Requisitos Previos

- Flutter SDK 3.0+
- Backend corriendo en `http://localhost:3000`

## 🛠️ Instalación

```bash
# 1. Instalar dependencias
flutter pub get

# 2. Habilitar soporte web (si no está habilitado)
flutter config --enable-web

# 3. Ejecutar en modo desarrollo
flutter run -d chrome --web-port 8081
```

## 🔑 Credenciales de Acceso

**Administrador:**
- Email: `admin@transporterural.com`
- Contraseña: `admin123`

## 📱 Uso

### Dashboard Principal
- Vista general con estadísticas del sistema
- Total de buses, rutas y usuarios
- Buses activos e inactivos
- Accesos rápidos a las secciones

### Gestión de Buses
- Lista de todos los buses registrados
- Agregar nuevo bus
- Editar información del bus
- Eliminar bus
- Ver estado en tiempo real

### Gestión de Rutas
- Lista de rutas disponibles
- Crear nueva ruta
- Editar ruta existente
- Ver paradas de la ruta
- Eliminar ruta

### Gestión de Usuarios
- Lista de todos los usuarios
- Crear nuevo usuario
- Asignar roles (Admin, Conductor, Usuario)
- Editar información
- Eliminar usuario

## 🏗️ Estructura del Proyecto

```
admin_web/
├── lib/
│   ├── main.dart                           # Punto de entrada
│   ├── models/                            # Modelos de datos
│   │   ├── bus.dart
│   │   ├── ruta.dart
│   │   └── usuario.dart
│   ├── providers/                         # Gestión de estado
│   │   └── admin_provider.dart
│   ├── screens/                           # Pantallas principales
│   │   ├── admin_login_screen.dart
│   │   ├── dashboard_screen.dart
│   │   ├── buses_management_screen.dart
│   │   ├── routes_management_screen.dart
│   │   └── users_management_screen.dart
│   └── services/                          # Servicios API
│       └── admin_api_service.dart
├── web/                                   # Archivos web
│   ├── index.html
│   └── manifest.json
└── pubspec.yaml                          # Dependencias

```

## 🔧 Configuración

### Backend API
El panel se conecta al backend en `http://localhost:3000/api`

Endpoints utilizados:
- `/api/users/login` - Autenticación
- `/api/bus-locations` - Gestión de buses
- `/api/routes` - Gestión de rutas
- `/api/users` - Gestión de usuarios

### Cambiar puerto
Para ejecutar en un puerto diferente:
```bash
flutter run -d chrome --web-port PUERTO
```

## 🚢 Despliegue

### Build para producción
```bash
flutter build web --release
```

Los archivos se generarán en `build/web/`

### Servir con servidor web
```bash
# Usando Python
cd build/web
python -m http.server 8081

# O usando cualquier servidor HTTP
```

## 📊 Tecnologías Utilizadas

- **Flutter** - Framework de UI
- **Provider** - Gestión de estado
- **HTTP** - Peticiones API
- **Material Design** - Componentes UI
- **Data Table 2** - Tablas de datos
- **FL Chart** - Gráficos (futuro)

## 🐛 Troubleshooting

### Error de CORS
Si aparece error de CORS, asegúrate de que el backend tenga configurado:
```javascript
app.use(cors());
```

### Backend no responde
Verifica que el backend esté corriendo en `http://localhost:3000`

### No se ven los datos
1. Verifica que el backend esté respondiendo
2. Abre las DevTools (F12) y revisa la consola
3. Verifica que las credenciales sean correctas

## 📝 Notas

- Este es un panel administrativo, solo accesible para usuarios con rol `admin`
- Los datos se cargan desde el backend en tiempo real
- Las credenciales de prueba son solo para desarrollo

## 🤝 Contribuir

1. Crea una rama para tu feature
2. Realiza tus cambios
3. Envía un Pull Request

## 📄 Licencia

MIT License

