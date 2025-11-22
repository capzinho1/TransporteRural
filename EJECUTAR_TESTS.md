# 🧪 Guía de Ejecución de Tests

Esta guía te ayudará a ejecutar los tests automatizados para verificar todas las mejoras implementadas.

## 📋 Tests Disponibles

### 1. Tests Automatizados del Backend ✅
**Ubicación**: `backend/tests/test_dashboard_improvements.js`

Estos tests verifican automáticamente:
- ✅ Sincronización de `nombreRuta`
- ✅ Actualización del estado del conductor
- ✅ Validación antes de eliminar rutas
- ✅ Múltiples buses por ruta

### 2. Tests Manuales de UI 📱
**Ubicación**: `FLUJO_PRUEBAS_MEJORAS_DASHBOARD.md`

Estos tests requieren interacción manual para verificar:
- Actualización automática del dashboard
- Recarga automática al cambiar de pantalla
- Filtros por empresa (super admin)
- Frecuencia unificada de actualización
- Integración completa end-to-end

---

## 🚀 Ejecutar Tests Automatizados

### Paso 1: Preparar el Entorno

1. **Asegúrate de que el backend esté corriendo**:
   ```bash
   cd backend
   npm start
   # O si usas nodemon:
   npm run dev
   ```

2. **Obtén los IDs necesarios** desde Supabase:

   **Opción A: Desde Supabase Dashboard**
   - Ve a la tabla `users` y copia el ID de un admin
   - Ve a la tabla `companies` y copia el ID de una empresa
   - Ve a la tabla `users` (filtra por `role = 'driver'`) y copia el ID de un conductor

   **Opción B: Desde SQL Editor en Supabase**
   ```sql
   -- Obtener User ID (Admin)
   SELECT id, name, email, role FROM users 
   WHERE role IN ('super_admin', 'company_admin') 
   LIMIT 1;
   
   -- Obtener Company ID
   SELECT id, name FROM companies LIMIT 1;
   
   -- Obtener Driver ID
   SELECT id, name, email FROM users 
   WHERE role = 'driver' 
   LIMIT 1;
   ```

### Paso 2: Ejecutar los Tests

**Opción 1: Con variables de entorno (Recomendado)**

```bash
cd backend
TEST_USER_ID=1 TEST_COMPANY_ID=1 TEST_DRIVER_ID=1 node tests/test_dashboard_improvements.js
```

Reemplaza los números con tus IDs reales.

**Opción 2: Editar el archivo**

1. Abre `backend/tests/test_dashboard_improvements.js`
2. Busca la función `runTests()` (alrededor de la línea 300)
3. Descomenta y configura:
   ```javascript
   testUserId = 1; // Tu User ID
   testCompanyId = 1; // Tu Company ID
   testDriverId = 1; // Tu Driver ID
   ```
4. Ejecuta:
   ```bash
   cd backend
   node tests/test_dashboard_improvements.js
   ```

### Paso 3: Interpretar Resultados

**Ejemplo de salida exitosa:**
```
🧪 INICIANDO TESTS AUTOMATIZADOS
============================================================

[TEST 1] Sincronización de nombreRuta al asignar bus a ruta
  ℹ️  INFO: Creando ruta de prueba...
  ℹ️  INFO: Ruta creada: TEST_ROUTE_1234567890
  ℹ️  INFO: Creando bus de prueba...
  ℹ️  INFO: Bus creado: TEST_BUS_1234567890 (ID: 42)
  ℹ️  INFO: Asignando bus a ruta...
  ℹ️  INFO: Verificando sincronización de nombre_ruta...
  ✅ PASS: nombre_ruta sincronizado correctamente: "Test Ruta 1234567890"

[TEST 2] Actualización del estado del conductor al asignar/desasignar
  ✅ PASS: Estado del conductor actualizado a "en_ruta"
  ✅ PASS: Estado del conductor actualizado a "disponible"

[TEST 3] Validación antes de eliminar rutas con buses asignados
  ✅ PASS: Backend correctamente rechaza eliminar ruta con buses asignados

[TEST 4] Múltiples buses por ruta
  ✅ PASS: Múltiples buses asignados correctamente: 2 buses en la ruta

============================================================
📊 RESUMEN DE TESTS
============================================================
Total de tests: 4
✅ Pasados: 4
❌ Fallidos: 0
Porcentaje de éxito: 100.0%
============================================================

🎉 ¡TODOS LOS TESTS PASARON!
```

**Si hay errores:**
- Revisa el mensaje de error específico
- Verifica que el backend esté corriendo
- Verifica que los IDs sean correctos
- Revisa los logs del backend para más detalles

---

## 📱 Ejecutar Tests Manuales de UI

### Paso 1: Abrir el Documento de Pruebas

Abre `FLUJO_PRUEBAS_MEJORAS_DASHBOARD.md` y sigue las pruebas en orden.

### Paso 2: Ejecutar Cada Prueba

Cada prueba tiene:
- ✅ **Pasos detallados** a seguir
- ✅ **Resultado esperado** para verificar
- ✅ **Consultas SQL** para verificación en Supabase

### Paso 3: Marcar el Checklist

Al final del documento hay un checklist. Márcalo conforme vayas completando las pruebas.

---

## 🎯 Orden Recomendado de Ejecución

1. **Primero**: Ejecuta los tests automatizados del backend
   - Son rápidos (1-2 minutos)
   - Verifican la lógica crítica
   - Te dan confianza de que el backend funciona

2. **Segundo**: Ejecuta las pruebas manuales de UI
   - Verifican la experiencia del usuario
   - Requieren más tiempo (15-30 minutos)
   - Verifican la integración completa

---

## 🐛 Solución de Problemas

### Error: "Cannot connect to backend"
- ✅ Verifica que el backend esté corriendo en `http://localhost:3000`
- ✅ Verifica que no haya errores en los logs del backend

### Error: "Variable not configured"
- ✅ Configura las variables de entorno o edita el archivo
- ✅ Verifica que los IDs sean válidos

### Error: "404 Not Found"
- ✅ Verifica que las rutas del API estén correctas
- ✅ Verifica que el backend tenga las rutas implementadas

### Error: "401 Unauthorized"
- ✅ Verifica que el `testUserId` sea de un usuario admin
- ✅ Verifica que el usuario tenga permisos

### Tests pasan pero UI no funciona
- ✅ Verifica que el frontend esté usando las mismas rutas
- ✅ Verifica que no haya errores en la consola del navegador
- ✅ Verifica que los datos se estén cargando correctamente

---

## 📊 Resumen de Cobertura

### Tests Automatizados ✅
- [x] Sincronización de `nombreRuta`
- [x] Actualización del estado del conductor
- [x] Validación antes de eliminar rutas
- [x] Múltiples buses por ruta

### Tests Manuales 📱
- [ ] Actualización automática del dashboard
- [ ] Recarga automática al cambiar de pantalla
- [ ] Filtros por empresa (super admin)
- [ ] Frecuencia unificada de actualización
- [ ] Integración completa end-to-end

---

## 💡 Tips

1. **Ejecuta los tests después de cada cambio importante**
2. **Mantén los IDs de prueba en un lugar seguro** (variables de entorno)
3. **Revisa los logs del backend** si algo falla
4. **Usa el modo desarrollo** del backend para ver más detalles

---

## 📞 ¿Necesitas Ayuda?

Si encuentras problemas:
1. Revisa esta guía completa
2. Revisa `backend/tests/README_TESTS.md`
3. Revisa los logs del backend
4. Verifica la conexión a Supabase

