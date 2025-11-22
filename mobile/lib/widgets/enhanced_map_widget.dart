import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/bus.dart';
import '../models/ruta.dart';
import '../models/user_report.dart';
import '../utils/bus_alerts.dart';
import '../utils/app_colors.dart';
import '../config/openstreetmap_config.dart';
import '../services/polyline_service.dart';
// Usaremos las paradas directamente para dibujar rutas

/// Widget de mapa mejorado con rutas, paradas y alertas
class EnhancedMapWidget extends StatefulWidget {
  final bool showMyLocation;
  final List<BusLocation> buses;
  final List<Ruta> routes;
  final bool showStops;
  final bool showAlerts;
  final String? initialBusId;
  final Function(BusLocation)? onBusTap;
  final String? selectedRouteId; // Ruta seleccionada para mostrar su polilínea
  final String? selectedBusId; // Bus seleccionado para mostrar su ruta

  const EnhancedMapWidget({
    super.key,
    this.showMyLocation = true,
    required this.buses,
    this.routes = const [],
    this.showStops = true,
    this.showAlerts = true,
    this.initialBusId,
    this.onBusTap,
    this.selectedRouteId,
    this.selectedBusId,
  });

  @override
  State<EnhancedMapWidget> createState() => _EnhancedMapWidgetState();
}

