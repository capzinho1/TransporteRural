/// Configuración para OpenStreetMap
class OpenStreetMapConfig {
  // Configuración por defecto (Santiago, Chile)
  static const double defaultLatitude = -33.4489;
  static const double defaultLongitude = -70.6693;
  static const double defaultZoom = 12.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  // URLs de tiles de OpenStreetMap
  // Usamos diferentes proveedores para mejor rendimiento
  static const String tileLayerUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Alternativa: Mapbox (requiere API key pero es más rápido)
  // static const String tileLayerUrlTemplate =
  //     'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/{z}/{x}/{y}@2x?access_token=YOUR_TOKEN';

  // Atribución requerida por OpenStreetMap
  static const String attribution =
      '© OpenStreetMap contributors | © GeoRu';

  // Configuración de caché de tiles
  static const int maxNativeZoom = 18;
}

