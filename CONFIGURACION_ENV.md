# 🔧 Configuración de Variables de Entorno - KitIt v2

## 📋 Instrucciones de Configuración

### 1. **Crear el archivo .env**

Copia el archivo `env.example` como `.env` en la raíz del proyecto:

```bash
cp env.example .env
```

### 2. **Configurar tus credenciales**

Edita el archivo `.env` con tus credenciales reales:

```env
# ===========================================
# MAPBOX CONFIGURATION
# ===========================================
MAPBOX_ACCESS_TOKEN=tu_token_de_mapbox_aqui

# ===========================================
# GOOGLE SERVICES
# ===========================================
GOOGLE_PLACES_API_KEY=tu_google_places_api_key_aqui
GOOGLE_MAPS_API_KEY=tu_google_maps_api_key_aqui

# ===========================================
# DATABASE CONFIGURATION
# ===========================================
MYSQL_HOST=10.0.2.2
MYSQL_PORT=3306
MYSQL_USERNAME=tu_usuario_mysql
MYSQL_PASSWORD=tu_password_mysql
MYSQL_DATABASE=tu_base_de_datos

# ===========================================
# API ENDPOINTS
# ===========================================
API_BASE_URL=http://10.0.2.2:3001
VISOR_URBANO_API_URL=https://visorurbano.com:3000/api/v2/catastro

# ===========================================
# GOOGLE SHEETS
# ===========================================
GOOGLE_SHEETS_CREDENTIALS=tu_json_de_credenciales_aqui
GOOGLE_SHEETS_SPREADSHEET_ID=tu_id_de_hoja_de_calculo

# ===========================================
# DENUE API
# ===========================================
DENUE_API_KEY=tu_denue_api_key_aqui
DENUE_VALIDATION_API_KEY=tu_denue_validation_key_aqui
```

## 🔑 Cómo Obtener las Credenciales

### **Mapbox Access Token**
1. Ve a [Mapbox](https://www.mapbox.com/)
2. Crea una cuenta o inicia sesión
3. Ve a tu [Account page](https://account.mapbox.com/)
4. Copia tu **Default public token**

### **Google Places API Key**
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un proyecto o selecciona uno existente
3. Habilita la **Places API**
4. Ve a **Credentials** → **Create Credentials** → **API Key**
5. Copia la API key generada

### **Google Maps API Key**
1. En la misma Google Cloud Console
2. Habilita la **Maps SDK for Android** y **Maps SDK for iOS**
3. Usa la misma API key o crea una nueva

### **MySQL Database**
1. Configura tu servidor MySQL
2. Crea la base de datos `kikit`
3. Configura usuario y contraseña
4. Asegúrate de que el puerto 3306 esté abierto

### **Google Sheets Credentials**
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Habilita la **Google Sheets API**
3. Crea una **Service Account**
4. Descarga el archivo JSON de credenciales
5. Copia todo el contenido del JSON en `GOOGLE_SHEETS_CREDENTIALS`

### **DENUE API Keys**
1. Ve a [INEGI DENUE](https://www.inegi.org.mx/servicios/api/denue.html)
2. Regístrate para obtener las API keys
3. Usa las keys proporcionadas

## 🚀 Instalación de Dependencias

Después de configurar el `.env`, instala las dependencias:

```bash
flutter pub get
```

## ✅ Verificación

Al ejecutar la app, verás en la consola el estado de las credenciales:

```
📋 Configuration Status:
  🗺️  Mapbox Token: ✅ Valid
  🏪 Google Places: ✅ Valid
  🗺️  Google Maps: ✅ Valid
  🗄️  MySQL Host: 10.0.2.2:3306
  🌐 API Base URL: http://10.0.2.2:3001
  📊 Debug Mode: true
```

## 🔒 Seguridad

### **Importante:**
- ❌ **NUNCA** subas el archivo `.env` al repositorio
- ✅ El archivo `.env` ya está en `.gitignore`
- ✅ Usa `env.example` como plantilla
- ✅ Mantén tus credenciales seguras

### **Para Producción:**
- Usa variables de entorno del sistema
- Considera usar servicios como AWS Secrets Manager
- Implementa rotación de credenciales

## 🐛 Solución de Problemas

### **Error: "Could not load .env file"**
- Verifica que el archivo `.env` existe en la raíz del proyecto
- Asegúrate de que el archivo tiene el formato correcto

### **Error: "Invalid API Key"**
- Verifica que las API keys son correctas
- Asegúrate de que las APIs están habilitadas en Google Cloud Console

### **Error de conexión MySQL**
- Verifica que el servidor MySQL está corriendo
- Confirma que las credenciales son correctas
- Asegúrate de que el puerto 3306 está abierto

## 📱 Ejecutar la App

```bash
# Desarrollo
flutter run

# Con variables de entorno específicas
flutter run --dart-define=DEBUG_MODE=true

# Para diferentes entornos
flutter run --dart-define=ENVIRONMENT=production
```

## 🔄 Actualizar Credenciales

Si necesitas cambiar alguna credencial:

1. Edita el archivo `.env`
2. Reinicia la aplicación
3. Las nuevas credenciales se cargarán automáticamente

¡Listo! Tu proyecto ahora usa variables de entorno de forma segura. 🎉
