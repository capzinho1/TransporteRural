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
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.buses.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header moderno
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1E3A8A).withValues(alpha: 0.08),
                      const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF1E3A8A),
                                Color(0xFF3B82F6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.directions_bus_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gestión de Buses',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${adminProvider.buses.length} buses registrados',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showBusDialog(context, null),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar Bus'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tabla de buses en formato de tarjetas
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => adminProvider.loadBuses(),
                  child: ListView.builder(
                    itemCount: adminProvider.buses.length,
                    itemBuilder: (context, index) {
                      final bus = adminProvider.buses[index];
                      return _buildBusCard(bus);
                    },
                  ),
                ),
              ),
            ],
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_bus_outlined,
              size: 80,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No hay buses registrados',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer bus para comenzar',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showBusDialog(context, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar Primer Bus'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusCard(BusLocation bus) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusColor(bus.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.directions_bus_rounded,
            color: _getStatusColor(bus.status),
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Text(
              bus.busId,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusChip(bus.status),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (bus.nombreRuta != null && bus.nombreRuta!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.route_rounded,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      bus.nombreRuta!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              if (bus.driverId != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_rounded,
                        size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Conductor ID: ${bus.driverId}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_rounded),
              color: const Color(0xFF3B82F6),
              onPressed: () => _showBusDialog(context, bus),
              tooltip: 'Editar',
            ),
            IconButton(
              icon: const Icon(Icons.delete_rounded),
              color: Colors.red,
              onPressed: () => _confirmDelete(context, bus),
              tooltip: 'Eliminar',
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'en_ruta':
        return const Color(0xFF10B981);
      case 'inactive':
        return Colors.grey;
      case 'maintenance':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF3B82F6);
    }
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _getStatusColor(status),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showBusDialog(BuildContext context, BusLocation? bus) {
    final patenteController = TextEditingController(text: bus?.busId ?? '');
    final nombreRutaController =
        TextEditingController(text: bus?.nombreRuta ?? '');

    String selectedStatus = bus?.status ?? 'inactive';
    int? selectedDriverId = bus?.driverId;

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    if (adminProvider.usuarios.isEmpty) {
      adminProvider.loadUsuarios();
    }

    showDialog(
      context: context,
      builder: (context) => Consumer<AdminProvider>(
        builder: (context, provider, child) {
          final conductores =
              provider.usuarios.where((u) => u.role == 'driver').toList();

          return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(bus == null ? 'Agregar Bus' : 'Editar Bus'),
                ],
              ),
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
                          prefixIcon: Icon(Icons.directions_bus_rounded),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nombreRutaController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre de Ruta',
                          hintText: 'Ej: La Pintana - Puente Alto',
                          prefixIcon: Icon(Icons.route_rounded),
                          border: OutlineInputBorder(),
                          helperText:
                              'Nombre para facilitar la búsqueda (opcional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<int?>(
                        key: ValueKey('driver_$selectedDriverId'),
                        initialValue: selectedDriverId,
                        decoration: const InputDecoration(
                          labelText: 'Conductor',
                          prefixIcon: Icon(Icons.person_rounded),
                          border: OutlineInputBorder(),
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
                          setState(() {
                            selectedDriverId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        key: ValueKey('status_$selectedStatus'),
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Estado *',
                          prefixIcon: Icon(Icons.info_rounded),
                          border: OutlineInputBorder(),
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
                    if (patenteController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor ingresa la patente del bus'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final newBus = BusLocation(
                      id: bus?.id,
                      busId: patenteController.text.trim().toUpperCase(),
                      nombreRuta: nombreRutaController.text.trim().isNotEmpty
                          ? nombreRutaController.text.trim()
                          : null,
                      routeId: bus?.routeId,
                      driverId: selectedDriverId,
                      latitude: bus?.latitude ?? 0.0,
                      longitude: bus?.longitude ?? 0.0,
                      status: selectedStatus,
                      companyId: bus?.companyId,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                  ),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Confirmar Eliminación'),
          ],
        ),
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
