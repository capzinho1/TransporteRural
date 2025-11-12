import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_localizations.dart';
import '../widgets/bus_card.dart';
import '../widgets/ruta_card.dart';
import '../widgets/georu_logo.dart';
import '../widgets/osm_map_widget.dart';
import '../models/trip.dart';
import '../models/bus.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    _userStatusCheckTimer?.cancel();
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GeoRuLogo(
              size: 28,
              showText: false,
              showSlogan: false,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'GeoRu',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: AppLocalizations.of(context)?.translate('refresh') ??
                'Actualizar',
          ),
          Builder(
            builder: (popupContext) {
              return PopupMenuButton<String>(
                onSelected: (value) {
                  final appProvider =
                      Provider.of<AppProvider>(context, listen: false);
                  final isPassenger = appProvider.currentUser?.role == 'user';

                  if (value == 'logout') {
                    _showLogoutDialog();
                  } else if (value == 'trips' && isPassenger) {
                    _showTripsHistoryDialog();
                  } else if (value == 'reports' && isPassenger) {
                    _showCreateReportDialog(busId: null);
                  }
                },
                itemBuilder: (context) {
                  final appProvider =
                      Provider.of<AppProvider>(context, listen: false);
                  final isPassenger = appProvider.currentUser?.role == 'user';
                  final loc = AppLocalizations.of(context);

                  final items = <PopupMenuItem<String>>[];

                  if (isPassenger) {
                    items.addAll([
                      PopupMenuItem(
                        value: 'trips',
                        child: Row(
                          children: [
                            const Icon(Icons.history, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(loc?.translate('trip_history') ??
                                'Historial de Viajes'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'reports',
                        child: Row(
                          children: [
                            const Icon(Icons.report, color: Colors.orange),
                            const SizedBox(width: 8),
                            Text(loc?.translate('create_report') ??
                                'Crear Reporte'),
                          ],
                        ),
                      ),
                    ]);
                  }

                  items.add(
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(
                        children: [
                          const Icon(Icons.logout, color: Colors.red),
                          const SizedBox(width: 8),
                          Text(loc?.translate('logout') ?? 'Cerrar Sesión'),
                        ],
                      ),
                    ),
                  );

                  return items;
                },
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.directions_bus),
              text: AppLocalizations.of(context)?.translate('buses') ?? 'Buses',
            ),
            Tab(
              icon: const Icon(Icons.route),
              text:
                  AppLocalizations.of(context)?.translate('routes') ?? 'Rutas',
            ),
            Tab(
              icon: const Icon(Icons.map),
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
      floatingActionButton: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final isPassenger = appProvider.currentUser?.role == 'user';

          if (isPassenger) {
            // Menú flotante expandible para pasajeros
            return FloatingActionButton(
              heroTag: 'home_passenger_menu',
              onPressed: () {
                _showPassengerMenu(context);
              },
              child: const Icon(Icons.more_vert),
            );
          } else {
            // Botón flotante normal para otros roles
            return FloatingActionButton(
              heroTag: 'home_map_button',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
              },
              child: const Icon(Icons.map),
            );
          }
        },
      ),
      // Botón flotante adicional para mapa completo (visible para todos)
      persistentFooterButtons: [
        FloatingActionButton.extended(
          heroTag: 'home_full_map_button',
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const MapScreen()),
            );
          },
          icon: const Icon(Icons.map),
          label: Text(AppLocalizations.of(context)?.translate('full_map') ??
              'Mapa Completo'),
          backgroundColor: Colors.green,
        ),
      ],
    );
  }

  Widget _buildBusesTab() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (appProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  appProvider.error!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitialData,
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }

        if (appProvider.busLocations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.directions_bus_outlined,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)
                          ?.translate('no_buses_available') ??
                      'No hay buses disponibles',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadInitialData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appProvider.busLocations.length,
            itemBuilder: (context, index) {
              final busLocation = appProvider.busLocations[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BusCard(busLocation: busLocation),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRutasTab() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        if (appProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (appProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  appProvider.error!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitialData,
                  child: Text(
                      AppLocalizations.of(context)?.translate('retry') ??
                          'Reintentar'),
                ),
              ],
            ),
          );
        }

        if (appProvider.rutas.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.route_outlined, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)
                          ?.translate('no_routes_available') ??
                      'No hay rutas disponibles',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadInitialData,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: appProvider.rutas.length,
            itemBuilder: (context, index) {
              final ruta = appProvider.rutas[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: RutaCard(ruta: ruta),
              );
            },
          ),
        );
      },
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
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<AppProvider>(context, listen: false).logout();
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: Text(localizations.translate('logout')),
            ),
          ],
        );
      },
    );
  }

  void _showPassengerMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Opciones de Pasajero',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.blue),
              title: Text(
                  AppLocalizations.of(context)?.translate('trip_history') ??
                      'Historial de Viajes'),
              subtitle: Text(AppLocalizations.of(context)
                      ?.translate('view_completed_trips') ??
                  'Ver tus viajes completados'),
              onTap: () {
                Navigator.pop(context);
                _showTripsHistoryDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.orange),
              title: Text(
                  AppLocalizations.of(context)?.translate('create_report') ??
                      'Crear Reporte'),
              subtitle: Text(AppLocalizations.of(context)
                      ?.translate('send_complaint_suggestion') ??
                  'Enviar queja o sugerencia'),
              onTap: () {
                Navigator.pop(context);
                _showCreateReportDialog(busId: null);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map, color: Colors.green),
              title: Text(
                  AppLocalizations.of(context)?.translate('view_full_map') ??
                      'Ver Mapa Completo'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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
            _buildDetailRow('Ruta', busLocation.routeId ?? 'N/A'),
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
              // Header del Drawer
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.green[700],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const GeoRuLogo(
                      size: 48,
                      showText: true,
                      showSlogan: false,
                    ),
                    const SizedBox(height: 16),
                    if (user != null) ...[
                      Text(
                        user.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Opciones del menú para pasajeros
              if (isPassenger) ...[
                ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(localizations.translate('trip_history')),
                  onTap: () {
                    Navigator.pop(context);
                    _showTripsHistoryDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.report),
                  title: Text(localizations.translate('create_report')),
                  onTap: () {
                    Navigator.pop(context);
                    _showCreateReportDialog(busId: null);
                  },
                ),
                const Divider(),
              ],

              // Configuración
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(localizations.translate('configuration')),
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

              // Mapa completo
              ListTile(
                leading: const Icon(Icons.map),
                title: Text(localizations.translate('full_map')),
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
