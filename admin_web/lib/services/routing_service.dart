import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart' as polyline_algorithm;

/// Servicio para generar polilíneas usando OSRM (Open Source Routing Machine)
class RoutingService {
  // URL base de OSRM (servicio público gratuito)
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';
  
  /// Genera una polilínea codificada (Google Polyline Encoding) entre múltiples puntos
  /// 
  /// [points] Lista de puntos LatLng en orden
  /// Retorna la polilínea codificada como String, o null si hay error
  static Future<String?> generatePolyline(List<LatLng> points) async {
    if (points.length < 2) {
      return null;
    }

    try {
      // Construir URL para OSRM con overview=full para obtener todos los puntos de la ruta
      // Esto es importante para rutas rurales con muchas curvas
      // Formato: /route/v1/driving/{lon1},{lat1};{lon2},{lat2};...
      final coordinates = points.map((p) => '${p.longitude},${p.latitude}').join(';');
      final url = Uri.parse('$_osrmBaseUrl/route/v1/driving/$coordinates?overview=full&geometries=geojson');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          
          if (geometry != null && geometry['coordinates'] != null) {
            // OSRM retorna coordenadas en formato [lon, lat]
            var coordinates = (geometry['coordinates'] as List)
                .map((coord) {
                  final lon = coord[0] is num ? coord[0].toDouble() : double.parse(coord[0].toString());
                  final lat = coord[1] is num ? coord[1].toDouble() : double.parse(coord[1].toString());
                  
                  // Validar que las coordenadas estén en rangos válidos antes de convertir
                  if (lat < -90 || lat > 90 || lon < -180 || lon > 180) {
                    print('⚠️ [ROUTING_SERVICE] Coordenada OSRM fuera de rango: lat=$lat, lon=$lon');
                    return null;
                  }
                  
                  return <double>[lat, lon]; // Convertir a [lat, lon]
                })
                .where((coord) => coord != null)
                .cast<List<double>>()
                .toList();
            
            if (coordinates.isEmpty) {
              print('❌ [ROUTING_SERVICE] No hay coordenadas válidas después de filtrar');
              return null;
            }
            
            print('✅ [ROUTING_SERVICE] Coordenadas OSRM procesadas: ${coordinates.length} puntos');
            print('   Primera coordenada: lat=${coordinates.first[0]}, lon=${coordinates.first[1]}');
            print('   Última coordenada: lat=${coordinates.last[0]}, lon=${coordinates.last[1]}');
            
            // MÁXIMA PRECISIÓN: No simplificar para preservar todas las curvas
            // Solo simplificar si hay un número extremadamente alto de puntos (5000+) 
            // y usar una tolerancia mínima para eliminar solo puntos prácticamente idénticos
            if (coordinates.length > 5000) {
              // Solo eliminar puntos que están prácticamente en la misma posición (menos de 1 metro de diferencia)
              coordinates = _simplifyPolyline(coordinates, tolerance: 0.000001); // Tolerancia extremadamente pequeña
              print('✅ [ROUTING_SERVICE] Simplificación mínima aplicada (solo puntos idénticos): ${coordinates.length} puntos');
            } else {
              print('✅ [ROUTING_SERVICE] MÁXIMA PRECISIÓN: Todas las coordenadas preservadas sin simplificación: ${coordinates.length} puntos');
            }
            
            // Codificar usando Google Polyline Algorithm
            final encoded = _encodePolyline(coordinates);
            print('✅ [ROUTING_SERVICE] Polilínea codificada: ${encoded.length} caracteres');
            
            // Verificar que se puede decodificar correctamente
            final testDecoded = decodePolyline(encoded);
            if (testDecoded == null || testDecoded.isEmpty) {
              print('❌ [ROUTING_SERVICE] Error: La polilínea codificada no se puede decodificar');
              return null;
            }
            print('✅ [ROUTING_SERVICE] Verificación: Polilínea decodificada correctamente (${testDecoded.length} puntos)');
            
            return encoded;
          }
        }
      }
      
