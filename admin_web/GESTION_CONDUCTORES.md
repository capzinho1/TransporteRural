# 🚗 Gestión de Conductores y Asignaciones - TransporteRural

## Descripción
El sistema de gestión avanzada de rutas permite asignar conductores y buses específicos a cada ruta. Esta funcionalidad centraliza toda la operación del transporte rural, permitiendo un control completo sobre quién maneja cada bus y en qué ruta opera.

## 📋 Características Principales

### ✨ Gestión Integral
- **Asignación de Conductores**: Asigna conductores específicos a rutas
- **Asignación de Buses**: Vincula buses a rutas operativas
- **Vista Consolidada**: Visualiza todas las asignaciones en un solo lugar
- **Estadísticas en Tiempo Real**: Monitorea conductores activos y buses disponibles
- **Registro Rápido**: Crea nuevos conductores directamente desde la pantalla

### 🎯 Funcionalidades

#### 1. Dashboard de Estadísticas
Muestra en tiempo real:
- **Conductores Totales**: Cantidad de conductores registrados
- **Conductores Asignados**: Conductores actualmente operando
- **Buses Disponibles**: Buses sin asignación de ruta
- **Rutas Activas**: Rutas con conductor y bus asignados

#### 2. Gestión de Rutas
Cada ruta muestra:
- ✅ **Estado de Asignación**: Visual de si tiene conductor asignado
- 👤 **Conductor Actual**: Nombre del conductor operando
- 🚌 **Bus Asignado**: Identificador del bus en la ruta
- 📍 **Paradas**: Lista completa de paradas de la ruta
- ⚙️ **Acciones Rápidas**: Asignar, editar o remover asignaciones

#### 3. Registro de Conductores
- Crear nuevos conductores desde la interfaz
- Campos requeridos: Nombre completo y Email
- Rol automático como 'driver'
- Disponibles inmediatamente para asignación

#### 4. Asignación de Recursos
- Selección de conductor desde dropdown
- Selección de bus disponible
- Solo muestra buses sin asignación previa
- Actualización automática del estado del bus
- Confirmación visual de asignación exitosa

## 🚀 Cómo Usar

### Acceder a la Pantalla
```
Panel Admin → Menú Lateral → "Rutas y Horarios"
```

### Crear un Nuevo Conductor

1. Clic en el botón **"Nuevo Conductor"** (verde, esquina superior derecha)
2. Completa el formulario:
   - **Nombre Completo**: Nombre del conductor
   - **Email**: Correo electrónico único
3. Clic en **"Crear Conductor"**
4. ✅ El conductor queda disponible para asignación inmediata

### Asignar Conductor y Bus a una Ruta

#### Opción 1: Desde la Tarjeta de Ruta
1. Encuentra la ruta en la lista
2. Clic en el ícono de **+** (verde) o **✏️** (azul) en la tarjeta
3. Se abre el diálogo de asignación

#### Opción 2: Desde los Detalles de la Ruta
1. Expande la ruta haciendo clic en la tarjeta
2. Revisa las paradas
3. Clic en el botón **"Asignar Conductor y Bus"** al final

#### En el Diálogo de Asignación:
1. **Seleccionar Conductor**: Dropdown con todos los conductores disponibles
2. **Seleccionar Bus**: Dropdown con buses sin asignación actual
3. Clic en **"Guardar"**
4. ✅ Confirmación de asignación exitosa

### Modificar una Asignación

1. Localiza la ruta con asignación (marcada en verde ✅)
2. Clic en el ícono de edición (✏️ azul)
3. Cambia conductor y/o bus según necesites
4. Clic en **"Guardar"**

### Remover una Asignación

1. Abre el diálogo de asignación de la ruta
2. Clic en el botón rojo **"Remover"**
3. Confirma la acción
4. El bus queda disponible para otras rutas
5. El conductor queda disponible para reasignación

## 📊 Estados Visuales

### Indicadores de Estado en Tarjetas

| Indicador | Significado |
|-----------|-------------|
| ✅ Chip verde "Asignada" | Ruta con conductor y bus asignados |
| ⚠️ Advertencia naranja | Ruta sin asignación |
| 👤 Ícono persona | Información del conductor |
| 🚌 Ícono bus | Información del bus |
| 📍 Contador de paradas | Cantidad de paradas en la ruta |

### Colores de Botones

| Color | Acción |
|-------|--------|
| 🟢 Verde | Asignar nuevo / Crear conductor |
| 🔵 Azul | Editar asignación existente |
| 🔴 Rojo | Remover asignación |
| ⚪ Gris | Cancelar |

## 💾 Datos en Supabase

### Tabla `users` (Conductores)
```sql
-- Ejemplo de conductor
{
  id: 3,
  email: 'pedro.gomez@transporterural.com',
  name: 'Pedro Gómez',
  role: 'driver',
  created_at: '2025-01-01T10:00:00'
}
```

