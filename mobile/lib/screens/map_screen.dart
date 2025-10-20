import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:math';
import '../providers/app_provider.dart';
import '../models/bus.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Obtener ubicación actual
    await appProvider.getCurrentLocation();
    if (appProvider.currentPosition != null) {
      setState(() {
        _currentLocation = LatLng(
          appProvider.currentPosition!.latitude,
          appProvider.currentPosition!.longitude,
        );
      });
    }

    // Cargar ubicaciones de buses y crear marcadores
    await appProvider.loadBusLocations();
    _createBusMarkers();
  }

  void _createBusMarkers() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    Set<Marker> markers = {};

    // Marcador de ubicación actual
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Mi Ubicación',
            snippet: 'Ubicación actual',
          ),
        ),
      );
    }

    // Marcadores de buses
    for (final busLocation in appProvider.busLocations) {
      markers.add(
        Marker(
          markerId: MarkerId('bus_${busLocation.busId}'),
          position: LatLng(busLocation.latitude, busLocation.longitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Buses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_currentLocation != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLng(_currentLocation!),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final appProvider = Provider.of<AppProvider>(
                context,
                listen: false,
              );
              await appProvider.loadBusLocations();
              _createBusMarkers();
            },
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _createBusMarkers();
            },
            initialCameraPosition: CameraPosition(
              target: _currentLocation ??
                  const LatLng(-33.4489, -70.6693), // Santiago, Chile
              zoom: 12.0,
            ),
            markers: _markers,
            onTap: (LatLng position) {
              _handleMapClick(position, appProvider.busLocations);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_currentLocation != null) {
            _mapController?.animateCamera(
              CameraUpdate.newLatLng(_currentLocation!),
            );
          }
        },
        child: const Icon(Icons.my_location),
      ),
    );
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

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a = (dLat / 2) * (dLat / 2) +
        (dLon / 2) *
            (dLon / 2) *
            cos(lat1 * 3.14159 / 180) *
            cos(lat2 * 3.14159 / 180);
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159 / 180);
  }
}
