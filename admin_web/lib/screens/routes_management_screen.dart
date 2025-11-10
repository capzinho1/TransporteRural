import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../models/bus.dart';

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
    // Si es edición, cargar datos existentes
    final nameController = TextEditingController(text: ruta?.name ?? '');
    final scheduleController =
        TextEditingController(text: ruta?.schedule ?? '06:00 - 22:00');
    final inicioController = TextEditingController();
    final finalController = TextEditingController();

    // Si es edición y hay paradas, el inicio y final son la primera y última parada
    if (ruta != null && ruta.stops.isNotEmpty) {
      inicioController.text = ruta.stops.first.name;
      if (ruta.stops.length > 1) {
        finalController.text = ruta.stops.last.name;
      }
    }

    // Lista de paradas intermedias (sin inicio y final)
    List<String> paradasNombres = [];
    if (ruta != null && ruta.stops.length > 2) {
      // Excluir primera y última parada
      paradasNombres = ruta.stops
          .sublist(1, ruta.stops.length - 1)
          .map((p) => p.name)
          .toList();
    }

    // Variable para controlar si se crea la ruta inversa (solo para nuevas rutas)
    bool createReverseRoute = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(ruta == null ? 'Crear Nueva Ruta' : 'Editar Ruta'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 600,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de Ruta *',
                      hintText: 'Ruta Centro - Norte',
                      prefixIcon: Icon(Icons.route),
                      helperText: 'Nombre descriptivo de la ruta',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: scheduleController,
                    decoration: const InputDecoration(
                      labelText: 'Horario *',
                      hintText: '06:00 - 22:00',
                      prefixIcon: Icon(Icons.schedule),
                      helperText: 'Horario de operación de la ruta',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Puntos de la Ruta',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: inicioController,
                    decoration: const InputDecoration(
                      labelText: 'Punto de Inicio *',
                      hintText: 'Ej: Terminal Central',
                      prefixIcon:
                          Icon(Icons.play_circle_outline, color: Colors.green),
                      helperText: 'Punto de partida de la ruta',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: finalController,
                    decoration: const InputDecoration(
                      labelText: 'Punto Final *',
                      hintText: 'Ej: Terminal Norte',
                      prefixIcon:
                          Icon(Icons.stop_circle_outlined, color: Colors.red),
                      helperText: 'Destino final de la ruta',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Paradas Intermedias',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            paradasNombres.add('');
                          });
                        },
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Agregar Parada'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (paradasNombres.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.grey[600], size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No hay paradas intermedias. Haz clic en "Agregar Parada" para añadir paradas entre el inicio y el final.',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[700]),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...List.generate(paradasNombres.length, (index) {
                      return Padding(
                        key: ValueKey('parada_$index'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: ValueKey('textfield_parada_$index'),
                                controller: TextEditingController(
                                    text: paradasNombres[index])
                                  ..selection = TextSelection.fromPosition(
                                    TextPosition(
                                        offset: paradasNombres[index].length),
                                  ),
                                decoration: InputDecoration(
                                  labelText: 'Parada ${index + 1}',
                                  hintText: 'Ej: Plaza de Armas',
                                  prefixIcon: const Icon(Icons.location_on),
                                  border: const OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  paradasNombres[index] = value;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setDialogState(() {
                                  paradasNombres.removeAt(index);
                                });
                              },
                              tooltip: 'Eliminar parada',
                            ),
                          ],
                        ),
                      );
                    }),
                  const SizedBox(height: 24),

                  // Opción para crear ruta inversa (solo para nuevas rutas)
                  if (ruta == null) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: createReverseRoute,
                            onChanged: (value) {
                              setDialogState(() {
                                createReverseRoute = value ?? false;
                              });
                            },
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.swap_horiz,
                                        color: Colors.blue[700], size: 20),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Crear ruta inversa automáticamente',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Se creará una ruta de vuelta con las paradas en orden inverso.\n'
                                  'Ej: Si creas "Linares-Talca-Rancagua", también se creará "Rancagua-Talca-Linares"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              onPressed: () {
                if (nameController.text.isEmpty ||
                    scheduleController.text.isEmpty ||
                    inicioController.text.isEmpty ||
                    finalController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Por favor completa todos los campos obligatorios'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Construir lista completa de paradas: inicio + paradas intermedias + final
                List<Parada> allStops = [];

                // Agregar inicio
                allStops.add(Parada(
                  name: inicioController.text.trim(),
                  latitude:
                      0.0, // Se puede actualizar después con coordenadas reales
                  longitude: 0.0,
                  order: 0,
                ));

                // Agregar paradas intermedias (solo las que tienen nombre)
                int orderIndex = 1;
                for (var nombre in paradasNombres) {
                  if (nombre.trim().isNotEmpty) {
                    allStops.add(Parada(
                      name: nombre.trim(),
                      latitude:
                          0.0, // Se puede actualizar después con coordenadas reales
                      longitude: 0.0,
                      order: orderIndex++,
                    ));
                  }
                }

                // Agregar final
                allStops.add(Parada(
                  name: finalController.text.trim(),
                  latitude:
                      0.0, // Se puede actualizar después con coordenadas reales
                  longitude: 0.0,
                  order: allStops.length,
                ));

                // Generar routeId si no existe (para nuevas rutas)
                String routeId;
                if (ruta != null) {
                  routeId = ruta.routeId;
                } else {
                  // Generar ID único basado en el nombre
                  final timestamp = DateTime.now().millisecondsSinceEpoch;
                  final namePart = nameController.text
                      .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
                      .substring(
                          0,
                          nameController.text.length > 5
                              ? 5
                              : nameController.text.length)
                      .toUpperCase();
                  routeId = 'R${namePart}_$timestamp';
                }

                final newRuta = Ruta(
                  routeId: routeId,
                  name: nameController.text.trim(),
                  schedule: scheduleController.text.trim(),
                  stops: allStops,
                  polyline: ruta?.polyline ?? '',
                  active: ruta?.active ?? true,
                );

                Navigator.pop(context);
                _createRouteWithReverse(
                    newRuta, ruta != null, createReverseRoute);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: Text(ruta == null ? 'Crear Ruta' : 'Actualizar Ruta'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createRouteWithReverse(
      Ruta ruta, bool isUpdate, bool createReverse) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    bool success;

    if (isUpdate) {
      // Si es actualización, no crear ruta inversa
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

    // Crear la ruta principal
    print('🔄 Creando ruta: ${ruta.routeId} - ${ruta.name}');
    success = await adminProvider.createRuta(ruta);
    print('✅ Resultado creación: $success');

    bool reverseSuccess = false;
    Ruta? reverseRuta;

    // Si se solicitó crear la ruta inversa y la ruta principal se creó exitosamente
    if (createReverse && success && ruta.stops.length >= 2) {
      // Crear ruta inversa
      reverseRuta = _createReverseRoute(ruta);
      print(
          '🔄 Creando ruta inversa: ${reverseRuta.routeId} - ${reverseRuta.name}');
      reverseSuccess = await adminProvider.createRuta(reverseRuta);
      print('✅ Resultado creación ruta inversa: $reverseSuccess');
    }

    if (success && mounted) {
      // Recargar rutas para asegurar que se muestren ambas (principal e inversa)
      await adminProvider.loadRutas();

      // Esperar un momento para que el provider se actualice
      await Future.delayed(const Duration(milliseconds: 100));

      // Forzar actualización del estado
      if (mounted) {
        setState(() {});
        String message;
        if (createReverse && reverseSuccess) {
          message =
              'Ruta "${ruta.name}" y ruta inversa "${reverseRuta!.name}" creadas exitosamente. Total: ${adminProvider.rutas.length}';
        } else if (createReverse && !reverseSuccess) {
          message =
              'Ruta "${ruta.name}" creada, pero hubo un error al crear la ruta inversa. Total: ${adminProvider.rutas.length}';
        } else {
          message =
              'Ruta creada exitosamente. Total: ${adminProvider.rutas.length}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: (createReverse && !reverseSuccess)
                ? Colors.orange
                : Colors.green,
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

  /// Crea una ruta inversa basada en la ruta original
  Ruta _createReverseRoute(Ruta originalRoute) {
    // Invertir el orden de las paradas
    List<Parada> reversedStops = [];
    for (int i = originalRoute.stops.length - 1; i >= 0; i--) {
      final originalStop = originalRoute.stops[i];
      reversedStops.add(Parada(
        name: originalStop.name,
        latitude: originalStop.latitude,
        longitude: originalStop.longitude,
        order: originalRoute.stops.length - 1 - i,
      ));
    }

    // Crear nombre para la ruta inversa
    String reverseName;
    final routeName = originalRoute.name.trim();

    // Intentar detectar formato "A - B - C" o "A-B-C" o "A -> B -> C"
    // Buscar el separador principal (el más común)
    String? separator;
    if (routeName.contains(' - ')) {
      separator = ' - ';
    } else if (routeName.contains(' -> ')) {
      separator = ' -> ';
    } else if (routeName.contains('-')) {
      separator = '-';
    } else if (routeName.contains('->')) {
      separator = '->';
    }

    if (separator != null) {
      // Dividir por el separador encontrado
      List<String> parts = routeName.split(RegExp(separator == ' - '
          ? r'\s*-\s*'
          : (separator == ' -> ' ? r'\s*->\s*' : separator)));

      // Limpiar partes y filtrar vacías
      parts = parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

      if (parts.length >= 2) {
        // Invertir el orden y unir con el mismo separador
        reverseName = parts.reversed.join(separator);
      } else {
        // Si no se puede invertir automáticamente, agregar "(Vuelta)"
        reverseName = '$routeName (Vuelta)';
      }
    } else {
      // Si no tiene formato reconocible, agregar "(Vuelta)"
      reverseName = '$routeName (Vuelta)';
    }

    // Generar routeId único para la ruta inversa
    // Usar un timestamp ligeramente mayor para asegurar unicidad
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final namePart = reverseName
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .substring(0, reverseName.length > 5 ? 5 : reverseName.length)
        .toUpperCase();
    // Usar timestamp + 10 para asegurar que sea diferente del routeId original
    final reverseRouteId = 'R${namePart}_${timestamp + 10}';

    return Ruta(
      routeId: reverseRouteId,
      name: reverseName,
      schedule: originalRoute.schedule,
      stops: reversedStops,
      polyline: '', // La polyline se puede generar después
      active: originalRoute.active ?? true,
      companyId: originalRoute.companyId,
    );
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
