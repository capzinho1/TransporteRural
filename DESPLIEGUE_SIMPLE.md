# 🚀 Despliegue Simple - Paso a Paso

## 🎯 Objetivo
- ✅ Generar APK para usar en tu dispositivo Android
- ✅ Backend corriendo en local (para desarrollo/testing)
- ✅ Panel Admin en Vercel (opcional por ahora)

---

## 📋 Paso 1: Configurar Backend Local

### 1.1 Verificar que el Backend Funciona

```bash
cd backend
npm install
npm run dev
```

Deberías ver:
```
🚌 TransporteRural API ejecutándose en puerto 3000
🌐 Acceso: http://localhost:3000
```

### 1.2 Verificar que Funciona

Abre en el navegador: `http://localhost:3000/health`

Deberías ver:
```json
{
  "status": "OK",
  "message": "TransporteRural API funcionando correctamente"
}
```

**✅ Si funciona, el backend está listo para usar localmente.**

---

## 📱 Paso 2: Configurar App Android para Backend Local

### 2.1 Problema: Android no puede acceder a `localhost`

Cuando ejecutas la app en un dispositivo Android físico, `localhost` se refiere al dispositivo, no a tu computadora.

### 2.2 Solución: Usar la IP de tu computadora

**En Windows:**
```powershell
ipconfig
```

Busca la dirección IPv4, algo como: `192.168.1.100` o `10.0.0.5`

**En Mac/Linux:**
```bash
ifconfig
# o
ip addr show
```

### 2.3 Actualizar URL en el código

**Archivo**: `mobile/lib/services/api_service.dart`

**Línea 12**, cambiar de:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

**A** (usando tu IP):
```dart
static const String baseUrl = 'http://192.168.1.100:3000/api';  // Reemplaza con TU IP
```

**⚠️ IMPORTANTE**: 
- Usa la IP de tu computadora (no `localhost`)
- Asegúrate de que tu dispositivo Android esté en la misma red WiFi
- El backend debe estar corriendo cuando uses la app

### 2.4 Verificar CORS en Backend

En `backend/src/server.js`, asegúrate de que CORS permita todas las conexiones (para desarrollo):

```javascript
app.use(cors());  // Esto permite todas las conexiones (OK para desarrollo local)
```

O si quieres ser más específico:
```javascript
app.use(cors({
  origin: '*',  // En producción cambiar esto
  credentials: true
}));
```

---

## 🔧 Paso 3: Configurar Android para Desarrollo

### 3.1 Verificar que Flutter está configurado

```bash
flutter doctor
```

Debería mostrar que Android está configurado correctamente.

### 3.2 Conectar dispositivo Android

1. **Habilita "Opciones de desarrollador"** en tu Android:
   - Ve a Configuración → Acerca del teléfono
   - Toca 7 veces en "Número de compilación"

2. **Habilita "Depuración USB"**:
   - Ve a Configuración → Opciones de desarrollador
   - Activa "Depuración USB"

3. **Conecta el dispositivo** vía USB

4. **Verifica conexión**:
```bash
flutter devices
```

Deberías ver tu dispositivo listado.

---

## 📦 Paso 4: Generar APK para Desarrollo

### 4.1 Build APK Debug (Más rápido, para testing)

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --debug
```

**Output**: `mobile/build/app/outputs/flutter-apk/app-debug.apk`

**Ventajas**:
- Build más rápido
- Incluye herramientas de debug
- No requiere keystore

**Desventajas**:
- APK más grande
- No optimizado

### 4.2 Build APK Release (Recomendado para uso)

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release
```

**Output**: `mobile/build/app/outputs/flutter-apk/app-release.apk`

**Ventajas**:
- APK optimizado
- Más pequeño
- Mejor rendimiento

**Desventajas**:
- Requiere configuración de keystore (ver abajo)

---

## 🔐 Paso 5: Configurar Keystore (Solo para Release)

Si quieres generar un APK release firmado (recomendado), necesitas un keystore.

### 5.1 Crear Keystore (Solo una vez)

```bash
cd mobile/android
keytool -genkey -v -keystore georu-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias georu
```

**Te pedirá:**
- Contraseña del keystore (GUÁRDALA)
- Información personal (nombre, ciudad, etc.)

### 5.2 Crear archivo key.properties

Crea `mobile/android/key.properties`:

