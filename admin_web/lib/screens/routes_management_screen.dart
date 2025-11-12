import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/bus.dart';
import '../widgets/route_dialog.dart';

class RoutesManagementScreen extends StatefulWidget {
  const RoutesManagementScreen({super.key});

  @override
  State<RoutesManagementScreen> createState() => _RoutesManagementScreenState();
}

class _RoutesManagementScreenState extends State<RoutesManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await Future.wait([
      adminProvider.loadRutas(),
      adminProvider.loadUsuarios(),
      adminProvider.loadBuses(),
    ]);
  }

  // Obtener conductor asignado a una ruta
  Usuario? _getAssignedDriver(String routeId, AdminProvider provider) {
    final bus = provider.buses.firstWhere(
      (b) => b.routeId == routeId && b.driverId != null,
      orElse: () => BusLocation(
        busId: '',
        latitude: 0,
        longitude: 0,
        status: 'inactive',
      ),
    );

    if (bus.driverId != null) {
      try {
        return provider.usuarios.firstWhere(
          (u) => u.id == bus.driverId && u.role == 'driver',
        );
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Obtener bus asignado a una ruta
  BusLocation? _getAssignedBus(String routeId, AdminProvider provider) {
    try {
      return provider.buses.firstWhere(
        (b) => b.routeId == routeId,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestión de Rutas',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${adminProvider.rutas.length} rutas registradas',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showManualRouteDialog(context, null),
                      icon: const Icon(Icons.add),
                      label: const Text('Nueva Ruta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Lista de rutas
                if (adminProvider.rutas.isEmpty)
                  _buildEmptyState()
                else
                  _buildRutasList(adminProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.route_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay rutas registradas',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showManualRouteDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Crear Nueva Ruta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRutasList(AdminProvider adminProvider) {
    return Column(
      children: adminProvider.rutas.map((ruta) {
        final assignedDriver = _getAssignedDriver(ruta.routeId, adminProvider);
        final assignedBus = _getAssignedBus(ruta.routeId, adminProvider);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header de la ruta
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                ruta.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  ruta.routeId,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.purple[100],
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.schedule,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                ruta.schedule,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 16),
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                '${ruta.stops.length} paradas',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              if (ruta.estimatedDuration != null) ...[
                                const SizedBox(width: 16),
                                const Icon(Icons.timer,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${ruta.estimatedDuration} min',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                              if (ruta.frequency != null) ...[
                                const SizedBox(width: 16),
                                const Icon(Icons.repeat,
                                    size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  'Cada ${ruta.frequency} min',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Estado activo/inactivo
                    if (ruta.active != null)
                      Chip(
                        label: Text(ruta.active! ? 'Activa' : 'Inactiva'),
                        backgroundColor:
                            ruta.active! ? Colors.green[100] : Colors.grey[200],
                        labelStyle: TextStyle(
                          color: ruta.active!
                              ? Colors.green[800]
                              : Colors.grey[800],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),

                // Asignaciones
                Row(
                  children: [
                    Expanded(
                      child: _buildAssignmentChip(
                        'Conductor',
                        assignedDriver?.name ?? 'Sin asignar',
                        assignedDriver != null ? Colors.green : Colors.grey,
                        Icons.person,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAssignmentChip(
                        'Bus',
                        assignedBus?.busId ?? 'Sin asignar',
                        assignedBus != null ? Colors.blue : Colors.grey,
                        Icons.directions_bus,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Acciones
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showRouteDetails(context, ruta),
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('Detalles'),
                    ),
                    TextButton.icon(
                      onPressed: () =>
                          _showAssignmentDialog(context, ruta, adminProvider),
                      icon: const Icon(Icons.assignment, size: 18),
                      label: const Text('Asignar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showManualRouteDialog(context, ruta),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Editar'),
                    ),
                    TextButton.icon(
                      onPressed: () => _confirmDelete(context, ruta),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Eliminar'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAssignmentChip(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showRouteDetails(BuildContext context, Ruta ruta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ruta.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID Ruta', ruta.routeId),
              _buildDetailRow('Horario', ruta.schedule),
              _buildDetailRow(
                  'Estado', ruta.active == true ? 'Activa' : 'Inactiva'),
              _buildDetailRow('Paradas', '${ruta.stops.length}'),
              const SizedBox(height: 16),
              if (ruta.stops.isNotEmpty) ...[
                const Text(
                  'Paradas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...ruta.stops.asMap().entries.map((entry) {
                  final index = entry.key;
                  final parada = entry.value;
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 12,
                      child: Text('${index + 1}'),
                    ),
                    title: Text(parada.name),
                    subtitle: Text(
                      '${parada.latitude.toStringAsFixed(4)}, ${parada.longitude.toStringAsFixed(4)}',
                    ),
                  );
                }),
              ],
            ],
          ),
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
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
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

  void _showManualRouteDialog(BuildContext context, Ruta? ruta) {
    showDialog(
      context: context,
      builder: (context) => RouteDialog(
        ruta: ruta,
        onCreateRoute: (newRuta) {
          _createRoute(newRuta, ruta != null);
        },
      ),
    );
  }

  Future<void> _createRoute(Ruta ruta, bool isUpdate) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    bool success;

    if (isUpdate) {
      success = await adminProvider.updateRuta(ruta.routeId, ruta);

      if (success && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ruta actualizada exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adminProvider.error ?? 'Error al actualizar la ruta',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Crear la ruta
    print('🔄 Creando ruta: ${ruta.routeId} - ${ruta.name}');
    success = await adminProvider.createRuta(ruta);
    print('✅ Resultado creación: $success');

    if (success && mounted) {
      // Recargar rutas
      await adminProvider.loadRutas();

      // Esperar un momento para que el provider se actualice
      await Future.delayed(const Duration(milliseconds: 100));

      // Forzar actualización del estado
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ruta "${ruta.name}" creada exitosamente. Total: ${adminProvider.rutas.length}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            adminProvider.error ?? 'Error al crear la ruta',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }


  void _showAssignmentDialog(
      BuildContext context, Ruta ruta, AdminProvider adminProvider) {
    final conductores =
        adminProvider.usuarios.where((u) => u.role == 'driver').toList();
    final buses = adminProvider.buses;

    final assignedDriver = _getAssignedDriver(ruta.routeId, adminProvider);
    final assignedBus = _getAssignedBus(ruta.routeId, adminProvider);

    int? selectedDriverId = assignedDriver?.id;
    String? selectedBusId = assignedBus?.busId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Asignar Recursos - ${ruta.name}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Seleccionar conductor
                  DropdownButtonFormField<int?>(
                    value: selectedDriverId,
                    decoration: const InputDecoration(
                      labelText: 'Conductor',
                      prefixIcon: Icon(Icons.person),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin conductor'),
                      ),
                      ...conductores.map((conductor) {
                        return DropdownMenuItem<int?>(
                          value: conductor.id,
                          child: Text('${conductor.name} (${conductor.email})'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedDriverId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Seleccionar bus
                  DropdownButtonFormField<String?>(
                    value: selectedBusId,
                    decoration: const InputDecoration(
                      labelText: 'Bus',
                      prefixIcon: Icon(Icons.directions_bus),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sin bus'),
                      ),
                      ...buses.map((bus) {
                        return DropdownMenuItem<String?>(
                          value: bus.busId,
                          child: Text('${bus.busId} - ${bus.status}'),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedBusId = value;
                      });
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
                await _saveAssignment(
                  context,
                  ruta,
                  selectedDriverId,
                  selectedBusId,
                  adminProvider,
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAssignment(
    BuildContext context,
    Ruta ruta,
    int? driverId,
    String? busId,
    AdminProvider adminProvider,
  ) async {
    try {
      // Buscar el bus seleccionado
      BusLocation? bus;
      if (busId != null) {
        try {
          bus = adminProvider.buses.firstWhere((b) => b.busId == busId);
        } catch (e) {
          // Bus no encontrado
        }
      }

      // Lógica de asignación:
      // 1. Si hay bus seleccionado, actualizarlo con conductor y ruta
      // 2. Si solo hay conductor, asignarlo al bus existente de ese conductor o crear nuevo bus
      // 3. Si se desasignan ambos, limpiar el bus

      if (bus != null && bus.id != null) {
        // Caso 1: Hay bus seleccionado
        final updatedBus = bus.copyWith(
          routeId: driverId != null
              ? ruta.routeId
              : (busId != null ? null : bus.routeId),
          driverId: driverId,
          status: driverId != null ? 'inactive' : bus.status,
        );
        await adminProvider.apiService.updateBusLocation(bus.id!, updatedBus);
      } else if (driverId != null) {
        // Caso 2: Solo hay conductor seleccionado (sin bus)
        // Buscar si el conductor ya tiene un bus asignado
        BusLocation? existingBus;
        try {
          existingBus = adminProvider.buses.firstWhere(
            (b) => b.driverId == driverId,
          );
        } catch (e) {
          // El conductor no tiene bus asignado
        }

        if (existingBus != null && existingBus.id != null) {
          // Actualizar el bus existente del conductor
          final updatedBus = existingBus.copyWith(
            routeId: ruta.routeId,
            driverId: driverId,
          );
          await adminProvider.apiService
              .updateBusLocation(existingBus.id!, updatedBus);
        } else {
          // El conductor no tiene bus - buscar uno disponible o informar al usuario
          BusLocation? availableBus;
          try {
            availableBus = adminProvider.buses.firstWhere(
              (b) =>
                  (b.routeId == null || b.routeId!.isEmpty) &&
                  b.driverId == null,
            );
          } catch (e) {
            // No hay buses disponibles
          }

          if (availableBus != null && availableBus.id != null) {
            // Asignar bus disponible
            final updatedBus = availableBus.copyWith(
              routeId: ruta.routeId,
              driverId: driverId,
            );
            await adminProvider.apiService
                .updateBusLocation(availableBus.id!, updatedBus);
          } else {
            // No hay buses disponibles - informar al usuario
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'No hay buses disponibles. Por favor crea un bus primero.'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }
      } else if (driverId == null && bus != null && bus.id != null) {
        // Caso 3: Desasignar conductor (pero mantener el bus si estaba asignado a esta ruta)
        final updatedBus = bus.copyWith(
          routeId: bus.routeId == ruta.routeId ? null : bus.routeId,
          driverId: null,
        );
        await adminProvider.apiService.updateBusLocation(bus.id!, updatedBus);
      }

      // Recargar datos
      await _loadData();

      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Asignación guardada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar asignación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, Ruta ruta) {
    final scaffoldContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar la ruta "${ruta.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final adminProvider =
                  Provider.of<AdminProvider>(dialogContext, listen: false);
              final success = await adminProvider.deleteRuta(ruta.routeId);

              if (!success) return;
              if (!dialogContext.mounted) return;

              Navigator.pop(dialogContext);
              await _loadData();

              if (!scaffoldContext.mounted) return;
              ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                const SnackBar(
                  content: Text('Ruta eliminada exitosamente'),
                  backgroundColor: Colors.green,
                ),
              );
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
