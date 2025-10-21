# 🔥 Guía de Configuración Firebase para exitoxy v2

## ✅ Estado Actual

### Servicios Implementados:
- ✅ Firebase Authentication (Email/Password + Google)
- ✅ Firebase Firestore (configurado en código)
- ⚠️ **PENDIENTE**: Habilitar Firestore en Firebase Console

---

## 🚀 Configuración Requerida en Firebase Console

### 1️⃣ Habilitar Cloud Firestore

1. **Ir a la consola de Firebase:**
   ```
   https://console.firebase.google.com/project/exitoxyv2
   ```

2. **Navegar a Firestore Database:**
   - En el menú lateral izquierdo → **"Firestore Database"**
   - O buscar **"Cloud Firestore"** en el buscador superior

3. **Crear la base de datos:**
   - Clic en **"Crear base de datos"** (Create database)
   - Seleccionar: **"Iniciar en modo de prueba"** (Start in test mode)
   - Ubicación recomendada: **us-central (Iowa)** o **nam5 (United States)**
   - Clic en **"Habilitar"** (Enable)

### 2️⃣ Configurar Reglas de Seguridad

**Para desarrollo (permite leer/escribir solo a usuarios autenticados):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Permitir acceso solo a usuarios autenticados
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**Para producción (reglas más específicas):**

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Historial de búsquedas - solo el usuario puede ver sus propias búsquedas
    match /searchHistory/{searchId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }
    
    // Recomendaciones - solo el usuario puede ver sus propias recomendaciones
    match /recommendations/{recId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userId;
    }
    
    // Preferencias de usuario
    match /userPreferences/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Datos públicos (solo lectura para todos)
    match /public/{document=**} {
      allow read: if true;
      allow write: if false;
    }
  }
}
```

### 3️⃣ Crear Índices (opcional, se crean automáticamente cuando sean necesarios)

Los índices se crean automáticamente cuando la app los necesite, pero puedes crearlos manualmente:

1. Ir a **"Índices"** en la pestaña de Firestore
2. Esperar a que la app intente hacer una consulta compleja
3. Firebase te dará un enlace para crear el índice automáticamente

---

## 📊 Estructura de Datos en Firestore

### Colección: `searchHistory`
```json
{
  "userId": "string",
  "timestamp": "timestamp",
  "latitude": "number",
  "longitude": "number",
  "locationName": "string",
  "searchQuery": "string",
  "apiData": {
    "denue": [...],
    "visorUrbano": {...},
    "delitos": [...],
    "places": [...]
  },
  "recommendations": [...]
}
```

### Colección: `recommendations`
```json
{
  "userId": "string",
  "createdAt": "timestamp",
  "location": {
    "latitude": "number",
    "longitude": "number",
    "name": "string"
  },
  "score": "number",
  "factors": {
    "safety": "number",
    "services": "number",
    "transport": "number"
  }
}
```

### Colección: `userPreferences`
```json
{
  "userId": "string",
  "favoriteLocations": [...],
  "searchPreferences": {...},
  "lastSearchLocation": {...}
}
```

---

## 🔐 Variables de Entorno (.env)

Asegúrate de que tu archivo `.env` tenga todas estas variables:

```bash
# Google Sheets (si aplica)
GOOGLE_SHEETS_ID=tu_sheet_id

# Facebook Marketplace
FACEBOOK_ACCESS_TOKEN=EAATSXWPIMEQBPtV5jkXxLrMUE8JtZCTEQWZAyljWP2DVorOurtP6aqmOWNIyZA906n2m5Dn8usFV3ZAaWdOu7nIWrhQKjjmeKIy1s6KT92tGjcZB2uPx7bUpZAv2Y7TjZC5yNTGbt72w78RHIfvYZBHICYKZA6WLSs6pz8CRKdXB3My9xwGulRSqHi1cGa08FgQZDZD
FACEBOOK_APP_ID=1357205435920452
FACEBOOK_APP_SECRET=IqkkVAuYv3a0jPrt1GrQp5g6690

# Mapbox (si aplica)
MAPBOX_ACCESS_TOKEN=pk.eyJ1Ijoia2V2aW5yb2JlcnRvIiwiYSI6ImNtZ2hhcHAyZzB0bjQya29pcmtoa2xuMm0ifQ.FPM4l0bfhiwenMZ6jVr2kA
```

---

## 🧪 Probar Firestore

Después de habilitar Firestore, puedes probar que funciona:

1. **Abre la app y regístrate/inicia sesión**
2. **Realiza una búsqueda de ubicación**
3. **Genera recomendaciones**
4. **Ve a Firebase Console → Firestore Database**
5. **Deberías ver las colecciones creadas con datos**

---

## ⚠️ Errores Comunes

### Error: "Cloud Firestore API has not been used"
**Solución:** Habilitar Firestore en Firebase Console (ver pasos arriba)

### Error: "PERMISSION_DENIED"
**Solución:** Verificar que las reglas de seguridad permitan el acceso

### Error: "Missing or insufficient permissions"
**Solución:** Asegurarse de que el usuario esté autenticado antes de acceder a Firestore

---

## 📱 APIs Integradas

### ✅ APIs Implementadas:

1. **DENUE (INEGI)** - Datos de negocios
   - URL: `https://www.inegi.org.mx/app/api/denue/v1/consulta`
   - API Key: Incluida en el código

2. **Visor Urbano** - Datos catastrales
   - URL: `https://visorurbano.com:3000/api/v2/catastro/predio`
   - Búsqueda por coordenadas y por calle/número

3. **Google Places** - Lugares cercanos
   - Implementado (requiere API key de Google Cloud)

4. **Google Street View** - Imágenes de calle
   - Implementado (requiere API key de Google Cloud)

5. **Facebook Marketplace** - Propiedades en renta
   - Implementado (requiere tokens de Facebook)

6. **Capa de Delitos (IIEG)** - CSV local
   - Archivo: `assets/data/Delitoszmg.csv`

---

## 🗺️ Mapbox 3D

### Credenciales:
- **Style URL:** `mapbox://styles/kevinroberto/cmgharq80006y01ryg3vl8zc5`
- **Token:** `pk.eyJ1Ijoia2V2aW5yb2JlcnRvIiwiYSI6ImNtZ2hhcHAyZzB0bjQya29pcmtoa2xuMm0ifQ.FPM4l0bfhiwenMZ6jVr2kA`

### Configuración:
Ya está integrado en `pubspec.yaml` con el paquete `mapbox_gl: ^0.16.0`

---

## 📞 Soporte

Si encuentras problemas:
1. Revisa la terminal de Flutter para ver errores específicos
2. Verifica Firebase Console para ver si hay errores de permisos
3. Asegúrate de que todas las APIs estén habilitadas en sus respectivas consolas

---

## ✨ Funcionalidades Completadas

- ✅ Firebase Authentication (Email/Password + Google)
- ✅ Firestore Database (estructura definida)
- ✅ API DENUE (negocios)
- ✅ API Visor Urbano (predios)
- ✅ Capa de Delitos (CSV local)
- ✅ Sistema de Recomendaciones
- ✅ Mapa 3D con Mapbox
- ✅ Material 3 UI/UX
- ✅ Widget integrado con pestañas
- ✅ Botón de recomendaciones visible

