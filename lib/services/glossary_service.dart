// lib/services/glossary_service.dart
/// Servicio de Glosario de Términos Técnicos
/// 
/// Contiene definiciones de términos económicos, estadísticos y de análisis
/// utilizados en la aplicación.

class GlossaryService {
  /// Mapa con todas las definiciones del glosario
  static const Map<String, GlossaryTerm> terms = {
    // =========================================================
    // ANÁLISIS DE MERCADO
    // =========================================================
    'hhi': GlossaryTerm(
      term: 'HHI',
      fullName: 'Índice Herfindahl-Hirschman',
      definition: 'Indicador que mide la concentración del mercado. Se calcula sumando los cuadrados de las cuotas de mercado de todas las empresas. Valores: 0-1,500 (competitivo), 1,500-2,500 (moderada concentración), >2,500 (alta concentración).',
      example: 'Un HHI de 3,200 indica un mercado altamente concentrado con pocas empresas dominantes.',
      category: 'Análisis de Mercado',
    ),
    'cr4': GlossaryTerm(
      term: 'CR4',
      fullName: 'Ratio de Concentración de 4 Empresas',
      definition: 'Mide el porcentaje del mercado controlado por las 4 empresas más grandes. Un CR4 mayor a 60% indica alta concentración; menor a 40% indica mercado competitivo.',
      example: 'CR4 de 75% significa que las 4 principales empresas controlan el 75% del mercado.',
      category: 'Análisis de Mercado',
    ),
    'estructura_mercado': GlossaryTerm(
      term: 'Estructura de Mercado',
      fullName: 'Estructura de Mercado',
      definition: 'Clasificación del mercado según el número de competidores y su poder: Monopolio (1 empresa), Oligopolio (pocas empresas), Competencia Monopolística (muchas con diferenciación), Competencia Perfecta (muchas sin diferenciación).',
      example: 'Las farmacias suelen operar en oligopolio (pocas cadenas dominantes).',
      category: 'Análisis de Mercado',
    ),
    'monopolio': GlossaryTerm(
      term: 'Monopolio',
      fullName: 'Estructura de Monopolio',
      definition: 'Estructura de mercado donde una sola empresa controla toda o casi toda la oferta. Tiene poder absoluto sobre el precio y no enfrenta competencia directa.',
      example: 'Un único proveedor de gas natural en una región es un monopolio.',
      category: 'Análisis de Mercado',
    ),
    'oligopolio': GlossaryTerm(
      term: 'Oligopolio',
      fullName: 'Estructura de Oligopolio',
      definition: 'Mercado dominado por pocas empresas grandes que tienen poder significativo sobre los precios. Las decisiones de una empresa afectan a las demás.',
      example: 'El mercado de telecomunicaciones en México es un oligopolio.',
      category: 'Análisis de Mercado',
    ),
    'competencia_monopolistica': GlossaryTerm(
      term: 'Competencia Monopolística',
      fullName: 'Competencia Monopolística',
      definition: 'Mercado con muchos vendedores que ofrecen productos diferenciados. Cada empresa tiene cierto poder sobre el precio de su producto específico.',
      example: 'Restaurantes: muchos competidores, pero cada uno ofrece algo único.',
      category: 'Análisis de Mercado',
    ),
    'competencia_perfecta': GlossaryTerm(
      term: 'Competencia Perfecta',
      fullName: 'Competencia Perfecta',
      definition: 'Mercado ideal con muchos compradores y vendedores, productos idénticos, información perfecta y libre entrada/salida. Ningún participante puede influir en el precio.',
      example: 'Los mercados agrícolas de productos básicos se aproximan a este modelo.',
      category: 'Análisis de Mercado',
    ),
    'cuota_mercado': GlossaryTerm(
      term: 'Cuota de Mercado',
      fullName: 'Participación de Mercado',
      definition: 'Porcentaje de las ventas totales del mercado que corresponde a una empresa específica. Indica el poder relativo de cada competidor.',
      example: 'Una empresa con cuota del 35% controla más de un tercio del mercado.',
      category: 'Análisis de Mercado',
    ),
    
    // =========================================================
    // ELASTICIDADES
    // =========================================================
    'elasticidad_precio': GlossaryTerm(
      term: 'Elasticidad Precio',
      fullName: 'Elasticidad Precio de la Demanda',
      definition: 'Mide cuánto cambia la cantidad demandada cuando cambia el precio. |E| > 1 = demanda elástica (sensible al precio); |E| < 1 = demanda inelástica (poco sensible).',
      example: 'Bienes de lujo suelen ser elásticos; medicinas esenciales son inelásticas.',
      category: 'Elasticidades',
    ),
    'elasticidad_espacial': GlossaryTerm(
      term: 'Elasticidad Precio-Espacial',
      fullName: 'Elasticidad Precio-Espacial',
      definition: 'Mide cómo la sensibilidad al precio varía según la ubicación geográfica. Combina factores de distancia, densidad de competidores y accesibilidad.',
      example: 'Un negocio aislado tiene menos elasticidad espacial que uno en zona comercial.',
      category: 'Elasticidades',
    ),
    'elasticidad_cruzada': GlossaryTerm(
      term: 'Elasticidad Cruzada',
      fullName: 'Elasticidad Cruzada de la Demanda',
      definition: 'Mide cómo cambia la demanda de un bien cuando cambia el precio de otro. Positiva = bienes sustitutos; Negativa = bienes complementarios.',
      example: 'Si sube el precio de Coca-Cola y aumenta la demanda de Pepsi, son sustitutos.',
      category: 'Elasticidades',
    ),
    'elasticidad_ingreso': GlossaryTerm(
      term: 'Elasticidad Ingreso',
      fullName: 'Elasticidad Ingreso de la Demanda',
      definition: 'Mide cómo cambia la demanda cuando cambia el ingreso del consumidor. E > 1 = bien de lujo; 0 < E < 1 = bien normal necesario; E < 0 = bien inferior.',
      example: 'Viajes internacionales (E > 1); alimentos básicos (E < 1); transporte público (E < 0).',
      category: 'Elasticidades',
    ),
    'bienes_sustitutos': GlossaryTerm(
      term: 'Bienes Sustitutos',
      fullName: 'Bienes Sustitutos',
      definition: 'Productos que pueden usarse en lugar de otro. Si el precio de uno sube, la demanda del otro aumenta. Elasticidad cruzada positiva.',
      example: 'Mantequilla y margarina, Uber y taxi, café y té.',
      category: 'Elasticidades',
    ),
    'bienes_complementarios': GlossaryTerm(
      term: 'Bienes Complementarios',
      fullName: 'Bienes Complementarios',
      definition: 'Productos que se consumen juntos. Si el precio de uno sube, la demanda de ambos baja. Elasticidad cruzada negativa.',
      example: 'Impresora y cartuchos de tinta, smartphone y apps, pan y mermelada.',
      category: 'Elasticidades',
    ),
    'bien_normal': GlossaryTerm(
      term: 'Bien Normal',
      fullName: 'Bien Normal',
      definition: 'Producto cuya demanda aumenta cuando el ingreso del consumidor aumenta. Incluye bienes necesarios (E < 1) y de lujo (E > 1).',
      example: 'Ropa de marca, restaurantes, entretenimiento.',
      category: 'Elasticidades',
    ),
    'bien_inferior': GlossaryTerm(
      term: 'Bien Inferior',
      fullName: 'Bien Inferior',
      definition: 'Producto cuya demanda disminuye cuando el ingreso aumenta. Los consumidores lo sustituyen por alternativas de mayor calidad.',
      example: 'Marcas genéricas, transporte público (sustituido por auto propio).',
      category: 'Elasticidades',
    ),
    'indice_sustitucion': GlossaryTerm(
      term: 'Índice de Sustitución',
      fullName: 'Índice de Sustitución',
      definition: 'Mide qué tan fácilmente un producto puede reemplazar a otro. Valores altos indican alta sustituibilidad entre productos.',
      example: 'Dos cafeterías cercanas tienen alto índice de sustitución.',
      category: 'Elasticidades',
    ),
    
    // =========================================================
    // MODELOS ECONÓMICOS
    // =========================================================
    'modelo_cournot': GlossaryTerm(
      term: 'Modelo de Cournot',
      fullName: 'Modelo de Oligopolio de Cournot',
      definition: 'Modelo donde empresas oligopólicas compiten eligiendo simultáneamente las cantidades a producir. Cada empresa maximiza beneficios dada la producción de las demás.',
      example: 'Usado para analizar mercados de gasolina, telecomunicaciones.',
      category: 'Modelos Económicos',
    ),
    'modelo_stackelberg': GlossaryTerm(
      term: 'Modelo de Stackelberg',
      fullName: 'Modelo de Liderazgo de Stackelberg',
      definition: 'Modelo donde una empresa líder decide primero su producción, y las seguidoras reaccionan después. El líder tiene ventaja estratégica.',
      example: 'Walmart como líder, tiendas pequeñas como seguidoras.',
      category: 'Modelos Económicos',
    ),
    'equilibrio_nash': GlossaryTerm(
      term: 'Equilibrio de Nash',
      fullName: 'Equilibrio de Nash',
      definition: 'Situación donde ningún jugador puede mejorar su resultado cambiando unilateralmente su estrategia. Punto estable donde todos hacen lo mejor posible.',
      example: 'Precios similares entre gasolineras cercanas pueden ser un equilibrio.',
      category: 'Modelos Económicos',
    ),
    'demanda_maxima': GlossaryTerm(
      term: 'Demanda Máxima (a)',
      fullName: 'Intercepto de Demanda',
      definition: 'Parámetro que representa la cantidad máxima demandada cuando el precio es cero. Define el tamaño potencial del mercado.',
      example: 'En la función P = a - bQ, "a" es el precio máximo que alguien pagaría.',
      category: 'Modelos Económicos',
    ),
    'pendiente_demanda': GlossaryTerm(
      term: 'Pendiente (b)',
      fullName: 'Pendiente de la Curva de Demanda',
      definition: 'Mide cuánto cambia el precio por cada unidad adicional vendida. Una pendiente mayor indica demanda más sensible a cambios de cantidad.',
      example: 'b = 2 significa que el precio baja 2 unidades por cada unidad adicional vendida.',
      category: 'Modelos Económicos',
    ),
    'costo_marginal': GlossaryTerm(
      term: 'Costo Marginal (c)',
      fullName: 'Costo Marginal',
      definition: 'Costo adicional de producir una unidad más. Es clave para decisiones de producción óptima.',
      example: 'Si producir la unidad 100 cuesta \$15 extra, el costo marginal es \$15.',
      category: 'Modelos Económicos',
    ),
    'diferenciacion': GlossaryTerm(
      term: 'Diferenciación (d)',
      fullName: 'Grado de Diferenciación',
      definition: 'Mide qué tan distintos perciben los consumidores los productos de diferentes empresas. Mayor diferenciación = menor competencia directa.',
      example: 'Apple tiene alta diferenciación vs. marcas genéricas de smartphones.',
      category: 'Modelos Económicos',
    ),
    
    // =========================================================
    // DEMOGRAFÍA Y TERRITORIO
    // =========================================================
    'ageb': GlossaryTerm(
      term: 'AGEB',
      fullName: 'Área Geoestadística Básica',
      definition: 'Unidad geográfica definida por INEGI que agrupa manzanas urbanas o localidades rurales. Es la base para censos y estadísticas territoriales.',
      example: 'Cada colonia de una ciudad puede contener una o más AGEBs.',
      category: 'Demografía',
    ),
    'pobtot': GlossaryTerm(
      term: 'POBTOT',
      fullName: 'Población Total',
      definition: 'Número total de habitantes que residen permanentemente en un área geográfica específica según el último censo.',
      example: 'Una AGEB con POBTOT de 5,000 tiene cinco mil habitantes.',
      category: 'Demografía',
    ),
    'pea': GlossaryTerm(
      term: 'PEA',
      fullName: 'Población Económicamente Activa',
      definition: 'Personas de 15 años o más que trabajan o buscan trabajo activamente. Excluye estudiantes, jubilados y personas en labores del hogar.',
      example: 'Alta PEA indica potencial de consumidores con ingresos propios.',
      category: 'Demografía',
    ),
    'graproes': GlossaryTerm(
      term: 'GRAPROES',
      fullName: 'Grado Promedio de Escolaridad',
      definition: 'Años promedio de educación formal de la población de 15 años o más. Indicador de nivel educativo de una zona.',
      example: 'GRAPROES de 12 indica que en promedio tienen preparatoria completa.',
      category: 'Demografía',
    ),
    'densidad_poblacional': GlossaryTerm(
      term: 'Densidad Poblacional',
      fullName: 'Densidad Poblacional',
      definition: 'Número de habitantes por unidad de superficie (generalmente km²). Indica qué tan concentrada está la población.',
      example: 'Centro de ciudades: alta densidad; zonas rurales: baja densidad.',
      category: 'Demografía',
    ),
    
    // =========================================================
    // INDICADORES DE NEGOCIO
    // =========================================================
    'denue': GlossaryTerm(
      term: 'DENUE',
      fullName: 'Directorio Estadístico Nacional de Unidades Económicas',
      definition: 'Base de datos de INEGI con información de todos los negocios registrados en México: ubicación, actividad económica, tamaño, etc.',
      example: 'Usado para mapear competidores y analizar densidad comercial.',
      category: 'Indicadores',
    ),
    'densidad_negocios': GlossaryTerm(
      term: 'Densidad de Negocios',
      fullName: 'Densidad de Unidades Económicas',
      definition: 'Número de negocios por km² o por habitantes. Indica el nivel de actividad comercial de una zona.',
      example: '50 negocios/km² indica zona comercial activa.',
      category: 'Indicadores',
    ),
    'indice_competencia': GlossaryTerm(
      term: 'Índice de Competencia',
      fullName: 'Índice de Competencia',
      definition: 'Medida que combina número de competidores, su proximidad y su tamaño relativo para evaluar la intensidad competitiva de una zona.',
      example: 'Índice de 0.8 indica alta competencia; 0.2 indica baja competencia.',
      category: 'Indicadores',
    ),
    'precio_equilibrio': GlossaryTerm(
      term: 'Precio de Equilibrio',
      fullName: 'Precio de Equilibrio de Mercado',
      definition: 'Precio donde la cantidad demandada iguala la cantidad ofrecida. En este punto el mercado se "vacía" sin exceso ni escasez.',
      example: 'Si oferta = demanda a \$100, ese es el precio de equilibrio.',
      category: 'Indicadores',
    ),
    'beneficio_economico': GlossaryTerm(
      term: 'Beneficio Económico',
      fullName: 'Beneficio Económico',
      definition: 'Diferencia entre ingresos totales y costos totales (incluyendo costo de oportunidad). Puede ser positivo, cero o negativo.',
      example: 'Beneficio = (Precio - Costo) × Cantidad vendida.',
      category: 'Indicadores',
    ),
    
    // =========================================================
    // ANÁLISIS ESPACIAL
    // =========================================================
    'postgis': GlossaryTerm(
      term: 'PostGIS',
      fullName: 'PostgreSQL Geographic Information System',
      definition: 'Extensión de PostgreSQL para manejar datos geográficos. Permite consultas espaciales como "negocios dentro de 2km".',
      example: 'Usado para calcular distancias y áreas de influencia.',
      category: 'Análisis Espacial',
    ),
    'geojson': GlossaryTerm(
      term: 'GeoJSON',
      fullName: 'Geographic JSON',
      definition: 'Formato estándar para representar geometrías (puntos, líneas, polígonos) y sus propiedades en formato JSON.',
      example: 'Los límites de colonias se almacenan como polígonos GeoJSON.',
      category: 'Análisis Espacial',
    ),
    'buffer': GlossaryTerm(
      term: 'Buffer',
      fullName: 'Zona de Influencia (Buffer)',
      definition: 'Área alrededor de un punto o línea a una distancia determinada. Usado para análisis de proximidad y área de servicio.',
      example: 'Buffer de 1km alrededor de una tienda define su área de influencia.',
      category: 'Análisis Espacial',
    ),
    'isocronas': GlossaryTerm(
      term: 'Isócronas',
      fullName: 'Líneas Isócronas',
      definition: 'Líneas que conectan puntos con igual tiempo de viaje desde un origen. Usadas para analizar accesibilidad.',
      example: 'Isócrona de 15 min muestra todo lo alcanzable en ese tiempo.',
      category: 'Análisis Espacial',
    ),
    
    // =========================================================
    // PREDIOS Y USO DE SUELO
    // =========================================================
    'predio': GlossaryTerm(
      term: 'Predio',
      fullName: 'Predio Catastral',
      definition: 'Unidad de propiedad inmobiliaria registrada en el catastro. Incluye terreno y construcciones, con información de superficie, valor y uso.',
      example: 'Un predio comercial de 500m² con local de 300m² construidos.',
      category: 'Predios',
    ),
    'visor_urbano': GlossaryTerm(
      term: 'Visor Urbano',
      fullName: 'Visor Urbano',
      definition: 'Herramienta digital que permite consultar información catastral, uso de suelo y regulaciones urbanísticas de predios específicos.',
      example: 'Consulta el visor urbano para verificar si puedes abrir un negocio.',
      category: 'Predios',
    ),
    'uso_suelo': GlossaryTerm(
      term: 'Uso de Suelo',
      fullName: 'Uso de Suelo',
      definition: 'Clasificación oficial de las actividades permitidas en un predio: habitacional, comercial, industrial, mixto, etc. Determinado por planes de desarrollo urbano.',
      example: 'Uso mixto permite comercio y vivienda en el mismo predio.',
      category: 'Predios',
    ),
    
    // =========================================================
    // SCORES Y OPORTUNIDADES
    // =========================================================
    'score_oportunidad': GlossaryTerm(
      term: 'Score de Oportunidad',
      fullName: 'Puntuación de Oportunidad de Negocio',
      definition: 'Métrica de 0-100 que evalúa el potencial de éxito de un negocio en una ubicación, combinando factores de concentración, demografía y accesibilidad.',
      example: 'Score de 75 indica buenas condiciones para el negocio.',
      category: 'Indicadores',
    ),
    'oportunidad_alta': GlossaryTerm(
      term: 'Oportunidad Alta',
      fullName: 'Nivel de Oportunidad Excelente',
      definition: 'Score de 70 o más. Indica condiciones favorables: baja competencia, alta demanda potencial, buena demografía y ubicación estratégica.',
      example: 'Zona residencial sin farmacias cercanas = oportunidad alta para farmacia.',
      category: 'Indicadores',
    ),
    'oportunidad_moderada': GlossaryTerm(
      term: 'Oportunidad Moderada',
      fullName: 'Nivel de Oportunidad Moderado',
      definition: 'Score entre 50-69. Condiciones aceptables pero con competencia presente. Requiere diferenciación o estrategia específica para destacar.',
      example: 'Zona comercial con 3-4 competidores similares.',
      category: 'Indicadores',
    ),
    'oportunidad_baja': GlossaryTerm(
      term: 'Oportunidad Limitada',
      fullName: 'Nivel de Oportunidad Limitado',
      definition: 'Score menor a 50. Alta competencia, mercado saturado o demografía desfavorable. Se recomienda buscar otra ubicación o nicho.',
      example: 'Centro comercial con múltiples negocios del mismo giro.',
      category: 'Indicadores',
    ),
  };

