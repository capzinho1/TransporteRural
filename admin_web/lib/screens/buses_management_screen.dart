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
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
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
    final patenteController = TextEditingController(text: bus?.busId ?? '');

    // Variables de estado que se mantendrán durante la vida del diálogo
    String selectedStatus = bus?.status ?? 'inactive';
    int? selectedDriverId = bus?.driverId;

    // Cargar usuarios (conductores) si no están cargados
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    if (adminProvider.usuarios.isEmpty) {
      adminProvider.loadUsuarios();
    }

    showDialog(
      context: context,
      builder: (context) => Consumer<AdminProvider>(
        builder: (context, provider, child) {
          // Filtrar solo conductores
          final conductores =
              provider.usuarios.where((u) => u.role == 'driver').toList();

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              title: Text(bus == null ? 'Agregar Bus' : 'Editar Bus'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: patenteController,
                        decoration: const InputDecoration(
                          labelText: 'Patente *',
                          hintText: 'ABC1234',
                          prefixIcon: Icon(Icons.directions_bus),
                          helperText: 'Ingresa la patente del bus',
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        value: selectedDriverId,
                        decoration: const InputDecoration(
                          labelText: 'Conductor',
                          prefixIcon: Icon(Icons.person),
                          helperText: 'Selecciona un conductor (opcional)',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Sin conductor asignado'),
                          ),
                          ...conductores.map((conductor) {
                            return DropdownMenuItem<int?>(
                              value: conductor.id,
                              child: Text(
                                  '${conductor.name} (${conductor.email})'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          selectedDriverId = value;
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Estado *',
                          prefixIcon: Icon(Icons.info),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'active', child: Text('Activo')),
                          DropdownMenuItem(
                              value: 'inactive', child: Text('Inactivo')),
                          DropdownMenuItem(
                              value: 'maintenance',
                              child: Text('Mantenimiento')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            selectedStatus = value;
                            setState(() {});
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      if (conductores.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'No hay conductores registrados. Agrega conductores en "Gestión de Conductores".',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        const Text(
                          'Nota: La ruta y ubicación se asignarán automáticamente cuando el bus esté en uso.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
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
                    // Validar que la patente no esté vacía
                    if (patenteController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingresa la patente del bus'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Crear el bus con valores por defecto
                    // route_id será null (se asignará después)
                    // latitude y longitude serán 0.0 (se actualizarán cuando el bus esté en ruta)
                    final newBus = BusLocation(
                      id: bus?.id,
                      busId: patenteController.text.trim().toUpperCase(),
                      routeId: bus
                          ?.routeId, // Mantener route_id al editar, null al crear
                      driverId:
                          selectedDriverId, // ID del conductor seleccionado (puede ser null)
                      latitude: bus?.latitude ??
                          0.0, // Mantener lat al editar, 0.0 al crear
                      longitude: bus?.longitude ??
                          0.0, // Mantener lng al editar, 0.0 al crear
                      status: selectedStatus,
                      companyId:
                          bus?.companyId, // Mantener company_id si existe
                    );

                    final provider =
                        Provider.of<AdminProvider>(context, listen: false);
                    bool success;

                    if (bus == null) {
                      success = await provider.createBus(newBus);
                    } else {
                      success = await provider.updateBus(bus.id!, newBus);
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
                    } else if (context.mounted) {
                      // Mostrar error si falla
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            provider.error ??
                                'Error al ${bus == null ? 'agregar' : 'actualizar'} el bus',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(bus == null ? 'Agregar' : 'Actualizar'),
                ),
              ],
            ),
          );
        },
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
