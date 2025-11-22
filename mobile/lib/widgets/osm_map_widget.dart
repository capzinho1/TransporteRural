import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/bus.dart';
import '../utils/app_colors.dart';
import '../config/openstreetmap_config.dart';

/// Widget de mapa usando OpenStreetMap con flutter_map
class OsmMapWidget extends StatefulWidget {
  final bool showMyLocation;
  final Function(BusLocation)? onBusTap;

  const OsmMapWidget({
    super.key,
    this.showMyLocation = true,
    this.onBusTap,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;

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
          _currentLocation = LatLng(
            appProvider.currentPosition!.latitude,
            appProvider.currentPosition!.longitude,
          );
        });
        _mapController.move(
          _currentLocation!,
          OpenStreetMapConfig.defaultZoom,
        );
      }
      return;
    }
    
    // Solo llamar a getCurrentLocation si no hay ubicación previa
    await appProvider.getCurrentLocation();
    if (appProvider.currentPosition != null && mounted) {
      setState(() {
        _currentLocation = LatLng(
          appProvider.currentPosition!.latitude,
          appProvider.currentPosition!.longitude,
        );
      });
      // Centrar el mapa en la ubicación actual
      _mapController.move(
        _currentLocation!,
        OpenStreetMapConfig.defaultZoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentLocation ??
                const LatLng(
                  OpenStreetMapConfig.defaultLatitude,
                  OpenStreetMapConfig.defaultLongitude,
                ),
            initialZoom: OpenStreetMapConfig.defaultZoom,
            minZoom: OpenStreetMapConfig.minZoom,
            maxZoom: OpenStreetMapConfig.maxZoom,
            onTap: (tapPosition, point) {
              _handleMapTap(point, appProvider.busLocations);
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

            // Marcadores de buses
            MarkerLayer(
              markers: _buildBusMarkers(appProvider.busLocations),
            ),

            // Marcador de ubicación actual (si está disponible)
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
          ],
        );
      },
    );
  }

  List<Marker> _buildBusMarkers(List<BusLocation> busLocations) {
    return busLocations.map((busLocation) {
      return Marker(
        point: LatLng(busLocation.latitude, busLocation.longitude),
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
          child: Container(
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
        ),
      );
    }).toList();
  }

  void _handleMapTap(LatLng position, List<BusLocation> busLocations) {
    // Buscar si se hizo clic cerca de un bus
    for (final busLocation in busLocations) {
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        busLocation.latitude,
        busLocation.longitude,
      );
      // Si está a menos de 100 metros
      if (distance < 100) {
        _showBusDetails(busLocation);
        break;
      }
    }
  }

  void _showBusDetails(BusLocation busLocation) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              _getRouteNameForBus(busLocation),
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
              'Lat: ${busLocation.latitude.toStringAsFixed(6)}\nLng: ${busLocation.longitude.toStringAsFixed(6)}',
              icon: Icons.location_on,
              iconColor: AppColors.accentIndigo,
            ),
            _buildDetailRow(
              'Última actualización',
              busLocation.lastUpdate ?? 'N/A',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  _moveToBusLocation(busLocation);
                },
                icon: const Icon(Icons.center_focus_strong),
                label: const Text('Centrar en este bus'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper para obtener el nombre de la ruta de un bus
  String _getRouteNameForBus(BusLocation busLocation) {
    // Obtener las rutas del provider
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final routes = appProvider.rutas;
    
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
            width: icon != null ? 80 : 120,
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
      LatLng(busLocation.latitude, busLocation.longitude),
      15.0, // Zoom más cercano
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      LatLng(lat1, lon1),
      LatLng(lat2, lon2),
    );
  }
}
