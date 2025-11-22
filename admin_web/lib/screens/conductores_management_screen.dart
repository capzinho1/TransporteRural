import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/usuario.dart';

class ConductoresManagementScreen extends StatefulWidget {
  const ConductoresManagementScreen({super.key});

  @override
  State<ConductoresManagementScreen> createState() =>
      _ConductoresManagementScreenState();
}

class _ConductoresManagementScreenState
    extends State<ConductoresManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadUsuarios();
    });
  }

  List<Usuario> _filterConductores(List<Usuario> usuarios) {
    return usuarios.where((u) => u.role == 'driver').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final conductores = _filterConductores(adminProvider.usuarios);

          if (conductores.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () => adminProvider.loadUsuarios(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
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
                              'Gestión de Conductores',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${conductores.length} conductores registrados',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: () => _showConductorDialog(context, null),
                          icon: const Icon(Icons.person_add),
                          label: const Text('Nuevo Conductor'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildConductoresGrid(conductores),
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
          Icon(
            Icons.drive_eta,
            size: 100,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay conductores registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showConductorDialog(context, null),
            icon: const Icon(Icons.person_add),
            label: const Text('Registrar Primer Conductor'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConductoresGrid(List<Usuario> conductores) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: conductores.map((conductor) {
        return _buildConductorCard(conductor);
      }).toList(),
    );
  }

  Widget _buildConductorCard(Usuario conductor) {
    return Card(
      elevation: 2,
      child: Container(
        width: 350,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con foto y nombre
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    conductor.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conductor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conductor.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),

            // Información del conductor
            _buildInfoRow(Icons.badge, 'ID', conductor.id.toString()),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.drive_eta, 'Rol', 'Conductor'),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.circle,
              'Estado',
              conductor.statusLabel,
              color: _getStatusColor(conductor.driverStatus ?? 'disponible'),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.check_circle,
              'Cuenta',
              conductor.isActive ? 'Activa' : 'Inactiva',
              color: conductor.isActive ? Colors.green : Colors.red,
            ),

            const SizedBox(height: 16),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showConductorDetails(context, conductor),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Detalles'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleConductorStatus(context, conductor),
                    icon: Icon(
                      conductor.isActive ? Icons.block : Icons.check_circle,
                      size: 16,
                    ),
                    label: Text(conductor.isActive ? 'Desactivar' : 'Activar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          conductor.isActive ? Colors.orange : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showConductorDialog(context, conductor),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: color ?? Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showConductorDetails(BuildContext context, Usuario conductor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.drive_eta, color: Colors.blue),
            const SizedBox(width: 8),
            Text(conductor.name),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', conductor.id.toString()),
              _buildDetailRow('Nombre', conductor.name),
              _buildDetailRow('Email', conductor.email),
              _buildDetailRow('Rol', 'Conductor'),
              _buildDetailRow('Estado', conductor.statusLabel),
              _buildDetailRow(
                  'Cuenta', conductor.isActive ? 'Activa' : 'Inactiva'),
              const SizedBox(height: 16),
              const Text(
                'Estadísticas:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              FutureBuilder(
                future: _getConductorStats(conductor.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  }

                  final stats = snapshot.data ?? {};
                  final tripsCount = stats['tripsCount'] ?? 0;
                  final avgRating = stats['avgRating'] ?? 0.0;
                  final punctuality = stats['punctuality'] ?? 0.0;

                  return Column(
                    children: [
                      _buildDetailRow(
                          'Viajes completados', tripsCount.toString()),
                      _buildDetailRow(
                          'Calificación promedio',
                          avgRating > 0
                              ? '${avgRating.toStringAsFixed(1)}/5'
                              : 'N/A'),
                      if (punctuality > 0)
                        _buildDetailRow('Puntualidad',
                            '${punctuality.toStringAsFixed(1)}%'),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showConductorDialog(context, conductor);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Editar'),
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
            width: 150,
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

  void _showConductorDialog(BuildContext context, Usuario? conductor) {
    final nameController = TextEditingController(text: conductor?.name ?? '');
    final emailController = TextEditingController(text: conductor?.email ?? '');
    final passwordController = TextEditingController();

    // Variables de estado para el diálogo
    String selectedStatus = conductor?.driverStatus ?? 'disponible';
    bool isActive = conductor?.isActive ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            conductor == null ? 'Nuevo Conductor' : 'Editar Conductor',
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Completo *',
                      hintText: 'Ej: Juan Pérez González',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      hintText: 'conductor@ejemplo.com',
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (conductor == null)
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña *',
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock),
                      ),
                    ),
                  if (conductor == null) const SizedBox(height: 16),
                  // Estado del conductor (solo para conductores)
                  if (conductor != null) ...[
                    const Text(
                      'Estado del Conductor',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        prefixIcon: Icon(Icons.drive_eta),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'disponible',
                          child: Text('Disponible'),
                        ),
                        DropdownMenuItem(
                          value: 'en_ruta',
                          child: Text('En Ruta'),
                        ),
                        DropdownMenuItem(
                          value: 'fuera_de_servicio',
                          child: Text('Fuera de Servicio'),
                        ),
                        DropdownMenuItem(
                          value: 'en_descanso',
                          child: Text('En Descanso'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedStatus = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Activar/Desactivar cuenta
                  Row(
                    children: [
                      Checkbox(
                        value: isActive,
                        onChanged: (value) {
                          setDialogState(() {
                            isActive = value ?? true;
                          });
                        },
                      ),
                      const Text('Cuenta activa'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'El conductor podrá actualizar su ubicación desde la app móvil',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
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
            if (conductor != null)
              TextButton(
                onPressed: () => _confirmDelete(context, conductor),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Eliminar'),
              ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty ||
                    emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor completa todos los campos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (conductor == null && passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La contraseña es requerida'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final adminProvider =
                    Provider.of<AdminProvider>(context, listen: false);

                // Crear el objeto Usuario para el conductor
                final newConductor = Usuario(
                  id: conductor?.id ?? 0,
                  name: nameController.text.trim(),
                  email: emailController.text.trim(),
                  role: 'driver',
                );

                // Para crear el conductor, necesitamos enviar también la contraseña
                // Crear un mapa con los datos adicionales (password) que no están en el modelo Usuario
                final conductorData = newConductor.toJson();
                if (conductor == null && passwordController.text.isNotEmpty) {
                  conductorData['password'] = passwordController.text;
                }

                // Agregar campos adicionales
                conductorData['active'] = isActive;
                // Agregar driver_status tanto para crear como para editar
                conductorData['driver_status'] = selectedStatus;

                bool success;

                if (conductor == null) {
                  // Usar el método del servicio directamente para enviar el password
                  success =
                      await adminProvider.createUsuarioWithData(conductorData);
                } else {
                  // Si se está editando y cambió el estado activo, pedir confirmación
                  if (conductor.isActive != isActive) {
                    final accion = isActive ? 'activar' : 'desactivar';
                    final mensaje = isActive
                        ? '¿Está seguro de que desea activar al conductor ${conductor.name}?'
                        : '¿Está seguro de que desea desactivar al conductor ${conductor.name}?\n\n'
                            'El conductor perderá el acceso inmediatamente y será desconectado de la aplicación.';

                    final confirmar = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text(
                            'Confirmar ${accion == 'activar' ? 'Activación' : 'Desactivación'}'),
                        content: Text(mensaje),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isActive ? Colors.green : Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(accion == 'activar'
                                ? 'Sí, Activar'
                                : 'Sí, Desactivar'),
                          ),
                        ],
                      ),
                    );

                    if (confirmar != true) {
                      return; // Cancelar la operación
                    }
                  }

                  // Actualizar con los nuevos campos
                  final usuarioActualizado = newConductor.copyWith(
                    active: isActive,
                    driverStatus: selectedStatus,
                  );
                  success = await adminProvider.updateUsuario(
                      conductor.id, usuarioActualizado);
                }

                if (!context.mounted) return;

                if (success) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        conductor == null
                            ? 'Conductor registrado exitosamente'
                            : 'Conductor actualizado exitosamente',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Mostrar error si falla la creación/actualización
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        adminProvider.error ??
                            'Error al ${conductor == null ? 'registrar' : 'actualizar'} el conductor',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: Text(conductor == null ? 'Registrar' : 'Actualizar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _getConductorStats(int driverId) async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);

      // Obtener viajes del conductor
      final trips = await adminProvider.apiService.getTripsByDriver(driverId);
      final completedTrips = trips.where((t) => t.status == 'completed').length;

      // Obtener calificaciones
      final ratingStats =
          await adminProvider.apiService.getDriverRatingStats(driverId);

      return {
        'tripsCount': completedTrips,
        'avgRating': ratingStats['average'] ?? 0.0,
        'punctuality': ratingStats['punctualityRate'] ?? 0.0,
      };
    } catch (e) {
      return {};
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_ruta':
        return Colors.blue;
      case 'disponible':
        return Colors.green;
      case 'fuera_de_servicio':
        return Colors.red;
      case 'en_descanso':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleConductorStatus(
      BuildContext context, Usuario conductor) async {
    final nuevaEstado = !conductor.isActive;
    final accion = nuevaEstado ? 'activar' : 'desactivar';
    final mensaje = nuevaEstado
        ? '¿Está seguro de que desea activar al conductor ${conductor.name}?'
        : '¿Está seguro de que desea desactivar al conductor ${conductor.name}?\n\n'
            'El conductor perderá el acceso inmediatamente y será desconectado de la aplicación.';

    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Confirmar ${accion == 'activar' ? 'Activación' : 'Desactivación'}'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevaEstado ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(accion == 'activar' ? 'Sí, Activar' : 'Sí, Desactivar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    if (!context.mounted) return;

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final usuarioActualizado = conductor.copyWith(active: nuevaEstado);

    final success =
        await adminProvider.updateUsuario(conductor.id, usuarioActualizado);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nuevaEstado
                ? 'Conductor ${conductor.name} activado exitosamente'
                : 'Conductor ${conductor.name} desactivado exitosamente',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await adminProvider.loadUsuarios();
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Error al $accion conductor: ${adminProvider.error ?? "Error desconocido"}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmDelete(BuildContext context, Usuario conductor) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de eliminar al conductor ${conductor.name}?\n\n'
          'Se removerán automáticamente todas sus asignaciones de rutas.\n\n'
          'Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final adminProvider =
                  Provider.of<AdminProvider>(context, listen: false);

              // Cerrar el diálogo primero
              if (context.mounted) {
                Navigator.pop(context);
              }

              final success = await adminProvider.deleteUsuario(conductor.id);

              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Conductor ${conductor.name} eliminado exitosamente.\n'
                      'Todas sus asignaciones de rutas han sido removidas.',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 4),
                  ),
                );

                // Recargar datos para actualizar la vista
                await adminProvider.loadBuses();
                await adminProvider.loadUsuarios();
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Error al eliminar conductor: ${adminProvider.error ?? "Error desconocido"}'),
                    backgroundColor: Colors.red,
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
