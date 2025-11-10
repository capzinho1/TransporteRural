import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bus.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/notificacion.dart';
import '../models/empresa.dart';

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
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: _getHeaders(),
      );
      
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
}

