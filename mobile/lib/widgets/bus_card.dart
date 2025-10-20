import 'package:flutter/material.dart';
import '../models/bus.dart';

class BusCard extends StatelessWidget {
  final BusLocation busLocation;

  const BusCard({super.key, required this.busLocation});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con patente y estado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getEstadoColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _getEstadoColor()),
                      ),
                      child: Text(
                        'Bus ${busLocation.busId}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getEstadoColor(),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.directions_bus,
                      color: _getEstadoColor(),
                      size: 20,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getEstadoColor(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    busLocation.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Información del bus
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus ID: ${busLocation.busId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ruta: ${busLocation.routeId}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Conductor: ${busLocation.driverId}',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      busLocation.lastUpdate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Ubicación
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.red[400], size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Lat: ${busLocation.latitude.toStringAsFixed(4)}, '
                    'Lng: ${busLocation.longitude.toStringAsFixed(4)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showBusDetails(context);
                    },
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Detalles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D32),
                      side: const BorderSide(color: Color(0xFF2E7D32)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showOnMap(context);
                    },
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text('Ver en Mapa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getEstadoColor() {
    switch (busLocation.status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'maintenance':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showBusDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.directions_bus, color: _getEstadoColor()),
            const SizedBox(width: 8),
            Text('Bus ${busLocation.busId}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Bus ID', '${busLocation.busId}'),
            _buildDetailRow('Ruta', 'Ruta #${busLocation.routeId}'),
            _buildDetailRow('Conductor', '${busLocation.driverId}'),
            _buildDetailRow('Estado', busLocation.status),
            _buildDetailRow(
              'Ubicación',
              'Lat: ${busLocation.latitude.toStringAsFixed(6)}\n'
                  'Lng: ${busLocation.longitude.toStringAsFixed(6)}',
            ),
            _buildDetailRow('Última actualización', busLocation.lastUpdate),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showOnMap(BuildContext context) {
    // TODO: Implementar navegación al mapa con el bus centrado
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mostrando Bus ${busLocation.busId} en el mapa'),
        action: SnackBarAction(
          label: 'Ver',
          onPressed: () {
            // Navegar al mapa
          },
        ),
      ),
    );
  }
}
