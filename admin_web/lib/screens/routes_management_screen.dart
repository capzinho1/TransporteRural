import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/ruta.dart';

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
      Provider.of<AdminProvider>(context, listen: false).loadRutas();
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

          if (adminProvider.rutas.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => adminProvider.loadRutas(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Gestión de Rutas',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showRutaDialog(context, null),
                        icon: const Icon(Icons.add),
                        label: const Text('Crear Ruta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildRutasGrid(adminProvider.rutas),
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
            onPressed: () => _showRutaDialog(context, null),
            icon: const Icon(Icons.add),
            label: const Text('Crear Primera Ruta'),
          ),
        ],
      ),
    );
  }

  Widget _buildRutasGrid(List<Ruta> rutas) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: rutas.map((ruta) => _buildRutaCard(ruta)).toList(),
    );
  }

  Widget _buildRutaCard(Ruta ruta) {
    return Card(
      elevation: 2,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Chip(
                  label: Text(ruta.routeId),
                  backgroundColor: Colors.purple[100],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(ruta.schedule),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${ruta.stops.length} paradas'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showRutaDetails(context, ruta),
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Detalles'),
                ),
                TextButton.icon(
                  onPressed: () => _showRutaDialog(context, ruta),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, ruta),
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  label: const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRutaDetails(BuildContext context, Ruta ruta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ruta.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID Ruta: ${ruta.routeId}'),
              const SizedBox(height: 8),
              Text('Horario: ${ruta.schedule}'),
              const SizedBox(height: 16),
              const Text(
                'Paradas:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...ruta.stops.map(
                (parada) => ListTile(
                  dense: true,
                  leading: Text('${parada.order ?? 0}'),
                  title: Text(parada.name),
                  subtitle: Text(
                      'Lat: ${parada.latitude.toStringAsFixed(4)}, Lng: ${parada.longitude.toStringAsFixed(4)}'),
                ),
              ),
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

  void _showRutaDialog(BuildContext context, Ruta? ruta) {
    final routeIdController = TextEditingController(text: ruta?.routeId ?? '');
    final nameController = TextEditingController(text: ruta?.name ?? '');
    final scheduleController =
        TextEditingController(text: ruta?.schedule ?? '06:00 - 22:00');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ruta == null ? 'Crear Ruta' : 'Editar Ruta'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: routeIdController,
                  decoration: const InputDecoration(
                    labelText: 'ID de Ruta *',
                    hintText: 'R001',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de Ruta *',
                    hintText: 'Ruta Centro - Norte',
                    prefixIcon: Icon(Icons.route),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: scheduleController,
                  decoration: const InputDecoration(
                    labelText: 'Horario *',
                    hintText: '06:00 - 22:00',
                    prefixIcon: Icon(Icons.schedule),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nota: Las paradas se pueden agregar posteriormente',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
              if (routeIdController.text.isEmpty ||
                  nameController.text.isEmpty ||
                  scheduleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor completa todos los campos'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newRuta = Ruta(
                routeId: routeIdController.text,
                name: nameController.text,
                schedule: scheduleController.text,
                stops: ruta?.stops ?? [],
                polyline: ruta?.polyline ?? '',
              );

              final adminProvider =
                  Provider.of<AdminProvider>(context, listen: false);
              bool success;

              if (ruta == null) {
                success = await adminProvider.createRuta(newRuta);
              } else {
                success =
                    await adminProvider.updateRuta(ruta.routeId, newRuta);
              }

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ruta == null
                          ? 'Ruta creada exitosamente'
                          : 'Ruta actualizada exitosamente',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(ruta == null ? 'Crear' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Ruta ruta) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar la ruta ${ruta.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final adminProvider =
                  Provider.of<AdminProvider>(context, listen: false);
              final success = await adminProvider.deleteRuta(ruta.routeId);

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ruta eliminada exitosamente'),
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

