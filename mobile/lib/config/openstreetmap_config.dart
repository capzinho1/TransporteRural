/// Configuración para OpenStreetMap
class OpenStreetMapConfig {
  // Configuración por defecto (Talca, Chile)
  static const double defaultLatitude = -35.4264;
  static const double defaultLongitude = -71.6558;
  static const double defaultZoom = 12.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  // URLs de tiles de OpenStreetMap
  // Usamos CartoDB Voyager para un mapa con más color (balance entre color y legibilidad)
  static const String tileLayerUrlTemplate =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';
  
  // URLs de subdominios para mejor rendimiento
  static const List<String> subdomains = ['a', 'b', 'c', 'd'];
  
  // Alternativas:
  // OpenStreetMap estándar (muy colorido y saturado):
  // 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'
  // 
  // CartoDB Positron (muy claro, minimalista):
  // 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png'
  //
  // CartoDB Dark Matter (oscuro):
  // 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'

  // Alternativa: Mapbox (requiere API key pero es más rápido)
  // static const String tileLayerUrlTemplate =
  //     'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/{z}/{x}/{y}@2x?access_token=YOUR_TOKEN';

  // Atribución requerida por CartoDB y OpenStreetMap
  static const String attribution =
      '© OpenStreetMap contributors | © CARTO | © GeoRu';

  // Configuración de caché de tiles
  static const int maxNativeZoom = 18;
}

