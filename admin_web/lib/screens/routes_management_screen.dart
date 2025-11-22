import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/bus.dart';
import '../widgets/route_dialog.dart';
import '../services/assignment_service.dart';

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

  // Obtener conductor asignado a una ruta (usando el servicio)
  Usuario? _getAssignedDriver(String routeId, AdminProvider provider) {
    return AssignmentService.getDriverAssignedToRoute(
      routeId,
      provider.buses,
      provider.usuarios,
    );
  }

  // Obtener buses asignados a una ruta (puede haber múltiples)
  List<BusLocation> _getAssignedBuses(String routeId, AdminProvider provider) {
    return AssignmentService.getBusesAssignedToRoute(routeId, provider.buses);
  }

  // Obtener el primer bus asignado (para compatibilidad con código existente)
  BusLocation? _getAssignedBus(String routeId, AdminProvider provider) {
    final buses = _getAssignedBuses(routeId, provider);
    return buses.isNotEmpty ? buses.first : null;
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            'Buses',
                            '${_getAssignedBuses(ruta.routeId, adminProvider).length} asignado(s)',
                            assignedBus != null ? Colors.blue : Colors.grey,
                            Icons.directions_bus,
                          ),
                        ),
                      ],
                    ),
                    // Mostrar lista de buses si hay múltiples
                    if (_getAssignedBuses(ruta.routeId, adminProvider).length >
                        0) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: _getAssignedBuses(ruta.routeId, adminProvider)
                            .map((bus) => Chip(
                                  label: Text(
                                    bus.busId,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  backgroundColor: Colors.blue[50],
                                  padding: EdgeInsets.zero,
                                ))
                            .toList(),
                      ),
                    ],
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
                  // Seleccionar conductor (con indicadores visuales)
                  DropdownButtonFormField<int?>(
                    initialValue: selectedDriverId,
                    decoration: const InputDecoration(
                      labelText: 'Conductor',
                      prefixIcon: Icon(Icons.person_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Sin conductor'),
                      ),
                      ...conductores.map((conductor) {
                        final isAssigned = !AssignmentService.isDriverAvailable(
                          conductor.id,
                          adminProvider.buses,
                        );
                        final assignedBus =
                            AssignmentService.getBusAssignedToDriver(
                          conductor.id,
                          adminProvider.buses,
                        );
                        final isAssignedToOtherRoute = assignedBus != null &&
                            assignedBus.routeId != null &&
                            assignedBus.routeId != ruta.routeId;

                        return DropdownMenuItem<int?>(
                          value: conductor.id,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    conductor.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isAssignedToOtherRoute
                                          ? Colors.orange[700]
                                          : Colors.black87,
                                    ),
                                  ),
                                  if (isAssignedToOtherRoute)
                                    Text(
                                      'Ya asignado',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              if (isAssigned)
                                Icon(
                                  Icons.warning_rounded,
                                  size: 16,
                                  color: isAssignedToOtherRoute
                                      ? Colors.orange
                                      : Colors.grey,
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedDriverId = value;
                        // Si el conductor ya tiene un bus, sugerir ese bus
                        if (value != null) {
                          final assignedBus =
                              AssignmentService.getBusAssignedToDriver(
                            value,
                            adminProvider.buses,
                          );
                          if (assignedBus != null) {
                            selectedBusId = assignedBus.busId;
                          }
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Seleccionar bus (con indicadores visuales)
                  DropdownButtonFormField<String?>(
                    initialValue: selectedBusId,
                    decoration: const InputDecoration(
                      labelText: 'Bus',
                      prefixIcon: Icon(Icons.directions_bus_rounded),
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Sin bus'),
                      ),
                      ...buses.map((bus) {
                        final isAssignedToOtherRoute = bus.routeId != null &&
                            bus.routeId!.isNotEmpty &&
                            bus.routeId != ruta.routeId;
                        final isAvailable =
                            AssignmentService.isBusAvailable(bus);

                        return DropdownMenuItem<String?>(
                          value: bus.busId,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    bus.busId,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isAssignedToOtherRoute
                                          ? Colors.orange[700]
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    isAssignedToOtherRoute
                                        ? 'Ya asignado'
                                        : isAvailable
                                            ? 'Disponible'
                                            : bus.status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isAssignedToOtherRoute
                                          ? Colors.orange[700]
                                          : Colors.grey[600],
                                      fontStyle: isAssignedToOtherRoute
                                          ? FontStyle.italic
                                          : FontStyle.normal,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              if (isAssignedToOtherRoute)
                                Icon(
                                  Icons.warning_rounded,
                                  size: 16,
                                  color: Colors.orange,
                                )
                              else if (isAvailable)
                                Icon(
                                  Icons.check_circle_outline_rounded,
                                  size: 16,
                                  color: Colors.green,
                                ),
                            ],
                          ),
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
      // Recargar datos antes de validar para asegurar que están actualizados
      await adminProvider.loadBuses();

      // Obtener el bus seleccionado (con datos actualizados)
      BusLocation? bus;
      if (busId != null) {
        try {
          bus = adminProvider.buses.firstWhere((b) => b.busId == busId);
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El bus seleccionado no existe'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Obtener company_id del usuario actual
      final currentCompanyId = adminProvider.currentUser?.companyId;

      // Debug: Verificar datos antes de validar
      print('🔍 [DEBUG] Validando asignación:');
      print(
          '  - Bus: ${bus?.busId} (driverId actual: ${bus?.driverId}, routeId: ${bus?.routeId})');
      print('  - Nuevo driverId: $driverId');
      print('  - Ruta destino: ${ruta.routeId}');

      // Validar la asignación completa usando el servicio
      final validation = AssignmentService.validateFullAssignment(
        bus: bus,
        driverId: driverId,
        route: ruta,
        allBuses: adminProvider.buses,
        allUsers: adminProvider.usuarios,
        currentCompanyId: currentCompanyId,
      );

      // Debug: Verificar resultado de validación
      print('🔍 [DEBUG] Resultado de validación:');
      print('  - isValid: ${validation.isValid}');
      print('  - warnings: ${validation.warnings.length}');
      validation.warnings.forEach((w) => print('    - $w'));

      // Si hay errores de validación, mostrar y salir
      if (!validation.isValid) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(validation.errorMessage ?? 'Error de validación'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Si hay advertencias, mostrar diálogo de confirmación
      print(
          '🔍 [DEBUG] Verificando advertencias: ${validation.warnings.length} advertencias encontradas');
      if (validation.warnings.isNotEmpty) {
        print(
            '⚠️ [DEBUG] Mostrando diálogo de advertencias con ${validation.warnings.length} advertencias');
        print('⚠️ [DEBUG] Advertencias:');
        validation.warnings.forEach((w) => print('    - $w'));

        if (!context.mounted) return;
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_rounded, color: Colors.orange[700]),
                const SizedBox(width: 12),
                const Text('Advertencias'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Se realizarán los siguientes cambios:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...validation.warnings.map((warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Expanded(child: Text(warning)),
                        ],
                      ),
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continuar'),
              ),
            ],
          ),
        );

        if (shouldContinue != true) {
          return; // Usuario canceló
        }
      }

      // Lógica de asignación mejorada
      BusLocation? targetBus;

      // Caso 1: Hay bus seleccionado explícitamente
      if (bus != null && bus.id != null) {
        targetBus = bus;

        // Si el bus ya está asignado a otra ruta, desasignarlo primero
        if (bus.routeId != null && bus.routeId != ruta.routeId) {
          // Desasignar el bus de su ruta anterior será manejado por la actualización
        }

        // Si el conductor ya tiene un bus diferente, desasignarlo primero
        if (driverId != null) {
          final existingDriverBus = AssignmentService.getBusAssignedToDriver(
            driverId,
            adminProvider.buses,
          );
          if (existingDriverBus != null &&
              existingDriverBus.id != bus.id &&
              existingDriverBus.id != null) {
            // Desasignar el conductor de su bus anterior
            await AssignmentService.desassignDriverFromBus(
              driverId,
              adminProvider.buses,
              adminProvider.apiService,
            );
          }
        }

        // Preparar actualización del bus
        final updateData = AssignmentService.prepareAssignmentUpdate(
          bus: bus,
          driverId: driverId,
          routeId: ruta.routeId, // Siempre asignar la ruta si hay bus
        );

        // Sincronizar nombreRuta con el nombre de la ruta
        updateData['nombre_ruta'] = ruta.name;

        await adminProvider.apiService
            .updateBusLocationDirect(bus.id!, updateData);
      }
      // Caso 2: Solo hay conductor seleccionado (sin bus explícito)
      else if (driverId != null) {
        // Buscar si el conductor ya tiene un bus asignado
        final existingDriverBus = AssignmentService.getBusAssignedToDriver(
          driverId,
          adminProvider.buses,
        );

        if (existingDriverBus != null && existingDriverBus.id != null) {
          // Actualizar el bus existente del conductor
          targetBus = existingDriverBus;
          final updateData = AssignmentService.prepareAssignmentUpdate(
            bus: existingDriverBus,
            driverId: driverId,
            routeId: ruta.routeId,
          );

          // Sincronizar nombreRuta con el nombre de la ruta
          updateData['nombre_ruta'] = ruta.name;

          await adminProvider.apiService.updateBusLocationDirect(
            existingDriverBus.id!,
            updateData,
          );
        } else {
          // El conductor no tiene bus - buscar uno disponible
          final availableBuses = adminProvider.buses
              .where(
                (b) => AssignmentService.isBusAvailable(b),
              )
              .toList();

          if (availableBuses.isEmpty) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'No hay buses disponibles. Por favor crea un bus primero o selecciona uno existente.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 4),
              ),
            );
            return;
          }

          // Usar el primer bus disponible
          targetBus = availableBuses.first;
          final updateData = AssignmentService.prepareAssignmentUpdate(
            bus: targetBus,
            driverId: driverId,
            routeId: ruta.routeId,
          );

          // Sincronizar nombreRuta con el nombre de la ruta
          updateData['nombre_ruta'] = ruta.name;

          await adminProvider.apiService.updateBusLocationDirect(
            targetBus.id!,
            updateData,
          );
        }
      }
      // Caso 3: Solo desasignar (sin bus ni conductor)
      else if (busId == null && driverId == null) {
        print('🔍 [DEBUG] Caso 3: Desasignando todo');

        // Si hay un bus actualmente asignado a esta ruta, desasignarlo completamente
        final currentBus = AssignmentService.getBusAssignedToRoute(
          ruta.routeId,
          adminProvider.buses,
        );

        if (currentBus != null && currentBus.id != null) {
          targetBus = currentBus;
          print(
              '🔍 [DEBUG] Desasignando bus ${currentBus.busId} (id: ${currentBus.id})');
          print('  - Conductor actual: ${currentBus.driverId}');
          print('  - Ruta actual: ${currentBus.routeId}');
          print('  - Estado actual: ${currentBus.status}');

          // Desasignar explícitamente: pasar null para route_id y driver_id
          final updateData = {
            'route_id': null,
            'driver_id': null,
            'nombre_ruta': null, // Limpiar nombreRuta al desasignar
            'status': 'inactive',
          };

          print('🔍 [DEBUG] updateData para desasignación: $updateData');

          try {
            await adminProvider.apiService.updateBusLocationDirect(
              currentBus.id!,
              updateData,
            );
            print('✅ [DEBUG] Bus desasignado exitosamente en backend');
          } catch (e) {
            print('❌ [DEBUG] Error al desasignar bus: $e');
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al desasignar: $e'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } else {
          print(
              '⚠️ [DEBUG] No se encontró bus asignado a la ruta ${ruta.routeId}');
        }
      }

      // Recargar TODOS los datos para asegurar sincronización
      await Future.wait([
        adminProvider.loadBuses(),
        adminProvider.loadRutas(),
        adminProvider.loadUsuarios(),
      ]);

      print('✅ [DEBUG] Datos recargados después de desasignación/asignación');

      if (!context.mounted) return;
      Navigator.pop(context);

      // Determinar mensaje apropiado según la acción
      final isUnassignment = busId == null && driverId == null;
      final message = isUnassignment
          ? 'Desasignación completada exitosamente'
          : 'Asignación guardada exitosamente';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar asignación: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, Ruta ruta) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);

    // Validar asignaciones antes de eliminar
    final busesAsignados = AssignmentService.getBusesAssignedToRoute(
      ruta.routeId,
      adminProvider.buses,
    );

    if (busesAsignados.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('No se puede eliminar'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'La ruta "${ruta.name}" tiene ${busesAsignados.length} bus(es) asignado(s):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...busesAsignados.map((bus) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Text('• ${bus.busId}'),
                  )),
              const SizedBox(height: 12),
              const Text(
                'Por favor desasigna los buses antes de eliminar la ruta.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    // Si no hay asignaciones, proceder con la eliminación
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar la ruta "${ruta.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    // Intentar eliminar (el backend también validará)
    try {
      final success = await adminProvider.deleteRuta(ruta.routeId);

      if (!context.mounted) return;

      if (success) {
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruta eliminada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              adminProvider.error ?? 'Error al eliminar la ruta',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
