/// Configuración para OpenStreetMap
class OpenStreetMapConfig {
  // Configuración por defecto (Santiago, Chile)
  static const double defaultLatitude = -33.4489;
  static const double defaultLongitude = -70.6693;
  static const double defaultZoom = 12.0;
  static const double minZoom = 3.0;
  static const double maxZoom = 18.0;

  // URLs de tiles de OpenStreetMap
  static const String tileLayerUrlTemplate =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  // Atribución requerida por OpenStreetMap
  static const String attribution =
      '© OpenStreetMap contributors | © GeoRu';

  // Configuración de caché de tiles
  static const int maxNativeZoom = 18;
}