### Tabla `bus_locations` (Asignaciones)
```sql
-- Ejemplo de bus asignado
{
  id: 1,
  bus_id: 'BUS-001',
  route_id: 'LONGAVI-CHALET',
  driver_id: 3,
  latitude: -36.0053,
  longitude: -71.6850,
  status: 'active',
  last_update: '2025-01-01T14:30:00'
}
```

## 🔄 Flujo de Trabajo Recomendado

### Configuración Inicial

1. **Crear Rutas**
   - Usa "Plantillas de Rutas" para crear rutas rápidamente
   - O crea rutas personalizadas en "Rutas y Horarios"

2. **Registrar Conductores**
   - Crea todos los conductores que operarán
   - Asegúrate de usar emails únicos

3. **Registrar Buses**
   - Ve a "Gestión de Buses"
   - Crea los buses disponibles para operar

4. **Realizar Asignaciones**
   - Asigna conductor + bus a cada ruta operativa
   - Verifica que los datos sean correctos

### Operación Diaria

1. **Verificar Asignaciones Activas**
   - Revisa el dashboard de estadísticas
   - Confirma que todas las rutas necesarias tengan asignación

2. **Modificar según Necesidad**
   - Reasigna conductores si hay cambios
   - Cambia buses en caso de mantenimiento

3. **Monitorear en Tiempo Real**
   - Usa "Mapa en Tiempo Real" para supervisar operación
   - Verifica ubicaciones y estados de buses

## 📱 Sincronización con App Móvil

Las asignaciones se reflejan automáticamente en:
- **App Móvil de Usuarios**: Pueden ver qué buses están activos en cada ruta
- **Seguimiento en Tiempo Real**: Las ubicaciones se actualizan para los buses asignados
- **Información de Rutas**: Los horarios y paradas son visibles para los pasajeros

## ⚠️ Notas Importantes

### Restricciones
- ❌ **Un bus solo puede estar en una ruta a la vez**
- ❌ **Un conductor solo puede operar un bus a la vez**
- ✅ **Varios conductores pueden estar registrados sin asignación**
- ✅ **Un conductor puede ser reasignado a diferentes rutas en diferentes momentos**

### Mejores Prácticas
- 📝 **Usa nombres descriptivos** para conductores (nombre completo real)
- 📧 **Emails únicos** para cada conductor (pueden ser ficticios si es necesario)
- 🔄 **Actualiza asignaciones** cuando haya cambios operativos
- 🚫 **Remueve asignaciones** cuando un bus entre en mantenimiento
- ✅ **Verifica disponibilidad** antes de asignar

## 🛠️ Solución de Problemas

### "No hay conductores registrados"
**Solución**: Haz clic en "Crear Conductor" en el diálogo de asignación o usa el botón "Nuevo Conductor" en el header.

### "No hay buses disponibles"
**Solución**: 
1. Ve a "Gestión de Buses"
2. Crea nuevos buses
3. O remueve asignaciones de buses no operativos

### No aparece el conductor en el dropdown
**Verificar**:
1. Que el usuario tenga `role: 'driver'` en la base de datos
2. Que el conductor esté registrado correctamente
3. Recarga la página (F5)

### La asignación no se guarda
**Verificar**:
1. Que tanto conductor como bus estén seleccionados
2. Que el bus no esté ya asignado a otra ruta
3. Revisa la consola del navegador para errores

## 📈 Métricas y Reportes

La pantalla muestra en tiempo real:
- **Tasa de asignación**: Rutas asignadas vs rutas totales
- **Conductores activos**: Conductores operando vs conductores totales
- **Utilización de flota**: Buses en operación vs buses disponibles
- **Cobertura de rutas**: Rutas con servicio activo

## 🎯 Casos de Uso

### Caso 1: Inicio de Operaciones del Día
1. Verifica conductores disponibles
2. Asigna conductores a rutas prioritarias
3. Confirma que los buses estén asignados
4. Monitorea en "Mapa en Tiempo Real"

### Caso 2: Cambio de Turno
1. Remueve asignación del conductor saliente
2. Asigna nuevo conductor al mismo bus/ruta
3. Verifica que el cambio se refleje en la app móvil

### Caso 3: Mantenimiento de Bus
1. Remueve asignación del bus en mantenimiento
2. Asigna un bus de reemplazo si está disponible
3. El conductor puede ser reasignado al nuevo bus

### Caso 4: Nueva Ruta
1. Crea la ruta desde plantillas o manualmente
2. Verifica que haya conductor disponible
3. Verifica que haya bus disponible
4. Realiza la asignación completa

## 📞 Soporte

Para modificar la lógica de asignación o agregar validaciones adicionales, edita el archivo:
`admin_web/lib/screens/routes_advanced_screen_v2.dart`

---

**¡Sistema completo de gestión de conductores y asignaciones implementado!** 🎉


