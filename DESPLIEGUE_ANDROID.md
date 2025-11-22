# 📱 Despliegue de la App Móvil en Android

## ⚠️ NOTA IMPORTANTE

Esta guía es para **publicar en Google Play Store**. 

**Si solo quieres generar un APK para uso personal**, usa la guía más simple: `DESPLIEGUE_SIMPLE.md`

---

## 📋 Requisitos Previos

- [ ] Flutter SDK instalado (versión 3.0+)
- [ ] Android Studio instalado
- [ ] Cuenta de Google Play Developer ($25 USD, pago único)
- [ ] Backend API desplegado y funcionando
- [ ] Credenciales de Supabase configuradas
- [ ] Google OAuth configurado

---

## 🔧 Paso 1: Configurar la URL del Backend

Antes de compilar, actualiza la URL del backend en el código.

### Archivo a modificar: `mobile/lib/services/api_service.dart`

**Línea 12** actualmente tiene:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

**Cambiar a** (usando tu dominio de backend):
```dart
static const String baseUrl = 'https://api.georu.cl/api';  // O tu dominio real
```

**⚠️ IMPORTANTE**: 
- Usa `https://` (no `http://`)
- No uses `localhost` en producción
- El backend debe tener CORS configurado (aunque para Android nativo no es crítico)

---

## 🔧 Paso 2: Verificar Configuración de Supabase

### Archivo: `mobile/lib/main.dart`

Verifica que las credenciales de Supabase estén correctas (líneas 27-29):

```dart
const supabaseUrl = 'https://aghbbmbbfcgtpipnrjev.supabase.co';
const supabaseAnonKey = 'tu_anon_key_aqui';
```

---

## 🔑 Paso 3: Configurar Google OAuth para Android

### 3.1 Obtener SHA-1 y SHA-256

Necesitas el SHA-1 y SHA-256 de tu keystore para configurar OAuth en Google Cloud Console.

**Para Debug (desarrollo):**
```bash
cd mobile/android
./gradlew signingReport
```

O en Windows:
```bash
cd mobile\android
gradlew.bat signingReport
```

Busca en la salida:
```
Variant: debug
Config: debug
Store: C:\Users\...\.android\debug.keystore
Alias: AndroidDebugKey
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
SHA256: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```

**Para Release (producción):**
Primero necesitas crear un keystore (ver Paso 4), luego:
```bash
keytool -list -v -keystore tu-keystore.jks -alias tu-alias
```

### 3.2 Configurar en Google Cloud Console

1. Ve a https://console.cloud.google.com/apis/credentials
2. Edita tu **Cliente OAuth Android** (o crea uno nuevo)
3. Agrega el **SHA-1** y **SHA-256** obtenidos
4. **Package name**: `com.transporterural` (verificar en `mobile/android/app/build.gradle`)

---

## 🔐 Paso 4: Crear Keystore para Release

Necesitas un keystore para firmar la app de producción.

### 4.1 Generar Keystore

```bash
cd mobile/android
keytool -genkey -v -keystore georu-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias georu
```

**Información que te pedirá:**
- Contraseña del keystore (GUÁRDALA BIEN, no la pierdas)
- Nombre y apellido
- Unidad organizacional
- Ciudad
- Estado/Provincia
- Código de país (ej: CL para Chile)

**⚠️ CRÍTICO**: 
- Guarda el keystore en un lugar seguro
- Guarda la contraseña
- Si pierdes el keystore, NO podrás actualizar la app en Play Store

### 4.2 Configurar key.properties

Crea `mobile/android/key.properties`:

```properties
storePassword=tu_contraseña_del_keystore
keyPassword=tu_contraseña_del_keystore
keyAlias=georu
storeFile=../georu-release-key.jks
```

**⚠️ IMPORTANTE**: Agrega `key.properties` a `.gitignore` (NO subirlo a Git)

### 4.3 Configurar build.gradle

Edita `mobile/android/app/build.gradle` (o `build.gradle.kts`):

**Antes de `android {`:**
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

**Dentro de `android {`, reemplaza `buildTypes`:**
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}
buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
    }
}
```

---

## 📦 Paso 5: Configurar App ID y Versión

### 5.1 Verificar Package Name

En `mobile/android/app/build.gradle`, verifica:
```gradle
applicationId "com.transporterural"
```

### 5.2 Configurar Versión

En `mobile/pubspec.yaml`:
```yaml
version: 1.0.0+1
```
- `1.0.0` = versión de la app (visible al usuario)
- `+1` = build number (debe incrementarse en cada release)

---

## 🏗️ Paso 6: Build de la App

### 6.1 Build APK (para testing)

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
```

**Output**: `mobile/build/app/outputs/flutter-apk/app-release.apk`

### 6.2 Build App Bundle (para Play Store) - RECOMENDADO

```bash
cd mobile
flutter clean
flutter pub get
flutter build appbundle --release
```

**Output**: `mobile/build/app/outputs/bundle/release/app-release.aab`

**⚠️ IMPORTANTE**: 
- El AAB (Android App Bundle) es el formato requerido por Google Play Store
- El APK es útil para testing o distribución directa

---

## 📱 Paso 7: Probar la App Localmente

### 7.1 Instalar en dispositivo físico

```bash
# Conecta tu dispositivo Android vía USB
# Habilita "Depuración USB" en opciones de desarrollador

flutter install
```

