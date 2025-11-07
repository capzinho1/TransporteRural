import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/bus.dart';

class RoutesDriversScreen extends StatefulWidget {
  const RoutesDriversScreen({super.key});

  @override
  State<RoutesDriversScreen> createState() => _RoutesDriversScreenState();
}

class _RoutesDriversScreenState extends State<RoutesDriversScreen> {
  // Mapa de asignaciones: routeId -> driverId
  Map<String, int> _assignments = {};
  // Flag para evitar bucles infinitos en la limpieza
  bool _isCleaning = false;

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

    // Cargar asignaciones existentes desde los buses
    // Esto verificará que los conductores existan antes de asignar
    _loadAssignmentsFromBuses(adminProvider);
  }

  void _loadAssignmentsFromBuses(AdminProvider adminProvider,
      {bool skipCleaning = false}) {
    if (!mounted) return;

    // Evitar bucles infinitos: si ya estamos limpiando, no volver a limpiar
    if (_isCleaning && !skipCleaning) return;

    try {
      final assignments = <String, int>{};
      final routeIdsSeen = <String>{};
      final busesToClean = <BusLocation>[];

      // Recorrer todos los buses y extraer las asignaciones route_id -> driver_id
      // IMPORTANTE: Verificar que tanto el conductor como la ruta existan antes de asignar
      // Esto previene autoasignaciones cuando se elimina un conductor o una ruta
      // IMPORTANTE: Solo mostrar asignaciones de buses que tienen status 'inactive' o 'en_ruta'
      // Buses con status 'active' sin asignación manual NO deben mostrarse como asignados
      // Primero, agrupar buses por routeId para detectar duplicados eficientemente
      final busesByRoute = <String, List<BusLocation>>{};

      for (final bus in adminProvider.buses) {
        // Solo considerar buses con ruta y conductor asignados
        // Y que tengan un status válido (no 'active' sin asignación manual)
        if (bus.routeId != null &&
            bus.routeId!.isNotEmpty &&
            bus.driverId != null) {
          busesByRoute.putIfAbsent(bus.routeId!, () => []).add(bus);
        }
      }

      // Procesar cada grupo de buses por ruta
      for (final entry in busesByRoute.entries) {
        final routeId = entry.key;
        final busesWithThisRoute = entry.value;

        // Verificar que la ruta existe
        final routeExists = adminProvider.rutas.any(
          (r) => r.routeId == routeId,
        );

        if (!routeExists) {
          // Si la ruta no existe, limpiar todos los buses con esta ruta
          busesToClean.addAll(busesWithThisRoute);
          continue;
        }

        // Filtrar buses con conductores válidos
        final validBuses = busesWithThisRoute.where((bus) {
          return adminProvider.usuarios.any(
            (u) => u.id == bus.driverId && u.role == 'driver',
          );
        }).toList();

        if (validBuses.isEmpty) {
          // Si ningún conductor es válido, limpiar todos
          busesToClean.addAll(busesWithThisRoute);
          continue;
        }

        // Si hay múltiples buses con la misma ruta, mantener solo el primero y limpiar los demás
        if (validBuses.length > 1) {
          // Mantener el primero (preferir buses con status 'inactive' o 'en_ruta' sobre 'active')
          validBuses.sort((a, b) {
            // Priorizar buses que NO están 'active' (para evitar autoasignaciones)
            if (a.status == 'active' && b.status != 'active') return 1;
            if (a.status != 'active' && b.status == 'active') return -1;
            return 0;
          });

          final firstBus = validBuses.first;

          // Solo agregar a assignments si el bus NO está en estado 'active' sin asignación manual
          // Los buses 'active' sin asignación manual deben limpiarse
          if (firstBus.status != 'active') {
            assignments[routeId] = firstBus.driverId!;
            routeIdsSeen.add(routeId);
          } else {
            // Si el primer bus es 'active', limpiarlo también (no debería tener ruta asignada)
            busesToClean.add(firstBus);
            print(
                '⚠️ Bus ${firstBus.id} tiene status "active" con ruta asignada, limpiando...');
          }

          // Limpiar los duplicados (todos excepto el primero)
          final duplicates = validBuses.skip(1).toList();
          busesToClean.addAll(duplicates);
          print(
              '⚠️ ADVERTENCIA: ${validBuses.length} buses tienen la ruta $routeId asignada. Manteniendo bus ${firstBus.id}, limpiando ${duplicates.length} duplicados');
        } else {
          // Solo hay un bus válido
          final bus = validBuses.first;

          // Solo agregar a assignments si el bus NO está en estado 'active'
          // Los buses 'active' sin asignación manual deben limpiarse
          if (bus.status != 'active') {
            assignments[routeId] = bus.driverId!;
            routeIdsSeen.add(routeId);
          } else {
            // Si el bus es 'active', limpiarlo (no debería tener ruta asignada automáticamente)
            busesToClean.add(bus);
            print(
                '⚠️ Bus ${bus.id} tiene status "active" con ruta asignada, limpiando...');
          }
        }

        // Limpiar buses con conductores inválidos
        final invalidBuses = busesWithThisRoute.where((bus) {
          return !adminProvider.usuarios.any(
            (u) => u.id == bus.driverId && u.role == 'driver',
          );
        }).toList();
        busesToClean.addAll(invalidBuses);
      }

      // Actualizar asignaciones primero
      if (mounted) {
        setState(() {
          _assignments = assignments;
        });
      }

      // Limpiar asignaciones inconsistentes automáticamente SOLO si no estamos en modo skipCleaning
      if (busesToClean.isNotEmpty && !skipCleaning && !_isCleaning) {
        print(
            '🧹 Limpiando ${busesToClean.length} asignaciones inconsistentes...');
        _cleanInvalidAssignments(busesToClean, adminProvider);
      }
    } catch (e) {
      print('❌ Error en _loadAssignmentsFromBuses: $e');
    }
  }

  Future<void> _cleanInvalidAssignments(
    List<BusLocation> busesToClean,
    AdminProvider adminProvider,
  ) async {
    // Marcar que estamos limpiando para evitar bucles infinitos
    if (_isCleaning) {
      print('⚠️ Ya se está limpiando, ignorando nueva solicitud de limpieza');
      return;
    }

    _isCleaning = true;

    try {
      print(
          '🧹 Iniciando limpieza de ${busesToClean.length} asignaciones inconsistentes...');

      // Limpiar todas las asignaciones
      for (final bus in busesToClean) {
        if (bus.id != null) {
          try {
            final updatedBus = bus.copyWith(routeId: null);
            await adminProvider.apiService
                .updateBusLocation(bus.id!, updatedBus);
            print('✅ Asignación limpiada del bus ${bus.id}');
          } catch (e) {
            print('⚠️ Error al limpiar asignación del bus ${bus.id}: $e');
          }
        }
      }

      // Esperar un momento para asegurar que los cambios se reflejen en la base de datos
      await Future.delayed(const Duration(milliseconds: 300));

      // Refrescar buses después de limpiar
      if (mounted) {
        await adminProvider.refreshBusesSilently();
        // Recargar asignaciones después de limpiar para reflejar los cambios
        // Usar skipCleaning=true para evitar que vuelva a limpiar inmediatamente
        _loadAssignmentsFromBuses(adminProvider, skipCleaning: true);
      }

      print('✅ Limpieza completada');
    } finally {
      // Resetear el flag después de un delay más largo para permitir que los cambios se reflejen completamente
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _isCleaning = false;
          print('🔄 Flag de limpieza reseteado');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        try {
          // Manejar errores del provider
          if (adminProvider.error != null && adminProvider.error!.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      'Error: ${adminProvider.error}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      adminProvider.clearError();
                      _loadData();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.rutas.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(adminProvider),
                  const SizedBox(height: 24),
                  _buildRutasList(adminProvider),
                ],
              ),
            ),
          );
        } catch (e, stackTrace) {
          print('❌ Error crítico en build: $e');
          print('Stack trace: $stackTrace');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'Error inesperado: $e',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _loadData();
                  },
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildHeader(AdminProvider adminProvider) {
    final drivers =
        adminProvider.usuarios.where((u) => u.role == 'driver').toList();
    final assignedRoutes = _assignments.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestión de Rutas y Conductores',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${adminProvider.rutas.length} rutas • $assignedRoutes asignadas • ${drivers.length} conductores',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: () => _showCreateDriverDialog(context),
              icon: const Icon(Icons.person_add),
              label: const Text('Nuevo Conductor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildStatsCards(adminProvider, drivers),
      ],
    );
  }

  Widget _buildStatsCards(AdminProvider adminProvider, List<Usuario> drivers) {
    final assignedDrivers = _assignments.values.toSet().length;
    final availableDrivers = drivers.length - assignedDrivers;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Conductores Totales',
            '${drivers.length}',
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Conductores Asignados',
            '$assignedDrivers',
            Icons.assignment_ind,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Conductores Disponibles',
            '$availableDrivers',
            Icons.person_outline,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Rutas Activas',
            '${_assignments.length}',
            Icons.route,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'No hay rutas configuradas',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Crea rutas desde "Plantillas de Rutas"',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRutasList(AdminProvider adminProvider) {
    return Column(
      children: adminProvider.rutas.map((ruta) {
        final driverId = _assignments[ruta.routeId];
        final hasAssignment = driverId != null;

        Usuario? assignedDriver;

        if (hasAssignment) {
          assignedDriver = adminProvider.usuarios.firstWhere(
            (u) => u.id == driverId,
            orElse: () =>
                Usuario(id: 0, email: '', name: 'Sin asignar', role: ''),
          );
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 3,
          child: ExpansionTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: hasAssignment ? Colors.green : Colors.grey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasAssignment ? Icons.check_circle : Icons.route,
                color: Colors.white,
              ),
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    ruta.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasAssignment) ...[
                  const SizedBox(width: 8),
                  const Chip(
                    label: Text(
                      'Asignada',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.zero,
                  ),
                ],
                const SizedBox(width: 8),
                // Botón visible de asignación
                ElevatedButton.icon(
                  onPressed: () => _showAssignmentDialog(context, ruta),
                  icon: Icon(
                    hasAssignment ? Icons.edit : Icons.person_add,
                    size: 16,
                  ),
                  label: Text(
                    hasAssignment ? 'Cambiar' : 'Asignar',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasAssignment ? Colors.blue : Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    minimumSize: const Size(0, 32),
                  ),
                ),
                // Botón para remover conductor (solo si hay asignación)
                if (hasAssignment) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _confirmRemoveAssignment(context, ruta),
                    icon: const Icon(Icons.person_remove, size: 16),
                    label: const Text(
                      'Remover',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
                  ),
                ],
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (hasAssignment) ...[
                  Row(
                    children: [
                      const Icon(Icons.person, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Conductor: ${assignedDriver?.name ?? "Sin asignar"}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Row(
                    children: [
                      Icon(Icons.warning, size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text('Sin conductor asignado'),
                      ),
                    ],
                  ),
                ],
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${ruta.stops.length} paradas'),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Paradas
                    const Text(
                      'Paradas de la Ruta:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...ruta.stops.asMap().entries.map((entry) {
                      final index = entry.key;
                      final parada = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.purple,
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(parada.name)),
                          ],
                        ),
                      );
                    }),

                    // Botones de asignación
                    const SizedBox(height: 16),
                    if (hasAssignment)
                      // Si hay asignación, mostrar dos botones lado a lado
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _showAssignmentDialog(context, ruta),
                              icon: const Icon(Icons.edit),
                              label: const Text('Cambiar Conductor'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _confirmRemoveAssignment(context, ruta),
                              icon: const Icon(Icons.person_remove),
                              label: const Text('Remover Conductor'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      // Si no hay asignación, mostrar solo el botón de asignar
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAssignmentDialog(context, ruta),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Asignar Conductor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showAssignmentDialog(BuildContext context, Ruta ruta) {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final drivers =
        adminProvider.usuarios.where((u) => u.role == 'driver').toList();

    final currentDriverId = _assignments[ruta.routeId];
    int? selectedDriverId = currentDriverId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.assignment_ind, color: Colors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Asignar Conductor\n${ruta.name}'),
                ),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Información de la ruta
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.route,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ruta: ${ruta.name}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text('${ruta.stops.length} paradas'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Seleccionar Conductor
                  const Text(
                    'Seleccionar Conductor',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  if (drivers.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('No hay conductores registrados'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _showCreateDriverDialog(context);
                            },
                            child: const Text('Crear'),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: selectedDriverId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                        hintText: 'Seleccione un conductor',
                      ),
                      items: drivers.map((driver) {
                        final isAssigned =
                            _assignments.values.contains(driver.id) &&
                                _assignments[ruta.routeId] != driver.id;
                        return DropdownMenuItem(
                          value: driver.id,
                          child: Row(
                            children: [
                              Text('${driver.name} (${driver.email})'),
                              if (isAssigned) ...[
                                const SizedBox(width: 8),
                                const Chip(
                                  label: Text('Asignado',
                                      style: TextStyle(fontSize: 10)),
                                  backgroundColor: Colors.orange,
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedDriverId = value;
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              if (currentDriverId != null)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _confirmRemoveAssignment(context, ruta);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text('Remover',
                      style: TextStyle(color: Colors.red)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton.icon(
                onPressed: () => _saveAssignment(
                  context,
                  ruta,
                  selectedDriverId,
                ),
                icon: const Icon(Icons.check),
                label: const Text('Guardar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveAssignment(
    BuildContext context,
    Ruta ruta,
    int? driverId,
  ) async {
    if (driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un conductor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      // IMPORTANTE: Primero remover la ruta del conductor anterior (si existe)
      final previousDriverId = _assignments[ruta.routeId];
      if (previousDriverId != null && previousDriverId != driverId) {
        // Buscar el bus del conductor anterior y remover la ruta
        try {
          final previousBus = adminProvider.buses.firstWhere(
            (b) => b.driverId == previousDriverId && b.routeId == ruta.routeId,
          );

          if (previousBus.id != null) {
            final updatedPreviousBus = previousBus.copyWith(routeId: null);
            await adminProvider.apiService.updateBusLocation(
              previousBus.id!,
              updatedPreviousBus,
            );
          }
        } catch (e) {
          print('⚠️ No se encontró bus del conductor anterior: $e');
        }
      }

      // Verificar si el nuevo conductor ya tiene una ruta asignada
      final existingAssignment = _assignments.entries.firstWhere(
        (entry) => entry.value == driverId && entry.key != ruta.routeId,
        orElse: () => const MapEntry('', 0),
      );

      if (existingAssignment.key.isNotEmpty) {
        // El conductor ya tiene una ruta asignada, mostrar alerta
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 8),
                Text('Conductor ya asignado'),
              ],
            ),
            content: Text(
              'Este conductor ya tiene asignada otra ruta. '
              '¿Deseas reasignarlo a esta ruta?',
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
                child: const Text('Reasignar'),
              ),
            ],
          ),
        );

        if (shouldContinue != true) {
          return; // El usuario canceló
        }

        // Remover la asignación anterior del nuevo conductor
        final previousBusOfNewDriver = adminProvider.buses.firstWhere(
          (b) => b.driverId == driverId && b.routeId == existingAssignment.key,
        );

        if (previousBusOfNewDriver.id != null) {
          final updatedBus = previousBusOfNewDriver.copyWith(routeId: null);
          await adminProvider.apiService.updateBusLocation(
            previousBusOfNewDriver.id!,
            updatedBus,
          );
        }

        _assignments.remove(existingAssignment.key);
      }

      // Buscar un bus existente para este conductor
      BusLocation? existingBus;
      try {
        existingBus = adminProvider.buses.firstWhere(
          (bus) => bus.driverId == driverId,
        );
      } catch (e) {
        // No hay bus para este conductor, crear uno nuevo
        existingBus = null;
      }

      // Si el bus existe, actualizarlo con la nueva ruta
      if (existingBus != null && existingBus.id != null) {
        final updatedBus = existingBus.copyWith(
          routeId: ruta.routeId,
          driverId: driverId,
        );

        await adminProvider.apiService.updateBusLocation(
          existingBus.id!,
          updatedBus,
        );
      } else {
        // Si no existe bus para este conductor, crear uno nuevo
        final newBus = BusLocation(
          busId: 'BUS-${driverId}', // ID temporal basado en el conductor
          routeId: ruta.routeId,
          driverId: driverId,
          latitude: -33.4489, // Santiago por defecto
          longitude: -70.6693,
          status: 'inactive',
        );

        await adminProvider.apiService.createBusLocation(newBus);
      }

      // Actualizar el estado local
      setState(() {
        _assignments[ruta.routeId] = driverId;
      });

      // Recargar buses para tener los datos actualizados
      await adminProvider.loadBuses();

      // Recargar asignaciones desde los buses actualizados
      _loadAssignmentsFromBuses(adminProvider);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conductor asignado a ${ruta.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al asignar conductor: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmRemoveAssignment(BuildContext context, Ruta ruta) async {
    final driverId = _assignments[ruta.routeId];
    if (driverId == null) return;

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final driver = adminProvider.usuarios.firstWhere(
      (u) => u.id == driverId,
      orElse: () => Usuario(id: 0, email: '', name: 'Desconocido', role: ''),
    );

    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'Remover Conductor',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            '¿Estás seguro de que deseas remover al conductor '
            '${driver.name} de la ruta "${ruta.name}"?\n\n'
            'La ruta quedará sin conductor asignado.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (shouldRemove == true) {
      // El diálogo ya se cerró automáticamente al retornar true
      // Esperar un frame para asegurar que el diálogo se cerró completamente
      await Future.delayed(const Duration(milliseconds: 150));

      // Luego remover la asignación
      if (mounted && context.mounted) {
        await _removeAssignment(context, ruta);
      }
    }
  }

  Future<void> _removeAssignment(
    BuildContext context,
    Ruta ruta,
  ) async {
    if (!mounted || !context.mounted) return;

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final driverId = _assignments[ruta.routeId];

      if (driverId != null) {
        // IMPORTANTE: Buscar TODOS los buses que tengan esta ruta asignada
        // y remover la asignación de todos ellos para evitar autoasignaciones
        final busesWithThisRoute = adminProvider.buses
            .where(
              (b) => b.routeId == ruta.routeId,
            )
            .toList();

        print(
            '🔍 Encontrados ${busesWithThisRoute.length} buses con ruta ${ruta.routeId}');

        // Remover la ruta de todos los buses que la tengan asignada
        // IMPORTANTE: También marcar el bus como 'inactive' para evitar que aparezca como activo en el dashboard
        for (final bus in busesWithThisRoute) {
          if (bus.id != null) {
            try {
              // Crear un mapa explícito para asegurar que route_id se envíe como null
              final updateData = {
                'bus_id': bus.busId,
                'route_id':
                    null, // EXPLÍCITAMENTE null para remover la asignación
                'driver_id': bus.driverId,
                'latitude': bus.latitude,
                'longitude': bus.longitude,
                'status': 'inactive', // Marcar como inactive al remover la ruta
              };

              // Usar el método de actualización directo del API
              await adminProvider.apiService.updateBusLocationDirect(
                bus.id!,
                updateData,
              );

              print(
                  '✅ Ruta removida del bus ${bus.id} (conductor ${bus.driverId}), marcado como inactive');
            } catch (e) {
              print('⚠️ Error al remover ruta del bus ${bus.id}: $e');
            }
          }
        }
      }

      // Remover del estado local PRIMERO para que la UI se actualice inmediatamente
      if (mounted) {
        setState(() {
          _assignments.remove(ruta.routeId);
        });
      }

      // Recargar buses para tener los datos actualizados
      // Usar refreshBusesSilently para evitar pantalla en blanco
      if (mounted && context.mounted) {
        try {
          // Limpiar errores previos
          adminProvider.clearError();

          // Refrescar buses sin activar el loading global
          await adminProvider.refreshBusesSilently();

          // Recargar asignaciones desde los buses actualizados
          // Usar skipCleaning=true porque ya removimos manualmente, no queremos limpieza automática
          if (mounted) {
            _loadAssignmentsFromBuses(adminProvider, skipCleaning: true);

            // Verificar que la ruta realmente quedó sin asignación
            if (_assignments.containsKey(ruta.routeId)) {
              print(
                  '⚠️ ADVERTENCIA: La ruta ${ruta.routeId} todavía tiene asignación después de remover');
              // Forzar la remoción del estado local
              setState(() {
                _assignments.remove(ruta.routeId);
              });
            } else {
              print(
                  '✅ Confirmado: La ruta ${ruta.routeId} quedó sin conductor asignado');
            }
          }
        } catch (e) {
          print('⚠️ Error al recargar buses: $e');
          // No propagar el error, solo loguearlo
        }
      }

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conductor removido de ${ruta.name}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error al remover asignación: $e');
      print('Stack trace: $stackTrace');

      // Si hay error, solo remover del estado local
      if (mounted) {
        try {
          setState(() {
            _assignments.remove(ruta.routeId);
          });
        } catch (setStateError) {
          print('❌ Error en setState: $setStateError');
        }
      }

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al remover asignación: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showCreateDriverDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.person_add, color: Colors.green),
            SizedBox(width: 12),
            Text('Registrar Nuevo Conductor'),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  hintText: 'conductor@ejemplo.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton.icon(
            onPressed: () => _createDriver(
              context,
              nameController.text,
              emailController.text,
            ),
            icon: const Icon(Icons.check),
            label: const Text('Crear Conductor'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createDriver(
    BuildContext context,
    String name,
    String email,
  ) async {
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe completar todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final newDriver = Usuario(
      id: 0, // Se asignará automáticamente
      name: name,
      email: email,
      role: 'driver',
    );

    final success = await adminProvider.createUsuario(newDriver);

    if (success && context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Conductor $name registrado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData(); // Recargar datos
    }
  }
}
