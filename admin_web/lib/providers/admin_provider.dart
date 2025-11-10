import 'package:flutter/material.dart';
import '../models/bus.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/empresa.dart';
import '../services/admin_api_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminApiService _apiService = AdminApiService();
  
  // Getter para acceder al ApiService desde fuera
  AdminApiService get apiService => _apiService;

  // Estado
  bool _isLoading = false;
  String? _error;
  Usuario? _currentUser;

  // Datos
  List<BusLocation> _buses = [];
  List<Ruta> _rutas = [];
  List<Usuario> _usuarios = [];
  List<Empresa> _empresas = [];
  Map<String, dynamic> _estadisticas = {};

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Usuario? get currentUser => _currentUser;
  List<BusLocation> get buses => _buses;
  List<BusLocation> get busLocations => _buses; // Alias para compatibilidad
  List<Ruta> get rutas => _rutas;
  List<Usuario> get usuarios => _usuarios;
  List<Empresa> get empresas => _empresas;
  Map<String, dynamic> get estadisticas => _estadisticas;

  // Setters privados
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // === AUTENTICACIÓN ===
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      final response = await _apiService.login(email, password);

      if (response['usuario'] != null) {
        _currentUser = Usuario.fromJson(response['usuario']);

        // Verificar que sea administrador (super_admin o company_admin)
        if (_currentUser!.role != 'super_admin' && _currentUser!.role != 'company_admin') {
          _setError('No tienes permisos de administrador');
          _currentUser = null;
          _setLoading(false);
          return false;
        }

        // Establecer user_id en el ApiService para filtrado automático
        _apiService.setCurrentUserId(_currentUser!.id);

        _setLoading(false);
        return true;
      }

      _setError('Error al iniciar sesión');
      _setLoading(false);
      return false;
    } catch (e) {
      _setError('Error: $e');
      _setLoading(false);
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _apiService.setCurrentUserId(null); // Limpiar el user_id del ApiService
    _buses = [];
    _rutas = [];
    _usuarios = [];
    _empresas = [];
    _estadisticas = {};
    notifyListeners();
  }

  // === BUSES ===
  Future<void> loadBuses() async {
    try {
      _setLoading(true);
      _buses = await _apiService.getBusLocations();
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar buses: $e');
      _setLoading(false);
    }
  }

  // Método para actualizar buses sin activar loading (útil para actualizaciones silenciosas)
  Future<void> refreshBusesSilently() async {
    try {
      _buses = await _apiService.getBusLocations();
      notifyListeners();
    } catch (e) {
      print('⚠️ Error al refrescar buses silenciosamente: $e');
      // No establecer error para no interrumpir la UI
    }
  }

  // Alias para compatibilidad con mapa en tiempo real
  Future<void> loadBusLocations() async {
    await loadBuses();
  }

  Future<bool> createBus(BusLocation bus) async {
    try {
      _setLoading(true);
      _setError(null); // Limpiar errores previos
      final newBus = await _apiService.createBusLocation(bus);
      _buses.add(newBus);
      await loadBuses(); // Recargar la lista para asegurar sincronización
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear bus: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateBus(int id, BusLocation bus) async {
    try {
      _setLoading(true);
      final updatedBus = await _apiService.updateBusLocation(id, bus);
      final index = _buses.indexWhere((b) => b.id == id);
      if (index != -1) {
        _buses[index] = updatedBus;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar bus: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteBus(int id) async {
    try {
      _setLoading(true);
      await _apiService.deleteBusLocation(id);
      _buses.removeWhere((b) => b.id == id);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar bus: $e');
      _setLoading(false);
      return false;
    }
  }

  // === RUTAS ===
  Future<void> loadRutas() async {
    try {
      _setLoading(true);
      final rutasCargadas = await _apiService.getRutas();
      _rutas = rutasCargadas;
      print('✅ Rutas cargadas: ${_rutas.length}');
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('❌ Error al cargar rutas: $e');
      _setError('Error al cargar rutas: $e');
      _setLoading(false);
      notifyListeners();
    }
  }

  Future<bool> createRuta(Ruta ruta) async {
    try {
      _setLoading(true);
      _setError(null);
      
      // Crear la ruta en el servidor
      await _apiService.createRuta(ruta);
      
      // Recargar la lista completa desde el servidor para asegurar sincronización
      // Esto es importante porque el backend puede haber asignado company_id automáticamente
      await loadRutas();
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error al crear ruta en provider: $e');
      _setError('Error al crear ruta: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRuta(String id, Ruta ruta) async {
    try {
      _setLoading(true);
      final updatedRuta = await _apiService.updateRuta(id, ruta);
      final index = _rutas.indexWhere((r) => r.routeId == id);
      if (index != -1) {
        _rutas[index] = updatedRuta;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar ruta: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteRuta(String id) async {
    try {
      _setLoading(true);
      await _apiService.deleteRuta(id);
      _rutas.removeWhere((r) => r.routeId == id);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar ruta: $e');
      _setLoading(false);
      return false;
    }
  }

  // === USUARIOS ===
  Future<void> loadUsuarios() async {
    try {
      _setLoading(true);
      _usuarios = await _apiService.getUsuarios();
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar usuarios: $e');
      _setLoading(false);
    }
  }

  Future<bool> createUsuario(Usuario usuario) async {
    return createUsuarioWithData(usuario.toJson());
  }
  
  Future<bool> createUsuarioWithData(Map<String, dynamic> usuarioData) async {
    try {
      _setLoading(true);
      _setError(null); // Limpiar errores previos
      await _apiService.createUsuarioWithData(usuarioData);
      // Recargar la lista completa para asegurar que se muestren todos los usuarios
      await loadUsuarios();
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear usuario: ${e.toString()}');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUsuario(int id, Usuario usuario) async {
    try {
      _setLoading(true);
      final updatedUsuario = await _apiService.updateUsuario(id, usuario);
      final index = _usuarios.indexWhere((u) => u.id == id);
      if (index != -1) {
        _usuarios[index] = updatedUsuario;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar usuario: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteUsuario(int id) async {
    try {
      _setLoading(true);
      
      // IMPORTANTE: Antes de eliminar el usuario, remover todas sus asignaciones de rutas
      // Buscar todos los buses que tengan este conductor asignado
      final busesWithThisDriver = _buses.where((b) => b.driverId == id).toList();
      
      // Remover la asignación de ruta de todos los buses de este conductor
      for (final bus in busesWithThisDriver) {
        if (bus.id != null && bus.routeId != null) {
          try {
            final updatedBus = bus.copyWith(routeId: null);
            await _apiService.updateBusLocation(bus.id!, updatedBus);
            print('✅ Ruta removida del bus ${bus.id} antes de eliminar conductor $id');
          } catch (e) {
            print('⚠️ Error al remover ruta del bus ${bus.id}: $e');
          }
        }
      }
      
      // Ahora eliminar el usuario
      await _apiService.deleteUsuario(id);
      _usuarios.removeWhere((u) => u.id == id);
      
      // Actualizar la lista de buses para reflejar los cambios
      await refreshBusesSilently();
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar usuario: $e');
      _setLoading(false);
      return false;
    }
  }

  // === ESTADÍSTICAS ===
  Future<void> loadEstadisticas() async {
    try {
      _setLoading(true);
      _estadisticas = await _apiService.getEstadisticas();
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar estadísticas: $e');
      _setLoading(false);
    }
  }

  // === EMPRESAS ===
  Future<void> loadEmpresas() async {
    try {
      _setLoading(true);
      _empresas = await _apiService.getEmpresas();
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar empresas: $e');
      _setLoading(false);
    }
  }

  Future<bool> createEmpresa(Empresa empresa) async {
    try {
      _setLoading(true);
      final newEmpresa = await _apiService.createEmpresa(empresa);
      _empresas.add(newEmpresa);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al crear empresa: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> updateEmpresa(int id, Empresa empresa) async {
    try {
      _setLoading(true);
      final updatedEmpresa = await _apiService.updateEmpresa(id, empresa);
      final index = _empresas.indexWhere((e) => e.id == id);
      if (index != -1) {
        _empresas[index] = updatedEmpresa;
      }
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al actualizar empresa: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> deleteEmpresa(int id) async {
    try {
      _setLoading(true);
      await _apiService.deleteEmpresa(id);
      _empresas.removeWhere((e) => e.id == id);
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Error al eliminar empresa: $e');
      _setLoading(false);
      return false;
    }
  }

  // === REFRESH ALL ===
  Future<void> refreshAllData() async {
    await Future.wait([
      loadBuses(),
      loadRutas(),
      loadUsuarios(),
      loadEstadisticas(),
      if (_currentUser?.isSuperAdmin == true) loadEmpresas(),
    ]);
  }
}
