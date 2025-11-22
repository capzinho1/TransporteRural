# 🔍 Flujo de Pruebas - Sistema de Asignación de Conductores y Buses a Rutas

## 📋 Pre-requisitos

1. **Backend corriendo** en `http://localhost:3000`
2. **Admin Web corriendo** y accesible
3. **Base de datos configurada** con datos de prueba

---

## 🎯 Escenarios de Prueba

### 📦 Preparación de Datos de Prueba

#### 1. Crear Empresa (si no existe)
- Ir a **Gestión de Empresas** o usar el super admin
- Crear una empresa de prueba: **"Transporte Test S.A."**
- Anotar el `company_id` generado

#### 2. Crear Conductores
- Ir a **Gestión de Conductores**
- Crear al menos 3 conductores:
  - **Conductor A**: `conductorA@test.com` - Nombre: "Juan Pérez"
  - **Conductor B**: `conductorB@test.com` - Nombre: "María García"
  - **Conductor C**: `conductorC@test.com` - Nombre: "Carlos López"
- Asegurarse de que todos pertenezcan a la misma empresa

#### 3. Crear Buses
- Ir a **Gestión de Buses**
- Crear al menos 4 buses:
  - **Bus 1**: Patente "TEST01" - Estado: Inactivo
  - **Bus 2**: Patente "TEST02" - Estado: Inactivo
  - **Bus 3**: Patente "TEST03" - Estado: Inactivo
  - **Bus 4**: Patente "TEST04" - Estado: Inactivo
- Asegurarse de que todos pertenezcan a la misma empresa

#### 4. Crear Rutas
- Ir a **Gestión de Rutas**
- Crear al menos 2 rutas:
  - **Ruta 1**: "Linares - Talca" (puede ser una ruta básica)
  - **Ruta 2**: "Talca - Curicó" (puede ser una ruta básica)
- Asegurarse de que todas pertenezcan a la misma empresa

---

## ✅ Prueba 1: Asignación Básica (Bus + Conductor)

### Objetivo
Verificar que se puede asignar un bus y un conductor a una ruta correctamente.

### Pasos
1. Ir a **Gestión de Rutas**
2. Buscar la ruta **"Linares - Talca"**
3. Click en el botón **"Asignar"** (ícono de asignación)
4. En el diálogo:
   - Seleccionar **Conductor A** (Juan Pérez) del dropdown
   - Seleccionar **Bus TEST01** del dropdown
5. Click en **"Guardar"**

### Resultado Esperado
- ✅ La asignación se guarda exitosamente
- ✅ Mensaje verde: "Asignación guardada exitosamente"
- ✅ En la tarjeta de la ruta se muestran:
  - Chip verde: "Juan Pérez" (conductor)
  - Chip azul: "TEST01" (bus)
- ✅ El estado del bus cambia a **"active"**

### Verificación Adicional
- Ir a **Gestión de Buses**
- Buscar **TEST01**
- Verificar que muestra:
  - Ruta asignada: "Linares - Talca"
  - Conductor: "Juan Pérez"
  - Estado: "active"

---

## ✅ Prueba 2: Indicadores Visuales - Bus ya Asignado

### Objetivo
Verificar que los indicadores visuales muestran cuando un bus ya está asignado a otra ruta.

### Pasos
1. Ir a **Gestión de Rutas**
2. Buscar la ruta **"Talca - Curicó"**
3. Click en **"Asignar"**
4. En el dropdown de buses, observar **Bus TEST01**

### Resultado Esperado
- ✅ **TEST01** muestra:
  - ⚠️ Icono de advertencia (naranja)
  - Texto naranja: "Ya asignado a otra ruta"
  - Descripción: "Ya asignado a otra ruta"
- ✅ Los buses disponibles (TEST02, TEST03, TEST04) muestran:
  - ✓ Icono verde de check
  - Texto: "Disponible"

---

## ✅ Prueba 3: Indicadores Visuales - Conductor ya Asignado

### Objetivo
Verificar que los indicadores visuales muestran cuando un conductor ya tiene un bus asignado.

### Pasos
1. Ir a **Gestión de Rutas**
2. Buscar la ruta **"Talca - Curicó"**
3. Click en **"Asignar"**
4. En el dropdown de conductores, observar **Conductor A** (Juan Pérez)

### Resultado Esperado
- ✅ **Juan Pérez** muestra:
  - ⚠️ Icono de advertencia (naranja)
  - Texto naranja: "Ya asignado a otra ruta"
  - Descripción: "Ya asignado a otra ruta"
- ✅ Si seleccionas **Juan Pérez**, el sistema debería auto-seleccionar **TEST01** (su bus actual)

---

## ✅ Prueba 4: Reasignación con Advertencia

### Objetivo
Verificar que aparece un diálogo de confirmación al reasignar un bus de una ruta a otra.

