import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_localizations.dart';
import '../widgets/bus_card.dart';
import '../widgets/ruta_card.dart';
import '../widgets/georu_logo.dart';
import '../widgets/osm_map_widget.dart';
import '../models/trip.dart';
import '../models/bus.dart';
import '../models/ruta.dart';
import '../utils/bus_alerts.dart';
import '../utils/app_colors.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  Timer? _userStatusCheckTimer;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<BusLocation> _filteredBuses = [];
  List<Ruta> _filteredRutas = [];
  bool _isSearching = false;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    // initialIndex: 2 para que inicie en la pestaña del Mapa
    _tabController = TabController(length: 3, vsync: this, initialIndex: 2);
    // Cargar datos después del primer frame para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
      _startUserStatusCheck();
    });
    
    // Inicializar listas vacías
    _filteredBuses = [];
    _filteredRutas = [];
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userStatusCheckTimer?.cancel();
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _startUserStatusCheck() {
    // Verificar estado del usuario cada 10 segundos
    _userStatusCheckTimer =
        Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final isActive = await appProvider.checkUserStatus();

      if (!isActive && mounted) {
        // Usuario fue desactivado, mostrar mensaje y redirigir al login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('account_deactivated') ??
                  'Su cuenta ha sido desactivada. Por favor, contacte al administrador.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );

        // Redirigir al login después de un breve delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context)
                .pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });

        timer.cancel();
      }
    });
  }

  Future<void> _loadInitialData() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.refreshAllData();
    
    // Si no hay búsqueda activa, mostrar todos los resultados
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredBuses = appProvider.busLocations;
        _filteredRutas = appProvider.rutas;
        _isSearching = false;
      });
    }
  }

  /// Realizar búsqueda fuzzy de rutas y buses
  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    
    setState(() {
      _isSearching = true;
    });
    
    if (query.trim().isEmpty) {
      // Si la búsqueda está vacía, mostrar todos los resultados
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      setState(() {
        _filteredBuses = appProvider.busLocations;
        _filteredRutas = appProvider.rutas;
        _isSearching = false;
      });
      return;
    }
    
    try {
      final apiService = ApiService();
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      apiService.setCurrentUserId(appProvider.currentUser?.id);
      
      final response = await apiService.searchRoutesAndBuses(
        query: query,
        limit: 50,
      );
      
      if (!mounted) return;
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        // Procesar rutas encontradas
        final routesData = data['routes'] as List<dynamic>? ?? [];
        final searchRoutes = routesData.map((r) => Ruta.fromJson(r)).toList();
        
        // Procesar buses encontrados
        final busesData = data['buses'] as List<dynamic>? ?? [];
        final searchBuses = busesData.map((b) {
          // Normalizar la estructura del bus
          final busData = Map<String, dynamic>.from(b);
          // Si tiene routes anidado, extraer el nombre
          if (busData['routes'] != null && busData['routes'] is Map) {
            final routeInfo = busData['routes'] as Map<String, dynamic>;
            busData['route_id'] = routeInfo['route_id'];
          }
          return BusLocation.fromJson(busData);
        }).toList();
        
        setState(() {
          _filteredRutas = searchRoutes;
          _filteredBuses = searchBuses;
          _isSearching = false;
        });
      } else {
        setState(() {
          _filteredRutas = [];
          _filteredBuses = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      print('❌ [HOME_SCREEN] Error en búsqueda: $e');
      if (!mounted) return;
      setState(() {
        _isSearching = false;
      });
      
      // Mostrar error al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al buscar: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Manejar cambios en el campo de búsqueda con debounce
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    
    // Cancelar el timer anterior si existe
    _searchDebounceTimer?.cancel();
    
    // Crear un nuevo timer para esperar 500ms antes de buscar
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  /// Limpiar búsqueda
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _isSearching = false;
    });
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    setState(() {
      _filteredBuses = appProvider.busLocations;
      _filteredRutas = appProvider.rutas;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GeoRuLogo(
              size: 32,
              showText: false,
              showSlogan: false,
            ),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'GeoRu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadInitialData,
            tooltip: AppLocalizations.of(context)?.translate('refresh') ??
                'Actualizar',
            iconSize: 24,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          tabs: [
            Tab(
              icon: const Icon(Icons.directions_bus_rounded, size: 22),
              text: AppLocalizations.of(context)?.translate('buses') ?? 'Buses',
            ),
            Tab(
              icon: const Icon(Icons.route_rounded, size: 22),
              text:
                  AppLocalizations.of(context)?.translate('routes') ?? 'Rutas',
            ),
            Tab(
              icon: const Icon(Icons.map_rounded, size: 22),
              text: AppLocalizations.of(context)?.translate('map') ?? 'Mapa',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBusesTab(),
          _buildRutasTab(),
          _buildMapTab(),
        ],
      ),
      // Eliminado: FloatingActionButton - Las acciones principales están en el Drawer y bottomNavigationBar
      // Barra inferior eliminada - las funciones están en el TabBar y Drawer
    );
  }

  /// Widget del campo de búsqueda
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? const Color(0xFFE0E0E0) : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Buscar ruta o bus por nombre...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  onPressed: _clearSearch,
                  tooltip: 'Limpiar búsqueda',
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32),
              width: 2,
            ),
          ),
        ),
        onChanged: _onSearchChanged,
        ),
    );
  }

  Widget _buildBusesTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)?.translate('loading') ?? 'Cargando...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (appProvider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Oops!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appProvider.error!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _loadInitialData,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reintentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

              // Usar resultados filtrados si hay búsqueda activa, sino todos los buses
              final busesToShow = _searchQuery.isNotEmpty 
                  ? _filteredBuses 
                  : appProvider.busLocations;

              if (_isSearching) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                        ),
                        SizedBox(height: 16),
                        Text('Buscando...'),
                      ],
                    ),
                  ),
                );
              }

              if (_searchQuery.isNotEmpty && busesToShow.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron buses',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Intenta con otro término de búsqueda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (busesToShow.isEmpty && !_searchQuery.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_bus_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No hay buses disponibles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Intenta actualizar más tarde',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadInitialData,
          color: const Color(0xFF2E7D32),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: busesToShow.length,
            itemBuilder: (context, index) {
                    final busLocation = busesToShow[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: BusCard(busLocation: busLocation),
              );
            },
          ),
        );
      },
          ),
        ),
      ],
    );
  }

  Widget _buildRutasTab() {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)?.translate('loading') ?? 'Cargando...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (appProvider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 64,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Oops!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appProvider.error!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _loadInitialData,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(
                      AppLocalizations.of(context)?.translate('retry') ??
                          'Reintentar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

              // Usar resultados filtrados si hay búsqueda activa, sino todas las rutas
              final rutasToShow = _searchQuery.isNotEmpty 
                  ? _filteredRutas 
                  : appProvider.rutas;

              if (_isSearching) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
                        ),
                        SizedBox(height: 16),
                        Text('Buscando...'),
                      ],
                    ),
                  ),
                );
              }

              if (_searchQuery.isNotEmpty && rutasToShow.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron rutas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Intenta con otro término de búsqueda',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (rutasToShow.isEmpty && !_searchQuery.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.route_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No hay rutas disponibles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Intenta actualizar más tarde',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadInitialData,
          color: const Color(0xFF2E7D32),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: rutasToShow.length,
            itemBuilder: (context, index) {
                    final ruta = rutasToShow[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: RutaCard(ruta: ruta),
              );
            },
          ),
        );
      },
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(localizations.translate('logout')),
          content: Text(localizations.translate('logout_confirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.translate('cancel')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final appProvider = Provider.of<AppProvider>(context, listen: false);
                final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
                
                // Limpiar configuraciones del usuario
                settingsProvider.clearUserSettings();
                
                // Cerrar sesión de Supabase si existe
                try {
                  await AuthService.signOut();
                  print('✅ [LOGOUT] Sesión de Supabase cerrada');
                } catch (e) {
                  print('⚠️ [LOGOUT] Error al cerrar sesión de Supabase: $e');
                }
                
                // Hacer logout en la app
                appProvider.logout();
                
                // Navegar al login usando pushNamedAndRemoveUntil para limpiar el stack
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              child: Text(localizations.translate('logout')),
            ),
          ],
        );
      },
    );
  }

  // ELIMINADO: _showPassengerMenu - Las opciones ahora están centralizadas en el Drawer
  // Usar el Drawer (menú lateral) para acceder a todas las funciones

  Future<void> _showTripsHistoryDialog() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Cargar viajes completados
    await appProvider.loadCompletedTrips();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(localizations.translate('trip_history')),
          content: SizedBox(
            width: double.maxFinite,
            child: appProvider.completedTrips.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.history,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            localizations.translate('no_completed_trips'),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: appProvider.completedTrips.length,
                    itemBuilder: (context, index) {
                      final trip = appProvider.completedTrips[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.directions_bus,
                              color: Colors.green),
                          title: Text(
                            '${localizations.translate('trip')} #${trip.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (trip.routeId != null)
                                Text(
                                    '${localizations.translate('route_label')}: ${trip.routeId}'),
                              if (trip.actualStart != null)
                                Text(
                                  '${localizations.translate('date_label')}: ${_formatDateTime(trip.actualStart!)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if (trip.durationMinutes != null)
                                Text(
                                  '${localizations.translate('duration_label')}: ${trip.durationMinutes} ${localizations.translate('minutes')}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: trip.driverId != null
                              ? IconButton(
                                  icon: const Icon(Icons.star,
                                      color: Colors.amber),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showRatingDialog(trip);
                                  },
                                  tooltip:
                                      localizations.translate('rate_driver'),
                                )
                              : null,
                          onTap: () {
                            Navigator.pop(context);
                            _showTripDetailsDialog(trip);
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.translate('close')),
            ),
          ],
        );
      },
    );
  }

  void _showTripDetailsDialog(Trip trip) {
    showDialog(
      context: context,
      builder: (context) {
        final localizations = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text('${localizations.translate('trip')} #${trip.id}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                    localizations.translate('status'), trip.statusLabel),
                if (trip.routeId != null)
                  _buildDetailRow(
                      localizations.translate('route_label'), trip.routeId!),
                _buildDetailRow(localizations.translate('bus'), trip.busId),
                if (trip.actualStart != null)
                  _buildDetailRow(localizations.translate('start'),
                      _formatDateTime(trip.actualStart!)),
                if (trip.actualEnd != null)
                  _buildDetailRow(localizations.translate('end'),
                      _formatDateTime(trip.actualEnd!)),
                if (trip.durationMinutes != null)
                  _buildDetailRow(localizations.translate('duration_label'),
                      '${trip.durationMinutes} ${localizations.translate('duration_minutes')}'),
                if (trip.passengerCount > 0)
                  _buildDetailRow(localizations.translate('passengers'),
                      '${trip.passengerCount}'),
              ],
            ),
          ),
          actions: [
            if (trip.driverId != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _showRatingDialog(trip);
                },
                icon: const Icon(Icons.star),
                label: Text(localizations.translate('rate_driver_title')),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.translate('close')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value,
      {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: iconColor ?? AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: icon != null ? 80 : 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showRatingDialog(Trip trip) {
    int selectedRating = 5;
    String comment = '';
    final scaffoldContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogBuildContext, setState) => AlertDialog(
          title: const Text('Calificar Conductor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calificación General',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 40,
                      ),
                      onPressed: () {
                        setState(() {
                          selectedRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Comentario (opcional)',
                    hintText: 'Escribe tu opinión...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    comment = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogBuildContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final appProvider =
                    Provider.of<AppProvider>(scaffoldContext, listen: false);

                final success = await appProvider.createRating(
                  driverId: trip.driverId!,
                  rating: selectedRating,
                  routeId: trip.routeId,
                  tripId: trip.id,
                  comment: comment.isNotEmpty ? comment : null,
                );

                if (!mounted) return;

                if (dialogBuildContext.mounted) {
                  Navigator.of(dialogBuildContext).pop();
                }

                if (!scaffoldContext.mounted) return;
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Calificación enviada exitosamente'
                          : 'Error al enviar calificación',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Enviar Calificación'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapTab() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return OsmMapWidget(
          showMyLocation: true,
          onBusTap: (busLocation) {
            _showBusInfoOnMap(context, busLocation);
          },
        );
      },
    );
  }

  // Helper para obtener el nombre de la ruta de un bus
  String _getRouteNameForBus(BusLocation busLocation, List<Ruta> routes) {
    // 1. Priorizar nombreRuta si está disponible
    if (busLocation.nombreRuta != null && busLocation.nombreRuta!.isNotEmpty) {
      return busLocation.nombreRuta!;
    }
    
    // 2. Buscar en la lista de rutas usando routeId
    if (busLocation.routeId != null && busLocation.routeId!.isNotEmpty) {
      try {
        final route = routes.firstWhere(
          (r) => r.routeId == busLocation.routeId,
        );
        return route.name;
      } catch (e) {
        // Si no se encuentra la ruta, usar el routeId como fallback
        return busLocation.routeId!;
      }
    }
    
    // 3. Fallback
    return 'Sin asignar';
  }

  void _showBusInfoOnMap(BuildContext context, BusLocation busLocation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.getStatusGradient(busLocation.status),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.getBusStatusColor(busLocation.status)
                            .withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.directions_bus, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus ${busLocation.busId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (busLocation.companyName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 14,
                              color: AppColors.getCompanyColor(
                                  busLocation.companyId),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                busLocation.companyName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.getCompanyColor(
                                      busLocation.companyId),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.getBusStatusColor(busLocation.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppColors.getBusStatusColor(busLocation.status),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          busLocation.status,
                          style: TextStyle(
                            color:
                                AppColors.getBusStatusColor(busLocation.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Ruta',
              _getRouteNameForBus(busLocation, Provider.of<AppProvider>(context, listen: false).rutas),
            ),
            _buildDetailRow(
              'Conductor',
              busLocation.driverName ??
                  (busLocation.driverId?.toString() ?? 'N/A'),
              icon: Icons.person,
              iconColor: AppColors.accentBlue,
            ),
            if (busLocation.companyName != null)
              _buildDetailRow(
                'Empresa',
                busLocation.companyName!,
                icon: Icons.business,
                iconColor: AppColors.getCompanyColor(busLocation.companyId),
              ),
            _buildDetailRow(
              'Ubicación',
              'Lat: ${busLocation.latitude.toStringAsFixed(6)}\n'
                  'Lng: ${busLocation.longitude.toStringAsFixed(6)}',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreateReportDialog(busId: busLocation.busId);
                    },
                    icon: const Icon(Icons.report_problem),
                    label: const Text('Reportar Problema'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MapScreen(
                            initialBusId: busLocation.busId,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('Ver Mapa'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateReportDialog({String? busId}) {
    String selectedType = 'complaint';
    String title = '';
    String description = '';
    String selectedPriority = 'medium';
    String? selectedRouteId;
    Set<String> selectedTags = {};
    final scaffoldContext = context;

    final appProvider =
        Provider.of<AppProvider>(scaffoldContext, listen: false);

    showDialog(
      context: scaffoldContext,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogBuildContext, setState) => AlertDialog(
          title: const Text('Crear Reporte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (busId != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_bus,
                            size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Reportando sobre: Bus $busId',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                if (busId != null) const SizedBox(height: 16),

                // Alertas predefinidas
                const Text(
                  'Alertas Predefinidas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona los problemas que has observado:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BusAlerts.predefinedAlerts.map((alert) {
                    final isSelected = selectedTags.contains(alert.id);
                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(alert.icon,
                              size: 16,
                              color: isSelected ? Colors.white : alert.color),
                          const SizedBox(width: 4),
                          Text(alert.label,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      selectedColor: alert.color,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedTags.add(alert.id);
                          } else {
                            selectedTags.remove(alert.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Reporte',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'complaint', child: Text('Queja')),
                    DropdownMenuItem(
                        value: 'suggestion', child: Text('Sugerencia')),
                    DropdownMenuItem(
                        value: 'compliment', child: Text('Elogio')),
                    DropdownMenuItem(value: 'issue', child: Text('Problema')),
                    DropdownMenuItem(value: 'other', child: Text('Otro')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: 'Resumen del reporte',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    title = value;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Descripción *',
                    hintText: 'Describe el problema o sugerencia...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                  onChanged: (value) {
                    description = value;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridad',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Baja')),
                    DropdownMenuItem(value: 'medium', child: Text('Media')),
                    DropdownMenuItem(value: 'high', child: Text('Alta')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedPriority = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (appProvider.rutas.isNotEmpty)
                  DropdownButtonFormField<String?>(
                    value: selectedRouteId,
                    decoration: const InputDecoration(
                      labelText: 'Ruta (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Ninguna'),
                      ),
                      ...appProvider.rutas.map((ruta) {
                        return DropdownMenuItem<String?>(
                          value: ruta.routeId,
                          child: Text(ruta.name),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedRouteId = value;
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogBuildContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.isEmpty || description.isEmpty) {
                  if (dialogBuildContext.mounted) {
                    ScaffoldMessenger.of(dialogBuildContext).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Por favor completa todos los campos obligatorios'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                  return;
                }

                final success = await appProvider.createUserReport(
                  type: selectedType,
                  title: title,
                  description: description,
                  priority: selectedPriority,
                  routeId: selectedRouteId,
                  busId: busId,
                  tags: selectedTags.isNotEmpty ? selectedTags.toList() : null,
                );

                if (!mounted) return;

                if (dialogBuildContext.mounted) {
                  Navigator.of(dialogBuildContext).pop();
                }

                if (!scaffoldContext.mounted) return;
                ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Reporte creado exitosamente'
                          : 'Error al crear reporte',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Enviar Reporte'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final user = appProvider.currentUser;
        final isPassenger = user?.role == 'user';

        return Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Header del Drawer con gradiente moderno
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2E7D32),
                      const Color(0xFF4CAF50),
                      Colors.green[300]!,
                    ],
                  ),
                ),
                child: DrawerHeader(
                  decoration: const BoxDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GeoRuLogo(
                        size: 56,
                        showText: true,
                        showSlogan: false,
                      ),
                      const SizedBox(height: 20),
                      if (user != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.email_rounded,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      user.email,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.9),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ===== SECCIÓN: ACCIONES PRINCIPALES =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  localizations.translate('main_actions') ?? 'Acciones Principales',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Opciones específicas para pasajeros
              if (isPassenger) ...[
                ListTile(
                  leading: const Icon(Icons.history, color: Colors.blue),
                  title: Text(localizations.translate('trip_history')),
                  subtitle: Text(
                    localizations.translate('view_completed_trips') ?? 
                    'Ver tus viajes completados',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showTripsHistoryDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report, color: Colors.orange),
                  title: Text(localizations.translate('create_report')),
                  subtitle: Text(
                    localizations.translate('send_complaint_suggestion') ?? 
                    'Enviar queja o sugerencia',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateReportDialog(busId: null);
                  },
                ),
              ],

              // Mapa completo (disponible para todos)
              ListTile(
                leading: const Icon(Icons.map, color: Colors.green),
                title: Text(localizations.translate('full_map')),
                subtitle: Text(
                  localizations.translate('view_complete_map') ?? 
                  'Ver mapa completo de buses',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MapScreen(),
                    ),
                  );
                },
              ),

              const Divider(),

              // ===== SECCIÓN: CONFIGURACIÓN =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  localizations.translate('settings') ?? 'Configuración',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),

              // Configuración
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(localizations.translate('configuration')),
                subtitle: Text(
                  localizations.translate('app_settings') ?? 
                  'Ajustes de la aplicación',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),

              const Divider(),

              // Cerrar sesión
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  localizations.translate('logout'),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
