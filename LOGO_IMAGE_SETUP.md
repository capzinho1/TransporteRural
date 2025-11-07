# 🖼️ Configuración del Logo GeoRu como Imagen

## 📍 Ubicación del Archivo

Coloca tu logo GeoRu en uno de estos lugares:

### App Móvil (`mobile/`)
```
mobile/assets/images/georu_logo.webp
```
o
```
mobile/assets/images/georu_logo.png
```

### Panel Administrativo (`admin_web/`)
```
admin_web/assets/images/georu_logo.webp
```
o
```
admin_web/assets/images/georu_logo.png
```

## ✅ Formatos Soportados

El widget soporta automáticamente:
- ✅ **WebP** (recomendado - mejor compresión)
- ✅ **PNG** (también funciona perfectamente)
- ✅ **JPEG/JPG** (si renombras el archivo)

## 🔧 Pasos para Configurar

### 1. Colocar el archivo del logo

1. Copia tu archivo `georu_logo.webp` (o `.png`)
2. Pégalo en `mobile/assets/images/`
3. Si también quieres usarlo en el admin, pégalo en `admin_web/assets/images/`

### 2. Verificar que los assets estén configurados

Los archivos `pubspec.yaml` ya están configurados para incluir `assets/images/`:

**mobile/pubspec.yaml:**
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```

**admin_web/pubspec.yaml:**
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```

### 3. Ejecutar `flutter pub get`

Después de agregar el archivo, ejecuta:

```bash
# Para mobile
cd mobile
flutter pub get

# Para admin_web
cd admin_web
flutter pub get
```

### 4. Hot Restart (no solo Hot Reload)

Después de agregar nuevos assets, necesitas hacer un **Hot Restart** completo:
- En VS Code: `Ctrl+Shift+F5` o `Cmd+Shift+F5`
- En Android Studio: Botón de "Restart" (no solo "Hot Reload")

## 🎨 Cómo Funciona

El widget `GeoRuLogo` ahora:

1. **Primero intenta cargar** la imagen desde `assets/images/georu_logo.webp`
2. **Si no existe**, intenta `assets/images/georu_logo.png`
3. **Si no existe**, intenta `assets/images/logo.webp` o `logo.png`
4. **Si ninguna imagen existe**, usa el `CustomPainter` (dibujo programático) como fallback

## 📝 Nombres de Archivo Soportados

El widget busca automáticamente estos nombres (en orden de prioridad):
1. `georu_logo.webp` ⭐ (recomendado)
2. `georu_logo.png`
3. `logo.webp`
4. `logo.png`

## 🔍 Verificación

Para verificar que el logo se está cargando correctamente:

1. Ejecuta la app: `flutter run -d chrome --web-port 8080`
2. Ve a la pantalla de login
3. Deberías ver tu logo WebP/PNG en lugar del dibujo programático

## 🐛 Troubleshooting

### El logo no aparece
- ✅ Verifica que el archivo esté en `mobile/assets/images/`
- ✅ Verifica que el nombre sea exactamente `georu_logo.webp` o `georu_logo.png`
- ✅ Ejecuta `flutter pub get` después de agregar el archivo
- ✅ Haz un **Hot Restart** completo (no solo Hot Reload)
- ✅ Verifica que el archivo no esté corrupto

### Error: "Unable to load asset"
- ✅ Verifica que `pubspec.yaml` incluya `assets/images/`
- ✅ Verifica que el nombre del archivo sea correcto (case-sensitive)
- ✅ Ejecuta `flutter clean` y luego `flutter pub get`

### El logo se ve pixelado
- ✅ Usa una imagen de alta resolución (al menos 2x el tamaño de visualización)
- ✅ Para un logo de 120px, usa una imagen de al menos 240x240px
- ✅ WebP mantiene mejor calidad con menor tamaño que PNG

### Prefiero usar PNG en lugar de WebP
- ✅ Simplemente renombra tu archivo a `georu_logo.png`
- ✅ El widget lo detectará automáticamente
- ✅ Colócalo en `mobile/assets/images/georu_logo.png`

## 💡 Recomendaciones

- **Tamaño recomendado**: 240x240px o 512x512px para mejor calidad
- **Formato**: WebP es mejor (menor tamaño, misma calidad)
- **Fondo**: Si tu logo tiene fondo transparente, funcionará perfectamente
- **Colores**: El widget respetará los colores originales de tu imagen

---

**Nota**: Si no colocas ninguna imagen, el widget seguirá funcionando usando el dibujo programático (CustomPainter) como respaldo.

