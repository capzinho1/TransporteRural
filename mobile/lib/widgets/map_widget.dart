import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/app_provider.dart';
import '../models/bus.dart';
import '../config/google_maps_config.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        // Verificar si Google Maps está disponible
        try {
          return GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _addBusMarkers(appProvider.busLocations);
            },
            initialCameraPosition: CameraPosition(
              target: LatLng(GoogleMapsConfig.defaultLatitude,
                  GoogleMapsConfig.defaultLongitude),
              zoom: GoogleMapsConfig.defaultZoom,
            ),
            markers: _markers,
            onTap: (LatLng position) {
              _handleMapClick(position, appProvider.busLocations);
            },
            mapType: MapType.normal,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
            compassEnabled: true,
          );
        } catch (e) {
          // Fallback si Google Maps no está disponible
          return _buildMapErrorWidget(e.toString());
        }
      },
    );
  }

  Widget _buildMapErrorWidget(String error) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 64,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'Error al cargar el mapa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Error: $error',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Recargar el widget
                setState(() {});
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _addBusMarkers(List<BusLocation> busLocations) {
    Set<Marker> markers = {};

    for (final busLocation in busLocations) {
      markers.add(
        Marker(
          markerId: MarkerId('bus_${busLocation.busId}'),
          position: LatLng(busLocation.latitude, busLocation.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: 'Bus ${busLocation.busId}',
            snippet:
                'Ruta: ${busLocation.routeId} - Estado: ${busLocation.status}',
          ),
          onTap: () => _showBusDetails(busLocation),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _handleMapClick(LatLng position, List<BusLocation> busLocations) {
    // Buscar si se hizo clic cerca de un bus
    for (final busLocation in busLocations) {
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        busLocation.latitude,
        busLocation.longitude,
      );
      if (distance < 0.001) {
        // 100 metros
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
                const Icon(Icons.directions_bus, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Bus ${busLocation.busId}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Ruta: ${busLocation.routeId}'),
            Text('Conductor: ${busLocation.driverId}'),
            Text('Estado: ${busLocation.status}'),
            Text('Última actualización: ${busLocation.lastUpdate}'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _moveToBusLocation(busLocation);
                },
                child: const Text('Ver en Mapa'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _moveToBusLocation(BusLocation busLocation) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(
        LatLng(busLocation.latitude, busLocation.longitude),
      ),
    );
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371000;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = (dLat / 2) * (dLat / 2) +
        (dLon / 2) * (dLon / 2) * cos(lat1 * pi / 180) * cos(lat2 * pi / 180);
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}
