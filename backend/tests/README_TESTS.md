# 🧪 Tests Automatizados - Mejoras del Dashboard

Este directorio contiene tests automatizados para verificar las mejoras implementadas.

## 📋 Requisitos

1. **Backend corriendo**: El servidor debe estar ejecutándose en `http://localhost:3000`
2. **Base de datos configurada**: Supabase debe estar configurado y accesible
3. **Variables de entorno**: Configurar las variables necesarias

## 🚀 Ejecución Rápida

### Opción 1: Con variables de entorno

```bash
cd backend
TEST_USER_ID=1 TEST_COMPANY_ID=1 TEST_DRIVER_ID=1 node tests/test_dashboard_improvements.js
```

### Opción 2: Editar el archivo

1. Abre `backend/tests/test_dashboard_improvements.js`
2. Busca la función `runTests()`
3. Configura las variables:
   ```javascript
   testUserId = 1; // ID de un usuario admin
   testCompanyId = 1; // ID de una empresa
   testDriverId = 1; // ID de un conductor
   ```
4. Ejecuta:
   ```bash
   cd backend
   node tests/test_dashboard_improvements.js
   ```

## 📝 Tests Incluidos

### ✅ Test 1: Sincronización de nombreRuta
- Crea una ruta de prueba
- Crea un bus de prueba
- Asigna el bus a la ruta
- Verifica que `nombre_ruta` se sincroniza automáticamente

### ✅ Test 2: Actualización del Estado del Conductor
- Verifica estado inicial del conductor
- Asigna conductor a bus
- Verifica que estado cambia a `'en_ruta'`
- Desasigna conductor
- Verifica que estado cambia a `'disponible'`

### ✅ Test 3: Validación Antes de Eliminar Rutas
- Intenta eliminar una ruta con buses asignados
- Verifica que el backend rechaza la operación (400)
- Verifica que el mensaje de error es descriptivo

### ✅ Test 4: Múltiples Buses por Ruta
- Crea un segundo bus
- Asigna ambos buses a la misma ruta
- Verifica que ambos buses están correctamente asignados

## 🔍 Obtener IDs Necesarios

### Obtener User ID (Admin)

```sql
-- En Supabase SQL Editor
SELECT id, name, email, role FROM users 
WHERE role IN ('super_admin', 'company_admin') 
LIMIT 1;
```

### Obtener Company ID

```sql
-- En Supabase SQL Editor
SELECT id, name FROM companies LIMIT 1;
```

### Obtener Driver ID

```sql
-- En Supabase SQL Editor
SELECT id, name, email FROM users 
WHERE role = 'driver' 
LIMIT 1;
```

## 📊 Interpretación de Resultados

### ✅ PASS
- La prueba pasó correctamente
- La funcionalidad está implementada y funciona

### ❌ FAIL
- La prueba falló
- Revisa el mensaje de error para identificar el problema
- Verifica que el backend esté corriendo
- Verifica que las variables estén configuradas correctamente

### ℹ️ INFO
- Información adicional sobre el proceso
- No indica éxito o fallo, solo información

## 🧹 Limpieza Automática

Los tests incluyen limpieza automática:
- Desasignan buses de rutas
- Eliminan buses de prueba
- Eliminan rutas de prueba

**Nota**: Los tests solo eliminan datos que crean ellos mismos (con prefijo `TEST_`).

## ⚠️ Advertencias

1. **No ejecutar en producción**: Estos tests crean y eliminan datos
2. **Backend debe estar corriendo**: Los tests hacen requests HTTP
3. **IDs válidos requeridos**: Debes proporcionar IDs reales de tu base de datos

## 🔄 Integración con CI/CD

Para integrar en un pipeline CI/CD:

```yaml
# Ejemplo para GitHub Actions
- name: Run Dashboard Tests
  run: |
    cd backend
    TEST_USER_ID=${{ secrets.TEST_USER_ID }} \
    TEST_COMPANY_ID=${{ secrets.TEST_COMPANY_ID }} \
    TEST_DRIVER_ID=${{ secrets.TEST_DRIVER_ID }} \
    node tests/test_dashboard_improvements.js
```

## 📞 Soporte

Si encuentras problemas:
1. Verifica que el backend esté corriendo
2. Verifica las variables de entorno
3. Revisa los logs del backend
4. Verifica la conexión a Supabase

