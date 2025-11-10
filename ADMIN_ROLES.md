# 🔐 Sistema de Administradores Multi-Empresa

## 📋 Descripción

El sistema ahora soporta dos tipos de administradores:

1. **Super Admin** (`super_admin`): Administrador del sistema completo
   - Puede gestionar todas las empresas
   - Ve todos los datos del sistema
   - Puede crear nuevas empresas
   - Acceso completo a todas las funcionalidades

2. **Company Admin** (`company_admin`): Administrador de empresa
   - Solo gestiona su propia empresa
   - Solo ve buses, rutas y usuarios de su empresa
   - No puede crear nuevas empresas
   - Acceso limitado a datos de su empresa

## 🗄️ Base de Datos

### Migración Requerida

Ejecuta el script de migración en Supabase:

```sql
-- Ejecutar database/migration_add_companies.sql en Supabase SQL Editor
```

Este script:
- Crea la tabla `companies`
- Agrega `company_id` a `users`, `routes` y `bus_locations`
- Crea empresa por defecto
- Actualiza el usuario admin inicial a `super_admin`

### Estructura

- **companies**: Empresas del sistema
- **users.company_id**: Asociación usuario-empresa
- **routes.company_id**: Asociación ruta-empresa
- **bus_locations.company_id**: Asociación bus-empresa

## 🔑 Credenciales

### Super Admin
```
Email: admin@transporterural.com
Contraseña: admin123
Rol: super_admin
```

### Company Admin (ejemplo)
```
Email: [crear desde panel super_admin]
Contraseña: admin123
Rol: company_admin
Company ID: [asignado al crear]
```

## 🎯 Funcionalidades por Rol

### Super Admin
**Enfoque: Reportes a gran escala y gestión de empresas**

- ✅ **Dashboard General**: Vista general del sistema completo
- ✅ **Reportes del Sistema**: 
  - Estadísticas globales (todas las empresas)
  - Análisis comparativo por empresa
  - Distribución de usuarios por empresa
  - Métricas agregadas del sistema
- ✅ **Gestión de Empresas**: Crear, editar, eliminar empresas
- ✅ **Mapa Global**: Ver todos los buses de todas las empresas
- ✅ **Notificaciones Globales**: Enviar notificaciones a nivel sistema
- ❌ NO tiene acceso a gestión detallada de buses/rutas/conductores individuales
- ❌ NO gestiona usuarios individuales (solo ve reportes)

### Company Admin
**Enfoque: Gestión completa de su empresa**

- ✅ **Dashboard**: Vista general de su empresa
- ✅ **Rutas y Conductores**: Gestionar rutas y asignaciones
- ✅ **Plantillas de Rutas**: Crear y gestionar plantillas
- ✅ **Gestión de Buses**: CRUD completo de buses de su empresa
- ✅ **Gestión de Conductores**: CRUD completo de conductores
- ✅ **Usuarios de la Empresa**: Gestionar usuarios (solo de su empresa)
- ✅ **Mapa en Tiempo Real**: Ver solo buses de su empresa
- ✅ **Reportes de la Empresa**: Estadísticas internas de su empresa
- ✅ **Notificaciones**: Enviar notificaciones a su empresa
- ✅ Todos los recursos creados se asignan automáticamente a su empresa
- ❌ NO puede gestionar empresas
- ❌ NO puede ver datos de otras empresas
- ❌ NO puede modificar recursos de otras empresas

## 🚀 Uso

### 1. Ejecutar Migración

En Supabase SQL Editor, ejecuta:
```sql
-- Contenido de database/migration_add_companies.sql
```

### 2. Crear Empresa (Super Admin)

1. Inicia sesión como `super_admin`
2. Ve a "Gestión de Empresas" en el menú lateral
3. Crea una nueva empresa
4. Anota el ID de la empresa

### 3. Crear Company Admin

1. Ve a "Usuarios" en el panel
2. Crea nuevo usuario con:
   - Rol: `company_admin`
   - Company ID: ID de la empresa creada
   - Email y contraseña

### 4. Login como Company Admin

1. Inicia sesión con las credenciales del company_admin
2. Verás solo los datos de su empresa
3. El panel mostrará "Admin Empresa" en lugar de "Super Admin"

## 🔒 Seguridad

- El backend filtra automáticamente los datos según el rol
- Los `company_admin` no pueden ver ni modificar datos de otras empresas
- El `company_id` se asigna automáticamente al crear recursos
- Las validaciones están en el backend para prevenir acceso no autorizado

## 📝 Notas

- El filtrado se realiza mediante headers `x-user-id` en las peticiones
- El `AdminApiService` envía automáticamente el user_id después del login
- Los recursos creados por `company_admin` se asignan automáticamente a su empresa
- El super_admin puede asignar cualquier empresa al crear recursos

