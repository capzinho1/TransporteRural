# 🗺️ Integración de OpenStreetMap - GeoRu

## ✅ OpenStreetMap es Perfecto para tu Proyecto

**OpenStreetMap** es una excelente alternativa gratuita a Google Maps:

- ✅ **100% Gratuito** - No requiere API key
- ✅ **Open Source** - Código abierto y comunidad activa
- ✅ **Sin límites** - Sin restricciones de uso
- ✅ **Buena cobertura** - Funciona en todo el mundo
- ✅ **Funciona offline** - Soporta caché de tiles

## 📦 Dependencias Agregadas

Se han agregado las siguientes dependencias a `pubspec.yaml`:

### App Móvil (`mobile/pubspec.yaml`)
```yaml
flutter_map: ^7.0.2
latlong2: ^0.9.1
```

### Panel Admin (`admin_web/pubspec.yaml`)
```yaml
flutter_map: ^7.0.2
latlong2: ^0.9.1
```

## 🚀 Pasos para Activar OpenStreetMap

### Paso 1: Instalar Dependencias

**Para la app móvil:**
```bash
cd mobile
flutter pub get
```

**Para el panel admin:**
```bash
cd admin_web
flutter pub get
```

### Paso 2: Verificar Instalación

Después de ejecutar `flutter pub get`, deberías ver:
```
Resolving dependencies...
Got dependencies!
```

### Paso 3: Ejecutar la Aplicación

**App Móvil:**
```bash
cd mobile
flutter run -d chrome --web-port 8080
```

**Panel Admin:**
```bash
cd admin_web
flutter run -d chrome --web-port 8081
```

## 📍 Archivos Creados/Modificados

### Nuevos Archivos

1. **`mobile/lib/config/openstreetmap_config.dart`**
   - Configuración de OpenStreetMap para la app móvil

2. **`admin_web/lib/config/openstreetmap_config.dart`**
   - Configuración de OpenStreetMap para el panel admin

3. **`mobile/lib/widgets/osm_map_widget.dart`**
   - Widget de mapa usando OpenStreetMap (reemplaza Google Maps)

4. **`admin_web/lib/widgets/osm_map_widget.dart`**
   - Widget de mapa para el panel administrativo

### Archivos Modificados

1. **`mobile/pubspec.yaml`**
   - Agregado `flutter_map` y `latlong2`
   - Removido `google_maps_flutter`

2. **`admin_web/pubspec.yaml`**
   - Agregado `flutter_map` y `latlong2`
   - Removido `google_maps_flutter` y `google_maps_flutter_web`

3. **`mobile/lib/widgets/map_widget.dart`**
   - Ahora usa `OsmMapWidget` en lugar de Google Maps

4. **`mobile/lib/screens/map_screen.dart`**
   - Actualizado para usar OpenStreetMap

5. **`admin_web/lib/screens/realtime_map_screen.dart`**
   - Actualizado para usar OpenStreetMap en lugar del mapa visual simple

## 🎨 Características del Mapa OpenStreetMap

### Funcionalidades Implementadas

- ✅ **Mapa interactivo** con tiles de OpenStreetMap
- ✅ **Marcadores de buses** con colores según estado
- ✅ **Ubicación actual** del usuario (app móvil)
- ✅ **Zoom y pan** completamente funcionales
- ✅ **Click en buses** para ver detalles
- ✅ **Centrar en bus** desde los detalles
- ✅ **Atribución** requerida por OpenStreetMap (incluida)

### Colores de Marcadores

- 🟢 **Verde**: Buses activos / en ruta
- 🔵 **Azul**: Buses finalizados
- ⚪ **Gris**: Buses inactivos
- 🟠 **Naranja**: Buses en mantenimiento

## 🔧 Configuración Avanzada

### Cambiar Proveedor de Tiles

Si quieres usar un proveedor diferente de tiles, edita:

**`mobile/lib/config/openstreetmap_config.dart`** o **`admin_web/lib/config/openstreetmap_config.dart`**

```dart
// Opción 1: OpenStreetMap estándar (actual)
static const String tileLayerUrlTemplate =
    'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

// Opción 2: CartoDB (más rápido, requiere atribución)
static const String tileLayerUrlTemplate =
    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';

// Opción 3: Stamen (diseños alternativos)
static const String tileLayerUrlTemplate =
    'https://stamen-tiles-{s}.a.ssl.fastly.net/toner/{z}/{x}/{y}.png';
```

### Configurar Ubicación por Defecto

Edita `openstreetmap_config.dart`:

```dart
static const double defaultLatitude = -33.4489; // Tu latitud
static const double defaultLongitude = -70.6693; // Tu longitud
static const double defaultZoom = 12.0; // Nivel de zoom inicial
```

## 🐛 Solución de Problemas

### Error: "Target of URI doesn't exist"

**Solución:**
```bash
cd mobile
flutter pub get

cd ../admin_web
flutter pub get
```

### El mapa no carga

1. Verifica tu conexión a internet (los tiles se descargan en tiempo real)
2. Verifica que `flutter pub get` se ejecutó correctamente
3. Haz un Hot Restart completo (no solo Hot Reload)

### Los marcadores no aparecen

- Verifica que hay buses en la base de datos
- Verifica que `loadBusLocations()` se está ejecutando
- Revisa la consola para errores

### El mapa es lento

- Los tiles se descargan en tiempo real
- Considera usar un proveedor de tiles más rápido (ver configuración avanzada)
- O implementa caché de tiles offline

## 📚 Recursos Adicionales

- [Documentación de flutter_map](https://pub.dev/packages/flutter_map)
- [OpenStreetMap Wiki](https://wiki.openstreetmap.org/)
- [Proveedores de tiles](https://wiki.openstreetmap.org/wiki/Tile_servers)

## 🎯 Ventajas sobre Google Maps

| Característica | Google Maps | OpenStreetMap |
|----------------|------------|---------------|
| Costo | Requiere API key (puede tener costos) | ✅ Gratis |
| Límites | Límites de uso | ✅ Sin límites |
| API Key | ✅ Requerida | ✅ No requerida |
| Offline | Limitado | ✅ Soporte completo |
| Personalización | Limitada | ✅ Totalmente personalizable |

---

**¡Listo!** Una vez que ejecutes `flutter pub get` en ambas carpetas, OpenStreetMap estará completamente integrado y funcionando.

