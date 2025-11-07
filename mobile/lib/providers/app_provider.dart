import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/bus.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/notificacion.dart';
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

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  Usuario? get currentUser => _currentUser;
  Position? get currentPosition => _currentPosition;
  List<BusLocation> get busLocations => _busLocations;
  List<Ruta> get rutas => _rutas;
  List<Usuario> get usuarios => _usuarios;
  List<Notificacion> get notifications => _notifications;
  
  // Obtener solo conductores
  List<Usuario> get conductores => _usuarios.where((u) => u.role == 'driver').toList();

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
      } else {
        throw Exception('Usuario no encontrado en la respuesta');
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Error al iniciar sesión: $e');
      _setLoading(false);
      return false;
    }
  }

  void logout() {
    _currentUser = null;
    _currentPosition = null;
    _busLocations.clear();
    _rutas.clear();
    notifyListeners();
  }

  // === UBICACIÓN ===
  Future<void> getCurrentLocation() async {
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

  List<BusLocation> getBusLocationsByRoute(int routeId) {
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
      _rutas = await _apiService.getRutas();
      _setLoading(false);
    } catch (e) {
      _setError('Error al cargar rutas: $e');
      _setLoading(false);
    }
  }

  Ruta? getRutaById(int id) {
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

  // === UTILIDADES ===
  double? calculateDistanceToBus(int busId) {
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
    await Future.wait([loadBusLocations(), loadRutas()]);
  }
}
