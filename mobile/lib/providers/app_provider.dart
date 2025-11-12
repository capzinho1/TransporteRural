import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bus.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/notificacion.dart';
import '../models/trip.dart';
import '../models/rating.dart';
import '../models/user_report.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

class AppProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final LocationService _locationService = LocationService();

  // Getter para acceder al ApiService desde fuera
  ApiService get apiService => _apiService;

  // Estado de la aplicación
  bool _isLoading = false;
  String? _error;
  Usuario? _currentUser;
  Position? _currentPosition;
  List<BusLocation> _busLocations = [];
  List<Ruta> _rutas = [];
  List<Usuario> _usuarios = [];
  List<Notificacion> _notifications = [];
  List<Trip> _trips = [];
  final List<Rating> _ratings = [];
  List<UserReport> _userReports = [];

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Usuario? get currentUser => _currentUser;
  Position? get currentPosition => _currentPosition;
  List<BusLocation> get busLocations => _busLocations;
  List<Ruta> get rutas => _rutas;
  List<Usuario> get usuarios => _usuarios;
  List<Notificacion> get notifications => _notifications;
  List<Trip> get trips => _trips;
  List<Rating> get ratings => _ratings;
  List<UserReport> get userReports => _userReports;

  // Obtener solo conductores
  List<Usuario> get conductores =>
      _usuarios.where((u) => u.role == 'driver').toList();

  // Obtener viajes completados
  List<Trip> get completedTrips => _trips.where((t) => t.isCompleted).toList();

  // Obtener reportes del usuario actual
  List<UserReport> get myReports =>
      _userReports.where((r) => r.userId == _currentUser?.id).toList();

  // Métodos para manejar el estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
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
      print('🔍 Response: $response'); // Debug
      if (response['usuario'] != null) {
        print('🔍 Usuario data: ${response['usuario']}'); // Debug
        _currentUser = Usuario.fromJson(response['usuario']);
        
        // Establecer el user ID en el ApiService para autenticación en peticiones futuras
        _apiService.setCurrentUserId(_currentUser!.id);
        
        // Cargar configuraciones del usuario después del login
        // Esto se hará desde el widget que maneja el login
      } else {
        throw Exception('Usuario no encontrado en la respuesta');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      // El mensaje de error ya viene del backend con el formato correcto
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _currentPosition = null;
    _busLocations.clear();
    _rutas.clear();
    // Limpiar el user ID del ApiService
    _apiService.setCurrentUserId(null);
    // Las configuraciones se limpiarán desde el widget que maneja el logout
    notifyListeners();
  }

  /// Establecer usuario actual (para autenticación con Supabase)
  void setCurrentUser(Usuario usuario) {
    _currentUser = usuario;
    // Establecer el user ID en el ApiService para autenticación en peticiones futuras
    _apiService.setCurrentUserId(usuario.id);
    print('✅ [APP_PROVIDER] Usuario establecido: ID=${usuario.id}, Email=${usuario.email}, Role=${usuario.role}');
    print('✅ [APP_PROVIDER] User ID configurado en ApiService: ${usuario.id}');
    notifyListeners();
  }
  
  /// Obtener ID del usuario actual (para SettingsProvider)
  int? get currentUserId => _currentUser?.id;

  // Verificar estado del usuario (para verificación periódica)
  Future<bool> checkUserStatus() async {
    if (_currentUser == null) return true;
    
    try {
      final status = await _apiService.checkUserStatus(_currentUser!.id);
      final isActive = status['active'] as bool? ?? true;
      
      if (!isActive) {
        // Usuario desactivado, hacer logout
        logout();
        return false;
      }
      
      return true;
    } catch (e) {
      // Si hay error al verificar, no hacer logout (podría ser un error de red)
      print('Error al verificar estado del usuario: $e');
      return true;
    }
  }

  // === UBICACIÓN ===
  Future<void> getCurrentLocation() async {
    // Evitar llamadas múltiples simultáneas
    if (_isLoading) return;
    
    try {
      _setLoading(true);
      _currentPosition = await _locationService.getCurrentPosition();
      _setLoading(false);
    } catch (e) {
      _setError('Error al obtener ubicación: $e');
      _setLoading(false);
    }
  }

  Future<void> startLocationTracking() async {
    try {
      _locationService.getPositionStream().listen((position) {
        _currentPosition = position;
        notifyListeners();
      });
    } catch (e) {
      _setError('Error al iniciar seguimiento de ubicación: $e');
    }
  }

  // === BUS LOCATIONS ===
  Future<void> loadBusLocations() async {
    try {
      _setLoading(true);
      print('🔍 Cargando ubicaciones de buses...'); // Debug
      _busLocations = await _apiService.getBusLocations();
      print('🔍 Ubicaciones cargadas: ${_busLocations.length}'); // Debug
      _setLoading(false);
    } catch (e) {
      print('🔍 Error cargando ubicaciones: $e'); // Debug
      _setError('Error al cargar ubicaciones de buses: $e');
      _setLoading(false);
    }
  }

  List<BusLocation> getBusLocationsByRoute(String routeId) {
    return _busLocations
        .where((location) => location.routeId == routeId)
        .toList();
  }

  List<BusLocation> getActiveBusLocations() {
    return _busLocations
        .where((location) => location.status == 'active')
        .toList();
  }

  // === RUTAS ===
  Future<void> loadRutas() async {
    try {
      _setLoading(true);
      _setError(null); // Limpiar errores anteriores
      print('🗺️ [APP_PROVIDER] Iniciando carga de rutas...');
      print('🗺️ [APP_PROVIDER] Usuario actual: ${_currentUser?.id} (${_currentUser?.email})');
      _rutas = await _apiService.getRutas();
      print('🗺️ [APP_PROVIDER] Rutas cargadas: ${_rutas.length}');
      for (var ruta in _rutas) {
        print('   - Ruta: ${ruta.routeId} - ${ruta.name}');
        print('     Polyline: ${ruta.polyline.isNotEmpty ? "Sí (${ruta.polyline.length} chars)" : "No"}');
        print('     Paradas: ${ruta.stops.length}');
        if (ruta.stops.isNotEmpty) {
          print('     Primera parada: ${ruta.stops.first.name} (${ruta.stops.first.latitude}, ${ruta.stops.first.longitude})');
        }
      }
      _setLoading(false);
    } catch (e) {
      print('❌ [APP_PROVIDER] Error al cargar rutas: $e');
      // Extraer el mensaje de error sin el prefijo "Exception: "
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      // Si el error menciona "Credenciales inválidas" pero no es del login, aclarar
      if (errorMessage.contains('Credenciales inválidas') && !errorMessage.contains('login')) {
        _setError('Error de autenticación. Por favor, cierra sesión e inicia sesión nuevamente.');
      } else {
        _setError('Error al cargar rutas: $errorMessage');
      }
      _setLoading(false);
    }
  }

  Ruta? getRutaById(String id) {
    try {
      return _rutas.firstWhere((ruta) => ruta.routeId == id);
    } catch (e) {
      return null;
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

  // === NOTIFICACIONES ===
  Future<void> loadNotifications() async {
    try {
      _setLoading(true);
      final driverId = _currentUser?.id;
      BusLocation? myBus;

      if (driverId != null) {
        try {
          myBus = _busLocations.firstWhere(
            (bus) => bus.driverId == driverId,
          );
        } catch (e) {
          // No hay bus asignado
        }
      }

      final routeId = myBus?.routeId;

      _notifications = await _apiService.getNotifications(
        driverId: driverId,
        routeId: routeId,
      );
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar notificaciones: $e');
      _setLoading(false);
    }
  }

  // === TRIPS (VIAJES) ===
  Future<void> loadTrips() async {
    try {
      _setLoading(true);
      _trips = await _apiService.getTrips();
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar viajes: $e');
      _setLoading(false);
    }
  }

  Future<void> loadCompletedTrips() async {
    try {
      _setLoading(true);
      _trips = await _apiService.getCompletedTrips();
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar viajes completados: $e');
      _setLoading(false);
    }
  }

  // === RATINGS (CALIFICACIONES) ===
  Future<bool> createRating({
    required int driverId,
    required int rating,
    String? routeId,
    int? tripId,
    String? comment,
    int? punctualityRating,
    int? serviceRating,
    int? cleanlinessRating,
    int? safetyRating,
  }) async {
    try {
      _setLoading(true);
      final ratingData = {
        'user_id': _currentUser?.id,
        'driver_id': driverId,
        'rating': rating,
        if (routeId != null) 'route_id': routeId,
        if (tripId != null) 'trip_id': tripId,
        if (comment != null) 'comment': comment,
        if (punctualityRating != null) 'punctuality_rating': punctualityRating,
        if (serviceRating != null) 'service_rating': serviceRating,
        if (cleanlinessRating != null) 'cleanliness_rating': cleanlinessRating,
        if (safetyRating != null) 'safety_rating': safetyRating,
      };
      await _apiService.createRating(ratingData);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al crear calificación: $e');
      _setLoading(false);
      return false;
    }
  }

  // === USER REPORTS (REPORTES) ===
  Future<bool> createUserReport({
    required String type,
    required String title,
    required String description,
    String? routeId,
    String? busId,
    int? tripId,
    String priority = 'medium',
    List<String>? tags,
  }) async {
    try {
      _setLoading(true);
      final reportData = {
        'user_id': _currentUser?.id,
        'type': type,
        'title': title,
        'description': description,
        'priority': priority,
        'status': 'pending',
        if (routeId != null) 'route_id': routeId,
        if (busId != null) 'bus_id': busId,
        if (tripId != null) 'trip_id': tripId,
        if (tags != null && tags.isNotEmpty) 'tags': tags,
      };
      await _apiService.createUserReport(reportData);
      // Recargar reportes después de crear uno nuevo
      await loadUserReports();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al crear reporte: $e');
      _setLoading(false);
      return false;
    }
  }

  // Obtener alertas activas por bus
  Future<List<UserReport>> getBusAlerts(String busId) async {
    try {
      final reports = await _apiService.getUserReportsByBus(busId);
      // Filtrar solo reportes activos (pending, reviewed) con tags
      return reports
          .where((report) =>
              report.busId == busId &&
              (report.status == 'pending' || report.status == 'reviewed') &&
              report.tags != null &&
              report.tags!.isNotEmpty)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> loadUserReports() async {
    try {
      _setLoading(true);
      _userReports = await _apiService.getUserReports();
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar reportes: $e');
      _setLoading(false);
    }
  }

  // === UTILIDADES ===
  double? calculateDistanceToBus(String busId) {
    if (_currentPosition == null) return null;

    final busLocation = _busLocations.firstWhere((b) => b.busId == busId);
    return _locationService.calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      busLocation.latitude,
      busLocation.longitude,
    );
  }

  List<BusLocation> getNearbyBusLocations(double radiusInMeters) {
    if (_currentPosition == null) return [];

    return _busLocations.where((location) {
      final distance = _locationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        location.latitude,
        location.longitude,
      );
      return distance <= radiusInMeters;
    }).toList();
  }

  // Método para refrescar todos los datos
  Future<void> refreshAllData() async {
    await Future.wait([
      loadBusLocations(),
      loadRutas(),
      loadUsuarios(),
    ]);
  }
}
