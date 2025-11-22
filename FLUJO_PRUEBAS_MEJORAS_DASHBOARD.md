# 📋 Flujo de Pruebas - Mejoras del Dashboard y Asignaciones

> **⚠️ NOTA**: Esta es una guía técnica de referencia. Para una guía paso a paso más detallada y fácil de seguir, consulta **`GUIA_COMPLETA_PRUEBAS_MANUALES.md`**.

Este documento describe el flujo completo de pruebas para todas las mejoras implementadas en el dashboard y el sistema de asignaciones.

## 🎯 Objetivo

Verificar que todas las correcciones implementadas funcionen correctamente:
1. Sincronización de `nombreRuta`
2. Actualización del estado del conductor
3. Validación antes de eliminar rutas
4. Múltiples buses por ruta
5. Actualización automática del dashboard
6. Recarga automática al cambiar de pantalla
7. Filtros por empresa para super admin
8. Frecuencia unificada de actualización

---

## 📋 Preparación de Datos

### Prerrequisitos

1. **Super Admin** debe estar autenticado
2. **Company Admin** debe estar autenticado
3. **Al menos 2 empresas** creadas
4. **Al menos 3 rutas** creadas:
   - Ruta A: Empresa 1
   - Ruta B: Empresa 1
   - Ruta C: Empresa 2
5. **Al menos 4 buses**:
   - Bus 1: Sin asignar, Empresa 1
   - Bus 2: Sin asignar, Empresa 1
   - Bus 3: Sin asignar, Empresa 2
   - Bus 4: Sin asignar, Empresa 2
6. **Al menos 2 conductores**:
   - Conductor A: Empresa 1
   - Conductor B: Empresa 1

---

## 🔍 PRUEBA 1: Sincronización de nombreRuta

**Objetivo**: Verificar que `nombreRuta` se sincroniza automáticamente al asignar un bus a una ruta.

### Pasos

1. Ir a **"Gestión de Rutas"**
2. Seleccionar **Ruta A** (nombre: "Linares - Talca")
3. Hacer clic en **"Asignar"**
4. Seleccionar **Bus 1** (sin asignar)
5. Seleccionar **Conductor A**
6. Hacer clic en **"Guardar"**

### Resultado Esperado

✅ **En la base de datos**:
- `bus_locations.nombre_ruta` = "Linares - Talca"
- `bus_locations.route_id` = route_id de Ruta A

✅ **En "Gestión de Buses"**:
- Bus 1 muestra `nombreRuta = "Linares - Talca"`

✅ **En la app móvil**:
- Al buscar "Linares", aparece Bus 1

### Verificación

```sql
-- Verificar en Supabase
SELECT bus_id, route_id, nombre_ruta FROM bus_locations WHERE bus_id = 'BUS1';
-- Debe mostrar: route_id correcto y nombre_ruta = "Linares - Talca"
```

---

## 🔍 PRUEBA 2: Actualización del Estado del Conductor

**Objetivo**: Verificar que `driver_status` se actualiza automáticamente al asignar/desasignar.

### Pasos - Asignación

1. Verificar estado inicial del **Conductor A**:
   ```sql
   SELECT id, name, driver_status FROM users WHERE name = 'Conductor A';
   -- Debe estar 'disponible' o NULL
   ```

2. Ir a **"Gestión de Rutas"**
3. Asignar **Conductor A** + **Bus 1** a **Ruta A**
4. Guardar

### Resultado Esperado

✅ **En la base de datos**:
- `users.driver_status` = `'en_ruta'` para Conductor A

### Pasos - Desasignación

1. Volver a **"Gestión de Rutas"**
2. Seleccionar **Ruta A**
3. Hacer clic en **"Asignar"**
4. Seleccionar **"Sin conductor"** y **"Sin bus"**
5. Guardar

### Resultado Esperado

✅ **En la base de datos**:
- `users.driver_status` = `'disponible'` para Conductor A
- `bus_locations.driver_id` = NULL para Bus 1
- `bus_locations.route_id` = NULL para Bus 1
- `bus_locations.nombre_ruta` = NULL para Bus 1

### Verificación

```sql
-- Verificar estado del conductor
SELECT id, name, driver_status FROM users WHERE name = 'Conductor A';
-- Debe estar 'disponible' después de desasignar

-- Verificar desasignación del bus
SELECT bus_id, route_id, driver_id, nombre_ruta FROM bus_locations WHERE bus_id = 'BUS1';
-- Todos deben ser NULL
```

---

## 🔍 PRUEBA 3: Validación Antes de Eliminar Rutas

**Objetivo**: Verificar que no se puede eliminar una ruta con buses asignados.

### Pasos - Intentar Eliminar Ruta con Buses

1. **Asignar Bus 2 a Ruta B** (usando Gestión de Rutas)
2. Ir a **"Gestión de Rutas"**
3. Seleccionar **Ruta B**
4. Hacer clic en **"Eliminar"**

### Resultado Esperado

