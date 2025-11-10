import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/bus.dart';
import '../config/openstreetmap_config.dart';

/// Widget de mapa usando OpenStreetMap para el panel administrativo
class OsmMapWidget extends StatefulWidget {
  final List<BusLocation>? buses;
  final Function(BusLocation)? onBusTap;

  const OsmMapWidget({
    super.key,
    this.buses,
    this.onBusTap,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  final MapController _mapController = MapController();

  List<BusLocation> get _buses {
    if (widget.buses != null) {
      return widget.buses!;
    }
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    return adminProvider.busLocations;
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(
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
          userAgentPackageName: 'com.transporterural.georu.admin',
          maxZoom: OpenStreetMapConfig.maxZoom,
          maxNativeZoom: OpenStreetMapConfig.maxNativeZoom,
        ),

        // Marcadores de buses
        MarkerLayer(
          markers: _buildBusMarkers(_buses),
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
                  color: Colors.black.withValues(alpha: 0.3),
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

  void _handleMapTap(LatLng position) {
    // Buscar si se hizo clic cerca de un bus
    for (final busLocation in _buses) {
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
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
            Text('Bus ${busLocation.busId}'),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('Ruta', busLocation.routeId ?? 'N/A'),
            _buildDetailRow(
                'Conductor', busLocation.driverId?.toString() ?? 'N/A'),
            _buildDetailRow('Estado', busLocation.status),
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _moveToBusLocation(busLocation);
            },
            icon: const Icon(Icons.center_focus_strong),
            label: const Text('Centrar'),
          ),
        ],
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
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
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
    const distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      LatLng(lat1, lon1),
      LatLng(lat2, lon2),
    );
  }
}
