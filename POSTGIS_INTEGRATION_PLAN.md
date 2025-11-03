# 📋 Plan de Integración de Capas PostGIS en la App

## 🎯 Objetivo
Integrar las 4 capas espaciales de PostgreSQL PostGIS en widgets y mapa de la aplicación.

---

## 📊 **CAPA 1: AGEB (ISDCOL2020_2021F)**
**Tipo:** MultiPolygon | **Registros:** 5,567

### **Widget en Análisis Integrado**:
```
📊 Tab: "Demografia" o "Socio-Económico"
   └─ Tabla con columnas:
      • Colonia (NOMBRE)
      • Municipio (MUNS)
      • Código Postal (CP)
      • Población Total (POBTOT)
      • Población Femenina/Masculina
      • Grado Promedio Educación (GRAPROES)
      • Viviendas (VIVTOT)
      • Discapacidades
   
   └─ Modal de detalle al hacer click:
      📱 Muestra TODOS los 228 campos con scroll
      🎨 UI similar a DelitoDetailModal
```

### **En el Mapa (Home)**:
```
🗺️ Display:
   ├─ Opción 1: POLÍGONOS semi-transparentes (colores por densidad poblacional)
   ├─ Opción 2: POLÍGONOS solo al hacer zoom cercano (performance)
   └─ Tooltip al hacer hover: 
      • Nombre de colonia
      • Población total
      • Superficie en hectáreas
   
🎨 Colores:
   • Verde claro → baja densidad
   • Amarillo → media densidad  
   • Rojo → alta densidad
```

---

## 🚌 **CAPA 2: Rutas de Transporte (ZMG_Rutas-Mov)**
**Tipo:** MultiLineString 3D | **Registros:** 546

### **Widget en Análisis Integrado**:
```
📊 Tab: "Transporte" o agregar al tab existente
   └─ Tabla con columnas:
      • Nombre de Ruta (NAME)
      • Carpeta (FOLDERPATH)
      • Longitud (SHAPE_LENG)
   
   └─ Modal de detalle al hacer click:
      • Muestra ruta en mini-mapa
      • Información detallada
```

### **En el Mapa**:
```
🗺️ Display:
   └─ LÍNEAS azules/púrpuras mostrando rutas
   
🎨 Colores:
   • Azul → Rutas principales
   • Morado → Rutas alimentadoras
```

---

## 🚉 **CAPA 3: Estaciones de Transporte**
**Tipo:** MultiPoint | **Registros:** 115

### **Widget en Análisis Integrado**:
```
📊 Tab: "Transporte"
   └─ Tabla con columnas:
      • Nombre Estación
      • Sistema (BRT, Tren Ligero, etc.)
      • Estructura (Superficie, Elevada, Subterránea)
      • Estado (Existente, Propuesto)
      • Línea
   
   └─ Modal de detalle al hacer click:
      • Muestra ubicación en mini-mapa
      • Información completa
```

### **En el Mapa**:
```
🗺️ Display:
   └─ MARCADORES según sistema:
      • 🔵 Azul → BRT (BRT)
      • 🟢 Verde → Tren Ligero
      • 🟠 Naranja → Otros sistemas
   
🎨 Iconos:
   • Icons.directions_bus → BRT
   • Icons.train → Tren Ligero
   • Icons.location_on → Otros
```

---

## 🚋 **CAPA 4: Líneas de Transporte Masivo/Alimentador**
**Tipo:** MultiLineString | **Registros:** 38

### **Widget en Análisis Integrado**:
```
📊 Tab: "Transporte"
   └─ Tabla con columnas:
      • Nombre
      • Tipo (Masivo/Alimentador)
      • Estado (Existente/Propuesto)
   
   └─ Modal de detalle al hacer click
```

### **En el Mapa**:
```
🗺️ Display:
   └─ LÍNEAS según tipo:
      • 🟦 Azul gruesa → Líneas Masivas (Macrobús, Tren Ligero)
      • 🟨 Amarillo delgada → Alimentadores
   
🎨 Estilos:
   • Líneas masivas: grosor 5px
   • Líneas alimentadoras: grosor 3px
```

---

## 🗺️ **IMPLEMENTACIÓN EN EL MAPA**

