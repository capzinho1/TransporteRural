import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/usuario.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadUsuarios();
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

          if (adminProvider.usuarios.isEmpty) {
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
                      const Text(
                        'Gestión de Usuarios',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showUserDialog(context, null),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Nuevo Usuario'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildUsersTable(adminProvider.usuarios),
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
            Icons.people_outline,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay usuarios registrados',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showUserDialog(context, null),
            icon: const Icon(Icons.person_add),
            label: const Text('Agregar Primer Usuario'),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTable(List<Usuario> usuarios) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        columns: const [
          DataColumn(label: Text('ID')),
          DataColumn(label: Text('Nombre')),
          DataColumn(label: Text('Email')),
          DataColumn(label: Text('Rol')),
          DataColumn(label: Text('Acciones')),
        ],
        rows: usuarios.map((usuario) {
          return DataRow(
            cells: [
              DataCell(Text(usuario.id.toString())),
              DataCell(Text(usuario.name)),
              DataCell(Text(usuario.email)),
              DataCell(_buildRoleChip(usuario.role)),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showUserDialog(context, usuario),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, usuario),
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

  Widget _buildRoleChip(String role) {
    Color color;
    IconData icon;
    String label;

    switch (role.toLowerCase()) {
      case 'admin':
        color = Colors.red;
        icon = Icons.admin_panel_settings;
        label = 'Administrador';
        break;
      case 'driver':
        color = Colors.blue;
        icon = Icons.drive_eta;
        label = 'Conductor';
        break;
      case 'user':
        color = Colors.green;
        icon = Icons.person;
        label = 'Usuario';
        break;
      default:
        color = Colors.grey;
        icon = Icons.person_outline;
        label = role;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  void _showUserDialog(BuildContext context, Usuario? usuario) {
    final nameController = TextEditingController(text: usuario?.name ?? '');
    final emailController = TextEditingController(text: usuario?.email ?? '');
    String selectedRole = usuario?.role ?? 'user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(usuario == null ? 'Nuevo Usuario' : 'Editar Usuario'),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo *',
                    hintText: 'Juan Pérez',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    hintText: 'usuario@ejemplo.com',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Rol *',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'user',
                      child: Row(
                        children: [
                          Icon(Icons.person, size: 20),
                          SizedBox(width: 8),
                          Text('Usuario'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'driver',
                      child: Row(
                        children: [
                          Icon(Icons.drive_eta, size: 20),
                          SizedBox(width: 8),
                          Text('Conductor'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'admin',
                      child: Row(
                        children: [
                          Icon(Icons.admin_panel_settings, size: 20),
                          SizedBox(width: 8),
                          Text('Administrador'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedRole = value;
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

              if (!emailController.text.contains('@')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Por favor ingresa un email válido'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final newUsuario = Usuario(
                id: usuario?.id ?? 0,
                name: nameController.text,
                email: emailController.text,
                role: selectedRole,
              );

              final adminProvider =
                  Provider.of<AdminProvider>(context, listen: false);
              bool success;

              if (usuario == null) {
                success = await adminProvider.createUsuario(newUsuario);
              } else {
                success =
                    await adminProvider.updateUsuario(usuario.id, newUsuario);
              }

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      usuario == null
                          ? 'Usuario creado exitosamente'
                          : 'Usuario actualizado exitosamente',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(usuario == null ? 'Crear' : 'Actualizar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Usuario usuario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de eliminar el usuario ${usuario.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final adminProvider =
                  Provider.of<AdminProvider>(context, listen: false);
              final success = await adminProvider.deleteUsuario(usuario.id);

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Usuario eliminado exitosamente'),
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

