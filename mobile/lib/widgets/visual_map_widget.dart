import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/bus.dart';

class VisualMapWidget extends StatefulWidget {
  const VisualMapWidget({super.key});

  @override
  State<VisualMapWidget> createState() => _VisualMapWidgetState();
}

class _VisualMapWidgetState extends State<VisualMapWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              // Header
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
                      'Mapa Visual de Buses',
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

              // Mapa visual
              Expanded(
                child: appProvider.busLocations.isEmpty
                    ? _buildEmptyState()
                    : _buildVisualMap(appProvider.busLocations),
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

  Widget _buildVisualMap(List<BusLocation> buses) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Leyenda
          _buildLegend(),
          const SizedBox(height: 16),

          // Mapa visual
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Stack(
                children: [
                  // Fondo del mapa
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.map_outlined,
                          size: 48,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),

                  // Marcadores de buses
                  ...buses.map((bus) => _buildBusMarker(bus)).toList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lista de buses
          _buildBusList(buses),
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(Colors.green, 'En Ruta'),
          _buildLegendItem(Colors.blue, 'Finalizado'),
          _buildLegendItem(Colors.grey, 'Inactivo'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildBusMarker(BusLocation bus) {
    final color = _getStatusColor(bus.status);
    final position = _calculatePosition(bus);

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: GestureDetector(
        onTap: () => _showBusDetails(bus),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              bus.busId.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Offset _calculatePosition(BusLocation bus) {
    // Simular posiciones en el mapa basadas en coordenadas
    final lat = bus.latitude;
    final lng = bus.longitude;

    // Convertir coordenadas a posición en el widget
    final x = ((lng + 70.7) / 0.2) * 200; // Ajustar según tu área
    final y = ((lat + 33.5) / 0.2) * 200; // Ajustar según tu área

    return Offset(x.clamp(12.0, 200.0), y.clamp(12.0, 200.0));
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

  void _showBusDetails(BusLocation bus) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus, color: _getStatusColor(bus.status)),
                const SizedBox(width: 8),
                Text(
                  'Bus ${bus.busId}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDetailRow('Ruta', '${bus.routeId}'),
            _buildDetailRow('Conductor', '${bus.driverId}'),
            _buildDetailRow('Estado', bus.status),
            _buildDetailRow('Latitud', bus.latitude.toStringAsFixed(6)),
            _buildDetailRow('Longitud', bus.longitude.toStringAsFixed(6)),
            _buildDetailRow('Última actualización', bus.lastUpdate),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
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
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildBusList(List<BusLocation> buses) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: buses.length,
        itemBuilder: (context, index) {
          final bus = buses[index];
          return Container(
            width: 200,
            margin: const EdgeInsets.only(right: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _getStatusColor(bus.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Bus ${bus.busId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ruta: ${bus.routeId}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Estado: ${bus.status}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Lat: ${bus.latitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                    Text(
                      'Lng: ${bus.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

