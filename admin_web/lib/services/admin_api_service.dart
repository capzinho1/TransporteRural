import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bus.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/notificacion.dart';

class AdminApiService {
  static const String baseUrl = 'http://localhost:3000/api';

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
      final response = await http.get(Uri.parse('$baseUrl/bus-locations'));
      
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
      final response = await http.post(
        Uri.parse('$baseUrl/bus-locations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bus.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return BusLocation.fromJson(data['data']);
      } else {
        throw Exception('Error al crear bus');
      }
    } catch (e) {
      throw Exception('Error: $e');
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
      final response = await http.get(Uri.parse('$baseUrl/routes'));
      
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
      final response = await http.post(
        Uri.parse('$baseUrl/routes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(ruta.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return Ruta.fromJson(data['data']);
      } else {
        throw Exception('Error al crear ruta');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Ruta> updateRuta(String id, Ruta ruta) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/routes/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(ruta.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Ruta.fromJson(data['data']);
      } else {
        throw Exception('Error al actualizar ruta');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> deleteRuta(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/routes/$id'),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar ruta');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  // === USUARIOS ===
  Future<List<Usuario>> getUsuarios() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/users'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> usuariosData = data['data'] ?? [];
        return usuariosData.map((json) => Usuario.fromJson(json)).toList();
      } else {
        throw Exception('Error al obtener usuarios');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Usuario> createUsuario(Usuario usuario) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(usuario.toJson()),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        return Usuario.fromJson(data['data']);
      } else {
        throw Exception('Error al crear usuario');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<Usuario> updateUsuario(int id, Usuario usuario) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$id'),
        headers: {'Content-Type': 'application/json'},
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

  // === ESTADÍSTICAS ===
  Future<Map<String, dynamic>> getEstadisticas() async {
    try {
      final buses = await getBusLocations();
      final rutas = await getRutas();
      final usuarios = await getUsuarios();

      final busesActivos = buses.where((b) => b.status == 'active' || b.status == 'en_ruta').length;
      final busesInactivos = buses.length - busesActivos;

      return {
        'totalBuses': buses.length,
        'busesActivos': busesActivos,
        'busesInactivos': busesInactivos,
        'totalRutas': rutas.length,
        'totalUsuarios': usuarios.length,
        'conductores': usuarios.where((u) => u.role == 'driver').length,
        'pasajeros': usuarios.where((u) => u.role == 'user').length,
        'administradores': usuarios.where((u) => u.role == 'admin').length,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }
}

