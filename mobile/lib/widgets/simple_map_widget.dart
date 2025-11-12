import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/bus.dart';

class SimpleMapWidget extends StatelessWidget {
  const SimpleMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Header del mapa
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.map, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Mapa de Buses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${appProvider.busLocations.length} buses',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de buses
              Expanded(
                child: appProvider.busLocations.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: appProvider.busLocations.length,
                        itemBuilder: (context, index) {
                          final bus = appProvider.busLocations[index];
                          return _buildBusItem(bus);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No hay buses disponibles',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusItem(BusLocation bus) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(bus.status),
          child: Text(
            bus.busId.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text('Bus ${bus.busId}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ruta: ${bus.routeId}'),
            Text('Conductor: ${bus.driverId}'),
            Text('Estado: ${bus.status}'),
            Text(
              'Lat: ${bus.latitude.toStringAsFixed(4)}, Lng: ${bus.longitude.toStringAsFixed(4)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Icon(
          Icons.location_on,
          color: _getStatusColor(bus.status),
        ),
        onTap: () => _showBusDetails(bus),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en_ruta':
        return Colors.green;
      case 'finalizado':
        return Colors.blue;
      case 'inactive':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  void _showBusDetails(BusLocation bus) {}
}