      return null;
    } catch (e) {
      print('Error generando polilínea: $e');
      return null;
    }
  }
  
  /// Codifica una lista de LatLng a polilínea codificada
  static String? encodePolyline(List<LatLng> points) {
    if (points.isEmpty) return null;
    
    List<List<double>> coordinates = points.map((p) => [p.latitude, p.longitude]).toList();
    return _encodePolyline(coordinates);
  }

  /// Codifica una lista de coordenadas usando Google Polyline Algorithm
  static String _encodePolyline(List<List<double>> coordinates) {
    if (coordinates.isEmpty) return '';
    
    String encoded = '';
    int prevLat = 0;
    int prevLng = 0;
    
    for (var coord in coordinates) {
      int lat = (coord[0] * 1e5).round();
      int lng = (coord[1] * 1e5).round();
      
      int dLat = lat - prevLat;
      int dLng = lng - prevLng;
      
      encoded += _encodeValue(dLat);
      encoded += _encodeValue(dLng);
      
      prevLat = lat;
      prevLng = lng;
    }
    
    return encoded;
  }
  
  /// Codifica un valor usando el algoritmo de Google Polyline
  static String _encodeValue(int value) {
    value = value < 0 ? ~(value << 1) : value << 1;
    String encoded = '';
    
    while (value >= 0x20) {
      encoded += String.fromCharCode((0x20 | (value & 0x1f)) + 63);
      value >>= 5;
    }
    
    encoded += String.fromCharCode(value + 63);
    return encoded;
  }
  
  /// Simplifica una polilínea usando el algoritmo de Douglas-Peucker
  /// [tolerance] Controla qué tan simplificada será la línea (menor = más puntos, mayor = menos puntos)
  static List<List<double>> _simplifyPolyline(List<List<double>> points, {double tolerance = 0.0001}) {
    if (points.length <= 2) return points;
    
    // Encontrar el punto más lejano de la línea entre el primer y último punto
    double maxDistance = 0;
    int maxIndex = 0;
    
    final first = points.first;
    final last = points.last;
    
    for (int i = 1; i < points.length - 1; i++) {
      final point = points[i];
      final distance = _perpendicularDistance(
        point[0], point[1],
        first[0], first[1],
        last[0], last[1],
      );
      
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }
    
    // Si la distancia máxima es mayor que la tolerancia, simplificar recursivamente
    if (maxDistance > tolerance) {
      // Simplificar la parte izquierda
      final leftPart = _simplifyPolyline(points.sublist(0, maxIndex + 1), tolerance: tolerance);
      // Simplificar la parte derecha
      final rightPart = _simplifyPolyline(points.sublist(maxIndex), tolerance: tolerance);
      
      // Combinar (evitar duplicar el punto medio)
      return [...leftPart, ...rightPart.sublist(1)];
    } else {
      // Si todos los puntos están cerca de la línea, retornar solo los extremos
      return [first, last];
    }
  }
  
  /// Calcula la distancia perpendicular de un punto a una línea
  static double _perpendicularDistance(double px, double py, double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    
    if (dx == 0 && dy == 0) {
      // Si los puntos son iguales, calcular distancia euclidiana
      return ((px - x1) * (px - x1) + (py - y1) * (py - y1)).abs();
    }
    
    // Distancia perpendicular usando la fórmula estándar
    final numerator = ((y2 - y1) * px - (x2 - x1) * py + x2 * y1 - y2 * x1).abs();
    final denominator = math.sqrt(dx * dx + dy * dy);
    
    return numerator / denominator;
  }
  
  /// Decodifica una polilínea codificada a una lista de LatLng
  /// Usa el paquete google_polyline_algorithm para decodificación confiable
  static List<LatLng>? decodePolyline(String encoded) {
    if (encoded.isEmpty) return null;
    
    try {
      // Usar el paquete google_polyline_algorithm para decodificar
      final decoded = polyline_algorithm.decodePolyline(encoded);
      
      if (decoded.isEmpty) {
        print('⚠️ [ROUTING_SERVICE] Polilínea decodificada está vacía');
        return null;
      }
      
      // Convertir de List<List<num>> a List<LatLng>
      // El formato es [[lat, lng], [lat, lng], ...]
      final points = decoded.map((point) {
        final lat = point[0].toDouble();
        final lng = point[1].toDouble();
        
        // Validar que las coordenadas estén en rangos válidos globales
        // Estos rangos cubren todo el mundo, incluyendo todo Chile
        if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
          return LatLng(lat, lng);
        } else {
          print('⚠️ [ROUTING_SERVICE] Coordenada fuera de rango: lat=$lat, lon=$lng');
          return null;
        }
      }).where((point) => point != null).cast<LatLng>().toList();
      
      if (points.isEmpty) {
        print('❌ [ROUTING_SERVICE] No se pudieron decodificar puntos válidos');
        return null;
      }
      
      print('✅ [ROUTING_SERVICE] Polilínea decodificada correctamente: ${points.length} puntos');
      return points;
    } catch (e) {
      print('❌ [ROUTING_SERVICE] Error al decodificar polilínea: $e');
      return null;
    }
  }
}

