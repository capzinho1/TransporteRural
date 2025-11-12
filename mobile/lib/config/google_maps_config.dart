class GoogleMapsConfig {
  // Reemplaza con tu API Key de Google Maps
  static const String apiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';

  // Configuración por defecto
  static const double defaultLatitude = -35.4264; // Talca, Chile
  static const double defaultLongitude = -71.6558;
  static const double defaultZoom = 12.0;

  // Estilos de mapa
  static const String mapStyle = '''
  [
    {
      "featureType": "all",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#f5f5f5"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#c9c9c9"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#757575"
        }
      ]
    }
  ]
  ''';
}

