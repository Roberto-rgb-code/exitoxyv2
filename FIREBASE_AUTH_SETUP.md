# 🔥 Configuración de Firebase Authentication

## 📋 Pasos para Configurar Firebase Authentication

### 1. **Descargar Archivos de Configuración**

#### **Para Android:**
1. Ve a [Firebase Console](https://console.firebase.google.com/project/exitoxyv2)
2. Ve a **Configuración del proyecto** (⚙️)
3. En la sección **Tus apps**, haz clic en **Android**
4. Descarga el archivo `google-services.json`
5. Reemplaza el archivo en `android/app/google-services.json`

#### **Para iOS:**
1. En la misma sección de configuración
2. Haz clic en **iOS**
3. Descarga el archivo `GoogleService-Info.plist`
4. Reemplaza el archivo en `ios/Runner/GoogleService-Info.plist`

### 2. **Configurar Google Sign-In**

#### **Para Android:**
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Selecciona el proyecto `exitoxyv2`
3. Ve a **APIs y servicios** → **Credenciales**
4. Crea una **ID de cliente OAuth 2.0** para Android
5. Agrega tu **SHA-1 fingerprint**:
   ```bash
   # Para debug
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Para release (cuando tengas tu keystore)
   keytool -list -v -keystore path/to/your/release-keystore.jks -alias your-key-alias
   ```

#### **Para iOS:**
1. En la misma sección de Google Cloud Console
2. Crea una **ID de cliente OAuth 2.0** para iOS
3. Usa el Bundle ID: `com.example.kititV2`
4. Descarga el archivo `GoogleService-Info.plist` actualizado

### 3. **Actualizar Archivos de Configuración**

#### **Actualizar `android/app/google-services.json`:**
```json
{
  "project_info": {
    "project_number": "333331472361",
    "project_id": "exitoxyv2",
    "storage_bucket": "exitoxyv2.appspot.com"
  },
  "client": [
    {
      "client_info": {
        "mobilesdk_app_id": "1:333331472361:android:TU_ANDROID_APP_ID_REAL",
        "android_client_info": {
          "package_name": "com.example.kitit_v2"
        }
      },
      "oauth_client": [
        {
          "client_id": "333331472361-TU_CLIENT_ID_REAL.apps.googleusercontent.com",
          "client_type": 3
        },
        {
          "client_id": "333331472361-TU_ANDROID_CLIENT_ID.apps.googleusercontent.com",
          "client_type": 1,
          "android_info": {
            "package_name": "com.example.kitit_v2",
            "certificate_hash": "TU_SHA1_FINGERPRINT"
          }
        }
      ],
      "api_key": [
        {
          "current_key": "TU_API_KEY_REAL"
        }
      ]
    }
  ]
}
```

#### **Actualizar `ios/Runner/GoogleService-Info.plist`:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CLIENT_ID</key>
    <string>333331472361-TU_IOS_CLIENT_ID.apps.googleusercontent.com</string>
    <key>REVERSED_CLIENT_ID</key>
    <string>com.googleusercontent.apps.333331472361-TU_REVERSED_CLIENT_ID</string>
    <key>API_KEY</key>
    <string>TU_API_KEY_REAL</string>
    <key>GCM_SENDER_ID</key>
    <string>333331472361</string>
    <key>PROJECT_ID</key>
    <string>exitoxyv2</string>
    <key>STORAGE_BUCKET</key>
    <string>exitoxyv2.appspot.com</string>
    <key>IS_ADS_ENABLED</key>
    <false></false>
    <key>IS_ANALYTICS_ENABLED</key>
    <false></false>
    <key>IS_APPINVITE_ENABLED</key>
    <true></true>
    <key>IS_GCM_ENABLED</key>
    <true></true>
    <key>IS_SIGNIN_ENABLED</key>
    <true></true>
    <key>GOOGLE_APP_ID</key>
    <string>1:333331472361:ios:TU_IOS_APP_ID_REAL</string>
</dict>
</plist>
```

#### **Actualizar `lib/firebase_options.dart`:**
Reemplaza los valores `YOUR_*` con los valores reales de tus archivos de configuración.

### 4. **Configurar URL Schemes para iOS**

En `ios/Runner/Info.plist`, agrega:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.333331472361-TU_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 5. **Instalar Dependencias**

```bash
flutter pub get
```

### 6. **Ejecutar la App**

```bash
# Para Android
flutter run

# Para iOS
flutter run -d ios
```

## 🚀 Funcionalidades Implementadas

### ✅ **Autenticación por Email/Contraseña**
- Login con email y contraseña
- Registro de nuevos usuarios
- Recuperación de contraseña
- Validación de formularios
- Mensajes de error en español

### ✅ **Google Sign-In**
- Login con Google
- Registro automático con Google
- Manejo de errores
- UI responsiva

### ✅ **Gestión de Estado**
- AuthWrapper para manejar estados de autenticación
- Loading states
- Error handling
- Persistencia de sesión

### ✅ **UI/UX Moderna**
- Diseño responsivo para móvil y tablet
- Animaciones con flutter_animate
- Google Fonts
- Material Design 3
- Gradientes y efectos visuales

### ✅ **Funcionalidades Adicionales**
- Perfil de usuario
- Información de sesión
- Logout con confirmación
- Verificación de email
- Actualización de perfil

## 🔧 Comandos Útiles

```bash
# Limpiar y reconstruir
flutter clean
flutter pub get

# Ejecutar con logs detallados
flutter run --verbose

# Verificar configuración Firebase
flutter packages pub run firebase_cli:firebase

# Generar SHA-1 para Android
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

## 🐛 Solución de Problemas

### **Error: "No Firebase App '[DEFAULT]' has been created"**
- Asegúrate de que `Firebase.initializeApp()` se ejecute antes de usar Firebase Auth

### **Error: "Google Sign-In failed"**
- Verifica que los archivos de configuración estén correctos
- Asegúrate de que el SHA-1 fingerprint esté configurado en Google Cloud Console
- Verifica que el Bundle ID coincida en todas las configuraciones

### **Error: "Email already in use"**
- El email ya está registrado con otro método de autenticación
- Usa el método de login correspondiente

### **Error: "Invalid email"**
- Verifica el formato del email
- Asegúrate de que el email no esté vacío

## 📱 Pruebas Recomendadas

1. **Registro con email/contraseña**
2. **Login con email/contraseña**
3. **Google Sign-In**
4. **Recuperación de contraseña**
5. **Logout y login nuevamente**
6. **Verificar persistencia de sesión**
7. **Probar en diferentes dispositivos**

## 🎯 Próximos Pasos

1. **Configurar archivos de Firebase** con valores reales
2. **Probar autenticación** en dispositivo físico
3. **Configurar notificaciones push** (opcional)
4. **Implementar roles de usuario** (opcional)
5. **Agregar más métodos de autenticación** (Facebook, Apple, etc.)

¡La autenticación está lista para usar! 🎉