class _EnhancedMapWidgetState extends State<EnhancedMapWidget> {
  final MapController _mapController = MapController();
  latlong2.LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    // Retrasar la carga de ubicación para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentLocation();
    });
  }

  Future<void> _loadCurrentLocation() async {
    if (!mounted) return;
    
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    
    // Si ya hay una ubicación, usarla directamente sin llamar a getCurrentLocation
    if (appProvider.currentPosition != null) {
      if (mounted) {
        setState(() {
          _currentLocation = latlong2.LatLng(
            appProvider.currentPosition!.latitude,
            appProvider.currentPosition!.longitude,
          );
        });
        
        // Si hay un bus inicial, centrar en ese bus
        if (widget.initialBusId != null && widget.buses.isNotEmpty) {
          final initialBus = widget.buses.firstWhere(
            (bus) => bus.busId == widget.initialBusId,
            orElse: () => widget.buses.first,
          );
          _mapController.move(
            latlong2.LatLng(initialBus.latitude, initialBus.longitude),
            15.0,
          );
        } else if (_currentLocation != null) {
          // Centrar en la ubicación actual
          _mapController.move(
            _currentLocation!,
            OpenStreetMapConfig.defaultZoom,
          );
        }
      }
      return;
    }
    
    // Solo llamar a getCurrentLocation si no hay ubicación previa
    await appProvider.getCurrentLocation();
    if (appProvider.currentPosition != null && mounted) {
      setState(() {
        _currentLocation = latlong2.LatLng(
          appProvider.currentPosition!.latitude,
          appProvider.currentPosition!.longitude,
        );
      });

      // Si hay un bus inicial, centrar en ese bus
      if (widget.initialBusId != null && widget.buses.isNotEmpty) {
        final initialBus = widget.buses.firstWhere(
          (bus) => bus.busId == widget.initialBusId,
          orElse: () => widget.buses.first,
        );
        _mapController.move(
          latlong2.LatLng(initialBus.latitude, initialBus.longitude),
          15.0,
        );
      } else if (_currentLocation != null) {
        // Centrar en la ubicación actual
        _mapController.move(
          _currentLocation!,
          OpenStreetMapConfig.defaultZoom,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLocation ??
            const latlong2.LatLng(
              OpenStreetMapConfig.defaultLatitude,
              OpenStreetMapConfig.defaultLongitude,
            ),
        initialZoom: OpenStreetMapConfig.defaultZoom,
        minZoom: OpenStreetMapConfig.minZoom,
        maxZoom: OpenStreetMapConfig.maxZoom,
        onTap: (tapPosition, point) {
          _handleMapTap(point);
        },
      ),
      children: [
        // Capa de tiles de OpenStreetMap (menos saturado)
        TileLayer(
          urlTemplate: OpenStreetMapConfig.tileLayerUrlTemplate,
          userAgentPackageName: 'com.transporterural.georu',
          maxZoom: OpenStreetMapConfig.maxZoom,
          maxNativeZoom: OpenStreetMapConfig.maxNativeZoom,
          subdomains: OpenStreetMapConfig.subdomains,
        ),

        // Capa de rutas (polylines) - solo mostrar si hay ruta o bus seleccionado
        if (widget.showStops && 
            (widget.selectedRouteId != null || widget.selectedBusId != null))
          PolylineLayer(
            polylines: _buildRoutePolylines(),
          ),

        // Capa de paradas - solo mostrar si hay ruta o bus seleccionado
        if (widget.showStops && 
            (widget.selectedRouteId != null || widget.selectedBusId != null))
          MarkerLayer(
            markers: _buildStopMarkers(),
          ),

        // Marcadores de buses
        MarkerLayer(
          markers: _buildBusMarkers(),
        ),

        // Marcador de ubicación actual
        if (widget.showMyLocation && _currentLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation!,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.my_location,
                  color: Colors.blue,
                  size: 30,
                ),
              ),
            ],
          ),

        // Atribución requerida por OpenStreetMap
        const RichAttributionWidget(
          alignment: AttributionAlignment.bottomRight,
          attributions: [
            TextSourceAttribution(
              OpenStreetMapConfig.attribution,
              textStyle: TextStyle(fontSize: 10),
            ),
          ],
        ),

        // Controles del mapa
        Positioned(
          bottom: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton.small(
                onPressed: _centerOnMyLocation,
                heroTag: 'center_location',
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              if (widget.buses.isNotEmpty)
                FloatingActionButton.small(
                  onPressed: _centerOnBuses,
                  heroTag: 'center_buses',
                  child: const Icon(Icons.directions_bus),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<Polyline> _buildRoutePolylines() {
    print('🗺️ [ENHANCED_MAP] Construyendo polilíneas...');
    print('   Rutas recibidas: ${widget.routes.length}');
    print('   selectedRouteId: ${widget.selectedRouteId}');
    print('   selectedBusId: ${widget.selectedBusId}');
    
    final polylines = <Polyline>[];
    
    // Determinar qué rutas mostrar
    List<Ruta> routesToShow = [];
    
    if (widget.selectedRouteId != null || widget.selectedBusId != null) {
      // Si hay una ruta o bus seleccionado, mostrar solo esa ruta
      String? routeIdToShow = widget.selectedRouteId;
      
      // Si hay un bus seleccionado, obtener su ruta
      if (routeIdToShow == null && widget.selectedBusId != null) {
        final selectedBus = widget.buses.firstWhere(
          (bus) => bus.busId == widget.selectedBusId,
          orElse: () => BusLocation(
            busId: '',
            latitude: 0,
            longitude: 0,
            status: 'inactive',
          ),
        );
        routeIdToShow = selectedBus.routeId;
      }
      
      if (routeIdToShow != null) {
        final route = widget.routes.firstWhere(
          (r) => r.routeId == routeIdToShow,
          orElse: () => Ruta(
            routeId: '',
            name: '',
            schedule: '',
            stops: [],
            polyline: '',
          ),
        );
        if (route.routeId.isNotEmpty) {
          routesToShow = [route];
        }
      }
    } else {
      // Si no hay selección, mostrar todas las rutas
      routesToShow = widget.routes;
    }

    print('   Rutas a mostrar: ${routesToShow.length}');

    // Generar polilíneas para cada ruta
    for (final route in routesToShow) {
      if (route.routeId.isEmpty) {
        print('   ⚠️ Saltando ruta con routeId vacío');
        continue;
      }

      print('   🔍 Procesando ruta: ${route.routeId} - ${route.name}');
      List<latlong2.LatLng> points = [];

      // Priorizar polilínea codificada si existe
      if (route.polyline.isNotEmpty) {
        print('     Intentando decodificar polilínea...');
        final decoded = PolylineService.decodePolyline(route.polyline);
        if (decoded != null && decoded.isNotEmpty) {
          points = decoded.map((p) => latlong2.LatLng(p.latitude, p.longitude)).toList();
          print('     ✅ Polilínea decodificada: ${points.length} puntos');
        } else {
          print('     ❌ Falló la decodificación de polilínea');
        }
      } else {
        print('     ⚠️ Ruta sin polilínea codificada');
      }

      // Si no hay polilínea codificada o falló, usar paradas
      if (points.isEmpty && route.stops.length > 1) {
        print('     Usando paradas como fallback (${route.stops.length} paradas)');
        // Ordenar paradas por orden si existe
        final sortedStops = List<Parada>.from(route.stops);
        sortedStops.sort((a, b) {
          final orderA = a.order ?? a.orden ?? 0;
          final orderB = b.order ?? b.orden ?? 0;
          return orderA.compareTo(orderB);
        });

        points = sortedStops
            .where((stop) => stop.latitude != 0.0 && stop.longitude != 0.0)
            .map((stop) => latlong2.LatLng(stop.latitude, stop.longitude))
            .toList();
        print('     Paradas válidas: ${points.length}');
      } else if (points.isEmpty) {
        print('     ⚠️ No hay suficientes paradas (${route.stops.length})');
      }

      if (points.length >= 2) {
        polylines.add(
          Polyline(
            points: points,
            strokeWidth: 4,
            color: AppColors.primaryGreen,
          ),
        );
        print('     ✅ Polilínea agregada al mapa');
      } else {
        print('     ❌ No se pudo crear polilínea (solo ${points.length} puntos)');
      }
    }

    print('🗺️ [ENHANCED_MAP] Total polilíneas creadas: ${polylines.length}');
    return polylines;
  }

  List<Marker> _buildStopMarkers() {
    final markers = <Marker>[];
    
    // Determinar qué rutas mostrar
    List<Ruta> routesToShow = [];
    
    if (widget.selectedRouteId != null || widget.selectedBusId != null) {
      // Si hay una ruta o bus seleccionado, mostrar solo esa ruta
      String? routeIdToShow = widget.selectedRouteId;
      
      // Si hay un bus seleccionado, obtener su ruta
      if (routeIdToShow == null && widget.selectedBusId != null) {
        final selectedBus = widget.buses.firstWhere(
          (bus) => bus.busId == widget.selectedBusId,
          orElse: () => BusLocation(
            busId: '',
            latitude: 0,
            longitude: 0,
            status: 'inactive',
          ),
        );
        routeIdToShow = selectedBus.routeId;
      }
      
      if (routeIdToShow != null) {
        final route = widget.routes.firstWhere(
          (r) => r.routeId == routeIdToShow,
          orElse: () => Ruta(
            routeId: '',
            name: '',
            schedule: '',
            stops: [],
            polyline: '',
          ),
        );
        if (route.routeId.isNotEmpty) {
          routesToShow = [route];
        }
      }
    } else {
      // Si no hay selección, mostrar todas las rutas
      routesToShow = widget.routes;
    }

    // Generar marcadores para cada ruta
    for (final route in routesToShow) {
      if (route.routeId.isEmpty) continue;

      for (final stop in route.stops) {
        if (stop.latitude == 0.0 && stop.longitude == 0.0) {
          continue; // Saltar paradas sin coordenadas
        }
        
        markers.add(
          Marker(
            point: latlong2.LatLng(stop.latitude, stop.longitude),
            width: 32,
            height: 32,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentOrange,
                    AppColors.accentOrange.withValues(alpha: 0.8),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  List<Marker> _buildBusMarkers() {
    return widget.buses.map((busLocation) {
      // Obtener alertas del bus si están habilitadas
      final hasAlerts = widget.showAlerts;
      final statusColor = AppColors.getBusStatusColor(busLocation.status);

      return Marker(
        point: latlong2.LatLng(busLocation.latitude, busLocation.longitude),
        width: 56,
        height: 56,
        child: GestureDetector(
          onTap: () {
            if (widget.onBusTap != null) {
              widget.onBusTap!(busLocation);
            } else {
              _showBusDetails(busLocation);
            }
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Sombra exterior animada
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              // Contenedor principal con gradiente
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor,
                      statusColor.withValues(alpha: 0.8),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3.5),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.6),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              // Indicador de alerta mejorado
              if (hasAlerts)
                FutureBuilder<List<UserReport>>(
                  future: Provider.of<AppProvider>(context, listen: false)
                      .getBusAlerts(busLocation.busId),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      final allTags = <String>{};
                      for (var report in snapshot.data!) {
                        if (report.tags != null) {
                          allTags.addAll(report.tags!);
                        }
                      }
                      if (allTags.isNotEmpty) {
                        return Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF5722), Color(0xFFFF7043)],
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.6),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.warning_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
              // Indicador de estado pulsante para buses activos
              if (busLocation.status == 'active' || busLocation.status == 'en_ruta')
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.5, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  builder: (context, opacity, child) {
                    return Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: opacity * 0.3),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  void _handleMapTap(latlong2.LatLng position) {
    // Buscar si se hizo clic cerca de un bus
    for (final busLocation in widget.buses) {
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        busLocation.latitude,
        busLocation.longitude,
      );
      // Si está a menos de 100 metros
      if (distance < 100) {
        if (widget.onBusTap != null) {
          widget.onBusTap!(busLocation);
        } else {
          _showBusDetails(busLocation);
        }
        break;
      }
    }
  }

  void _showBusDetails(BusLocation busLocation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppColors.getStatusGradient(
                                  busLocation.status),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.getBusStatusColor(
                                          busLocation.status)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.directions_bus,
                                color: Colors.white),
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
                                    color: AppColors.getBusStatusColor(
                                            busLocation.status)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.getBusStatusColor(
                                          busLocation.status),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    busLocation.status,
                                    style: TextStyle(
                                      color: AppColors.getBusStatusColor(
                                          busLocation.status),
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
                        _getRouteNameForBus(busLocation, widget.routes),
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
                          iconColor:
                              AppColors.getCompanyColor(busLocation.companyId),
                        ),
                      _buildDetailRow(
                        'Ubicación',
                        'Lat: ${busLocation.latitude.toStringAsFixed(6)}\n'
                            'Lng: ${busLocation.longitude.toStringAsFixed(6)}',
                      ),
                      _buildDetailRow(
                        'Última actualización',
                        busLocation.lastUpdate ?? 'N/A',
                      ),
                      // Alertas del bus
                      if (widget.showAlerts) ...[
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        FutureBuilder<List<UserReport>>(
                          future:
                              Provider.of<AppProvider>(context, listen: false)
                                  .getBusAlerts(busLocation.busId),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                              final allTags = <String>{};
                              for (var report in snapshot.data!) {
                                if (report.tags != null) {
                                  allTags.addAll(report.tags!);
                                }
                              }
                              if (allTags.isNotEmpty) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Alertas Activas:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: allTags.map((tagId) {
                                        final alert =
                                            BusAlerts.getAlertById(tagId);
                                        if (alert == null) {
                                          return Chip(
                                            label: Text(
                                              tagId,
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                            backgroundColor: Colors.orange[200],
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            materialTapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                            visualDensity:
                                                VisualDensity.compact,
                                          );
                                        }
                                        return Chip(
                                          label: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(alert.icon,
                                                  size: 14,
                                                  color: Colors.white),
                                              const SizedBox(width: 4),
                                              Text(
                                                alert.label,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: alert.color,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                );
                              }
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showReportDialog(context, busLocation);
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
                                Navigator.of(context).pop();
                                _moveToBusLocation(busLocation);
                              },
                              icon: const Icon(Icons.center_focus_strong),
                              label: const Text('Centrar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
            width: 100,
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

  void _moveToBusLocation(BusLocation busLocation) {
    _mapController.move(
      latlong2.LatLng(busLocation.latitude, busLocation.longitude),
      15.0, // Zoom más cercano
    );
  }

  void _centerOnMyLocation() {
    if (_currentLocation != null) {
      _mapController.move(
        _currentLocation!,
        15.0,
      );
    } else {
      _loadCurrentLocation();
    }
  }

  void _centerOnBuses() {
    if (widget.buses.isEmpty) return;

    // Calcular el centro de todos los buses
    double sumLat = 0;
    double sumLng = 0;
    for (final bus in widget.buses) {
      sumLat += bus.latitude;
      sumLng += bus.longitude;
    }
    final centerLat = sumLat / widget.buses.length;
    final centerLng = sumLng / widget.buses.length;

    _mapController.move(
      latlong2.LatLng(centerLat, centerLng),
      12.0,
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const distance = latlong2.Distance();
    return distance.as(
      latlong2.LengthUnit.Meter,
      latlong2.LatLng(lat1, lon1),
      latlong2.LatLng(lat2, lon2),
    );
  }

  void _showReportDialog(BuildContext context, BusLocation busLocation) {
    String selectedType = 'complaint';
    String title = '';
    String description = '';
    String selectedPriority = 'medium';
    Set<String> selectedTags = {};

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reportar Problema'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                        'Reportando sobre: Bus ${busLocation.busId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

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
                  'Selecciona las alertas que aplican:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
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
                          Text(alert.label),
                        ],
                      ),
                      selectedColor: alert.color,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setDialogState(() {
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
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: 'Título del reporte',
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
                    hintText: 'Describe el problema...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    description = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.isEmpty || description.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Por favor completa todos los campos obligatorios'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final success = await appProvider.createUserReport(
                  type: selectedType,
                  title: title,
                  description: description,
                  priority: selectedPriority,
                  busId: busLocation.busId,
                  tags: selectedTags.isNotEmpty ? selectedTags.toList() : null,
                );

                if (!context.mounted) return;

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
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
}