✅ **Diálogo de error**:
- Título: "No se puede eliminar"
- Mensaje: "La ruta tiene X bus(es) asignado(s):"
- Lista de buses asignados visible
- Botón "Entendido"

✅ **Ruta NO se elimina**

### Pasos - Eliminar Ruta sin Buses

1. Desasignar todos los buses de **Ruta B**
2. Intentar eliminar **Ruta B** nuevamente

### Resultado Esperado

✅ **Diálogo de confirmación**:
- "¿Estás seguro de eliminar la ruta 'Nombre'?"
- Botones: "Cancelar" y "Eliminar"

✅ **Ruta se elimina correctamente**

### Verificación Backend

1. Intentar eliminar una ruta con buses asignados vía API:
```bash
curl -X DELETE http://localhost:3000/api/routes/ROUTE_ID \
  -H "x-user-id: USER_ID"
```

✅ Debe retornar **400 Bad Request** con mensaje descriptivo

---

## 🔍 PRUEBA 4: Múltiples Buses por Ruta

**Objetivo**: Verificar que se pueden asignar múltiples buses a una ruta y se muestran correctamente.

### Pasos

1. Ir a **"Gestión de Rutas"**
2. Seleccionar **Ruta A**
3. Hacer clic en **"Asignar"**
4. Asignar **Bus 1** + **Conductor A**
5. Guardar

6. Repetir para **Bus 2** + **Conductor B** (si existe) o dejar sin conductor

### Resultado Esperado

✅ **En "Gestión de Rutas"**:
- Card de Ruta A muestra: **"Buses: 2 asignado(s)"**
- Lista de chips mostrando: **"BUS1"**, **"BUS2"**

✅ **En "Gestión de Buses"**:
- Ambos buses muestran `routeId = RUTA_A`
- Ambos buses muestran `nombreRuta = "Nombre de Ruta A"`

✅ **En la base de datos**:
```sql
SELECT bus_id, route_id, nombre_ruta FROM bus_locations WHERE route_id = 'RUTA_A';
-- Debe mostrar 2 buses con route_id y nombre_ruta correctos
```

---

## 🔍 PRUEBA 5: Actualización Automática del Dashboard

**Objetivo**: Verificar que el dashboard se actualiza automáticamente cada 30 segundos.

### Pasos

1. Iniciar sesión como **Super Admin**
2. Ir al **Dashboard**
3. Anotar los valores de las estadísticas:
   - Total Buses: X
   - Buses Activos: Y
4. Esperar **35 segundos** (sin hacer nada)
5. Verificar si las estadísticas cambiaron

### Resultado Esperado

✅ **Dashboard se actualiza automáticamente**:
- Las estadísticas se refrescan cada 30 segundos
- No es necesario hacer refresh manual

### Pasos - Cambiar Datos

1. En otra pestaña/navegador, como **Company Admin**:
   - Asignar un nuevo bus a una ruta
   - Cambiar estado de un bus a "activo"
2. Volver a la pestaña del **Super Admin Dashboard**
3. Esperar **30 segundos**

### Resultado Esperado

✅ **Estadísticas se actualizan** reflejando los cambios

---

## 🔍 PRUEBA 6: Recarga Automática al Cambiar de Pantalla

**Objetivo**: Verificar que los datos se recargan al cambiar entre pantallas.

### Pasos

1. Ir a **"Gestión de Rutas"**
2. Asignar **Bus 1** a **Ruta A**
3. Cambiar a **"Dashboard"**
4. Anotar estadísticas (Total Buses, Buses Activos)
5. Cambiar a **"Gestión de Buses"**
6. Verificar que **Bus 1** muestra la asignación correcta

### Resultado Esperado

✅ **Al cambiar a cada pantalla**:
- Los datos se recargan automáticamente
- Los cambios se reflejan inmediatamente

✅ **En Dashboard**:
- Estadísticas actualizadas
- Total Buses correcto
- Buses Activos correcto

✅ **En Gestión de Buses**:
- Bus 1 muestra `routeId` y `nombreRuta` correctos

---

## 🔍 PRUEBA 7: Filtros por Empresa (Super Admin)

**Objetivo**: Verificar que el super admin puede filtrar el dashboard por empresa.

### Pasos

1. Iniciar sesión como **Super Admin**
2. Ir al **Dashboard**
3. Verificar que existe un **filtro "Filtrar por empresa"**
4. Anotar estadísticas globales:
   - Total Buses: X (todas las empresas)
   - Total Rutas: Y
5. Seleccionar **Empresa 1** en el filtro
6. Verificar las estadísticas

### Resultado Esperado

✅ **Estadísticas filtradas**:
- Total Buses = Solo buses de Empresa 1
- Total Rutas = Solo rutas de Empresa 1
- Total Usuarios = Solo usuarios de Empresa 1

✅ **Estadísticas diferentes a las globales**

### Pasos - Cambiar Filtro

1. Seleccionar **"Todas las empresas"**
2. Verificar que vuelven las estadísticas globales

### Resultado Esperado

✅ **Estadísticas vuelven a ser globales**

### Pasos - Verificar desde Company Admin

