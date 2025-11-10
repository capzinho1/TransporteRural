import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bus.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/notificacion.dart';
import '../models/trip.dart';
import '../models/rating.dart';
import '../models/user_report.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  // Headers por defecto
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Método genérico para hacer peticiones HTTP
  Future<Map<String, dynamic>> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final requestHeaders = {..._headers, ...?headers};

      http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(url, headers: requestHeaders);
          break;
        case 'POST':
          response = await http.post(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: requestHeaders,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: requestHeaders);
          break;
        default:
          throw Exception('Método HTTP no soportado: $method');
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error en petición API: $e');
    }
  }

  // === RUTAS ===
  Future<List<Ruta>> getRutas() async {
    final response = await _makeRequest('GET', '/routes');
    final List<dynamic> rutasData = response['data'] ?? [];
    return rutasData.map((json) => Ruta.fromJson(json)).toList();
  }

  Future<Ruta> getRuta(int id) async {
    final response = await _makeRequest('GET', '/routes/$id');
    return Ruta.fromJson(response['data']);
  }

  Future<Ruta> createRuta(Map<String, dynamic> rutaData) async {
    final response = await _makeRequest('POST', '/routes', body: rutaData);
    return Ruta.fromJson(response['data']);
  }

  Future<Ruta> updateRuta(int id, Map<String, dynamic> rutaData) async {
    final response = await _makeRequest('PUT', '/routes/$id', body: rutaData);
    return Ruta.fromJson(response['data']);
  }

  Future<void> deleteRuta(int id) async {
    await _makeRequest('DELETE', '/routes/$id');
  }

  // === BUS LOCATIONS ===
  Future<List<BusLocation>> getBusLocations() async {
    final response = await _makeRequest('GET', '/bus-locations');
    final List<dynamic> locationsData = response['data'] ?? [];
    return locationsData.map((json) => BusLocation.fromJson(json)).toList();
  }

  Future<BusLocation> getBusLocation(int busId) async {
    final response = await _makeRequest('GET', '/bus-locations/$busId');
    return BusLocation.fromJson(response['data']);
  }

  Future<BusLocation> createBusLocation(
      Map<String, dynamic> locationData) async {
    final response =
        await _makeRequest('POST', '/bus-locations', body: locationData);
    return BusLocation.fromJson(response['data']);
  }

  Future<void> updateBusLocation(
    int busId,
    Map<String, dynamic> locationData,
  ) async {
    await _makeRequest('PUT', '/bus-locations/$busId', body: locationData);
  }

  // === USUARIOS ===
  Future<List<Usuario>> getUsuarios() async {
    final response = await _makeRequest('GET', '/users');
    final List<dynamic> usuariosData = response['data'] ?? [];
    return usuariosData.map((json) => Usuario.fromJson(json)).toList();
  }

  Future<Usuario> getUsuario(int id) async {
    final response = await _makeRequest('GET', '/users/$id');
    return Usuario.fromJson(response['data']);
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _makeRequest(
      'POST',
      '/users/login',
      body: {'email': email, 'password': password},
    );
    return response['data'];
  }

  Future<Usuario> createUsuario(Map<String, dynamic> usuarioData) async {
    final response = await _makeRequest('POST', '/users', body: usuarioData);
    return Usuario.fromJson(response['data']);
  }

  Future<Usuario> updateUsuario(
    int id,
    Map<String, dynamic> usuarioData,
  ) async {
    final response = await _makeRequest(
      'PUT',
      '/users/$id',
      body: usuarioData,
    );
    return Usuario.fromJson(response['data']);
  }

  Future<void> deleteUsuario(int id) async {
    await _makeRequest('DELETE', '/users/$id');
  }

  // === NOTIFICACIONES ===
  Future<List<Notificacion>> getNotifications({
    int? driverId,
    String? routeId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (driverId != null) queryParams['driverId'] = driverId.toString();
      if (routeId != null) queryParams['routeId'] = routeId;
      
      final uri = Uri.parse('$baseUrl/notifications').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      
      final response = await http.get(uri, headers: _headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> notificationsData = data['data'] ?? [];
        return notificationsData
            .map((json) => Notificacion.fromJson(json))
            .toList();
      } else {
        throw Exception('Error al obtener notificaciones');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // === TRIPS (VIAJES) ===
  Future<List<Trip>> getTrips() async {
    try {
      final response = await _makeRequest('GET', '/trips');
      final List<dynamic> tripsData = response['data'] ?? [];
      return tripsData.map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener viajes: $e');
    }
  }

  Future<List<Trip>> getCompletedTrips() async {
    try {
      final response = await _makeRequest('GET', '/trips/completed/all');
      final List<dynamic> tripsData = response['data'] ?? [];
      return tripsData.map((json) => Trip.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener viajes completados: $e');
    }
  }

  Future<Trip> getTrip(int id) async {
    try {
      final response = await _makeRequest('GET', '/trips/$id');
      return Trip.fromJson(response['data']);
    } catch (e) {
      throw Exception('Error al obtener viaje: $e');
    }
  }

  // === RATINGS (CALIFICACIONES) ===
  Future<Rating> createRating(Map<String, dynamic> ratingData) async {
    try {
      final response = await _makeRequest('POST', '/ratings', body: ratingData);
      return Rating.fromJson(response['data']);
    } catch (e) {
      throw Exception('Error al crear calificación: $e');
    }
  }

  Future<List<Rating>> getRatingsByDriver(int driverId) async {
    try {
      final response = await _makeRequest('GET', '/ratings/driver/$driverId');
      final List<dynamic> ratingsData = response['data'] ?? [];
      return ratingsData.map((json) => Rating.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener calificaciones: $e');
    }
  }

  // === USER REPORTS (REPORTES DE USUARIOS) ===
  Future<UserReport> createUserReport(Map<String, dynamic> reportData) async {
    try {
      final response = await _makeRequest('POST', '/user-reports', body: reportData);
      return UserReport.fromJson(response['data']);
    } catch (e) {
      throw Exception('Error al crear reporte: $e');
    }
  }

  Future<List<UserReport>> getUserReports() async {
    try {
      final response = await _makeRequest('GET', '/user-reports');
      final List<dynamic> reportsData = response['data'] ?? [];
      return reportsData.map((json) => UserReport.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener reportes: $e');
    }
  }

  Future<UserReport> getUserReport(int id) async {
    try {
      final response = await _makeRequest('GET', '/user-reports/$id');
      return UserReport.fromJson(response['data']);
    } catch (e) {
      throw Exception('Error al obtener reporte: $e');
    }
  }

  Future<List<UserReport>> getUserReportsByBus(String busId) async {
    try {
      final response = await _makeRequest('GET', '/user-reports/bus/$busId');
      final List<dynamic> reportsData = response['data'] ?? [];
      return reportsData.map((json) => UserReport.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al obtener reportes del bus: $e');
    }
  }

  // === HEALTH CHECK ===
  Future<Map<String, dynamic>> healthCheck() async {
    return await _makeRequest('GET', '/health');
  }
}
