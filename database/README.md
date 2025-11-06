# 🗄️ Configuración de Base de Datos - Supabase

## 📋 Requisitos

- Cuenta en [Supabase](https://supabase.com)
- El archivo `supabase_schema.sql` (incluido en este proyecto)

---

## 🚀 Pasos para Configurar Supabase

### **1. Crear Proyecto en Supabase**

1. Ve a [https://supabase.com/dashboard](https://supabase.com/dashboard)
2. Clic en **"New Project"**
3. Completa los datos:
   - **Name**: TransporteRural
   - **Database Password**: (guarda esta contraseña, la necesitarás)
   - **Region**: Elige la más cercana (ej: South America)
4. Clic en **"Create new project"**
5. Espera 1-2 minutos mientras se crea el proyecto

---

### **2. Ejecutar el Schema SQL**

1. En el dashboard de Supabase, ve a **"SQL Editor"** (menú lateral)
2. Clic en **"New Query"**
3. Copia TODO el contenido del archivo `supabase_schema.sql`
4. Pégalo en el editor SQL
5. Clic en **"Run"** (o presiona `Ctrl + Enter`)
6. Verifica que aparezca: ✅ **"Success. No rows returned"**

---

### **3. Obtener las Credenciales**

1. Ve a **"Settings"** > **"API"** (menú lateral)
2. Copia los siguientes valores:

   - **Project URL**: `https://[tu-proyecto].supabase.co`
   - **anon public**: (clave larga que empieza con `eyJ...`)

---

### **4. Configurar el Backend**

1. Abre el archivo `backend/.env` (si no existe, créalo)
2. Agrega las siguientes variables:

```env
# Supabase Configuration
SUPABASE_URL=https://aghbbmbbfcgtpipnrjev.supabase.co
SUPABASE_KEY=tu_anon_key_aqui

# Backend
PORT=3000
NODE_ENV=development
```

3. Reemplaza `SUPABASE_KEY` con tu **anon public** key

---

### **5. Verificar las Tablas**

1. En Supabase, ve a **"Table Editor"**
2. Deberías ver las siguientes tablas:
   - ✅ `users`
   - ✅ `routes`
   - ✅ `bus_locations`
   - ✅ `notifications`

---

### **6. Verificar Datos Iniciales**

1. Abre la tabla **`users`**
2. Deberías ver 2 usuarios:
   - **admin@transporterural.com** (role: admin)
   - **usuario@transporterural.com** (role: user)

---

## 🔐 Credenciales de Acceso

### **Panel Admin**
```
Email: admin@transporterural.com
Contraseña: admin123
```

### **App Móvil**
```
Email: usuario@transporterural.com
Contraseña: usuario123
```

---

## 🔄 Habilitar Realtime (Opcional pero Recomendado)

Para que los cambios se reflejen en tiempo real:

1. Ve a **"Database"** > **"Replication"**
2. Busca las tablas:
   - `bus_locations`
   - `routes`
   - `users`
3. Activa el **toggle** de "Realtime" para cada tabla
4. Clic en **"Save"**

---

## 📊 Vistas Disponibles

El schema incluye 2 vistas útiles:

### `active_buses`
Muestra todos los buses activos con información completa (ruta, conductor, ubicación).

```sql
SELECT * FROM active_buses;
```

### `system_stats`
Estadísticas generales del sistema.

```sql
SELECT * FROM system_stats;
```

---

## 🛠️ Comandos Útiles

### Ver todos los usuarios
```sql
SELECT * FROM users ORDER BY created_at DESC;
```

### Ver buses activos
```sql
SELECT * FROM bus_locations WHERE status IN ('active', 'en_ruta');
```

### Ver todas las rutas
```sql
SELECT * FROM routes WHERE active = true;
```

### Eliminar todos los buses (resetear)
```sql
DELETE FROM bus_locations;
```

---

## ⚠️ Troubleshooting

### Error: "relation does not exist"
- Asegúrate de haber ejecutado TODO el `supabase_schema.sql`

### Error: "permission denied"
- Verifica que las políticas RLS estén correctamente configuradas
- Ve a **"Authentication"** > **"Policies"** y revisa las tablas

### No aparecen datos en el frontend
- Verifica que `SUPABASE_KEY` esté correctamente configurada en el backend
- Revisa los logs del backend: `cd backend && npm run dev`

---

## 📖 Documentación Adicional

- [Supabase Docs](https://supabase.com/docs)
- [Supabase Realtime](https://supabase.com/docs/guides/realtime)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

---

✅ **¡Listo!** Ahora tu base de datos está configurada y lista para usar.

