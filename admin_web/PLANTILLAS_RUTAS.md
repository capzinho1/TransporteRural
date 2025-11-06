# 📋 Plantillas de Rutas - TransporteRural

## Descripción
El sistema de plantillas de rutas permite a los administradores crear rutas rápidamente desde plantillas predefinidas para la Región del Maule. Esto agiliza el proceso de configuración de nuevas rutas, especialmente para rutas rurales comunes o recurrentes.

## Características

### ✨ Funcionalidades Principales
- **12 Plantillas Predefinidas**: Rutas rurales de Longaví y Linares con ida y vuelta
- **Categorización**: Plantillas organizadas por comuna (Longaví, Linares)
- **Creación Rápida**: Genera una ruta completa con un solo clic
- **Personalización**: Modifica ID, nombre y horarios antes de crear
- **Vista Previa**: Revisa todas las paradas y horarios antes de crear la ruta

### 📍 Plantillas Disponibles

#### Longaví (6 rutas)
1. **Longaví - Chalet Quemado**
   - 4 paradas hacia Chalet Quemado
   - 6 horarios sugeridos (07:00 - 20:00)

2. **Chalet Quemado - Longaví**
   - 4 paradas de regreso
   - 6 horarios sugeridos (07:30 - 20:30)

3. **Longaví - Las Rosas**
   - 4 paradas hacia Las Rosas
   - 6 horarios sugeridos (06:30 - 19:00)

4. **Las Rosas - Longaví**
   - 4 paradas de regreso
   - 6 horarios sugeridos (07:00 - 19:30)

5. **Longaví - Los Cristales**
   - 4 paradas hacia Los Cristales
   - 6 horarios sugeridos (06:00 - 19:00)

6. **Los Cristales - Longaví**
   - 4 paradas de regreso
   - 6 horarios sugeridos (06:30 - 19:30)

#### Linares (6 rutas)
7. **Linares - Maitencillo**
   - 5 paradas hacia Maitencillo
   - 6 horarios sugeridos (06:30 - 19:30)

8. **Maitencillo - Linares**
   - 5 paradas de regreso
   - 6 horarios sugeridos (07:00 - 20:00)

9. **Linares - Las Cabras**
   - 4 paradas hacia Las Cabras
   - 6 horarios sugeridos (06:00 - 19:00)

10. **Las Cabras - Linares**
    - 4 paradas de regreso
    - 6 horarios sugeridos (06:30 - 19:30)

11. **Linares - Semillero**
    - 5 paradas hacia Semillero
    - 6 horarios sugeridos (05:30 - 18:30)

12. **Semillero - Linares**
    - 5 paradas de regreso
    - 6 horarios sugeridos (06:00 - 19:00)

## Cómo Usar

### 1. Acceder a Plantillas
```
Panel Admin → Menú Lateral → "Plantillas de Rutas"
```

### 2. Filtrar por Categoría
- Selecciona una categoría en los chips de filtro
- O elige "Todos" para ver todas las plantillas

### 3. Ver Detalles de una Plantilla
- Haz clic en cualquier tarjeta de plantilla
- Se abrirá un modal con:
  - Lista completa de paradas (en orden)
  - Horarios sugeridos
  - Descripción de la ruta

### 4. Crear Ruta desde Plantilla
- Desde el modal de vista previa o la tarjeta, haz clic en "Crear Ruta"
- Completa el formulario:
  - **ID de Ruta**: Identificador único (ej: RUTA-001)
  - **Nombre**: Personaliza el nombre si lo deseas
  - **Horarios**: Selecciona los horarios que necesites
- Haz clic en "Crear Ruta"
- ✅ La ruta se creará con todas las paradas predefinidas

## Estructura de una Plantilla

```dart
RouteTemplate(
  id: 'CENTRO-MAIPU',                    // ID base sugerido
  name: 'Santiago Centro - Maipú',       // Nombre descriptivo
  description: 'Ruta desde el centro...', // Descripción
  category: 'Centro',                     // Categoría
  scheduleOptions: ['06:00', '07:00'],   // Horarios sugeridos
  stops: [                                // Paradas predefinidas
    TemplateStop(
      nombre: 'Terminal Santiago',
      latitud: -33.4489,
      longitud: -70.6693,
      orden: 1,
    ),
    // ... más paradas
  ],
)
```

## Personalización de Plantillas

### Agregar Nuevas Plantillas
1. Abre `admin_web/lib/models/route_template.dart`
2. En `RouteTemplates.templates`, agrega una nueva plantilla:

```dart
RouteTemplate(
  id: 'MI-RUTA',
  name: 'Mi Ruta Personalizada',
  description: 'Descripción de mi ruta',
  category: 'MiCategoria', // Puedes crear nuevas categorías
  scheduleOptions: ['08:00', '14:00', '20:00'],
  stops: [
    TemplateStop(
      nombre: 'Parada 1',
      latitud: -33.4372,
      longitud: -70.6506,
      orden: 1,
    ),
    // Agrega más paradas...
  ],
),
```

### Crear Nueva Categoría
Las categorías se generan automáticamente desde las plantillas. Solo asigna un nuevo `category` y aparecerá en los filtros.

### Colores de Categorías
Para asignar un color personalizado a una nueva categoría, edita el método `_getCategoryColor()` en `route_templates_screen.dart`:

```dart
Color _getCategoryColor(String category) {
  switch (category) {
    case 'MiCategoria':
      return Colors.teal;
    // ... casos existentes
  }
}
```

## Ventajas

✅ **Ahorro de Tiempo**: Crea rutas completas en segundos
✅ **Consistencia**: Usa configuraciones probadas
✅ **Menos Errores**: Paradas pre-verificadas
✅ **Flexibilidad**: Personaliza antes de crear
✅ **Escalable**: Fácil agregar nuevas plantillas

## Interfaz de Usuario

### Grid de Plantillas
- Diseño en 3 columnas
- Cada tarjeta muestra:
  - Categoría con color
  - Nombre de la ruta
  - Descripción
  - Número de paradas y horarios
  - Botón "Crear Ruta"

### Modal de Vista Previa
- Header con categoría
- Descripción completa
- Lista numerada de paradas
- Chips con horarios sugeridos
- Botón para crear directamente

### Formulario de Creación
- ID editable (pre-rellenado)
- Nombre editable (pre-rellenado)
- Selección múltiple de horarios
- Contador de paradas incluidas

## Integración con el Sistema

Las rutas creadas desde plantillas:
- Se almacenan en Supabase como cualquier otra ruta
- Están disponibles inmediatamente en el panel "Rutas y Horarios"
- Se sincronizan con la app móvil en tiempo real
- Pueden editarse posteriormente si es necesario

## Tips

💡 **ID Único**: Asegúrate de usar un ID único para cada ruta
💡 **Horarios Flexibles**: No estás obligado a usar todos los horarios sugeridos
💡 **Edición Posterior**: Puedes editar las rutas creadas desde "Rutas y Horarios"
💡 **Coordenadas**: Las coordenadas están pre-configuradas y funcionan correctamente

## Soporte

Si necesitas:
- Agregar nuevas plantillas de rutas comunes
- Crear categorías personalizadas
- Modificar horarios sugeridos

Edita el archivo: `admin_web/lib/models/route_template.dart`

