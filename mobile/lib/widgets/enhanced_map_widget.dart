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

  const EnhancedMapWidget({
    super.key,
    this.showMyLocation = true,
    required this.buses,
    this.routes = const [],
    this.showStops = true,
    this.showAlerts = true,
    this.initialBusId,
    this.onBusTap,
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
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
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
        // Capa de tiles de OpenStreetMap
        TileLayer(
          urlTemplate: OpenStreetMapConfig.tileLayerUrlTemplate,
          userAgentPackageName: 'com.transporterural.georu',
          maxZoom: OpenStreetMapConfig.maxZoom,
          maxNativeZoom: OpenStreetMapConfig.maxNativeZoom,
        ),

        // Capa de rutas (polylines)
        if (widget.showStops && widget.routes.isNotEmpty)
          PolylineLayer(
            polylines: _buildRoutePolylines(),
          ),

        // Capa de paradas
        if (widget.showStops && widget.routes.isNotEmpty)
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
    final polylines = <Polyline>[];

    for (final route in widget.routes) {
      // Dibujar línea entre paradas (ordenadas)
      if (route.stops.length > 1) {
        // Ordenar paradas por orden si existe
        final sortedStops = List<Parada>.from(route.stops);
        sortedStops.sort((a, b) {
          final orderA = a.order ?? a.orden ?? 0;
          final orderB = b.order ?? b.orden ?? 0;
          return orderA.compareTo(orderB);
        });

        final points = sortedStops.map((stop) {
          return latlong2.LatLng(stop.latitude, stop.longitude);
        }).toList();

        polylines.add(
          Polyline(
            points: points,
            strokeWidth: 4,
            color: AppColors.primaryGreen,
          ),
        );
      }
    }

    return polylines;
  }

  List<Marker> _buildStopMarkers() {
    final markers = <Marker>[];

    for (final route in widget.routes) {
      for (final stop in route.stops) {
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

      return Marker(
        point: latlong2.LatLng(busLocation.latitude, busLocation.longitude),
        width: 50,
        height: 50,
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
              Container(
                decoration: BoxDecoration(
                  color: AppColors.getBusStatusColor(busLocation.status),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.getBusStatusColor(busLocation.status)
                          .withValues(alpha: 0.5),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                  size: 24,
                ),
              ),
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
                          top: -5,
                          right: -5,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.warning,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        );
                      }
                    }
                    return const SizedBox.shrink();
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