O instala el APK manualmente:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 7.2 Verificar funcionalidades

- [ ] La app inicia correctamente
- [ ] Login funciona (email/password)
- [ ] Login con Google funciona
- [ ] Se conecta al backend correctamente
- [ ] Los mapas cargan
- [ ] Las notificaciones funcionan (si aplica)
- [ ] No hay crashes

---

## 🚀 Paso 8: Subir a Google Play Store

### 8.1 Crear cuenta de Google Play Developer

1. Ve a https://play.google.com/console
2. Paga la tarifa única de $25 USD
3. Completa el perfil de desarrollador

### 8.2 Crear la aplicación

1. En Play Console, haz clic en "Crear aplicación"
2. Completa la información:
   - **Nombre de la app**: GeoRu (o el que prefieras)
   - **Idioma predeterminado**: Español
   - **Tipo de app**: App
   - **Gratis o de pago**: Gratis

### 8.3 Configurar Store Listing

Completa:
- **Descripción corta** (80 caracteres)
- **Descripción completa** (4000 caracteres)
- **Capturas de pantalla** (mínimo 2, recomendado 8)
- **Icono de la app** (512x512 px)
- **Imagen destacada** (1024x500 px)
- **Categoría**: Transporte
- **Contacto**: Email de soporte

### 8.4 Configurar Contenido de la app

1. **Política de privacidad**: URL a tu política (obligatorio)
2. **Clasificación de contenido**: Completa el cuestionario
3. **Objetivo y público**: Configura restricciones de edad

### 8.5 Subir el AAB

1. Ve a **Producción** → **Crear nueva versión**
2. Sube el archivo `app-release.aab`
3. Completa las **Notas de la versión**
4. Haz clic en **Revisar versión**

### 8.6 Revisar y publicar

1. Revisa todos los requisitos:
   - [ ] Store listing completo
   - [ ] Política de privacidad
   - [ ] Contenido de la app configurado
   - [ ] AAB subido
   - [ ] Clasificación de contenido

2. Haz clic en **Iniciar rollout a producción**

3. Google revisará la app (puede tardar 1-7 días)

---

## 🔄 Paso 9: Actualizaciones Futuras

Para actualizar la app:

1. **Incrementar versión** en `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # Incrementar ambos números
   ```

2. **Build nuevo AAB**:
   ```bash
   flutter build appbundle --release
   ```

3. **Subir a Play Console**:
   - Ve a tu app
   - Producción → Crear nueva versión
   - Sube el nuevo AAB
   - Publica

---

## 🐛 Solución de Problemas

### Error: "Gradle build failed"
**Solución**:
```bash
cd mobile/android
./gradlew clean
cd ../..
flutter clean
flutter pub get
flutter build appbundle --release
```

### Error: "Keystore file not found"
**Solución**: 
- Verifica la ruta en `key.properties`
- Asegúrate de que el keystore esté en `mobile/android/`

### Error: OAuth no funciona en Android
**Solución**:
1. Verifica SHA-1 y SHA-256 en Google Cloud Console
2. Verifica que el package name sea correcto
3. Verifica que el Client ID de Android esté configurado en Supabase

### Error: "App not installed" al instalar APK
**Solución**:
- Habilita "Instalar desde fuentes desconocidas" en Android
- O usa `adb install` desde la computadora

### La app no se conecta al backend
**Solución**:
1. Verifica que la URL en `api_service.dart` sea correcta
2. Verifica que uses `https://` (no `http://`)
3. Verifica que el backend esté funcionando
4. Revisa logs: `flutter logs` o `adb logcat`

---

## 📊 Monitoreo Post-Lanzamiento

### Google Play Console
- **Estadísticas**: Descargas, usuarios activos, crashes
- **Reseñas**: Lee y responde reseñas
- **Crashes**: Revisa reportes de errores

### Firebase Crashlytics (Opcional)
Integra Firebase para mejor tracking de errores:
```bash
flutter pub add firebase_crashlytics
```

---

## ✅ Checklist Final

### Pre-Build
- [ ] URL del backend actualizada
- [ ] Credenciales de Supabase verificadas
- [ ] Keystore creado y configurado
- [ ] SHA-1 y SHA-256 agregados a Google Cloud Console
- [ ] Package name verificado

### Build
- [ ] Build AAB exitoso
- [ ] App probada en dispositivo físico
- [ ] Todas las funcionalidades probadas

### Play Store
- [ ] Cuenta de desarrollador creada
- [ ] Store listing completo
- [ ] Política de privacidad publicada
- [ ] AAB subido
- [ ] App publicada

---

## 🎉 ¡Listo!

Tu app Android debería estar disponible en Google Play Store.

**Próximos pasos**:
- Monitorear descargas y reseñas
- Responder a feedback de usuarios
- Planificar actualizaciones

---

## 📝 Notas Adicionales

### Distribución Interna (Testing)
Si quieres distribuir la app sin Play Store:
- Usa **Google Play Internal Testing** (gratis)
- O distribuye el APK directamente (menos seguro)

### Versiones de Android
Verifica `minSdkVersion` en `build.gradle`:
```gradle
minSdkVersion 21  // Android 5.0 (Lollipop)
```

### Permisos
Revisa `mobile/android/app/src/main/AndroidManifest.xml` para verificar permisos necesarios (ubicación, internet, etc.)

