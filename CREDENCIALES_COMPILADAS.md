# 🔐 Credenciales Compiladas en APK e iOS

## ✅ SÍ: Estas credenciales se compilan en el código

Cuando compilas:
- **Android**: `flutter build apk --release`
- **iOS**: `flutter build ios --release`

**TODOS los valores por defecto en `Config.dart` se incluyen en el código compilado.**

---

## 📋 Lista Completa de Credenciales Compiladas

### ✅ Valores Públicos (OK estar en el código):

| Credencial | Valor | Estado |
|------------|-------|--------|
| **API Base URL** | `https://monorepo-kikit.onrender.com` | ✅ Público |
| **MySQL Host** | `132.148.179.75` | ✅ Público |
| **MySQL Database** | `dbExitoXY` | ✅ Público |
| **PostGIS Host** | `dpg-d444266mcj7s73bmcar0-a...` | ✅ Público |
| **Rentas Host** | `dpg-d458gn4hg0os73b9g05g-a...` | ✅ Público |
| **Mapbox Token** | `pk.eyJ1Ijoia2V2...` | ✅ Público (token público) |
| **DENUE API Keys** | `d28a2536-ca8d...` | ✅ Público (INEGI) |

### ⚠️ Valores Sensibles (Expuestos en el código):

| Credencial | Valor | Riesgo |
|------------|-------|--------|
| **MySQL Username** | `dbUserExitoXY` | ⚠️ Medio |
| **MySQL Password** | `YjE_[AipL}.f` | ⚠️ **ALTO** |
| **PostGIS Username** | `gis_db_kmw5_user` | ⚠️ Medio |
| **PostGIS Password** | `giqLt0wGTmmnBBeAtzGp8ur4r0IOYc9e` | ⚠️ **ALTO** |
| **Rentas Username** | `db_exitoxy_user` | ⚠️ Medio |
| **Rentas Password** | `0wGKpZeGn4CrD6ixENwlP3bDZhK8aqXM` | ⚠️ **ALTO** |

### ❌ Valores NO Funcionales (Placeholders):

| Credencial | Valor | Estado |
|------------|-------|--------|
| **Google Places API Key** | `your_google_places_api_key_here` | ❌ No funciona |
| **Google Maps API Key** | `your_google_maps_api_key_here` | ❌ No funciona |

### 🔒 Valores que NO se compilan (Requieren .env):

| Credencial | Estado |
|------------|--------|
| **Google Sheets Credentials** | ❌ Lanza excepción si no está en .env |
| **Google Sheets Spreadsheet ID** | ❌ Lanza excepción si no está en .env |

---

## 🔍 Cómo Verificar qué está Compilado

### En Android (APK):

1. Descompila el APK:
   ```bash
   # Usar herramientas como jadx o apktool
   jadx -d output app-release.apk
   ```

2. Busca en el código descompilado:
   - Busca: `132.148.179.75`
   - Busca: `YjE_[AipL}.f`
   - Busca: `monorepo-kikit.onrender.com`

**Resultado**: ✅ Todos estos valores estarán visibles en texto plano

### En iOS (IPA):

1. Descompila el IPA:
   ```bash
   # Extraer el IPA
   unzip app.ipa
   # El código está en el bundle
   ```

2. Busca en los strings compilados:
   - Los valores hardcodeados estarán en el binario

**Resultado**: ✅ Todos estos valores estarán visibles (aunque más difícil de extraer que Android)

---

## ⚠️ Riesgos de Seguridad

### 🔴 Riesgo ALTO:

1. **Contraseñas de Bases de Datos**:
   - MySQL Password: `YjE_[AipL}.f`
   - PostGIS Password: `giqLt0wGTmmnBBeAtzGp8ur4r0IOYc9e`
   - Rentas Password: `0wGKpZeGn4CrD6ixENwlP3bDZhK8aqXM`

   **Impacto**: Si alguien descompila el APK/IPA, puede:
   - Conectarse directamente a tus bases de datos
   - Leer/escribir datos
   - Modificar o eliminar información

### 🟡 Riesgo MEDIO:

1. **Usernames de Bases de Datos**:
   - Aunque no son tan críticos como las contraseñas, facilitan el acceso si se obtiene la contraseña

### 🟢 Riesgo BAJO:

1. **URLs y Hosts**: Son públicos de todas formas
2. **API Keys Públicas**: Mapbox public token, DENUE keys (son públicas por diseño)

---

## 🛡️ Soluciones Recomendadas

### Opción 1: Backend como Proxy (RECOMENDADO)

**Mover todas las conexiones DB al backend:**

```
App → Backend (Render) → Bases de Datos
```

**Ventajas:**
- ✅ Las contraseñas nunca salen del servidor
- ✅ Máxima seguridad
- ✅ Control total de acceso

**Implementación:**
- Ya tienes el backend en Render ✅
- Solo necesitas agregar endpoints para las consultas que ahora hace la app directamente

### Opción 2: Firebase Remote Config

**Obtener credenciales dinámicamente:**

```dart
static Future<String> get mysqlPassword async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.fetchAndActivate();
  return remoteConfig.getString('mysql_password');
}
```

**Ventajas:**
- ✅ Credenciales no están en el código
- ✅ Puedes rotar contraseñas sin actualizar la app

**Desventajas:**
- ⚠️ Requiere Firebase
- ⚠️ Primera conexión necesita internet

### Opción 3: Obfuscación (No Recomendado)

**Obfuscar el código:**

```bash
flutter build apk --release --obfuscate --split-debug-info=./debug-info
```

**Ventajas:**
- ✅ Hace más difícil extraer credenciales

**Desventajas:**
- ❌ No es seguridad real (solo dificulta)
- ❌ Un atacante determinado puede extraerlas igual

---

## 📊 Estado Actual de tu App

### ✅ Lo que está bien:

- URLs públicas (API, hosts)
- Tokens públicos (Mapbox, DENUE)
- La app funciona correctamente

### ⚠️ Lo que debería mejorarse:

- **3 contraseñas de bases de datos** están expuestas
- **3 usernames** están expuestos
- Si alguien descompila el APK/IPA, puede acceder a tus DBs

---

## 🎯 Recomendación Inmediata

### Para Desarrollo/Testing:
✅ **Está bien como está** - Funciona y es práctico

### Para Producción:

1. **Corto plazo** (1-2 semanas):
   - ✅ Mantener como está si no hay datos críticos
   - ⚠️ Monitorear accesos a las bases de datos

2. **Mediano plazo** (1-2 meses):
   - 🔄 Mover conexiones MySQL al backend
   - 🔄 Mover conexiones PostGIS al backend
   - 🔄 Mover conexiones Rentas al backend

3. **Largo plazo** (3+ meses):
   - 🔄 Implementar autenticación en el backend
   - 🔄 Rate limiting
   - 🔄 Logging y monitoreo

---

## ✅ Conclusión

**SÍ, todas las credenciales hardcodeadas se compilan tanto en APK como en iOS.**

**Estado actual:**
- ✅ Funciona correctamente
- ⚠️ 3 contraseñas están expuestas en el código
- ✅ URLs y tokens públicos están bien

**Para producción:** Considera mover las conexiones DB al backend para máxima seguridad.