### **En ExploreController**:
```dart
// Agregar variables para controlar visibilidad
bool _showAgebPolygons = false;
bool _showTransportLines = false;
bool _showTransportStations = false;

// Agregar métodos para cargar cada capa
Future<void> loadAgebPolygons() async {
  final bounds = _getMapBounds();
  final data = await PostgresGisService().getAgebInBounds(...);
  _agebPolygons = data.map((d) => CensoAgeb.fromJson(d)).toList();
  notifyListeners();
}

Future<void> loadTransportData() async {
  // Cargar estaciones, rutas y líneas
}
```

### **En ExplorePage**:
```dart
// Agregar controles en FloatingActionButton o Drawer
// para mostrar/ocultar cada capa
```

---

## 🎨 **LEGEND (Actualizar MapLegendWidget)**

Agregar items para:
```
✅ AGEB (Polígonos Demográficos)
✅ Rutas de Transporte (Líneas Azules)
✅ Estaciones de Transporte (Marcadores)
✅ Líneas Masivas/Alimentadoras
```

---

## 📱 **TABS EN ANÁLISIS INTEGRADO**

### **ESTRUCTURA ACTUAL** (5 tabs):
```
1. Delitos        (rojo)
2. DENUE          (negocios)
3. Marketplace    (inmuebles)
4. Recomendaciones (amarillo)
5. 3D             (Mapbox)
```

### **PROPUESTAS DE INTEGRACIÓN**:

**PROPUESTA A**: Agregar 2 tabs nuevos (MÁS LIMPIO) ⭐ RECOMENDADO
```
1. Delitos
2. DENUE
3. Marketplace
4. Demografía      (NUEVO) → Solo AGEB con 228 campos
5. Transporte      (NUEVO) → Estaciones + Rutas + Líneas juntos
6. Recomendaciones
7. 3D

✅ Ventajas:
   • Separación clara de funcionalidades
   • Mejor UX: cada tab tiene un propósito específico
   • Fácil de navegar
   
❌ Contras:
   • Más tabs en la barra (puede ser menos responsive)
```

**PROPUESTA B**: Agregar contenido a tabs existentes
```
1. Delitos
2. DENUE + Transporte (agregar sección)
3. Marketplace + Demografía (agregar sección)
4. Recomendaciones
5. 3D

✅ Ventajas:
   • No se agregan tabs
   • Mantiene tamaño actual
   
❌ Contras:
   • Tabs con mezcla de información (confuso)
   • Difícil encontrar información específica
```

**PROPUESTA C**: Reemplazar tab 3D con tabs temáticos
```
1. Delitos
2. DENUE
3. Marketplace
4. Demografía      (reemplaza 3D en análisis)
5. Transporte      (reemplaza 3D en análisis)
6. Recomendaciones

✅ Ventajas:
   • Información más útil que 3D en análisis
   
❌ Contras:
   • Se pierde visualización 3D
```

---

## ⚡ **PERFORMANCE**

### **Optimizaciones**:
1. **Lazy Loading**: Cargar capas solo cuando se soliciten
2. **Zoom-based**: AGEB solo cuando zoom > 14
3. **Limitado**: Máximo 100 registros por consulta inicial
4. **Caché**: Guardar consultas en CacheService
5. **Simplificación**: Simplificar geometrías para zoom lejano

---

## ✅ **ESTADO DE IMPLEMENTACIÓN**

### **COMPLETADO** ✅
1. ✅ **Análisis de esquema**: 4 capas espaciales identificadas y documentadas
2. ✅ **Modelos de datos**: CensoAgeb, EstacionTransporte, RutaTransporte, LineaTransporte
3. ✅ **Servicio PostgreSQL**: PostgresGisService con métodos para cada capa
4. ✅ **Widgets de análisis**: DemografiaWidget, TransporteWidget, CapasGisWidget
5. ✅ **Tabs integrados**: 3 nuevos tabs agregados sin romper funcionalidad existente
6. ✅ **Modales de detalle**: DemografiaDetailModal, TransporteDetailModal

### **PENDIENTE** ⏳
1. ⏳ **Visualización en mapa**: Marcadores, polígonos y líneas en el mapa principal
2. ⏳ **Layer control**: Widget para activar/desactivar capas en el mapa
3. ⏳ **Performance**: Carga lazy, zoom-based rendering, cache
4. ⏳ **UX/UI**: Mejoras de interfaz para las capas

---

## 🎯 **PRÓXIMOS PASOS**

**Para completar la integración:**
1. Agregar métodos en `ExploreController` para cargar capas PostGIS
2. Crear marcadores/polígonos desde datos PostGIS
3. Actualizar `MapLegendWidget` con controles de capas PostGIS
4. Probar y optimizar performance

**¿Seguimos con la implementación del mapa?**

