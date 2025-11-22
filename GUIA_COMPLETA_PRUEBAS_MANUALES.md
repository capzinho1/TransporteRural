# 📋 Guía Completa de Pruebas Manuales - Mejoras del Dashboard

Esta guía te llevará paso a paso a través de todas las pruebas necesarias para verificar que las mejoras implementadas funcionan correctamente.

---

## 🎯 Índice

1. [Preparación](#preparación)
2. [PRUEBA 1: Sincronización de nombreRuta](#prueba-1-sincronización-de-nombreruta)
3. [PRUEBA 2: Actualización del Estado del Conductor](#prueba-2-actualización-del-estado-del-conductor)
4. [PRUEBA 3: Validación Antes de Eliminar Rutas](#prueba-3-validación-antes-de-eliminar-rutas)
5. [PRUEBA 4: Múltiples Buses por Ruta](#prueba-4-múltiples-buses-por-ruta)
6. [PRUEBA 5: Actualización Automática del Dashboard](#prueba-5-actualización-automática-del-dashboard)
7. [PRUEBA 6: Recarga Automática al Cambiar de Pantalla](#prueba-6-recarga-automática-al-cambiar-de-pantalla)
8. [PRUEBA 7: Filtros por Empresa (Super Admin)](#prueba-7-filtros-por-empresa-super-admin)
9. [PRUEBA 8: Frecuencia Unificada de Actualización](#prueba-8-frecuencia-unificada-de-actualización)
10. [PRUEBA 9: Integración Completa End-to-End](#prueba-9-integración-completa-end-to-end)

---

## 📋 Preparación

### ✅ Requisitos Previos

**1. Verificar que el backend esté corriendo:**
```bash
# Abre una terminal y verifica:
curl http://localhost:3000/health
# O simplemente abre en el navegador: http://localhost:3000/health
```

**2. Verificar que el admin panel esté corriendo:**
- Debe estar en: `http://localhost:8081`

**3. Preparar datos de prueba en Supabase:**

Ejecuta estas consultas en Supabase SQL Editor para verificar datos:

```sql
-- Verificar que tienes al menos 2 empresas
SELECT id, name FROM companies LIMIT 5;

-- Verificar que tienes al menos 2 rutas (de diferentes empresas si es posible)
SELECT route_id, name, company_id FROM routes LIMIT 5;

-- Verificar que tienes buses disponibles
SELECT id, bus_id, route_id, driver_id, company_id, status FROM bus_locations LIMIT 10;

-- Verificar que tienes conductores disponibles
SELECT id, name, email, role, company_id, driver_status FROM users WHERE role = 'driver' LIMIT 5;

-- Verificar usuarios admin
SELECT id, name, email, role, company_id FROM users WHERE role IN ('super_admin', 'company_admin') LIMIT 5;
```

**4. Anotar información clave:**

Crea una tabla con esta información (cópiala y complétala):

```
| Concepto | ID | Nombre/Valor |
|----------|----|--------------|
| Usuario Super Admin | _____ | _____ |
| Usuario Company Admin | _____ | _____ |
| Empresa 1 | _____ | _____ |
| Empresa 2 | _____ | _____ |
| Ruta A (Empresa 1) | _____ | _____ |
| Ruta B (Empresa 1) | _____ | _____ |
| Bus 1 (Sin asignar) | _____ | _____ |
| Bus 2 (Sin asignar) | _____ | _____ |
| Conductor A | _____ | _____ |
| Conductor B | _____ | _____ |
```

---

## 🔍 PRUEBA 1: Sincronización de nombreRuta

**Objetivo**: Verificar que cuando asignas un bus a una ruta desde "Gestión de Rutas", el campo `nombreRuta` se sincroniza automáticamente con el nombre de la ruta.

### 📝 Pasos Detallados

#### Paso 1.1: Preparar la ruta de prueba

1. **Abre el Admin Panel** en `http://localhost:8081`
2. **Inicia sesión** como Company Admin (no Super Admin)
3. **Ve a "Gestión de Rutas"** en el menú lateral
4. **Busca una ruta existente** o crea una nueva con un nombre claro:
   - Ejemplo: "Linares - Talca"
   - **Anota el `route_id`**: _______________

#### Paso 1.2: Verificar estado inicial del bus

1. **Ve a "Gestión de Buses"** en el menú lateral
2. **Selecciona un bus** que NO tenga ruta asignada (Bus 1)
   - Busca un bus que muestre "Sin asignar" en la columna de ruta
3. **Haz clic en "Editar"** (icono de lápiz)
4. **Verifica** en el formulario:
   - ✅ Campo "Nombre de Ruta" debe estar **vacío** o mostrar el valor anterior
5. **Cierra el diálogo** sin guardar (botón "Cancelar")
6. **Anota el `bus_id`**: _______________

#### Paso 1.3: Asignar bus a ruta desde Gestión de Rutas

1. **Vuelve a "Gestión de Rutas"**
2. **Busca la ruta** que anotaste (ej: "Linares - Talca")
3. **Haz clic en "Asignar"** (icono de asignación en la tarjeta de la ruta)
4. **En el diálogo que aparece:**
   - **Selecciona "Bus"**: Bus 1 (el que anotaste)
   - **Selecciona "Conductor"**: Un conductor disponible (opcional para esta prueba)
5. **Haz clic en "Guardar"**
6. **Espera** el mensaje de éxito verde: "Asignación guardada exitosamente"

#### Paso 1.4: Verificar sincronización en Gestión de Buses

1. **Ve a "Gestión de Buses"** inmediatamente después de asignar
2. **Busca el Bus 1** en la lista
3. **Verifica** en la tabla:
   - ✅ La columna "Ruta" debe mostrar el **nombre de la ruta** (ej: "Linares - Talca")
   - ✅ NO debe mostrar solo el `route_id`
4. **Haz clic en "Editar"** en el Bus 1
5. **Verifica en el formulario:**
   - ✅ Campo "Nombre de Ruta" debe mostrar automáticamente: "Linares - Talca"
   - ✅ NO debe estar vacío
   - ✅ Debe coincidir EXACTAMENTE con el nombre de la ruta

#### Paso 1.5: Verificar en la base de datos

1. **Abre Supabase Dashboard** → SQL Editor
2. **Ejecuta esta consulta** (reemplaza los valores con los tuyos):

```sql
-- Reemplaza 'TU_BUS_ID' con el bus_id real
SELECT bus_id, route_id, nombre_ruta, status 
FROM bus_locations 
WHERE bus_id = 'TU_BUS_ID';
```

3. **Verifica los resultados:**
   - ✅ `nombre_ruta` debe contener el nombre de la ruta (ej: "Linares - Talca")
   - ✅ `route_id` debe contener el ID de la ruta
   - ✅ `nombre_ruta` NO debe ser `NULL`

#### Paso 1.6: Verificar en la app móvil (búsqueda)

1. **Abre la app móvil** (GeoRu)
2. **Ve a la pestaña "Buses"**
3. **Usa la barra de búsqueda** y escribe: "Linares" (sin las comillas)
4. **Verifica**:
   - ✅ El Bus 1 debe aparecer en los resultados de búsqueda
   - ✅ Debe mostrar el nombre de la ruta en la tarjeta del bus

### ✅ Resultado Esperado

**En Gestión de Buses:**
- El bus muestra el nombre de la ruta en la columna "Ruta"
- El campo "Nombre de Ruta" en el formulario de edición muestra el nombre correcto

**En la Base de Datos:**
- `bus_locations.nombre_ruta` = "Linares - Talca" (o el nombre que usaste)

**En la App Móvil:**
- El bus aparece en búsquedas por nombre de ruta

### ❌ Si Algo Falló

- **Si `nombreRuta` está vacío**: Verifica que guardaste la asignación correctamente
- **Si muestra `route_id` en lugar del nombre**: El backend no está sincronizando correctamente
- **Si la búsqueda no funciona**: Verifica que el índice GIN esté creado en Supabase

---

## 🔍 PRUEBA 2: Actualización del Estado del Conductor

**Objetivo**: Verificar que el `driver_status` se actualiza automáticamente a 'en_ruta' cuando asignas un conductor a un bus, y vuelve a 'disponible' cuando lo desasignas.

### 📝 Pasos Detallados

#### Paso 2.1: Verificar estado inicial del conductor

1. **Abre Supabase Dashboard** → SQL Editor
2. **Ejecuta esta consulta** (reemplaza con el ID del conductor):

```sql
-- Reemplaza 21 con el ID real de tu conductor
SELECT id, name, email, role, driver_status, company_id 
FROM users 
WHERE id = 21;
```

3. **Anota el `driver_status` actual**: _______________
   - Puede ser: `NULL`, `'disponible'`, `'en_ruta'`, u otro

#### Paso 2.2: Asignar conductor a un bus

1. **En el Admin Panel**, ve a **"Gestión de Rutas"**
2. **Selecciona una ruta** (puede ser la misma de la prueba anterior)
3. **Haz clic en "Asignar"**
4. **En el diálogo:**
   - **Selecciona "Conductor"**: El conductor que consultaste (ID: 21 - Nicolás Muñoz)
   - **Selecciona "Bus"**: Un bus disponible
5. **Haz clic en "Guardar"**
6. **Espera** el mensaje de éxito: "Asignación guardada exitosamente"

#### Paso 2.3: Verificar cambio de estado a 'en_ruta'

1. **Espera 2-3 segundos** después de guardar
2. **Abre Supabase Dashboard** → SQL Editor
3. **Ejecuta la misma consulta del Paso 2.1**:

```sql
SELECT id, name, email, role, driver_status, company_id 
FROM users 
WHERE id = 21;
```

4. **Verifica el resultado:**
   - ✅ `driver_status` debe ser **`'en_ruta'`**
   - ✅ NO debe ser `NULL` ni `'disponible'`

#### Paso 2.4: Verificar en Gestión de Conductores (opcional)

1. **En el Admin Panel**, ve a **"Gestión de Conductores"**
2. **Busca el conductor** (Nicolás Muñoz)
3. **Verifica visualmente** que el estado se muestra como "En ruta" o similar
   - Nota: Esto depende de cómo esté implementado en la UI

#### Paso 2.5: Desasignar conductor

1. **Vuelve a "Gestión de Rutas"**
2. **Selecciona la misma ruta**
3. **Haz clic en "Asignar"**
4. **En el diálogo:**
   - **Selecciona "Conductor"**: "Sin conductor"
   - **Selecciona "Bus"**: "Sin bus" (para desasignar todo)
5. **Haz clic en "Guardar"**
6. **Espera** el mensaje: "Desasignación completada exitosamente"

#### Paso 2.6: Verificar cambio de estado a 'disponible'

1. **Espera 2-3 segundos** después de desasignar
2. **Ejecuta nuevamente la consulta** en Supabase:

```sql
SELECT id, name, email, role, driver_status, company_id 
FROM users 
WHERE id = 21;
```

3. **Verifica el resultado:**
   - ✅ `driver_status` debe ser **`'disponible'`**
   - ✅ NO debe ser `'en_ruta'` ni `NULL`

### ✅ Resultado Esperado

**Estado Inicial:**
- Puede ser `NULL`, `'disponible'`, u otro estado

**Después de Asignar:**
- `driver_status` = `'en_ruta'`

**Después de Desasignar:**
- `driver_status` = `'disponible'`

### ❌ Si Algo Falló

- **Si el estado no cambia a 'en_ruta'**: El backend no está actualizando el estado del conductor
- **Si el estado no vuelve a 'disponible'**: El backend no está limpiando el estado al desasignar
- **Si el estado cambia pero tarda mucho**: Puede ser un problema de sincronización

---

## 🔍 PRUEBA 3: Validación Antes de Eliminar Rutas

**Objetivo**: Verificar que no puedes eliminar una ruta que tiene buses asignados, y que el sistema muestra un mensaje de error claro.

### 📝 Pasos Detallados

#### Paso 3.1: Preparar una ruta con bus asignado

1. **En el Admin Panel**, ve a **"Gestión de Rutas"**
2. **Selecciona una ruta** (puede ser nueva o existente)
3. **Asegúrate de que esta ruta tenga un bus asignado:**
   - Si no tiene bus asignado, haz clic en "Asignar"
   - Asigna un bus (y opcionalmente un conductor)
   - Guarda la asignación
4. **Anota el nombre de la ruta**: _______________
5. **Anota el `route_id`**: _______________

#### Paso 3.2: Verificar en la base de datos que hay buses asignados

1. **Abre Supabase Dashboard** → SQL Editor
2. **Ejecuta esta consulta** (reemplaza con tu `route_id`):

```sql
-- Reemplaza 'TU_ROUTE_ID' con el route_id real
SELECT bus_id, route_id, driver_id, status 
FROM bus_locations 
WHERE route_id = 'TU_ROUTE_ID';
```

3. **Verifica que aparezca al menos 1 bus** en los resultados
4. **Cuenta cuántos buses hay**: _______________ bus(es)

#### Paso 3.3: Intentar eliminar la ruta desde la UI

1. **En "Gestión de Rutas"**, busca la ruta que preparaste
2. **Haz clic en "Eliminar"** (icono de basura en la tarjeta)
3. **Observa qué sucede:**

   **Resultado Esperado A**: Diálogo de error (antes de mostrar confirmación)
   - ✅ Debe aparecer un diálogo que dice: **"No se puede eliminar"**
   - ✅ Debe mostrar: **"La ruta tiene X bus(es) asignado(s):"**
   - ✅ Debe listar los buses asignados (ej: "BUS1", "BUS2")
   - ✅ Debe tener un botón **"Entendido"**
   - ✅ NO debe aparecer el diálogo de confirmación normal

   **Resultado Esperado B**: Diálogo de confirmación con advertencia
   - ✅ Debe aparecer primero el diálogo de confirmación normal
   - ✅ Pero al hacer clic en "Eliminar", debe mostrar un error

4. **Anota qué sucedió**: _______________

#### Paso 3.4: Verificar que la ruta NO se eliminó

1. **Después de ver el error**, haz clic en "Entendido" o "Cancelar"
2. **Busca la ruta** nuevamente en "Gestión de Rutas"
3. **Verifica:**
   - ✅ La ruta **debe seguir existiendo** en la lista
   - ✅ NO debe haberse eliminado

#### Paso 3.5: Desasignar buses y luego eliminar

1. **Asegúrate de desasignar todos los buses** de la ruta:
   - Ve a "Asignar" en la ruta
   - Selecciona "Sin conductor" y "Sin bus"
   - Guarda
2. **Verifica en la base de datos** que no hay buses asignados:

```sql
SELECT bus_id, route_id 
FROM bus_locations 
WHERE route_id = 'TU_ROUTE_ID';
-- No debe retornar filas (o todas deben tener route_id = NULL)
```

3. **Ahora intenta eliminar la ruta** nuevamente:
   - Haz clic en "Eliminar"
   - Debe aparecer el diálogo de confirmación normal
   - Haz clic en "Eliminar" para confirmar
4. **Verifica:**
   - ✅ Debe aparecer mensaje: "Ruta eliminada exitosamente"
   - ✅ La ruta ya NO debe aparecer en "Gestión de Rutas"

#### Paso 3.6: Verificar validación en el backend (opcional - avanzado)

1. **Crea una nueva ruta de prueba**:
   - Nombre: "Ruta Test Eliminación"
   - Asigna un bus a esta ruta
2. **Intenta eliminar vía API** usando curl o Postman:

```bash
# Reemplaza con tus valores reales
curl -X DELETE http://localhost:3000/api/routes/TU_ROUTE_ID \
  -H "x-user-id: TU_USER_ID"
```

3. **Verifica la respuesta:**
   - ✅ Debe retornar **400 Bad Request**
   - ✅ El body debe contener: `"error": "No se puede eliminar la ruta"`
   - ✅ Debe incluir el mensaje sobre buses asignados

### ✅ Resultado Esperado

**Con buses asignados:**
- ✅ No permite eliminar
- ✅ Muestra diálogo de error con lista de buses
- ✅ La ruta no se elimina

**Sin buses asignados:**
- ✅ Permite eliminar
- ✅ Muestra diálogo de confirmación normal
- ✅ La ruta se elimina correctamente

### ❌ Si Algo Falló

- **Si permite eliminar con buses asignados**: El frontend no está validando antes de mostrar el diálogo
- **Si el mensaje de error no es claro**: Necesita mejorarse la UX del mensaje
- **Si el backend retorna 200 cuando debería retornar 400**: El backend no está validando correctamente

---

## 🔍 PRUEBA 4: Múltiples Buses por Ruta

**Objetivo**: Verificar que se pueden asignar múltiples buses a una misma ruta y que se muestran correctamente en la UI.

### 📝 Pasos Detallados

#### Paso 4.1: Preparar la ruta

1. **En el Admin Panel**, ve a **"Gestión de Rutas"**
2. **Selecciona o crea una ruta** para la prueba
3. **Anota el nombre de la ruta**: _______________
4. **Anota el `route_id`**: _______________

#### Paso 4.2: Verificar estado inicial

1. **Busca la ruta** en "Gestión de Rutas"
2. **Observa la tarjeta de la ruta:**
   - Debe mostrar información de asignaciones
   - Anota cuántos buses muestra actualmente: _______________
3. **Anota el bus actualmente asignado (si hay uno)**: _______________

#### Paso 4.3: Asignar el primer bus

1. **Haz clic en "Asignar"** en la ruta
2. **Asigna:**
   - **Bus**: Bus 1 (cualquier bus disponible)
   - **Conductor**: Conductor A (opcional)
3. **Guarda** y espera el mensaje de éxito
4. **Verifica en la tarjeta de la ruta:**
   - ✅ Debe mostrar información del bus asignado

#### Paso 4.4: Asignar el segundo bus (MUY IMPORTANTE)

**⚠️ IMPORTANTE**: Para asignar un segundo bus a la misma ruta, necesitas hacerlo de manera diferente porque el diálogo actual solo permite asignar un bus a la vez.

**Opción A: Desde "Gestión de Buses"** (si está implementado)
1. Ve a **"Gestión de Buses"**
2. Busca **Bus 2** (que no esté asignado)
3. Haz clic en **"Editar"**
4. En el formulario, busca el campo "Ruta" o "Route ID"
5. Selecciona la misma ruta que usaste para Bus 1
6. Guarda

**Opción B: Verificar en la base de datos y UI**
1. **Asigna Bus 2 directamente desde SQL** (temporalmente para verificar la UI):

```sql
-- Reemplaza con tus valores reales
UPDATE bus_locations 
SET route_id = 'TU_ROUTE_ID', 
    nombre_ruta = 'TU_NOMBRE_RUTA'
WHERE bus_id = 'TU_BUS_2_ID';
```

2. **Refresca la página** de "Gestión de Rutas"

#### Paso 4.5: Verificar que se muestran múltiples buses

1. **En "Gestión de Rutas"**, busca la ruta
2. **Observa la tarjeta de la ruta:**
   - ✅ Debe mostrar: **"Buses: 2 asignado(s)"** o similar
   - ✅ Debe mostrar una **lista de chips** con los buses:
     - Chip 1: "BUS1"
     - Chip 2: "BUS2"
3. **Haz una captura de pantalla** o anota cómo se ve: _______________

#### Paso 4.6: Verificar en Gestión de Buses

1. **Ve a "Gestión de Buses"**
2. **Busca Bus 1:**
   - ✅ Debe mostrar el `route_id` correcto en la columna "Ruta"
   - ✅ Debe mostrar el `nombreRuta` correcto
3. **Busca Bus 2:**
   - ✅ Debe mostrar el mismo `route_id` que Bus 1
   - ✅ Debe mostrar el mismo `nombreRuta` que Bus 1
4. **Verifica que ambos buses están en la misma ruta**

#### Paso 4.7: Verificar en la base de datos

1. **Ejecuta esta consulta** en Supabase:

```sql
-- Reemplaza con tu route_id
SELECT bus_id, route_id, nombre_ruta, driver_id, status 
FROM bus_locations 
WHERE route_id = 'TU_ROUTE_ID'
ORDER BY bus_id;
```

2. **Verifica:**
   - ✅ Debe retornar **2 o más filas**
   - ✅ Todas deben tener el mismo `route_id`
   - ✅ Todas deben tener el mismo `nombre_ruta`
   - ✅ El `nombre_ruta` debe coincidir con el nombre de la ruta

### ✅ Resultado Esperado

**En Gestión de Rutas:**
- La tarjeta muestra "Buses: X asignado(s)"
- Muestra una lista de chips con los buses asignados

**En Gestión de Buses:**
- Múltiples buses muestran el mismo `route_id` y `nombreRuta`

**En la Base de Datos:**
- Múltiples buses tienen el mismo `route_id` y `nombre_ruta`

### ❌ Si Algo Falló

- **Si solo muestra 1 bus**: La UI no está mostrando todos los buses asignados
- **Si los chips no se ven**: Hay un problema de diseño en la UI
- **Si los buses tienen diferentes `nombre_ruta`**: La sincronización no está funcionando para todos los buses

---

## 🔍 PRUEBA 5: Actualización Automática del Dashboard

**Objetivo**: Verificar que el dashboard se actualiza automáticamente cada 30 segundos sin necesidad de hacer refresh manual.

### 📝 Pasos Detallados

#### Paso 5.1: Preparar datos para el cambio

1. **Abre el Admin Panel** en una pestaña (Pestaña 1)
2. **Inicia sesión** como Super Admin o Company Admin
3. **Ve al Dashboard** (primera opción del menú)
4. **Anota los valores actuales** de las estadísticas:
   - Total Buses: _______________
   - Buses Activos: _______________
   - Buses Inactivos: _______________
   - Total Rutas: _______________
   - Total Usuarios: _______________
   - Conductores: _______________

#### Paso 5.2: Hacer cambios en otra pestaña

1. **Abre otra pestaña del navegador** (Pestaña 2)
2. **Inicia sesión** en el Admin Panel (mismo usuario o diferente)
3. **Ve a "Gestión de Buses"**
4. **Crea un nuevo bus** o cambia el estado de un bus existente:
   - Si creas un bus nuevo: **Anota el `bus_id`**: _______________
   - Si cambias el estado: **Anota qué bus cambiaste**: _______________

5. **Espera** a que se guarde correctamente

#### Paso 5.3: Observar el dashboard en la Pestaña 1

1. **Vuelve a la Pestaña 1** (donde está el Dashboard)
2. **NO hagas refresh manual**
3. **Observa las estadísticas:**
   - Mira el reloj o un cronómetro
   - **Espera hasta 35 segundos** (un poco más de los 30 segundos del timer)
4. **Verifica si las estadísticas cambiaron:**
   - ✅ **Total Buses** debe aumentar si creaste un bus nuevo
   - ✅ **Buses Activos/Inactivos** debe cambiar si modificaste el estado

#### Paso 5.4: Verificar con cambios adicionales

1. **En la Pestaña 2**, haz otro cambio:
   - Cambia el estado de un bus de "inactivo" a "activo"
   - O crea otra ruta
2. **Vuelve a la Pestaña 1** (Dashboard)
3. **Espera otros 30 segundos**
4. **Verifica** que las estadísticas se actualizaron nuevamente

#### Paso 5.5: Verificar que el timer está activo

1. **Abre las DevTools del navegador** (F12)
2. **Ve a la pestaña "Console"**
3. **Busca mensajes** relacionados con actualizaciones automáticas
   - Puede que no aparezcan, pero verifica si hay algún log

**Alternativa - Verificar en el código:**
1. **Abre** `admin_web/lib/screens/dashboard_screen.dart`
2. **Busca** el código del timer:
   - Debe haber un `Timer.periodic(Duration(seconds: 30), ...)`
   - Debe estar en `initState()`

### ✅ Resultado Esperado

**Actualización Automática:**
- ✅ Las estadísticas se actualizan automáticamente cada 30 segundos
- ✅ NO necesitas hacer refresh manual
- ✅ Los cambios realizados en otras pestañas se reflejan automáticamente

**Timer Configurado:**
- ✅ El código usa `AppConfig.dashboardRefreshIntervalSeconds` (30 segundos)

### ❌ Si Algo Falló

- **Si las estadísticas no se actualizan**: El timer no está funcionando o no se está ejecutando
- **Si tarda más de 35 segundos**: El timer puede estar configurado con un intervalo diferente
- **Si necesitas hacer refresh manual**: El timer no está activo

---

## 🔍 PRUEBA 6: Recarga Automática al Cambiar de Pantalla

**Objetivo**: Verificar que cuando cambias entre diferentes pantallas del admin panel, los datos se recargan automáticamente para mostrar la información más reciente.

### 📝 Pasos Detallados

#### Paso 6.1: Preparar cambios en una pantalla

1. **En el Admin Panel**, ve a **"Gestión de Rutas"**
2. **Asigna un bus a una ruta**:
   - Selecciona una ruta
   - Haz clic en "Asignar"
   - Asigna Bus 1 + Conductor A
   - Guarda
3. **Anota**:
   - **Ruta**: _______________
   - **Bus asignado**: _______________
   - **Conductor asignado**: _______________

#### Paso 6.2: Cambiar al Dashboard

1. **Haz clic en "Dashboard"** en el menú lateral (o usa el acceso rápido)
2. **Observa las estadísticas:**
   - **Total Buses**: _______________
   - **Buses Activos**: _______________
   - **Total Rutas**: _______________
3. **Verifica que los datos están actualizados:**
   - ✅ Las estadísticas deben reflejar los cambios recientes

#### Paso 6.3: Cambiar a Gestión de Buses

1. **Haz clic en "Gestión de Buses"** en el menú lateral
2. **Busca el Bus 1** que asignaste en el Paso 6.1
3. **Verifica:**
   - ✅ Debe mostrar el `route_id` correcto en la columna "Ruta"
   - ✅ Debe mostrar el `nombreRuta` correcto
   - ✅ Debe mostrar el conductor asignado (si se muestra en la tabla)
4. **Haz clic en "Editar"** en el Bus 1
5. **Verifica en el formulario:**
   - ✅ El campo "Nombre de Ruta" debe estar lleno con el nombre correcto
   - ✅ Los datos deben coincidir con lo que asignaste

#### Paso 6.4: Volver a Gestión de Rutas

1. **Haz clic en "Gestión de Rutas"** en el menú lateral
2. **Busca la ruta** que usaste en el Paso 6.1
3. **Verifica la tarjeta de la ruta:**
   - ✅ Debe mostrar el bus asignado correctamente
   - ✅ Debe mostrar el conductor asignado correctamente
   - ✅ Los datos deben estar actualizados

#### Paso 6.5: Hacer cambios y verificar propagación

1. **En "Gestión de Rutas"**, desasigna el bus y conductor:
   - Haz clic en "Asignar"
   - Selecciona "Sin conductor" y "Sin bus"
   - Guarda
2. **Cambia inmediatamente a "Gestión de Buses"** (sin hacer refresh manual)
3. **Busca el Bus 1** que acabas de desasignar
4. **Verifica:**
   - ✅ La columna "Ruta" debe mostrar "Sin asignar" o estar vacía
   - ✅ El `nombreRuta` debe estar vacío o NULL

#### Paso 6.6: Verificar recarga automática (avanzado)

1. **Abre las DevTools** (F12)
2. **Ve a la pestaña "Network"**
3. **Filtra por "XHR" o "Fetch"**
4. **Cambia entre pantallas** del menú lateral
5. **Observa las peticiones HTTP:**
   - ✅ Debe haber peticiones a `/api/bus-locations`, `/api/routes`, etc.
   - ✅ Estas peticiones deben ejecutarse automáticamente al cambiar de pantalla

### ✅ Resultado Esperado

**Recarga Automática:**
- ✅ Al cambiar de pantalla, los datos se recargan automáticamente
- ✅ Los cambios realizados en una pantalla se reflejan inmediatamente en otras
- ✅ NO necesitas hacer refresh manual del navegador

**Sincronización:**
- ✅ Todas las pantallas muestran datos consistentes
- ✅ No hay datos desactualizados entre pantallas

### ❌ Si Algo Falló

- **Si los datos no se actualizan al cambiar de pantalla**: El método `_changeScreen` no está recargando los datos
- **Si necesitas hacer refresh manual**: La recarga automática no está implementada correctamente
- **Si hay inconsistencias entre pantallas**: Los datos no se están sincronizando

---

## 🔍 PRUEBA 7: Filtros por Empresa (Super Admin)

**Objetivo**: Verificar que el super admin puede filtrar el dashboard por empresa y ver estadísticas específicas de cada empresa.

### 📝 Pasos Detallados

#### Paso 7.1: Preparar datos de prueba

1. **Asegúrate de tener al menos 2 empresas** en el sistema:
   - Ejecuta en Supabase:
   ```sql
   SELECT id, name FROM companies;
   ```
2. **Verifica que cada empresa tiene datos:**
   ```sql
   -- Empresa 1
   SELECT COUNT(*) as buses_empresa_1 FROM bus_locations WHERE company_id = 1;
   SELECT COUNT(*) as rutas_empresa_1 FROM routes WHERE company_id = 1;
   
   -- Empresa 2 (reemplaza con el ID real)
   SELECT COUNT(*) as buses_empresa_2 FROM bus_locations WHERE company_id = 2;
   SELECT COUNT(*) as rutas_empresa_2 FROM routes WHERE company_id = 2;
   ```
3. **Anota**:
   - **Empresa 1** - ID: _______, Nombre: _______, Buses: _______, Rutas: _______
   - **Empresa 2** - ID: _______, Nombre: _______, Buses: _______, Rutas: _______

#### Paso 7.2: Iniciar sesión como Super Admin

1. **Cierra sesión** si estás logueado como Company Admin
2. **Inicia sesión** como **Super Admin**
3. **Verifica** que eres Super Admin:
   - En el sidebar, debe decir "Super Admin" en el header
   - El menú debe mostrar opciones de Super Admin (Gestión de Empresas, etc.)

#### Paso 7.3: Ir al Dashboard y verificar estadísticas globales

1. **Haz clic en "Dashboard General"** en el menú lateral
2. **Anota las estadísticas globales** (sin filtro):
   - Total Buses: _______________
   - Buses Activos: _______________
   - Total Rutas: _______________
   - Total Usuarios: _______________
   - Total Empresas: _______________
   - Conductores: _______________

#### Paso 7.4: Verificar que existe el filtro por empresa

1. **Busca en el Dashboard** un filtro o dropdown
2. **Debe aparecer** un filtro que diga:
   - **"Filtrar por empresa:"** o similar
   - Un dropdown con las empresas disponibles
3. **Si NO aparece**, hay un problema con la implementación
4. **Anota si encontraste el filtro**: ✅ Sí / ❌ No

#### Paso 7.5: Filtrar por Empresa 1

1. **En el filtro**, selecciona **Empresa 1** (la primera de tu lista)
2. **Espera** a que se actualicen las estadísticas (puede tardar 1-2 segundos)
3. **Anota las nuevas estadísticas**:
   - Total Buses: _______________ (debe ser menor que el global)
   - Buses Activos: _______________
   - Total Rutas: _______________ (debe ser menor que el global)
   - Total Usuarios: _______________
   - Conductores: _______________

4. **Verifica que los números coinciden con los de la base de datos:**
   - ✅ Total Buses debe ser igual al número de buses de Empresa 1 que anotaste
   - ✅ Total Rutas debe ser igual al número de rutas de Empresa 1 que anotaste

#### Paso 7.6: Filtrar por Empresa 2

1. **En el filtro**, selecciona **Empresa 2**
2. **Espera** a que se actualicen las estadísticas
3. **Anota las nuevas estadísticas**:
   - Total Buses: _______________
   - Buses Activos: _______________
   - Total Rutas: _______________
   - Total Usuarios: _______________
   - Conductores: _______________

4. **Verifica:**
   - ✅ Los números deben ser DIFERENTES a los de Empresa 1
   - ✅ Deben coincidir con los datos de Empresa 2 en la base de datos

#### Paso 7.7: Seleccionar "Todas las empresas"

1. **En el filtro**, selecciona **"Todas las empresas"** o deja el dropdown vacío
2. **Espera** a que se actualicen las estadísticas
3. **Verifica:**
   - ✅ Las estadísticas deben volver a ser las **globales** (iguales al Paso 7.3)
   - ✅ Total Buses debe ser la suma de Empresa 1 + Empresa 2
   - ✅ Total Rutas debe ser la suma de ambas empresas

#### Paso 7.8: Verificar que Company Admin NO ve el filtro

1. **Cierra sesión** como Super Admin
2. **Inicia sesión** como **Company Admin** (no Super Admin)
3. **Ve al Dashboard**
4. **Verifica:**
   - ✅ **NO debe aparecer** el filtro por empresa
   - ✅ Solo debe ver las estadísticas de su propia empresa
   - ✅ Las estadísticas deben coincidir con su empresa solamente

### ✅ Resultado Esperado

**Super Admin:**
- ✅ Ve un filtro "Filtrar por empresa:" en el Dashboard
- ✅ Puede seleccionar diferentes empresas y ver sus estadísticas
- ✅ Puede seleccionar "Todas las empresas" para ver estadísticas globales

**Company Admin:**
- ✅ NO ve el filtro por empresa
- ✅ Solo ve estadísticas de su propia empresa

**Estadísticas Filtradas:**
- ✅ Coinciden con los datos reales en la base de datos
- ✅ Son diferentes para cada empresa
- ✅ La suma de empresas individuales = estadísticas globales

### ❌ Si Algo Falló

- **Si el filtro no aparece para Super Admin**: El código condicional no está funcionando
- **Si el filtro aparece para Company Admin**: La condición `isSuperAdmin` está incorrecta
- **Si las estadísticas no cambian al filtrar**: El método `_getFilteredStats` no está funcionando correctamente
- **Si las estadísticas filtradas no coinciden con la BD**: El filtrado no está consultando correctamente

---

## 🔍 PRUEBA 8: Frecuencia Unificada de Actualización

**Objetivo**: Verificar que todas las pantallas usan frecuencias de actualización consistentes y configuradas centralmente.

### 📝 Pasos Detallados

#### Paso 8.1: Verificar configuración centralizada

1. **Abre** el archivo `admin_web/lib/config/app_config.dart`
2. **Verifica que existe** y contiene:
   ```dart
   static const int refreshIntervalSeconds = 30;
   static const int realtimeMapRefreshIntervalSeconds = 5;
   static const int dashboardRefreshIntervalSeconds = 30;
   ```
3. **Anota los valores**:
   - Intervalo general: _______________ segundos
   - Mapa en tiempo real: _______________ segundos
   - Dashboard: _______________ segundos

#### Paso 8.2: Verificar Dashboard

1. **En el Admin Panel**, ve al **Dashboard**
2. **Abre DevTools** (F12) → **Console**
3. **Observa el código del Dashboard** (no es necesario, pero puedes verificar):
   - Abre `admin_web/lib/screens/dashboard_screen.dart`
   - Busca: `AppConfig.dashboardRefreshIntervalSeconds`
   - Debe estar en un `Timer.periodic`
4. **Haz cambios en otra pestaña**:
   - Crea un nuevo bus o cambia el estado
5. **Vuelve al Dashboard** y **espera 30 segundos**
6. **Verifica** que las estadísticas se actualizaron automáticamente

#### Paso 8.3: Verificar Mapa en Tiempo Real

1. **Ve a "Mapa en Tiempo Real"** en el menú lateral
2. **Abre DevTools** → **Console**
3. **Observa** si hay algún log relacionado con actualizaciones
4. **Espera 5 segundos** y observa:
   - ✅ El mapa debe actualizar automáticamente (si hay cambios en los buses)
   - ✅ Los marcadores de buses deben actualizarse

#### Paso 8.4: Verificar otras pantallas

1. **Ve a "Gestión de Buses"**
2. **Observa** si hay actualización automática:
   - Por defecto, esta pantalla NO debería tener actualización automática
   - Solo se actualiza al cambiar de pantalla o hacer refresh manual
3. **Verifica que el comportamiento es consistente** con lo esperado

### ✅ Resultado Esperado

**Configuración Centralizada:**
- ✅ Existe `app_config.dart` con constantes para frecuencias
- ✅ Todas las pantallas que usan timers importan este archivo

**Dashboard:**
- ✅ Se actualiza cada 30 segundos automáticamente

**Mapa en Tiempo Real:**
- ✅ Se actualiza cada 5 segundos (más frecuente)

**Otras Pantallas:**
- ✅ NO tienen actualización automática (solo al cambiar de pantalla o manual)

### ❌ Si Algo Falló

- **Si no existe `app_config.dart`**: La frecuencia no está centralizada
- **Si las pantallas usan valores hardcodeados**: No están usando la configuración centralizada
- **Si las frecuencias son diferentes a las configuradas**: Hay un problema en la implementación

---

## 🔍 PRUEBA 9: Integración Completa End-to-End

**Objetivo**: Verificar que todas las mejoras funcionan juntas correctamente en un flujo completo.

### 📝 Pasos Detallados

#### Paso 9.1: Preparación completa

1. **Inicia sesión** como **Company Admin**
2. **Prepara datos limpios:**
   - Selecciona una ruta existente o crea una nueva
   - Selecciona 2 buses disponibles
   - Selecciona 2 conductores disponibles
3. **Anota**:
   - **Ruta**: _______________
   - **Bus 1**: _______________
   - **Bus 2**: _______________
   - **Conductor A**: _______________
   - **Conductor B**: _______________

#### Paso 9.2: Asignación múltiple con sincronización

1. **Ve a "Gestión de Rutas"**
2. **Asigna Bus 1 + Conductor A** a la ruta:
   - Haz clic en "Asignar"
   - Selecciona Bus 1 y Conductor A
   - Guarda
3. **Espera** el mensaje de éxito
4. **Verifica en la base de datos** (Supabase):

```sql
-- Verificar bus 1
SELECT bus_id, route_id, nombre_ruta, driver_id 
FROM bus_locations 
WHERE bus_id = 'TU_BUS_1';

-- Verificar conductor A
SELECT id, name, driver_status 
FROM users 
WHERE id = TU_CONDUCTOR_A_ID;
```

5. **Verifica**:
   - ✅ `nombre_ruta` debe estar sincronizado con el nombre de la ruta
   - ✅ `driver_status` debe ser `'en_ruta'`

#### Paso 9.3: Asignar segundo bus

1. **Desde "Gestión de Buses"**, edita Bus 2:
   - Haz clic en "Editar"
   - En el campo de ruta (si existe), selecciona la misma ruta
   - O asigna desde "Gestión de Rutas" de manera alternativa
2. **Asigna Bus 2** a la misma ruta (puede requerir SQL temporal):

```sql
UPDATE bus_locations 
SET route_id = 'TU_ROUTE_ID', 
    nombre_ruta = 'TU_NOMBRE_RUTA'
WHERE bus_id = 'TU_BUS_2_ID';
```

3. **Refresca** "Gestión de Rutas"
4. **Verifica**:
   - ✅ La ruta muestra "Buses: 2 asignado(s)"
   - ✅ Muestra chips con ambos buses

#### Paso 9.4: Verificar en Dashboard

1. **Ve al Dashboard**
2. **Verifica las estadísticas:**
   - ✅ Total Buses debe incluir ambos buses
   - ✅ Buses Activos debe reflejar los buses asignados
3. **Espera 30 segundos** (o haz refresh manual)
4. **Verifica** que las estadísticas están actualizadas

#### Paso 9.5: Validación de eliminación

1. **Intenta eliminar la ruta** (con buses asignados):
   - Ve a "Gestión de Rutas"
   - Haz clic en "Eliminar"
2. **Verifica**:
   - ✅ Debe mostrar error: "No se puede eliminar"
   - ✅ Debe listar los buses asignados
3. **NO elimines** la ruta todavía

#### Paso 9.6: Desasignación completa

1. **Ve a "Gestión de Rutas"**
2. **Desasigna todo**:
   - Haz clic en "Asignar"
   - Selecciona "Sin conductor" y "Sin bus"
   - Guarda
3. **Espera** el mensaje: "Desasignación completada exitosamente"

#### Paso 9.7: Verificar estado final

1. **Verifica en la base de datos**:

```sql
-- Bus 1
SELECT bus_id, route_id, nombre_ruta, driver_id, status 
FROM bus_locations 
WHERE bus_id = 'TU_BUS_1';

-- Bus 2
SELECT bus_id, route_id, nombre_ruta, driver_id, status 
FROM bus_locations 
WHERE bus_id = 'TU_BUS_2';

-- Conductor A
SELECT id, name, driver_status 
FROM users 
WHERE id = TU_CONDUCTOR_A_ID;
```

2. **Verifica**:
   - ✅ `route_id` debe ser `NULL` en ambos buses
   - ✅ `nombre_ruta` debe ser `NULL` en ambos buses
   - ✅ `driver_id` debe ser `NULL` en ambos buses
   - ✅ `status` debe ser `'inactive'` en ambos buses
   - ✅ `driver_status` debe ser `'disponible'` para el conductor

#### Paso 9.8: Eliminar ruta (ahora sí)

1. **Intenta eliminar la ruta** nuevamente:
   - Ve a "Gestión de Rutas"
   - Haz clic en "Eliminar"
2. **Esta vez**:
   - ✅ Debe aparecer el diálogo de confirmación normal
   - ✅ NO debe mostrar error sobre buses asignados
3. **Confirma la eliminación**
4. **Verifica**:
   - ✅ Mensaje: "Ruta eliminada exitosamente"
   - ✅ La ruta ya NO aparece en la lista

#### Paso 9.9: Verificar Dashboard actualizado

1. **Ve al Dashboard** (sin hacer refresh manual)
2. **Espera 30 segundos** o cambia de pantalla y vuelve
3. **Verifica**:
   - ✅ Total Rutas debe haber disminuido en 1
   - ✅ Las estadísticas están actualizadas

### ✅ Resultado Esperado

**Flujo Completo:**
- ✅ Sincronización de `nombreRuta` funciona
- ✅ Actualización de estado del conductor funciona
- ✅ Múltiples buses por ruta se muestran correctamente
- ✅ Validación de eliminación funciona
- ✅ Desasignación limpia todos los campos
- ✅ Dashboard se actualiza automáticamente
- ✅ Todas las pantallas muestran datos consistentes

**Base de Datos:**
- ✅ Todos los campos están correctamente sincronizados
- ✅ Los estados son consistentes
- ✅ No hay datos huérfanos

### ❌ Si Algo Falló

Revisa cada paso individualmente y verifica qué funcionalidad específica está fallando. Puede ser un problema de:
- Sincronización
- Actualización de estados
- Validaciones
- UI/UX

---

## 📊 Checklist Final de Verificación

Usa este checklist para marcar cada prueba completada:

### Funcionalidades Críticas
- [ ] **PRUEBA 1**: Sincronización de `nombreRuta` funciona correctamente
- [ ] **PRUEBA 2**: Estado del conductor se actualiza al asignar/desasignar
- [ ] **PRUEBA 3**: Validación de eliminación funciona (no permite eliminar con buses)
- [ ] **PRUEBA 4**: Múltiples buses por ruta se muestran correctamente
- [ ] **PRUEBA 9**: Flujo end-to-end completo funciona

### Funcionalidades de UI/UX
- [ ] **PRUEBA 5**: Dashboard se actualiza automáticamente cada 30 segundos
- [ ] **PRUEBA 6**: Datos se recargan automáticamente al cambiar de pantalla
- [ ] **PRUEBA 7**: Filtros por empresa funcionan (super admin)
- [ ] **PRUEBA 8**: Frecuencias de actualización están unificadas

### Verificaciones Adicionales
- [ ] No hay errores en la consola del navegador
- [ ] No hay errores en los logs del backend
- [ ] La base de datos mantiene consistencia
- [ ] El rendimiento es aceptable (sin lag)

---

## 🐛 Casos de Error a Verificar

### Error 1: Sincronización de nombreRuta al cambiar nombre de ruta

**Escenario**: 
1. Asignas Bus 1 a Ruta A (nombre: "Linares - Talca")
2. Editas Ruta A y cambias el nombre a "Linares - San Javier"
3. Verifica si `nombreRuta` del bus se actualiza automáticamente

**Resultado Esperado**:
- ⚠️ **Nota**: Esta funcionalidad puede requerir implementación adicional (trigger en BD o sincronización periódica)
- Idealmente, `nombreRuta` debería actualizarse automáticamente
- Por ahora, puede que solo se sincronice en la próxima asignación

---

## 📝 Notas Finales

### Tiempo Estimado

- **Pruebas críticas** (1-4): ~30 minutos
- **Pruebas de UI** (5-8): ~20 minutos
- **Prueba end-to-end** (9): ~15 minutos
- **Total**: ~65 minutos

### Recomendaciones

1. **Ejecuta las pruebas en orden**: Cada prueba puede depender de la anterior
2. **Anota los resultados**: Usa la tabla de anotaciones para cada prueba
3. **Toma capturas de pantalla**: Si encuentras errores, toma capturas para documentarlos
4. **Verifica en la base de datos**: Siempre verifica en Supabase para confirmar los cambios
5. **No tengas prisa**: Tómate tu tiempo en cada paso

---

## 📞 Si Encuentras Problemas

1. **Anota el problema** específico que encontraste
2. **Verifica en la consola del navegador** (F12) si hay errores JavaScript
3. **Verifica en los logs del backend** si hay errores del servidor
4. **Verifica en la base de datos** si los datos están correctos
5. **Documenta** qué pasó y qué esperabas que pasara

---

**Fecha de creación**: ${new Date().toLocaleDateString()}

**Versión**: 1.0 - Guía completa y detallada para pruebas manuales

