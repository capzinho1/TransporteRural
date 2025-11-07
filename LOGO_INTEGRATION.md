# 🎨 Integración del Logo GeoRu

El logo GeoRu ha sido integrado en todas las partes necesarias del proyecto. Actualmente se está usando un widget Flutter personalizado que dibuja el logo basándose en la descripción proporcionada.

## 📍 Ubicaciones donde se usa el logo

### App Móvil (`mobile/`)
- ✅ **Splash Screen** - Logo grande con texto y eslogan
- ✅ **Login Screen** - Logo con texto "GeoRu"
- ✅ **Home Screen** - Logo pequeño en el AppBar

### Panel Administrativo (`admin_web/`)
- ✅ **Login Screen** - Logo con texto "GeoRu"
- ✅ **Dashboard AppBar** - Logo pequeño con texto
- ✅ **Drawer Header** - Logo con información del usuario

### Archivos Web
- ✅ **Títulos** - Actualizados a "GeoRu"
- ✅ **Manifest.json** - Nombres y descripciones actualizadas
- ✅ **Meta tags** - Descripciones SEO actualizadas

## 🖼️ Usar tu logo como imagen (Opcional)

Si tienes el logo GeoRu como archivo de imagen (PNG, SVG, etc.), puedes reemplazar el widget personalizado:

### Paso 1: Agregar la imagen del logo

1. Coloca tu logo en:
   - `mobile/assets/images/georu_logo.png` (o SVG)
   - `admin_web/assets/images/georu_logo.png` (o SVG)

2. Si usas SVG, asegúrate de tener `flutter_svg` en `pubspec.yaml` (ya está incluido)

### Paso 2: Actualizar el widget GeoRuLogo

Edita `mobile/lib/widgets/georu_logo.dart` y `admin_web/lib/widgets/georu_logo.dart`:

```dart
Widget _buildLogoIcon(double size) {
  // Opción 1: PNG/JPG
  return Image.asset(
    'assets/images/georu_logo.png',
    width: size,
    height: size,
    fit: BoxFit.contain,
  );
  
  // Opción 2: SVG
  // return SvgPicture.asset(
  //   'assets/images/georu_logo.svg',
  //   width: size,
  //   height: size,
  //   fit: BoxFit.contain,
  // );
}
```

### Paso 3: Actualizar pubspec.yaml (si agregaste nuevas imágenes)

Ya está configurado para incluir `assets/images/`, pero verifica que tus archivos estén en:
- `mobile/pubspec.yaml` → `assets: - assets/images/`
- `admin_web/pubspec.yaml` → `assets: - assets/images/`

### Paso 4: Actualizar favicon e iconos web

Para actualizar el favicon y los iconos de la web:

1. **Favicon** (`mobile/web/favicon.png` y `admin_web/web/favicon.png`):
   - Crea un favicon de 32x32 o 64x64 píxeles
   - Reemplaza los archivos existentes

2. **Iconos de la app** (`mobile/web/icons/` y `admin_web/web/icons/`):
   - `Icon-192.png` - 192x192 píxeles
   - `Icon-512.png` - 512x512 píxeles
   - `Icon-maskable-192.png` - 192x192 píxeles (con padding)
   - `Icon-maskable-512.png` - 512x512 píxeles (con padding)

   Puedes usar herramientas online como:
   - [Favicon Generator](https://favicon.io/)
   - [App Icon Generator](https://appicon.co/)

## 🎨 Personalización del Logo Actual

El logo actual está dibujado con `CustomPainter`. Puedes ajustar los colores editando `GeoRuLogoPainter`:

```dart
// Colores actuales:
paint.color = const Color(0xFF1B5E20); // Verde oscuro (parte izquierda)
paint.color = const Color(0xFF81D4FA); // Azul claro (parte derecha)
roadGradient colors: [
  const Color(0xFFA5D6A7), // Verde claro (inicio del camino)
  const Color(0xFF8D6E63), // Marrón tierra (fin del camino)
]
```

## ✅ Verificación

Después de integrar tu logo:

1. **Ejecuta la app móvil:**
   ```bash
   cd mobile
   flutter run -d chrome --web-port 8080
   ```
   Verifica que el logo aparezca en:
   - Pantalla de inicio (splash)
   - Pantalla de login
   - Barra superior (AppBar)

2. **Ejecuta el panel admin:**
   ```bash
   cd admin_web
   flutter run -d chrome --web-port 8081
   ```
   Verifica que el logo aparezca en:
   - Pantalla de login
   - Barra superior
   - Menú lateral (Drawer)

3. **Verifica los títulos web:**
   - Abre `http://localhost:8080` y verifica el título del navegador
   - Abre `http://localhost:8081` y verifica el título del navegador

## 📝 Notas

- El widget `GeoRuLogo` es completamente reutilizable y configurable
- Puedes mostrar solo el ícono, solo el texto, o ambos
- El tamaño es ajustable mediante el parámetro `size`
- El fondo es opcional mediante `showBackground`

## 🔧 Troubleshooting

**El logo no aparece:**
- Verifica que los assets estén declarados en `pubspec.yaml`
- Ejecuta `flutter pub get` después de agregar nuevos assets
- Verifica que las rutas de las imágenes sean correctas

**El logo se ve pixelado:**
- Usa imágenes de alta resolución (al menos 2x el tamaño de visualización)
- Para SVG, asegúrate de que el archivo sea vectorial y no rasterizado

**Los colores no coinciden:**
- Ajusta los colores en `GeoRuLogoPainter` si usas el widget personalizado
- Si usas imagen, edita la imagen directamente

---

**¿Necesitas ayuda?** Revisa los archivos de ejemplo en `mobile/lib/widgets/georu_logo.dart` y `admin_web/lib/widgets/georu_logo.dart`.

