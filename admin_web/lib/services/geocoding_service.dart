import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Servicio para geocoding usando Nominatim (OpenStreetMap)
class GeocodingService {
  // URL base de Nominatim (servicio público gratuito)
  static const String _nominatimBaseUrl = 'https://nominatim.openstreetmap.org';
  
  /// Busca coordenadas a partir de un nombre de lugar
  /// 
  /// [query] Nombre del lugar a buscar (ej: "Terminal Central, Santiago")
  /// Retorna LatLng si se encuentra, o null si hay error
  static Future<LatLng?> searchPlace(String query) async {
    if (query.trim().isEmpty) {
      return null;
    }

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        '$_nominatimBaseUrl/search?q=$encodedQuery&format=json&limit=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'GeoRu-Admin/1.0', // Requerido por Nominatim
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List && data.isNotEmpty) {
          final result = data[0];
          final lat = double.tryParse(result['lat'] ?? '');
          final lon = double.tryParse(result['lon'] ?? '');
          
          if (lat != null && lon != null) {
            return LatLng(lat, lon);
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error en geocoding: $e');
      return null;
    }
  }
  
  /// Obtiene el nombre de un lugar a partir de coordenadas (reverse geocoding)
  /// 
  /// [lat] Latitud
  /// [lng] Longitud
  /// Retorna el nombre del lugar o null si hay error
  static Future<String?> getPlaceName(double lat, double lng) async {
    try {
      final url = Uri.parse(
        '$_nominatimBaseUrl/reverse?lat=$lat&lon=$lng&format=json'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'GeoRu-Admin/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['display_name'] as String?;
      }
      
      return null;
    } catch (e) {
      print('Error en reverse geocoding: $e');
      return null;
    }
  }
  
  /// Busca múltiples lugares que coincidan con la consulta
  /// 
  /// [query] Nombre del lugar a buscar
  /// [limit] Número máximo de resultados (default: 5)
  /// Retorna lista de resultados con nombre y coordenadas
  static Future<List<Map<String, dynamic>>> searchPlaces(
    String query, {
    int limit = 5,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final encodedQuery = Uri.encodeComponent(query);
      final url = Uri.parse(
        '$_nominatimBaseUrl/search?q=$encodedQuery&format=json&limit=$limit'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'GeoRu-Admin/1.0',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data is List) {
          return data.map((result) {
            final lat = double.tryParse(result['lat'] ?? '') ?? 0.0;
            final lon = double.tryParse(result['lon'] ?? '') ?? 0.0;
            
            return {
              'name': result['display_name'] ?? '',
              'lat': lat,
              'lng': lon,
              'latLng': LatLng(lat, lon),
            };
          }).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error buscando lugares: $e');
      return [];
    }
  }
}

