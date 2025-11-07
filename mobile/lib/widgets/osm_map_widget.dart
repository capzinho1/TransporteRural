import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/bus.dart';
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
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
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
                LatLng(
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
            // Capa de tiles de OpenStreetMap
            TileLayer(
              urlTemplate: OpenStreetMapConfig.tileLayerUrlTemplate,
              userAgentPackageName: 'com.transporterural.georu',
              maxZoom: OpenStreetMapConfig.maxZoom,
              maxNativeZoom: OpenStreetMapConfig.maxNativeZoom,
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
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomRight,
              attributions: [
                TextSourceAttribution(
                  OpenStreetMapConfig.attribution,
                  textStyle: const TextStyle(fontSize: 10),
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
              color: _getStatusColor(busLocation.status),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
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
                    color: _getStatusColor(busLocation.status),
                    shape: BoxShape.circle,
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
                        ),
                      ),
                      Text(
                        'Estado: ${busLocation.status}',
                        style: TextStyle(
                          color: _getStatusColor(busLocation.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Ruta', busLocation.routeId ?? 'N/A'),
            _buildDetailRow('Conductor', busLocation.driverId?.toString() ?? 'N/A'),
            _buildDetailRow(
              'Latitud',
              busLocation.latitude.toStringAsFixed(6),
            ),
            _buildDetailRow(
              'Longitud',
              busLocation.longitude.toStringAsFixed(6),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'en_ruta':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'finalizado':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    final distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      LatLng(lat1, lon1),
      LatLng(lat2, lon2),
    );
  }
}

