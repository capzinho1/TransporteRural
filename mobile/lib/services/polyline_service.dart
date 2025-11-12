import 'package:latlong2/latlong.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart' as polyline_algorithm;

/// Servicio para decodificar polilíneas codificadas (Google Polyline Encoding)
class PolylineService {
  /// Decodifica una polilínea codificada a una lista de LatLng
  static List<LatLng>? decodePolyline(String encoded) {
    if (encoded.isEmpty) {
      print('⚠️ [POLYLINE_SERVICE] Polilínea vacía');
      return null;
    }
    
    print('🔍 [POLYLINE_SERVICE] Decodificando polilínea (${encoded.length} chars)');
    
    try {
      // Usar el paquete google_polyline_algorithm para decodificar
      final decoded = polyline_algorithm.decodePolyline(encoded);
      
      if (decoded.isEmpty) {
        print('⚠️ [POLYLINE_SERVICE] Polilínea decodificada está vacía');
        return null;
      }
      
      // Convertir de List<List<num>> a List<LatLng>
      // El formato es [[lat, lng], [lat, lng], ...]
      final points = decoded.map((point) => LatLng(point[0].toDouble(), point[1].toDouble())).toList();
      
      print('✅ [POLYLINE_SERVICE] Polilínea decodificada: ${points.length} puntos');
      if (points.isNotEmpty) {
        print('   Primer punto: ${points.first.latitude}, ${points.first.longitude}');
        print('   Último punto: ${points.last.latitude}, ${points.last.longitude}');
        
        // Validar que las coordenadas estén en rangos válidos
        final firstPoint = points.first;
        if (firstPoint.latitude < -90 || firstPoint.latitude > 90 ||
            firstPoint.longitude < -180 || firstPoint.longitude > 180) {
          print('❌ [POLYLINE_SERVICE] Coordenadas fuera de rango válido!');
          print('   Latitud válida: -90 a 90, recibida: ${firstPoint.latitude}');
          print('   Longitud válida: -180 a 180, recibida: ${firstPoint.longitude}');
          return null;
        }
      }
      return points;
    } catch (e) {
      print('❌ [POLYLINE_SERVICE] Error al decodificar: $e');
      print('   Stack trace: ${StackTrace.current}');
      return null;
    }
  }
}