### Pasos
1. Ir a **Gestión de Rutas**
2. Buscar la ruta **"Talca - Curicó"**
3. Click en **"Asignar"**
4. Seleccionar:
   - **Conductor B** (María García)
   - **Bus TEST01** (que ya está asignado a "Linares - Talca")
5. Click en **"Guardar"**

### Resultado Esperado
- ✅ Aparece un diálogo de advertencia con:
  - ⚠️ Título: "Advertencias"
  - Mensaje: "El bus TEST01 ya está asignado a otra ruta. La asignación anterior será removida."
  - Botones: "Cancelar" y "Continuar"
- ✅ Si click en **"Continuar"**:
  - La asignación se realiza
  - TEST01 ahora está asignado a "Talca - Curicó"
  - TEST01 ya NO está asignado a "Linares - Talca"
- ✅ Si click en **"Cancelar"**:
  - No se realiza ninguna asignación
  - El diálogo se cierra

---

## ✅ Prueba 5: Reasignación de Conductor

### Objetivo
Verificar que al reasignar un conductor que ya tiene un bus, se actualiza correctamente.

### Pasos
1. Ir a **Gestión de Rutas**
2. Buscar la ruta **"Linares - Talca"** (que ahora debería tener TEST01 y Juan Pérez)
3. Click en **"Asignar"**
4. Seleccionar:
   - **Conductor B** (María García) - que no tiene bus asignado
   - **Bus TEST01** - que ya tiene Juan Pérez como conductor
5. Click en **"Guardar"**

### Resultado Esperado
- ✅ Si hay advertencias, aparece el diálogo de confirmación:
  - Mensaje: "El conductor María García ya tiene un bus asignado..." (si tiene)
  - O: "El bus TEST01 ya está asignado a otra ruta..."
- ✅ Al confirmar:
  - TEST01 ahora tiene **María García** como conductor
  - TEST01 está asignado a **"Linares - Talca"**
  - **Juan Pérez** queda sin bus asignado

---

## ✅ Prueba 6: Asignar Solo Conductor (sin Bus)

### Objetivo
Verificar que al asignar solo un conductor (sin seleccionar bus), el sistema busca automáticamente un bus disponible.

### Pasos
1. Ir a **Gestión de Rutas**
2. Buscar la ruta **"Linares - Talca"**
3. Click en **"Asignar"**
4. En el diálogo:
   - Seleccionar **Conductor C** (Carlos López)
   - Dejar **"Sin bus"** seleccionado
5. Click en **"Guardar"**

### Resultado Esperado
- ✅ Si hay buses disponibles:
  - Se asigna automáticamente un bus disponible (por ejemplo, TEST02, TEST03 o TEST04)
  - Mensaje: "Asignación guardada exitosamente"
- ✅ Si NO hay buses disponibles:
  - Mensaje naranja: "No hay buses disponibles. Por favor crea un bus primero o selecciona uno existente."

---

## ✅ Prueba 7: Desasignar Todo

### Objetivo
Verificar que se puede desasignar tanto el conductor como el bus de una ruta.

### Pasos
1. Ir a **Gestión de Rutas**
2. Buscar una ruta que tenga asignación (por ejemplo, "Linares - Talca")
3. Click en **"Asignar"**
4. En el diálogo:
   - Seleccionar **"Sin conductor"**
   - Seleccionar **"Sin bus"**
5. Click en **"Guardar"**

### Resultado Esperado
- ✅ La desasignación se completa exitosamente
- ✅ Mensaje: "Desasignación completada exitosamente"
- ✅ Los chips de asignación desaparecen de la tarjeta de la ruta
- ✅ El bus queda sin ruta asignada
- ✅ El conductor queda sin bus asignado
- ✅ El estado del bus cambia a **"inactive"**

---

## ✅ Prueba 8: Validación de Empresa - Intentar Asignar Bus de Otra Empresa

### Objetivo
Verificar que no se puede asignar un bus de una empresa diferente.

### Pasos
1. **Crear otra empresa** (si no existe): "Empresa B Test"
2. **Crear un bus** en esa empresa: "OTRO01"
3. Ir a **Gestión de Rutas** (siendo admin de la primera empresa)
4. Buscar una ruta de la primera empresa
5. Click en **"Asignar"**
6. Intentar seleccionar el bus **"OTRO01"** (de la otra empresa)

### Resultado Esperado
- ✅ Si el sistema filtra por empresa: **"OTRO01"** NO aparece en el dropdown
- ✅ O si aparece: al intentar guardar, aparece error: "El bus OTRO01 pertenece a otra empresa y no puede ser asignado."

---

## ✅ Prueba 9: Validación de Conductor - Intentar Asignar Conductor de Otra Empresa

### Objetivo
Verificar que no se puede asignar un conductor de una empresa diferente.

