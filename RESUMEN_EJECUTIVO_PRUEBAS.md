# 📊 Resumen Ejecutivo - Pruebas Manuales

## 🎯 Guía Rápida

### Documento Principal
**`GUIA_COMPLETA_PRUEBAS_MANUALES.md`** - Guía paso a paso detallada con todas las pruebas

### Tiempo Total Estimado
⏱️ **~65 minutos** para completar todas las pruebas

---

## ✅ Checklist Rápido

### Funcionalidades Críticas (30 min)
- [ ] **PRUEBA 1**: Sincronización de `nombreRuta` (10 min)
- [ ] **PRUEBA 2**: Actualización del estado del conductor (10 min)
- [ ] **PRUEBA 3**: Validación antes de eliminar rutas (5 min)
- [ ] **PRUEBA 4**: Múltiples buses por ruta (5 min)

### Funcionalidades de UI/UX (20 min)
- [ ] **PRUEBA 5**: Actualización automática del dashboard (5 min)
- [ ] **PRUEBA 6**: Recarga automática al cambiar de pantalla (5 min)
- [ ] **PRUEBA 7**: Filtros por empresa (super admin) (5 min)
- [ ] **PRUEBA 8**: Frecuencia unificada de actualización (5 min)

### Integración Completa (15 min)
- [ ] **PRUEBA 9**: Flujo end-to-end completo (15 min)

---

## 🚀 Inicio Rápido

### 1. Preparación (5 minutos)

```sql
-- Ejecutar en Supabase SQL Editor
SELECT id, name FROM companies LIMIT 5;
SELECT route_id, name FROM routes LIMIT 5;
SELECT id, bus_id FROM bus_locations WHERE route_id IS NULL LIMIT 5;
SELECT id, name FROM users WHERE role = 'driver' LIMIT 5;
```

### 2. Anotar IDs Necesarios

| Item | ID | Nombre |
|------|----|--------|
| Super Admin | _____ | _____ |
| Company Admin | _____ | _____ |
| Empresa 1 | _____ | _____ |
| Empresa 2 | _____ | _____ |
| Ruta de Prueba | _____ | _____ |
| Bus 1 | _____ | _____ |
| Bus 2 | _____ | _____ |
| Conductor (ID 21) | 21 | Nicolás Muñoz |

### 3. Iniciar Pruebas

Sigue **`GUIA_COMPLETA_PRUEBAS_MANUALES.md`** en orden.

---

## 📋 Qué Verificar en Cada Prueba

### PRUEBA 1: nombreRuta
✅ Campo "Nombre de Ruta" se llena automáticamente en Gestión de Buses
✅ Aparece en búsquedas de la app móvil
✅ `nombre_ruta` en BD coincide con el nombre de la ruta

### PRUEBA 2: Estado del Conductor
✅ `driver_status = 'en_ruta'` después de asignar
✅ `driver_status = 'disponible'` después de desasignar

### PRUEBA 3: Validación Eliminación
✅ No permite eliminar ruta con buses asignados
✅ Muestra diálogo de error con lista de buses
✅ Permite eliminar si no hay buses asignados

### PRUEBA 4: Múltiples Buses
✅ Ruta muestra "Buses: X asignado(s)"
✅ Lista de chips con los buses asignados
✅ Ambos buses tienen mismo `route_id` y `nombre_ruta` en BD

### PRUEBA 5: Dashboard Auto-Update
✅ Estadísticas se actualizan cada 30 segundos
✅ No necesitas hacer refresh manual

### PRUEBA 6: Recarga al Cambiar
✅ Datos se recargan al cambiar de pantalla
✅ Cambios se reflejan inmediatamente

### PRUEBA 7: Filtros Empresa
✅ Super Admin ve filtro por empresa
✅ Company Admin NO ve filtro
✅ Estadísticas cambian al filtrar por empresa

### PRUEBA 8: Frecuencia Unificada
✅ Dashboard: 30 segundos
✅ Mapa tiempo real: 5 segundos
✅ Configuración centralizada en `app_config.dart`

### PRUEBA 9: End-to-End
✅ Todo funciona correctamente en conjunto
✅ Base de datos mantiene consistencia

---

## 🔍 Verificaciones en Base de Datos

### Consultas Útiles

```sql
-- Verificar nombreRuta sincronizado
SELECT bus_id, route_id, nombre_ruta 
FROM bus_locations 
WHERE bus_id = 'TU_BUS_ID';

-- Verificar estado del conductor
SELECT id, name, driver_status 
FROM users 
WHERE id = 21;

-- Verificar buses asignados a ruta
SELECT bus_id, route_id, nombre_ruta 
FROM bus_locations 
WHERE route_id = 'TU_ROUTE_ID';

-- Verificar estadísticas por empresa
SELECT company_id, COUNT(*) as total_buses 
FROM bus_locations 
GROUP BY company_id;
```

---

## ❌ Problemas Comunes y Soluciones

### Problema: nombreRuta está vacío
**Solución**: Verifica que guardaste la asignación correctamente desde "Gestión de Rutas"

### Problema: Estado del conductor no cambia
**Solución**: Espera 2-3 segundos después de asignar/desasignar y verifica en BD

### Problema: Permite eliminar ruta con buses
**Solución**: Verifica que el backend esté validando correctamente (consulta SQL)

### Problema: Dashboard no se actualiza automáticamente
**Solución**: Verifica que el timer esté activo (revisa código o espera 35 segundos)

### Problema: Filtro no aparece para Super Admin
**Solución**: Verifica que el usuario sea realmente `super_admin` (consulta SQL)

---

## 📞 Documentar Problemas

Si encuentras problemas, documenta:

1. **Qué prueba**: PRUEBA X
2. **Qué paso**: Paso X.X
3. **Qué esperabas**: _______________
4. **Qué ocurrió**: _______________
5. **Screenshot o logs**: (opcional)

---

**¡Buena suerte con las pruebas! 🚀**


