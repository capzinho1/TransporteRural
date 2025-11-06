import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';

class RoutesDriversScreen extends StatefulWidget {
  const RoutesDriversScreen({super.key});

  @override
  State<RoutesDriversScreen> createState() => _RoutesDriversScreenState();
}

class _RoutesDriversScreenState extends State<RoutesDriversScreen> {
  // Mapa de asignaciones: routeId -> driverId
  Map<String, int> _assignments = {};

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
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Gestión de Rutas y Conductores',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${adminProvider.rutas.length} rutas • $assignedRoutes asignadas • ${drivers.length} conductores',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
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
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
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
              children: [
                Expanded(
                  child: Text(
                    ruta.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (hasAssignment)
                  Chip(
                    label: const Text(
                      'Asignada',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.zero,
                  ),
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
                      Text(
                          'Conductor: ${assignedDriver?.name ?? "Sin asignar"}'),
                    ],
                  ),
                ] else ...[
                  const Row(
                    children: [
                      Icon(Icons.warning, size: 14, color: Colors.orange),
                      SizedBox(width: 4),
                      Text('Sin conductor asignado'),
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

                    // Botón de asignación prominente
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAssignmentDialog(context, ruta),
                        icon:
                            Icon(hasAssignment ? Icons.edit : Icons.person_add),
                        label: Text(
                          hasAssignment
                              ? 'Cambiar Conductor'
                              : 'Asignar Conductor',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              hasAssignment ? Colors.blue : Colors.green,
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
                            Text(
                              'Ruta: ${ruta.name}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
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
                  onPressed: () => _removeAssignment(context, ruta),
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

  void _saveAssignment(
    BuildContext context,
    Ruta ruta,
    int? driverId,
  ) {
    if (driverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe seleccionar un conductor'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _assignments[ruta.routeId] = driverId;
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conductor asignado a ${ruta.name}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _removeAssignment(BuildContext context, Ruta ruta) {
    setState(() {
      _assignments.remove(ruta.routeId);
    });

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Conductor removido de ${ruta.name}'),
        backgroundColor: Colors.orange,
      ),
    );
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