### Pasos
1. **Crear un conductor** en "Empresa B Test": "Pedro Test"
2. Ir a **Gestión de Rutas** (siendo admin de la primera empresa)
3. Buscar una ruta de la primera empresa
4. Click en **"Asignar"**
5. Intentar seleccionar el conductor **"Pedro Test"** (de la otra empresa)

### Resultado Esperado
- ✅ Si el sistema filtra por empresa: **"Pedro Test"** NO aparece en el dropdown
- ✅ O si aparece: al intentar guardar, aparece error: "El conductor Pedro Test pertenece a otra empresa y no puede ser asignado."

---

## ✅ Prueba 10: Estado del Bus - Auto-determinación

### Objetivo
Verificar que el estado del bus se actualiza automáticamente según las asignaciones.

### Pasos
1. Ir a **Gestión de Buses**
2. Seleccionar un bus sin asignaciones (por ejemplo, TEST03)
3. Verificar que su estado es **"inactive"**
4. Ir a **Gestión de Rutas**
5. Asignar **TEST03** a una ruta con un conductor
6. Volver a **Gestión de Buses**
7. Verificar el estado de **TEST03**

### Resultado Esperado
- ✅ El estado cambia de **"inactive"** a **"active"**
- ✅ Si se desasigna, vuelve a **"inactive"**

---

## ✅ Prueba 11: Asignación Compleja - Múltiples Reasignaciones

### Objetivo
Verificar el comportamiento con múltiples reasignaciones simultáneas.

### Pasos
1. **Estado inicial:**
   - Ruta 1 "Linares - Talca": TEST01 + Juan Pérez
   - Ruta 2 "Talca - Curicó": TEST02 + María García

2. Ir a **Ruta 1** y asignar:
   - Conductor: María García (que tiene TEST02)
   - Bus: TEST02 (que ya está en Ruta 2)
3. Guardar

### Resultado Esperado
- ✅ Diálogo de advertencias con múltiples mensajes:
  - "El conductor María García ya tiene un bus asignado en otra ruta..."
  - "El bus TEST02 ya está asignado a otra ruta..."
- ✅ Al confirmar:
  - TEST02 se desasigna de Ruta 2
  - TEST02 se asigna a Ruta 1
  - María García se desasigna de TEST02 y se reasigna a TEST02 en Ruta 1
  - Ruta 2 queda sin asignaciones

---

## ✅ Prueba 12: Casos Edge - Conductor sin Bus Disponible

### Objetivo
Verificar el mensaje cuando un conductor no tiene bus y no hay buses disponibles.

### Pasos
1. Asignar TODOS los buses disponibles a diferentes rutas
2. Intentar asignar un conductor nuevo (sin bus) a una ruta
3. Dejar "Sin bus" seleccionado
4. Guardar

### Resultado Esperado
- ✅ Mensaje claro: "No hay buses disponibles. Por favor crea un bus primero o selecciona uno existente."
- ✅ La asignación NO se realiza

---

## 📊 Checklist de Verificación Final

Después de completar todas las pruebas, verificar:

- [ ] ✅ Todos los indicadores visuales funcionan correctamente
- [ ] ✅ Las advertencias se muestran antes de reasignar
- [ ] ✅ El diálogo de confirmación aparece con advertencias
- [ ] ✅ Las validaciones de empresa funcionan
- [ ] ✅ El estado del bus se actualiza automáticamente
- [ ] ✅ La desasignación funciona correctamente
- [ ] ✅ La auto-asignación de bus funciona cuando se asigna solo conductor
- [ ] ✅ Los mensajes de error son claros y útiles
- [ ] ✅ No hay conflictos de asignación en la base de datos
- [ ] ✅ La UI refleja correctamente el estado de las asignaciones

---

## 🐛 Problemas Comunes y Soluciones

### Problema: No aparecen los indicadores visuales
**Solución**: Verificar que los datos se hayan cargado correctamente en `_loadData()`

### Problema: El diálogo de advertencias no aparece
**Solución**: Verificar que `validation.warnings` no esté vacío

### Problema: El estado del bus no cambia
**Solución**: Verificar que `prepareAssignmentUpdate` esté calculando correctamente el estado

### Problema: Las validaciones de empresa no funcionan
**Solución**: Verificar que `currentCompanyId` se esté pasando correctamente desde `adminProvider.currentUser?.companyId`

---

## 📝 Notas Adicionales

- **Super Admin**: Como super admin, puedes ver y asignar recursos de todas las empresas
- **Company Admin**: Como company admin, solo puedes asignar recursos de tu propia empresa
- **Estado del Bus**: El estado solo se actualiza automáticamente si tiene tanto conductor como ruta asignados
- **Desasignación Parcial**: Si solo desasignas el conductor o solo el bus, el estado se mantiene

---

## 🎉 ¡Listo para Probar!

Sigue este flujo paso a paso y verifica que cada funcionalidad funcione como se espera. Si encuentras algún problema, anota el escenario y el resultado obtenido para corregirlo.

