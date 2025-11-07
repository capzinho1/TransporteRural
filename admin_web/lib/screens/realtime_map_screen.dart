import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/admin_provider.dart';
import '../models/bus.dart';
import '../widgets/osm_map_widget.dart';

class RealtimeMapScreen extends StatefulWidget {
  const RealtimeMapScreen({super.key});

  @override
  State<RealtimeMapScreen> createState() => _RealtimeMapScreenState();
}

class _RealtimeMapScreenState extends State<RealtimeMapScreen> {
  Timer? _refreshTimer;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    // Cargar datos después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    // Refrescar cada 5 segundos para simular tiempo real
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.loadBusLocations();
  }

  List<BusLocation> _filterBuses(List<BusLocation> buses) {
    switch (_selectedFilter) {
      case 'active':
        return buses
            .where((b) => b.status == 'active' || b.status == 'en_ruta')
            .toList();
      case 'inactive':
        return buses.where((b) => b.status == 'inactive').toList();
      case 'maintenance':
        return buses.where((b) => b.status == 'maintenance').toList();
      default:
        return buses;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final filteredBuses = _filterBuses(adminProvider.busLocations);

        return Column(
          children: [
            // Header con filtros
            _buildHeader(
                adminProvider.busLocations.length, filteredBuses.length),

            // Mapa visual
            Expanded(
              child: Row(
                children: [
                  // Mapa
                  Expanded(
                    flex: 2,
                    child: _buildVisualMap(filteredBuses),
                  ),

                  // Panel lateral con lista de buses
                  SizedBox(
                    width: 350,
                    child: _buildBusesList(filteredBuses),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(int total, int filtered) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.map, color: Colors.blue, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Supervisión en Tiempo Real',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Mostrando $filtered de $total buses',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const Spacer(),

          // Filtros
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'all',
                label: Text('Todos'),
                icon: Icon(Icons.all_inclusive, size: 16),
              ),
              ButtonSegment(
                value: 'active',
                label: Text('Activos'),
                icon: Icon(Icons.check_circle, size: 16),
              ),
              ButtonSegment(
                value: 'inactive',
                label: Text('Inactivos'),
                icon: Icon(Icons.cancel, size: 16),
              ),
              ButtonSegment(
                value: 'maintenance',
                label: Text('Mantenimiento'),
                icon: Icon(Icons.build, size: 16),
              ),
            ],
            selected: {_selectedFilter},
            onSelectionChanged: (Set<String> newSelection) {
              setState(() {
                _selectedFilter = newSelection.first;
              });
            },
          ),

          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
    );
  }

  Widget _buildVisualMap(List<BusLocation> buses) {
    if (buses.isEmpty) {
      return Container(
        color: Colors.grey[200],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 100, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No hay buses para mostrar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        // Mapa de OpenStreetMap
        OsmMapWidget(
          buses: buses,
          onBusTap: (bus) => _showBusDetails(context, bus),
        ),

        // Leyenda flotante
        Positioned(
          bottom: 16,
          right: 16,
          child: _buildLegend(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Leyenda',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildLegendItem(Colors.green, 'Activo / En Ruta'),
            _buildLegendItem(Colors.grey, 'Inactivo'),
            _buildLegendItem(Colors.orange, 'Mantenimiento'),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBusesList(List<BusLocation> buses) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Buses (${buses.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: buses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.directions_bus_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No hay buses',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: buses.length,
                    itemBuilder: (context, index) {
                      final bus = buses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(bus.status),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            'Bus ${bus.busId}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Ruta: ${bus.routeId ?? 'N/A'}'),
                              Text(
                                'Estado: ${bus.status}',
                                style: TextStyle(
                                  color: _getStatusColor(bus.status),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => _showBusDetails(context, bus),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showBusDetails(BuildContext context, BusLocation bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getStatusColor(bus.status),
              child: const Icon(Icons.directions_bus, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text('Bus ${bus.busId}'),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow('ID Bus', bus.busId),
            _buildDetailRow('Ruta', bus.routeId ?? 'N/A'),
            _buildDetailRow('Conductor', bus.driverId?.toString() ?? 'N/A'),
            _buildDetailRow('Estado', bus.status),
            _buildDetailRow(
              'Latitud',
              bus.latitude.toStringAsFixed(6),
            ),
            _buildDetailRow(
              'Longitud',
              bus.longitude.toStringAsFixed(6),
            ),
            _buildDetailRow(
              'Última actualización',
              bus.lastUpdate ?? 'N/A',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'en_ruta':
        return Colors.green;
      case 'inactive':
        return Colors.grey;
      case 'maintenance':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
