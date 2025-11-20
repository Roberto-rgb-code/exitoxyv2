# 🔒 Variables de Entorno en Producción

## ❌ El archivo `.env` NO se sube a las tiendas

### ¿Por qué?

1. **Está en `.gitignore`**: El archivo `.env` está excluido del repositorio
2. **No se incluye en el build**: Flutter no incluye el `.env` en el APK/IPA compilado
3. **Seguridad**: Las credenciales no deben estar en el código compilado

---

## ✅ ¿Qué SÍ se incluye en el APK?

### Valores por defecto en `Config.dart`

Los valores que están como **fallback** en `lib/core/config.dart` **SÍ se compilan** en el APK:

```dart
static String get apiBaseUrl => 
    dotenv.env['API_BASE_URL'] ?? 
    'https://monorepo-kikit.onrender.com'; // ⚠️ Este valor SÍ está en el APK
```

### Valores actuales compilados:

- ✅ **API Base URL**: `https://monorepo-kikit.onrender.com` (público, OK)
- ✅ **MySQL Host**: `132.148.179.75` (público, OK)
- ⚠️ **MySQL Password**: `YjE_[AipL}.f` (⚠️ SENSIBLE - está en el código)
- ⚠️ **API Keys**: Google Maps, Places, etc. (⚠️ SENSIBLES - están en el código)

---

## 🔐 Estado Actual de Seguridad

### ✅ Valores Seguros (pueden estar en el código):
- URLs públicas de APIs
- Hosts de bases de datos (si son públicos)
- Tokens públicos (como Mapbox public token)

### ⚠️ Valores Sensibles (deberían protegerse):
- **Contraseñas de bases de datos**
- **API Keys privadas** (Google Maps, Places)
- **Credenciales de servicios**

---

## 🛡️ Mejores Prácticas para Producción

### Opción 1: Usar valores por defecto seguros (Actual)

**Ventajas:**
- ✅ Simple
- ✅ Funciona inmediatamente
- ✅ No requiere configuración adicional

**Desventajas:**
- ⚠️ Las contraseñas están en el código
- ⚠️ Si alguien descompila el APK, puede ver las credenciales

**Recomendación**: OK para desarrollo y pruebas, pero **NO recomendado para producción con datos sensibles**.

---

### Opción 2: Remote Config (Recomendado para Producción)

Usar Firebase Remote Config o similar:

```dart
// Obtener valores desde Firebase Remote Config
static Future<String> get apiBaseUrl async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  await remoteConfig.fetchAndActivate();
  return remoteConfig.getString('api_base_url');
}
```

**Ventajas:**
- ✅ Credenciales no están en el código
- ✅ Puedes cambiar valores sin actualizar la app
- ✅ Más seguro

---

### Opción 3: Backend como Proxy

Todas las llamadas pasan por tu backend:

```
App → Tu Backend (Render) → Bases de Datos
```

**Ventajas:**
- ✅ Las credenciales nunca salen del servidor
- ✅ Máxima seguridad
- ✅ Control total

**Desventajas:**
- ⚠️ Más complejo
- ⚠️ Requiere más recursos del backend

---

## 📱 Para tu App Actual

### Estado Actual:

1. **API Backend**: ✅ Ya está en Render (seguro)
2. **MySQL**: ⚠️ Contraseña está en el código (pero es servidor remoto)
3. **PostGIS**: ✅ Credenciales en código (pero son públicas de Render)
4. **Rentas DB**: ✅ Credenciales en código (pero son públicas de Render)

### Recomendación Inmediata:

**Para desarrollo/testing**: ✅ Está bien como está

**Para producción**:
1. ✅ Las URLs públicas (API, hosts) están bien
2. ⚠️ Considera mover contraseñas a Remote Config
3. ⚠️ O mejor aún: hacer que el backend maneje todas las conexiones a DB

---

## 🔄 ¿Qué pasa cuando compilas el APK?

```bash
flutter build apk --release
```

1. ✅ El código se compila
2. ✅ Los valores por defecto de `Config.dart` se incluyen
3. ❌ El archivo `.env` NO se incluye
4. ✅ La app funcionará con los valores por defecto

---

## ✅ Conclusión

- **`.env`**: NO se sube (solo para desarrollo local)
- **Valores por defecto en `Config.dart`**: SÍ se compilan en el APK
- **Para producción**: Considera usar Remote Config o backend proxy para credenciales sensibles

---

## 🎯 Próximos Pasos Recomendados

1. **Corto plazo**: Mantener como está (funciona para testing)
2. **Mediano plazo**: Implementar Firebase Remote Config para contraseñas
3. **Largo plazo**: Mover todas las conexiones DB al backend (máxima seguridad)

