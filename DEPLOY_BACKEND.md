# 🚀 Guía de Despliegue del Backend en Render

## 📋 Prerequisitos

1. Cuenta en [Render](https://render.com)
2. Repositorio Git (GitHub, GitLab, etc.)
3. Base de datos MySQL configurada en el servidor remoto

## 🔧 Configuración en Render

### Paso 1: Crear un nuevo Web Service

1. Ve a tu dashboard de Render
2. Click en **"New +"** → **"Web Service"**
3. Conecta tu repositorio Git

### Paso 2: Configurar el Build

En la configuración del servicio, establece:

- **Name:** `exitoxy-api` (o el nombre que prefieras)
- **Environment:** `Node`
- **Build Command:** 
  ```bash
  cd backend && npm install
  ```
- **Start Command:**
  ```bash
  cd backend && npm start
  ```
- **Root Directory:** (dejar vacío, el proyecto está en la raíz)

### Paso 3: Configurar Variables de Entorno

En la sección **"Environment"**, agrega las siguientes variables:

```
NODE_ENV=production
PORT=3001
DB_HOST=132.148.179.75
DB_PORT=3306
DB_USER=dbUserExitoXY
DB_PASSWORD=YjE_[AipL}.f
DB_NAME=dbExitoXY
```

⚠️ **Importante:** Asegúrate de que `DB_PASSWORD` esté configurada correctamente.

### Paso 4: Desplegar

1. Click en **"Create Web Service"**
2. Render comenzará a construir y desplegar tu aplicación
3. Espera a que el build termine (puede tomar 2-5 minutos)

### Paso 5: Obtener la URL

Una vez desplegado, Render te dará una URL como:
```
https://exitoxy-api.onrender.com
```

## 🔗 Actualizar la URL en Flutter

Después de obtener la URL de Render, actualiza el archivo `lib/core/config.dart`:

```dart
static String get apiBaseUrl => 
    dotenv.env['API_BASE_URL'] ?? 
    'https://tu-api.onrender.com'; // Reemplaza con tu URL real
```

O agrega en tu archivo `.env`:
```
API_BASE_URL=https://tu-api.onrender.com
```

## ✅ Verificación

Para verificar que el backend está funcionando:

1. Visita la URL de Render en tu navegador
2. Deberías ver: `"Éxito XY API - Backend funcionando correctamente"`
3. Prueba un endpoint desde Flutter o con Postman

## 🐛 Solución de Problemas

### Error: "Cannot connect to database"
- Verifica que las credenciales de MySQL sean correctas
- Asegúrate de que el servidor MySQL permita conexiones remotas desde Render
- Verifica que el firewall permita conexiones en el puerto 3306

### Error: "Build failed"
- Verifica que `package.json` esté en la carpeta `backend/`
- Asegúrate de que el comando de build sea correcto
- Revisa los logs de build en Render

### Error: "Application failed to start"
- Verifica que el `PORT` esté configurado correctamente
- Revisa los logs de la aplicación en Render
- Asegúrate de que todas las variables de entorno estén configuradas

## 📝 Notas Adicionales

- Render puede tardar unos segundos en "despertar" el servicio si está inactivo (plan gratuito)
- Considera usar un plan de pago si necesitas que el servicio esté siempre activo
- Los logs están disponibles en el dashboard de Render

## 🔒 Seguridad

- ⚠️ **NUNCA** subas el archivo `.env` al repositorio
- Usa variables de entorno en Render para credenciales sensibles
- Considera usar Render Secrets para contraseñas

