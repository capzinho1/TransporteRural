# 🔄 Instrucciones para Resetear la Base de Datos

## 📋 Descripción

Este script elimina todos los datos y deja **SOLO 2 usuarios**:
- **1 super_admin** para el panel web administrativo: `admin@transporterural.com` (contraseña: `admin123`)
- **1 usuario** para la app móvil: `usuario@transporterural.com` (contraseña: `usuario123`)

**NO se crean conductores, company_admin, ni empresas por defecto.** Todo se creará desde el panel administrativo.

## 🚨 Advertencia

⚠️ **Este script eliminará TODOS los datos:**
- Todos los conductores
- Todos los company_admin
- Todas las empresas
- Todas las rutas
- Todos los buses
- Todas las notificaciones

Solo se mantendrán los 2 usuarios básicos mencionados arriba.

## 📝 Pasos para Ejecutar

### 1. Abrir Supabase SQL Editor

1. Ve a tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard)
2. Haz clic en **"SQL Editor"** en el menú lateral
3. Haz clic en **"New Query"**

### 2. Ejecutar el Script de Reset

1. Abre el archivo `database/reset_database.sql`
2. Copia TODO el contenido
3. Pégalo en el SQL Editor de Supabase
4. Haz clic en **"Run"** (o presiona `Ctrl + Enter`)

### 3. Verificar los Resultados

El script mostrará:
- Lista de usuarios restantes (debería ser solo 2)
- Lista de empresas (debería estar vacía)
- Conteo de registros en cada tabla

## ✅ Resultado Esperado

Después de ejecutar el script, deberías ver:

### Usuarios (SOLO 2)
- ✅ `admin@transporterural.com` (super_admin) - **Panel Web Administrativo**
- ✅ `usuario@transporterural.com` (user) - **App Móvil**
- ❌ 0 conductores
- ❌ 0 company_admins
- ❌ 0 otros usuarios

### Empresas
- ❌ 0 empresas (se crearán desde el panel)

### Otros Datos
- ❌ 0 rutas
- ❌ 0 buses
- ❌ 0 notificaciones

## 🔐 Credenciales Después del Reset

### Super Admin (Panel Administrativo)
```
Email: admin@transporterural.com
Contraseña: admin123
```

### Usuario App Móvil
```
Email: usuario@transporterural.com
Contraseña: usuario123
```

## 🚀 Próximos Pasos

Después de resetear tendrás **SOLO 2 usuarios**:

1. **Iniciar sesión como super_admin** en el panel web administrativo
2. **Crear empresas** desde el panel (cada empresa tendrá su propio company_admin)
3. **Crear conductores** desde el panel (asignados a empresas)
4. **Crear rutas y buses** desde el panel
5. **Usar la app móvil** con el usuario `usuario@transporterural.com`

## ⚠️ Notas Importantes

- El script es **idempotente**: puedes ejecutarlo varias veces sin problemas
- Los usuarios básicos se crearán o actualizarán automáticamente
- No se crean empresas por defecto - debes crearlas desde el panel
- Los usuarios básicos NO tienen `company_id` asignado

## 🐛 Solución de Problemas

### Error: "column password does not exist"
Ejecuta primero el script `database/add_password_to_users.sql` para agregar la columna password.

### Error: "relation companies does not exist"
Ejecuta primero el script `database/migration_add_companies.sql` para crear la tabla companies.

### Los usuarios no se crean
Verifica que los emails no estén siendo bloqueados por políticas RLS. El script asume que RLS está configurado para permitir acceso público.

