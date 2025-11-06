import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/bus.dart';

class BusesManagementScreen extends StatefulWidget {
  const BusesManagementScreen({super.key});

  @override
  State<BusesManagementScreen> createState() => _BusesManagementScreenState();
}

class _BusesManagementScreenState extends State<BusesManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadBuses();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.buses.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => adminProvider.loadBuses(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gestión de Buses',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showBusDialog(context, null),
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Bus'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildBusesTable(adminProvider.buses),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.directions_bus_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay buses registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showBusDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Agregar Primer Bus'),
          ),
        ],
      ),
    );
  }

  Widget _buildBusesTable(List<BusLocation> buses) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('ID Bus')),
          DataColumn(label: Text('Ruta')),
          DataColumn(label: Text('Conductor')),
          DataColumn(label: Text('Latitud')),
          DataColumn(label: Text('Longitud')),
          DataColumn(label: Text('Estado')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: buses.map((bus) {
          return DataRow(
            cells: [
              DataCell(Text(bus.busId)),
              DataCell(Text(bus.routeId ?? 'N/A')),
              DataCell(Text(bus.driverId?.toString() ?? 'N/A')),
              DataCell(Text(bus.latitude.toStringAsFixed(4))),
              DataCell(Text(bus.longitude.toStringAsFixed(4))),
              DataCell(_buildStatusChip(bus.status)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showBusDialog(context, bus),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, bus),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'active':
      case 'en_ruta':
        color = Colors.green;
        label = 'Activo';
        break;
      case 'inactive':
        color = Colors.grey;
        label = 'Inactivo';
        break;
      case 'maintenance':
        color = Colors.orange;
        label = 'Mantenimiento';
        break;
      default:
        color = Colors.blue;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  void _showBusDialog(BuildContext context, BusLocation? bus) {
    final busIdController = TextEditingController(text: bus?.busId ?? '');
    final routeIdController = TextEditingController(text: bus?.routeId ?? '');
    final driverIdController =
        TextEditingController(text: bus?.driverId?.toString() ?? '');
    final latitudeController =
        TextEditingController(text: bus?.latitude.toString() ?? '-33.4489');
    final longitudeController =
        TextEditingController(text: bus?.longitude.toString() ?? '-70.6693');
    String selectedStatus = bus?.status ?? 'inactive';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(bus == null ? 'Agregar Bus' : 'Editar Bus'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: busIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID del Bus *',
                    hintText: 'BUS001',
                    prefixIcon: Icon(Icons.directions_bus),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: routeIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID de Ruta *',
                    hintText: 'R001',
                    prefixIcon: Icon(Icons.route),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: driverIdController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'ID del Conductor',
                    hintText: '1',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: latitudeController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Latitud *',
                    hintText: '-33.4489',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: longitudeController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Longitud *',
                    hintText: '-70.6693',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Estado *',
                    prefixIcon: Icon(Icons.info),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Activo')),
                    DropdownMenuItem(
                        value: 'inactive', child: Text('Inactivo')),
                    DropdownMenuItem(
                        value: 'maintenance', child: Text('Mantenimiento')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedStatus = value;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (busIdController.text.isEmpty ||
                  routeIdController.text.isEmpty ||
                  latitudeController.text.isEmpty ||
                  longitudeController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor completa los campos obligatorios'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newBus = BusLocation(
                id: bus?.id,
                busId: busIdController.text,
                routeId: routeIdController.text,
                driverId: driverIdController.text.isEmpty
                    ? null
                    : int.tryParse(driverIdController.text),
                latitude: double.parse(latitudeController.text),
                longitude: double.parse(longitudeController.text),
                status: selectedStatus,
              );

              final adminProvider =
                  Provider.of<AdminProvider>(context, listen: false);
              bool success;

              if (bus == null) {
                success = await adminProvider.createBus(newBus);
              } else {
                success = await adminProvider.updateBus(bus.id!, newBus);
              }

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      bus == null
                          ? 'Bus agregado exitosamente'
                          : 'Bus actualizado exitosamente',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(bus == null ? 'Agregar' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, BusLocation bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar el bus ${bus.busId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final adminProvider =
                  Provider.of<AdminProvider>(context, listen: false);
              final success = await adminProvider.deleteBus(bus.id!);

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bus eliminado exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