```properties
storePassword=tu_contraseña_aqui
keyPassword=tu_contraseña_aqui
keyAlias=georu
storeFile=georu-key.jks
```

**⚠️ IMPORTANTE**: Agrega `key.properties` a `.gitignore`

### 5.3 Configurar build.gradle

Edita `mobile/android/app/build.gradle`:

**Al inicio del archivo** (antes de `android {`):
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

**Dentro de `android {`, busca `buildTypes` y reemplaza:**
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
    }
}
```

### 5.4 Build APK Release Firmado

```bash
cd mobile
flutter build apk --release
```

---

## 📲 Paso 6: Instalar APK en tu Dispositivo

### Opción A: Instalación Automática (USB)

```bash
cd mobile
flutter install
```

O directamente:
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Opción B: Instalación Manual

1. **Copia el APK** a tu dispositivo Android:
   - Por USB (carpeta de descargas)
   - Por email
   - Por Google Drive
   - Por WiFi (usando apps como AirDroid)

2. **En tu dispositivo Android**:
   - Abre el archivo APK
   - Si aparece "Instalar desde fuentes desconocidas", permite la instalación
   - Toca "Instalar"

---

## ✅ Paso 7: Verificar que Funciona

1. **Abre la app** en tu dispositivo
2. **Verifica que se conecta al backend**:
   - Intenta hacer login
   - Verifica que carga datos
   - Revisa si hay errores de conexión

3. **Si hay errores de conexión**:
   - Verifica que el backend esté corriendo
   - Verifica que uses la IP correcta (no localhost)
   - Verifica que el dispositivo esté en la misma red WiFi
   - Verifica CORS en el backend

---

## 🔄 Uso Diario

### Cuando quieras usar la app:

1. **Inicia el backend**:
```bash
cd backend
npm run dev
```

2. **Abre la app** en tu dispositivo Android

3. **Listo** ✅

---

## ⚠️ Limitaciones del Backend Local

### ✅ Funciona para:
- Desarrollo y testing
- Uso personal
- Pruebas con dispositivos en la misma red

### ❌ No funciona para:
- Usuarios fuera de tu red WiFi
- Uso en diferentes ubicaciones
- Producción real

### 💡 Solución Futura: AWS EC2

Cuando necesites que el backend esté accesible desde cualquier lugar, puedes desplegarlo en AWS EC2. Pero por ahora, el backend local es suficiente.

---

## 🐛 Solución de Problemas

### Error: "No se puede conectar al backend"
**Solución**:
1. Verifica que el backend esté corriendo (`http://localhost:3000/health`)
2. Verifica que uses la IP correcta (no `localhost`)
3. Verifica que el dispositivo esté en la misma red WiFi
4. Verifica el firewall de Windows (puede estar bloqueando el puerto 3000)

### Error: "CORS policy"
**Solución**: Asegúrate de que el backend tenga `app.use(cors())` configurado.

### Error: "App not installed"
**Solución**: 
- Habilita "Instalar desde fuentes desconocidas"
- O usa `adb install` desde la computadora

### El APK es muy grande
**Solución**: 
- Usa `flutter build apk --release --split-per-abi` para generar APKs separados por arquitectura
- Esto genera APKs más pequeños (uno para ARM64, uno para ARM32, etc.)

---

## 📝 Checklist Rápido

- [ ] Backend corriendo en `http://localhost:3000`
- [ ] IP de la computadora obtenida
- [ ] URL del backend actualizada en `api_service.dart` (con la IP)
- [ ] CORS configurado en backend
- [ ] Dispositivo Android conectado y detectado por Flutter
- [ ] APK generado (`flutter build apk --release`)
- [ ] APK instalado en dispositivo
- [ ] App funciona y se conecta al backend

---

## 🎉 ¡Listo!

Ya tienes la app funcionando en tu dispositivo Android con el backend local.

**Próximo paso (cuando lo necesites)**: Desplegar el backend en AWS EC2 para que esté accesible desde cualquier lugar.

---

## 🔜 Siguiente Paso: AWS EC2 (Cuando lo Necesites)

Cuando quieras que el backend esté accesible desde cualquier lugar:

1. Crear instancia EC2 en AWS
2. Configurar seguridad (Security Groups)
3. Desplegar el backend
4. Obtener IP pública o dominio
5. Actualizar URL en la app Android

**Pero por ahora, el backend local es suficiente** ✅