1. Iniciar sesión como **Company Admin** (Empresa 1)
2. Ir al **Dashboard**

### Resultado Esperado

✅ **NO debe aparecer filtro de empresa** (solo ve su empresa)

✅ **Estadísticas muestran solo datos de su empresa**

---

## 🔍 PRUEBA 8: Frecuencia Unificada de Actualización

**Objetivo**: Verificar que todas las pantallas usan frecuencias de actualización consistentes.

### Pasos - Dashboard

1. Ir al **Dashboard**
2. Abrir **DevTools/Console**
3. Verificar que hay un timer cada **30 segundos**

### Resultado Esperado

✅ **Timer configurado para 30 segundos**

### Pasos - Mapa en Tiempo Real

1. Ir a **"Mapa en Tiempo Real"**
2. Abrir **DevTools/Console**
3. Verificar que hay un timer cada **5 segundos**

### Resultado Esperado

✅ **Timer configurado para 5 segundos** (más frecuente para tiempo real)

### Verificación de Código

✅ **Archivo `app_config.dart`** existe con constantes:
```dart
static const int refreshIntervalSeconds = 30;
static const int realtimeMapRefreshIntervalSeconds = 5;
static const int dashboardRefreshIntervalSeconds = 30;
```

---

## 🔍 PRUEBA 9: Integración Completa - Flujo End-to-End

**Objetivo**: Verificar que todas las mejoras funcionan juntas correctamente.

### Pasos

1. **Super Admin** - Filtrar dashboard por Empresa 1
2. **Company Admin** (Empresa 1) - Asignar Bus 1 + Conductor A a Ruta A
3. **Verificar**:
   - Dashboard super admin se actualiza (con filtro activo)
   - `nombreRuta` se sincroniza
   - Estado del conductor cambia a 'en_ruta'
4. **Asignar Bus 2** a la misma Ruta A
5. **Verificar**:
   - Ruta A muestra "2 buses asignados"
   - Ambos buses tienen `nombreRuta` correcto
6. **Desasignar todo** de Ruta A
7. **Verificar**:
   - Estado del conductor vuelve a 'disponible'
   - `nombreRuta` se limpia (NULL)
   - Dashboard se actualiza
8. **Intentar eliminar Ruta A** (sin buses)
9. **Verificar**:
   - Se elimina correctamente
   - No hay errores

### Resultado Esperado

✅ **Todo funciona correctamente**:
- Sincronización automática
- Actualización de estados
- Validaciones funcionan
- Dashboard se actualiza
- Filtros funcionan
- No hay errores en consola

---

## 🐛 Casos de Error a Verificar

### Error 1: Eliminar Ruta con Viajes Activos

**Pasos**:
1. Crear un viaje programado para Ruta A
2. Intentar eliminar Ruta A

**Resultado Esperado**:
✅ Backend retorna error 400 con mensaje sobre viajes activos

---

### Error 2: Sincronización de nombreRuta al Cambiar Nombre de Ruta

**Pasos**:
1. Asignar Bus 1 a Ruta A (nombre: "Linares - Talca")
2. Editar Ruta A y cambiar nombre a "Linares - San Javier"
3. Verificar `nombreRuta` del bus

**Resultado Esperado**:
✅ `nombreRuta` debe actualizarse automáticamente (o al menos debe sincronizarse en la próxima asignación)

**Nota**: Esta funcionalidad puede requerir implementación adicional (trigger en BD o sincronización periódica).

---

## 📝 Checklist de Verificación

- [ ] **PRUEBA 1**: Sincronización de `nombreRuta` funciona
- [ ] **PRUEBA 2**: Estado del conductor se actualiza correctamente
- [ ] **PRUEBA 3**: Validación de eliminación funciona
- [ ] **PRUEBA 4**: Múltiples buses por ruta se muestran correctamente
- [ ] **PRUEBA 5**: Dashboard se actualiza automáticamente
- [ ] **PRUEBA 6**: Datos se recargan al cambiar de pantalla
- [ ] **PRUEBA 7**: Filtros por empresa funcionan (super admin)
- [ ] **PRUEBA 8**: Frecuencias de actualización están unificadas
- [ ] **PRUEBA 9**: Flujo end-to-end funciona correctamente
- [ ] **Error 1**: Manejo de errores al eliminar ruta con viajes
- [ ] **Error 2**: Sincronización de nombreRuta al cambiar nombre de ruta

---

## 🎯 Criterios de Aceptación

✅ **Todas las pruebas pasan** sin errores
✅ **No hay errores en consola** del navegador
✅ **No hay errores en logs** del backend
✅ **Base de datos** mantiene consistencia
✅ **Performance** es aceptable (actualizaciones no bloquean UI)
✅ **UX** es fluida (sin parpadeos, sin recargas innecesarias)

---

## 📅 Fecha de Creación

Fecha: ${new Date().toLocaleDateString()}

---

## 🔄 Historial de Cambios

- **v1.0**: Flujo inicial de pruebas creado para todas las mejoras implementadas