  /// Obtiene un término específico por su clave
  static GlossaryTerm? getTerm(String key) {
    return terms[key.toLowerCase()];
  }

  /// Obtiene todos los términos de una categoría
  static List<GlossaryTerm> getTermsByCategory(String category) {
    return terms.values
        .where((term) => term.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Obtiene todas las categorías disponibles
  static List<String> getCategories() {
    return terms.values.map((t) => t.category).toSet().toList()..sort();
  }

  /// Busca términos por texto
  static List<GlossaryTerm> search(String query) {
    final q = query.toLowerCase();
    return terms.values.where((term) {
      return term.term.toLowerCase().contains(q) ||
          term.fullName.toLowerCase().contains(q) ||
          term.definition.toLowerCase().contains(q);
    }).toList();
  }

  /// Obtiene todos los términos ordenados alfabéticamente
  static List<GlossaryTerm> getAllTerms() {
    final allTerms = terms.values.toList();
    allTerms.sort((a, b) => a.term.compareTo(b.term));
    return allTerms;
  }
}

/// Modelo para un término del glosario
class GlossaryTerm {
  final String term;
  final String fullName;
  final String definition;
  final String? example;
  final String category;

  const GlossaryTerm({
    required this.term,
    required this.fullName,
    required this.definition,
    this.example,
    required this.category,
  });
}

