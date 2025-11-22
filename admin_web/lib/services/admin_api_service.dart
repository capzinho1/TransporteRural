import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bus.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/notificacion.dart';
import '../models/empresa.dart';
import '../models/trip.dart';
import '../models/user_report.dart';
import '../models/rating.dart';

class AdminApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  int? _currentUserId;

  void setCurrentUserId(int? userId) {
    _currentUserId = userId;
  }

  Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_currentUserId != null) {
      headers['x-user-id'] = _currentUserId.toString();
    }
    return headers;
  }

  // === AUTENTICACIÓN ===
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final usuario = data['data']['usuario'];
        if (usuario != null && usuario['id'] != null) {
          setCurrentUserId(usuario['id']);
        }
        return data['data'];
      } else {
        throw Exception('Error al iniciar sesión');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  // === BUSES ===
  Future<List<BusLocation>> getBusLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bus-locations'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> locationsData = data['data'] ?? [];
        return locationsData.map((json) => BusLocation.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener buses');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<BusLocation> createBusLocation(BusLocation bus) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/bus-locations'),
        headers: headers,
        body: json.encode(bus.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return BusLocation.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? data['error'] ?? 'Error al crear bus');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'Error al crear bus: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear bus: ${e.toString()}');
    }
  }

  Future<BusLocation> updateBusLocation(int id, BusLocation bus) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bus-locations/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bus.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusLocation.fromJson(data['data']);
      } else {
        throw Exception('Error al actualizar bus');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // Método para actualizar bus con datos explícitos (útil para remover route_id)
  Future<BusLocation> updateBusLocationDirect(int id, Map<String, dynamic> updateData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bus-locations/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updateData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusLocation.fromJson(data['data']);
      } else {
        final errorBody = response.body;
        throw Exception('Error al actualizar bus: $errorBody');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteBusLocation(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/bus-locations/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar bus');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // === RUTAS ===
  Future<List<Ruta>> getRutas() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/routes'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> rutasData = data['data'] ?? [];
        return rutasData.map((json) => Ruta.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener rutas');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Ruta> createRuta(Ruta ruta) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/routes'),
        headers: headers,
        body: json.encode(ruta.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Ruta.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? data['error'] ?? 'Error al crear ruta');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'Error al crear ruta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear ruta: ${e.toString()}');
    }
  }

  Future<Ruta> updateRuta(String id, Ruta ruta) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.put(
        Uri.parse('$baseUrl/routes/$id'),
        headers: headers,
        body: json.encode(ruta.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Ruta.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? data['error'] ?? 'Error al actualizar ruta');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'Error al actualizar ruta: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al actualizar ruta: ${e.toString()}');
    }
  }

  Future<void> deleteRuta(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/routes/$id'),
        headers: _getHeaders(),
      );

      final responseBody = json.decode(response.body);
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return; // Éxito
      } else if (response.statusCode == 400) {
        // Error de validación (buses asignados, viajes activos, etc.)
        throw Exception(responseBody['message'] ?? responseBody['error'] ?? 'No se puede eliminar la ruta');
      } else {
        throw Exception(responseBody['message'] ?? responseBody['error'] ?? 'Error al eliminar ruta');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al eliminar ruta: ${e.toString()}');
    }
  }

  // === USUARIOS ===
  /// Obtiene usuarios sin autenticación (útil para login/autocompletado)
  Future<List<Usuario>> getUsuariosPublic() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> usuariosData = data['data'] ?? [];
        return usuariosData.map((json) => Usuario.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  /// Obtiene usuarios con autenticación (requiere estar logueado)
  Future<List<Usuario>> getUsuarios() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> usuariosData = data['data'] ?? [];
        return usuariosData.map((json) => Usuario.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Usuario> createUsuario(Usuario usuario) async {
    return createUsuarioWithData(usuario.toJson());
  }
  
  Future<Usuario> createUsuarioWithData(Map<String, dynamic> usuarioData) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: headers,
        body: json.encode(usuarioData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Usuario.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? data['error'] ?? 'Error al crear usuario');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'Error al crear usuario: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear usuario: ${e.toString()}');
    }
  }

  Future<Usuario> updateUsuario(int id, Usuario usuario) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: headers,
        body: json.encode(usuario.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Usuario.fromJson(data['data']);
      } else {
        throw Exception('Error al actualizar usuario');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteUsuario(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar usuario');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // === NOTIFICACIONES ===
  Future<List<Notificacion>> getNotifications() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/notifications'));
      
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

  Future<Notificacion> createNotification({
    required String title,
    required String message,
    required String type,
    String? targetId,
    int? createdBy,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title,
          'message': message,
          'type': type,
          'targetId': targetId,
          'createdBy': createdBy,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return Notificacion.fromJson(data['data']);
      } else {
        final errorBody = response.body;
        throw Exception('Error al crear notificación: $errorBody');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // === EMPRESAS ===
  Future<List<Empresa>> getEmpresas() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/empresas'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> empresasData = data['data'] ?? [];
        return empresasData.map((json) => Empresa.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener empresas');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Empresa> createEmpresa(Empresa empresa) async {
    try {
      // Crear payload sin id ni fechas para creación
      final payload = <String, dynamic>{
        'name': empresa.name,
        'email': empresa.email,
        'active': empresa.active,
      };
      
      // Password es obligatorio al crear
      if (empresa.password != null && empresa.password!.isNotEmpty) {
        payload['password'] = empresa.password!;
      }
      
      if (empresa.phone != null && empresa.phone!.isNotEmpty) {
        payload['phone'] = empresa.phone!;
      }
      if (empresa.address != null && empresa.address!.isNotEmpty) {
        payload['address'] = empresa.address!;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/empresas'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Empresa.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Error al crear empresa');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? errorData['message'] ?? 'Error al crear empresa');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Empresa> updateEmpresa(int id, Empresa empresa) async {
    try {
      // Crear payload solo con campos que se pueden actualizar
      final payload = <String, dynamic>{
        'name': empresa.name,
        'email': empresa.email,
        'active': empresa.active,
      };
      
      // Solo incluir password si se está actualizando
      if (empresa.password != null && empresa.password!.isNotEmpty) {
        payload['password'] = empresa.password!;
      }
      
      // Incluir campos opcionales (pueden ser null para limpiarlos)
      payload['phone'] = empresa.phone;
      payload['address'] = empresa.address;
      
      final response = await http.put(
        Uri.parse('$baseUrl/empresas/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Empresa.fromJson(data['data']);
        } else {
          throw Exception(data['error'] ?? 'Error al actualizar empresa');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? errorData['message'] ?? 'Error al actualizar empresa');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteEmpresa(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/empresas/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar empresa');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // === ESTADÍSTICAS ===
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      final buses = await getBusLocations();
      final rutas = await getRutas();
      final usuarios = await getUsuarios();
      final empresas = await getEmpresas();

      final busesActivos = buses.where((b) => b.status == 'active' || b.status == 'en_ruta').length;
      final busesInactivos = buses.length - busesActivos;

      // Estadísticas por empresa (para super_admin)
      final statsPorEmpresa = <String, Map<String, dynamic>>{};
      for (final empresa in empresas) {
        final busesEmpresa = buses.where((b) => b.companyId == empresa.id).toList();
        final rutasEmpresa = rutas.where((r) => r.companyId == empresa.id).toList();
        final usuariosEmpresa = usuarios.where((u) => u.companyId == empresa.id).toList();
        
        statsPorEmpresa[empresa.name] = {
          'empresaId': empresa.id,
          'totalBuses': busesEmpresa.length,
          'busesActivos': busesEmpresa.where((b) => b.status == 'active' || b.status == 'en_ruta').length,
          'totalRutas': rutasEmpresa.length,
          'totalUsuarios': usuariosEmpresa.length,
          'conductores': usuariosEmpresa.where((u) => u.role == 'driver').length,
        };
      }

      return {
        'totalBuses': buses.length,
        'busesActivos': busesActivos,
        'busesInactivos': busesInactivos,
        'totalRutas': rutas.length,
        'totalUsuarios': usuarios.length,
        'totalEmpresas': empresas.length,
        'conductores': usuarios.where((u) => u.role == 'driver').length,
        'pasajeros': usuarios.where((u) => u.role == 'user').length,
        'administradores': usuarios.where((u) => u.role == 'super_admin' || u.role == 'company_admin').length,
        'statsPorEmpresa': statsPorEmpresa,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // === TRIPS (VIAJES) ===
  Future<List<Trip>> getTrips() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trips'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tripsData = data['data'] ?? [];
        return tripsData.map((json) => Trip.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener viajes');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Trip>> getCompletedTrips() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trips/completed/all'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tripsData = data['data'] ?? [];
        return tripsData.map((json) => Trip.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener viajes completados');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Trip>> getTripsByDriver(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trips/driver/$driverId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tripsData = data['data'] ?? [];
        return tripsData.map((json) => Trip.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener viajes del conductor');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Trip>> getTripsByRoute(String routeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trips/route/$routeId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> tripsData = data['data'] ?? [];
        return tripsData.map((json) => Trip.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener viajes de la ruta');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Trip> createTrip(Map<String, dynamic> tripData) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/trips'),
        headers: headers,
        body: json.encode(tripData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Trip.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? data['error'] ?? 'Error al crear viaje');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'Error al crear viaje: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear viaje: ${e.toString()}');
    }
  }

  Future<Trip> startTrip(int tripId, {double? latitude, double? longitude}) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.put(
        Uri.parse('$baseUrl/trips/$tripId/start'),
        headers: headers,
        body: json.encode({
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Trip.fromJson(data['data']);
      } else {
        throw Exception('Error al iniciar viaje');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Trip> completeTrip(int tripId, {
    double? latitude,
    double? longitude,
    int? passengerCount,
    String? notes,
    String? issues,
  }) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.put(
        Uri.parse('$baseUrl/trips/$tripId/complete'),
        headers: headers,
        body: json.encode({
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          if (passengerCount != null) 'passenger_count': passengerCount,
          if (notes != null) 'notes': notes,
          if (issues != null) 'issues': issues,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Trip.fromJson(data['data']);
      } else {
        throw Exception('Error al completar viaje');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Trip> cancelTrip(int tripId, {String? reason}) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.put(
        Uri.parse('$baseUrl/trips/$tripId/cancel'),
        headers: headers,
        body: json.encode({
          if (reason != null) 'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Trip.fromJson(data['data']);
      } else {
        throw Exception('Error al cancelar viaje');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getPunctualityStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/trips/stats/punctuality'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Error al obtener estadísticas de puntualidad');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getComprehensiveStats({
    String? period,
    int? companyId,
    String? routeId,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (period != null) queryParams['period'] = period;
      if (companyId != null) queryParams['company_id'] = companyId.toString();
      if (routeId != null) queryParams['route_id'] = routeId;
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final uri = Uri.parse('$baseUrl/trips/stats/comprehensive').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http.get(
        uri,
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Error al obtener estadísticas');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // === USER REPORTS (REPORTES DE USUARIOS) ===
  Future<List<UserReport>> getUserReports() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-reports'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> reportsData = data['data'] ?? [];
        return reportsData.map((json) => UserReport.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener reportes');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<UserReport>> getPendingReports() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user-reports/pending/all'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> reportsData = data['data'] ?? [];
        return reportsData.map((json) => UserReport.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener reportes pendientes');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<UserReport> createUserReport(Map<String, dynamic> reportData) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/user-reports'),
        headers: headers,
        body: json.encode(reportData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return UserReport.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? data['error'] ?? 'Error al crear reporte');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'Error al crear reporte: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear reporte: ${e.toString()}');
    }
  }

  Future<UserReport> reviewReport(int reportId, {
    String? status,
    String? adminResponse,
    String? priority,
  }) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.put(
        Uri.parse('$baseUrl/user-reports/$reportId/review'),
        headers: headers,
        body: json.encode({
          if (status != null) 'status': status,
          if (adminResponse != null) 'admin_response': adminResponse,
          if (priority != null) 'priority': priority,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return UserReport.fromJson(data['data']);
      } else {
        throw Exception('Error al revisar reporte');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // === RATINGS (CALIFICACIONES) ===
  Future<List<Rating>> getRatings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ratingsData = data['data'] ?? [];
        return ratingsData.map((json) => Rating.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener calificaciones');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<List<Rating>> getRatingsByDriver(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/driver/$driverId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> ratingsData = data['data'] ?? [];
        return ratingsData.map((json) => Rating.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener calificaciones del conductor');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Map<String, dynamic>> getDriverRatingStats(int driverId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ratings/stats/driver/$driverId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? {};
      } else {
        throw Exception('Error al obtener estadísticas de calificaciones');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Rating> createRating(Map<String, dynamic> ratingData) async {
    try {
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final response = await http.post(
        Uri.parse('$baseUrl/ratings'),
        headers: headers,
        body: json.encode(ratingData),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Rating.fromJson(data['data']);
        } else {
          throw Exception(data['message'] ?? data['error'] ?? 'Error al crear calificación');
        }
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? errorData['error'] ?? 'Error al crear calificación: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error al crear calificación: ${e.toString()}');
    }
  }
}

