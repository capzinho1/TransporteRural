import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/app_provider.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../models/bus.dart';
import '../models/ruta.dart';
import '../widgets/osm_map_widget.dart';
import 'notifications_screen.dart';

/// Pantalla específica para conductores
/// Permite actualizar ubicación, iniciar/finalizar recorridos, ver ruta asignada
class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> {
  Timer? _locationUpdateTimer;
  Timer? _dataRefreshTimer;
  Timer? _userStatusCheckTimer;
  bool _isTrackingLocation = false;
  BusLocation? _myBus;
  Ruta? _assignedRoute;
  String? _floatingNotification;
  Color? _floatingNotificationColor;
  IconData? _floatingNotificationIcon;
  Timer? _notificationTimer;
  final Set<int> _shownNotificationIds =
      {}; // IDs de notificaciones ya mostradas

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDriverData();
      // Iniciar actualización automática cada 5 segundos
      _startDataRefreshTimer();
      // Iniciar verificación de estado del usuario
      _startUserStatusCheck();
    });
  }

  @override
  void dispose() {
    _locationUpdateTimer?.cancel();
    _dataRefreshTimer?.cancel();
    _notificationTimer?.cancel();
    _userStatusCheckTimer?.cancel();
    super.dispose();
  }

  void _showFloatingNotification(String message, Color backgroundColor,
      {IconData? icon}) {
    // Cancelar notificación anterior si existe
    _notificationTimer?.cancel();

    // Mostrar nueva notificación
    setState(() {
      _floatingNotification = message;
      _floatingNotificationColor = backgroundColor;
      _floatingNotificationIcon = icon;
    });

    // Ocultar después de 15 segundos
    _notificationTimer = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        setState(() {
          _floatingNotification = null;
          _floatingNotificationColor = null;
          _floatingNotificationIcon = null;
        });
      }
    });
  }

  void _startDataRefreshTimer() {
    // Actualizar datos cada 5 segundos para detectar cambios desde el admin
    _dataRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadDriverData();
      } else {
        timer.cancel();
      }
    });
  }

  void _startUserStatusCheck() {
    // Verificar estado del usuario cada 10 segundos
    _userStatusCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      final appProvider = Provider.of<AppProvider>(context, listen: false);
      final isActive = await appProvider.checkUserStatus();
      
      if (!isActive && mounted) {
        // Usuario fue desactivado, mostrar mensaje y redirigir al login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Su cuenta de conductor ha sido desactivada. Por favor, contacte al administrador de su empresa.',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
        
        // Redirigir al login después de un breve delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
        
        timer.cancel();
      }
    });
  }

  Future<void> _loadDriverData() async {
    if (!mounted) return;

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.loadBusLocations();
    await appProvider.loadRutas();

    // Cargar notificaciones también
    await appProvider.loadNotifications();

    // Detectar y mostrar nuevas notificaciones
    _checkForNewNotifications(appProvider);

    // Buscar el bus asignado a este conductor
    final driverId = appProvider.currentUser?.id;
    if (driverId != null) {
      try {
        final myBus = appProvider.busLocations.firstWhere(
          (bus) => bus.driverId == driverId,
        );

        // Verificar si el routeId cambió o se removió
        final previousRouteId = _myBus?.routeId;
        final currentRouteId = myBus.routeId;

        if (mounted) {
          setState(() {
            _myBus = myBus;
          });
        }

        // Cargar la ruta asignada
        if (currentRouteId != null && currentRouteId.isNotEmpty) {
          try {
            final route = appProvider.rutas.firstWhere(
              (r) => r.routeId == currentRouteId,
            );
            if (mounted) {
              setState(() {
                _assignedRoute = route;
              });
            }

            // Si la ruta cambió, mostrar notificación flotante
            if (previousRouteId != currentRouteId && previousRouteId != null) {
              if (mounted) {
                _showFloatingNotification(
                  'Nueva ruta asignada: ${route.name}',
                  Colors.green,
                );
              }
            }
          } catch (e) {
            // Ruta no encontrada, limpiar asignación
            if (mounted) {
              setState(() {
                _assignedRoute = null;
              });
            }
            print('⚠️ Ruta $currentRouteId no encontrada: $e');
          }
        } else {
          // No hay ruta asignada, limpiar
          if (mounted) {
            // Si antes tenía ruta y ahora no, mostrar notificación y detener seguimiento
            if (previousRouteId != null &&
                previousRouteId.isNotEmpty &&
                _assignedRoute != null) {
              final previousRouteName = _assignedRoute!.name;

              // Detener el seguimiento de ubicación si está activo
              if (_isTrackingLocation) {
                _stopLocationTracking();
              }

              setState(() {
                _assignedRoute = null;
              });

              // Mostrar notificación flotante
              _showFloatingNotification(
                'Ruta "$previousRouteName" removida por el administrador',
                Colors.orange,
              );
            } else {
              setState(() {
                _assignedRoute = null;
              });
            }
          }
        }
      } catch (e) {
        // No se encontró bus para este conductor
        if (mounted) {
          setState(() {
            _myBus = null;
            _assignedRoute = null;
          });
        }
        print('⚠️ No se encontró bus para el conductor $driverId: $e');
      }
    }
  }

  Future<void> _updateMyLocation() async {
    if (_myBus == null || _assignedRoute == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No hay ruta asignada. No puedes actualizar la ubicación.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.getCurrentLocation();

    if (appProvider.currentPosition != null) {
      try {
        if (_myBus!.id == null) {
          throw Exception('El bus no tiene ID asignado');
        }

        // Actualizar ubicación en el backend
        await appProvider.apiService.updateBusLocation(
          _myBus!.id!,
          {
            'latitude': appProvider.currentPosition!.latitude,
            'longitude': appProvider.currentPosition!.longitude,
            'status': _myBus!.status,
          },
        );

        // Actualizar el estado local del bus con la nueva ubicación
        if (mounted) {
          setState(() {
            _myBus = _myBus!.copyWith(
              latitude: appProvider.currentPosition!.latitude,
              longitude: appProvider.currentPosition!.longitude,
              lastUpdate: DateTime.now().toIso8601String(),
            );
          });
        }

        // Recargar datos del conductor (sin mostrar mensaje de error si falla)
        try {
          await appProvider.loadBusLocations();
          await _loadDriverData();
        } catch (e) {
          // Ignorar errores de recarga, la actualización ya se hizo
          print(
              '⚠️ Error al recargar datos después de actualizar ubicación: $e');
        }

        // No mostrar mensaje de éxito para no interrumpir el flujo
        // El conductor verá la actualización en la UI automáticamente
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar ubicación: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        print('❌ Error al actualizar ubicación: $e');
      }
    }
  }

  void _startLocationTracking() {
    if (_myBus == null || _assignedRoute == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('No hay ruta asignada. No puedes iniciar el seguimiento.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_isTrackingLocation) {
      _stopLocationTracking();
      return;
    }

    setState(() {
      _isTrackingLocation = true;
    });

    // Actualizar ubicación cada 30 segundos
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _updateMyLocation(),
    );

    // Primera actualización inmediata
    _updateMyLocation();
  }

  void _stopLocationTracking() {
    _locationUpdateTimer?.cancel();
    setState(() {
      _isTrackingLocation = false;
    });
  }

  Future<void> _changeBusStatus(String newStatus) async {
    if (_myBus == null || _assignedRoute == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay ruta asignada. No puedes cambiar el estado.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    try {
      if (_myBus!.id == null) {
        throw Exception('El bus no tiene ID asignado');
      }

      // Actualizar estado en el backend
      await appProvider.apiService.updateBusLocation(
        _myBus!.id!,
        {
          'latitude': _myBus!.latitude,
          'longitude': _myBus!.longitude,
          'status': newStatus,
        },
      );

      // Actualizar el estado local inmediatamente
      if (mounted) {
        setState(() {
          _myBus = _myBus!.copyWith(
            status: newStatus,
            lastUpdate: DateTime.now().toIso8601String(),
          );
        });
      }

      // Recargar datos del backend
      try {
        await appProvider.loadBusLocations();
        await _loadDriverData();
      } catch (e) {
        // Ignorar errores de recarga, la actualización ya se hizo
        print('⚠️ Error al recargar datos después de cambiar estado: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Estado cambiado a: ${_getStatusLabel(newStatus)}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cambiar estado: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      print('❌ Error al cambiar estado: $e');
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'en_ruta':
        return 'En Ruta';
      case 'active':
        return 'Activo';
      case 'inactive':
        return 'Inactivo';
      case 'finalizado':
        return 'Finalizado';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en_ruta':
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'finalizado':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AppProvider>(
          builder: (context, appProvider, child) {
            final userName = appProvider.currentUser?.name ?? 'Conductor';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.drive_eta),
                    SizedBox(width: 8),
                    Text(
                      'Vista de Conductor',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                Consumer<AppProvider>(
                  builder: (context, appProvider, child) {
                    final unreadCount = appProvider.notifications.length;
                    if (unreadCount > 0) {
                      return Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            tooltip: 'Notificaciones',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDriverData,
            tooltip: 'Actualizar',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Cerrar Sesión'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading && _myBus == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_myBus == null) {
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
                  const Text(
                    'No tienes un bus asignado',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Contacta al administrador para asignarte un bus',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    // Información del bus
                    _buildBusInfoCard(_myBus!, appProvider),

                    // Mapa con ubicación actual
                    const SizedBox(
                      height: 300,
                      child: OsmMapWidget(
                        showMyLocation: true,
                      ),
                    ),

                    // Controles de conductor (solo si hay ruta asignada)
                    if (_assignedRoute != null) _buildDriverControls(_myBus!),

                    // Información de la ruta
                    if (_assignedRoute != null)
                      _buildRouteInfoCard(_assignedRoute!),

                    // Mensaje cuando no hay ruta asignada
                    if (_assignedRoute == null && _myBus != null)
                      _buildNoRouteAssignedCard(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
              // Notificación flotante
              if (_floatingNotification != null)
                _buildFloatingNotification(
                  _floatingNotification!,
                  _floatingNotificationColor ?? Colors.blue,
                  _floatingNotificationIcon ?? Icons.notifications,
                ),
            ],
          );
        },
      ),
    );
  }

  void _checkForNewNotifications(AppProvider appProvider) {
    final notifications = appProvider.notifications;

    // Encontrar notificaciones nuevas que no hemos mostrado
    for (final notification in notifications) {
      if (!_shownNotificationIds.contains(notification.id)) {
        // Marcar como mostrada
        _shownNotificationIds.add(notification.id);

        // Mostrar como notificación flotante
        if (mounted) {
          // Determinar color según el tipo
          Color backgroundColor;
          IconData icon;

          switch (notification.type) {
            case 'drivers':
              backgroundColor = Colors.blue;
              icon = Icons.drive_eta;
              break;
            case 'route':
              backgroundColor = Colors.green;
              icon = Icons.route;
              break;
            case 'driver':
              backgroundColor = Colors.orange;
              icon = Icons.person;
              break;
            default:
              backgroundColor = Colors.blue;
              icon = Icons.notifications;
          }

          // Crear mensaje con título y contenido
          final message = '${notification.title}\n${notification.message}';

          _showFloatingNotification(message, backgroundColor, icon: icon);
        }
      }
    }
  }

  Widget _buildFloatingNotification(
      String message, Color backgroundColor, IconData icon) {
    // Si el mensaje tiene múltiples líneas (título y mensaje), formatearlo mejor
    final displayMessage = message;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Material(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: backgroundColor,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      displayMessage,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBusInfoCard(BusLocation bus, AppProvider appProvider) {
    final userName = appProvider.currentUser?.name ?? 'Conductor';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getStatusColor(bus.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_bus,
                    color: _getStatusColor(bus.status),
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus ${bus.busId}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Conductor: $userName',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(bus.status)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusLabel(bus.status),
                          style: TextStyle(
                            color: _getStatusColor(bus.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Ruta', bus.routeId ?? 'Sin asignar'),
            _buildInfoRow('Última actualización', bus.lastUpdate ?? 'Nunca'),
            if (appProvider.currentPosition != null)
              _buildInfoRow(
                'Mi ubicación',
                '${appProvider.currentPosition!.latitude.toStringAsFixed(6)}, ${appProvider.currentPosition!.longitude.toStringAsFixed(6)}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverControls(BusLocation bus) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Botón de seguimiento de ubicación
          ElevatedButton.icon(
            onPressed: _startLocationTracking,
            icon: Icon(_isTrackingLocation ? Icons.stop : Icons.play_arrow),
            label: Text(
              _isTrackingLocation
                  ? 'Detener Seguimiento'
                  : 'Iniciar Seguimiento',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isTrackingLocation ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 12),

          // Botón de actualizar ubicación manual
          OutlinedButton.icon(
            onPressed: _updateMyLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Actualizar Ubicación Ahora'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),

          // Botones de estado
          const Text(
            'Cambiar Estado del Recorrido',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusButton('en_ruta', 'Iniciar Ruta', Colors.green, bus),
              _buildStatusButton(
                  'finalizado', 'Finalizar Ruta', Colors.blue, bus),
              _buildStatusButton(
                  'inactive', 'Marcar Inactivo', Colors.grey, bus),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    String status,
    String label,
    Color color,
    BusLocation bus,
  ) {
    final isSelected = bus.status.toLowerCase() == status.toLowerCase();
    return ElevatedButton(
      onPressed: isSelected ? null : () => _changeBusStatus(status),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withValues(alpha: 0.1),
        foregroundColor: isSelected ? Colors.white : color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(label),
    );
  }

  Widget _buildNoRouteAssignedCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Sin Ruta Asignada',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Esperando asignación de ruta por el administrador',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard(Ruta route) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    route.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Builder(
              builder: (context) {
                List<String> scheduleList = [];
                if (route.schedule is List) {
                  scheduleList = (route.schedule as List)
                      .map((e) => e.toString())
                      .toList();
                } else if (route.schedule is String &&
                    (route.schedule as String).isNotEmpty) {
                  scheduleList = [route.schedule as String];
                }

                if (scheduleList.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Horarios:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: scheduleList.map((time) {
                        return Chip(
                          label: Text(time),
                          backgroundColor: Colors.blue[50],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
            if (route.stops.isNotEmpty) ...[
              const Text(
                'Paradas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...route.stops.asMap().entries.map((entry) {
                final stop = entry.value;
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.blue,
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(stop.name.isNotEmpty
                      ? stop.name
                      : 'Parada ${entry.key + 1}'),
                  subtitle: Text(
                    '${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}',
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final appProvider =
                  Provider.of<AppProvider>(context, listen: false);
              // Limpiar configuraciones del usuario
              final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
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
            child: const Text('Cerrar Sesión',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
