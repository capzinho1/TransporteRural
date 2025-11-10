import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/empresa.dart';

class CompaniesManagementScreen extends StatefulWidget {
  const CompaniesManagementScreen({super.key});

  @override
  State<CompaniesManagementScreen> createState() => _CompaniesManagementScreenState();
}

class _CompaniesManagementScreenState extends State<CompaniesManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadEmpresas();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Empresas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.empresas.isEmpty) {
            return _buildEmptyState(adminProvider);
          }

          return RefreshIndicator(
            onRefresh: () => adminProvider.loadEmpresas(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: adminProvider.empresas.length,
              itemBuilder: (context, index) {
                final empresa = adminProvider.empresas[index];
                return _buildEmpresaCard(context, empresa, adminProvider);
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          // Solo super_admin puede crear empresas
          if (adminProvider.currentUser?.isSuperAdmin == true) {
            return FloatingActionButton(
              onPressed: () => _showCreateEmpresaDialog(context, adminProvider),
              backgroundColor: Colors.deepPurple,
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildEmptyState(AdminProvider adminProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No hay empresas registradas',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          if (adminProvider.currentUser?.isSuperAdmin == true)
            ElevatedButton.icon(
              onPressed: () => _showCreateEmpresaDialog(context, adminProvider),
              icon: const Icon(Icons.add),
              label: const Text('Crear Primera Empresa'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpresaCard(BuildContext context, Empresa empresa, AdminProvider adminProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: empresa.active ? Colors.green : Colors.grey,
          child: Icon(
            Icons.business,
            color: Colors.white,
          ),
        ),
        title: Text(
          empresa.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: empresa.active ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${empresa.email}'),
            if (empresa.phone != null) Text('Teléfono: ${empresa.phone}'),
            Row(
              children: [
                Icon(
                  empresa.active ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: empresa.active ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  empresa.active ? 'Activa' : 'Inactiva',
                  style: TextStyle(
                    color: empresa.active ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: adminProvider.currentUser?.isSuperAdmin == true
            ? PopupMenuButton(
                icon: const Icon(Icons.more_vert),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _showEditEmpresaDialog(context, empresa, adminProvider);
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(
                          empresa.active ? Icons.block : Icons.check_circle,
                          size: 20,
                          color: empresa.active ? Colors.orange : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(empresa.active ? 'Desactivar' : 'Activar'),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _toggleEmpresaStatus(context, empresa, adminProvider);
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: const Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                    onTap: () {
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _showDeleteConfirmDialog(context, empresa, adminProvider);
                      });
                    },
                  ),
                ],
              )
            : null,
        onTap: adminProvider.currentUser?.isSuperAdmin == true
            ? () => _showEditEmpresaDialog(context, empresa, adminProvider)
            : null,
      ),
    );
  }

  void _showCreateEmpresaDialog(BuildContext context, AdminProvider adminProvider) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();
    bool _obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Nueva Empresa'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email *',
                    border: OutlineInputBorder(),
                    helperText: 'Será el email del administrador de la empresa',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña del Admin *',
                    border: const OutlineInputBorder(),
                    helperText: 'Contraseña para acceder como admin de la empresa',
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es requerido')),
                  );
                  return;
                }
                
                if (emailController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El email es requerido')),
                  );
                  return;
                }
                
                if (passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La contraseña es requerida')),
                  );
                  return;
                }
                
                if (passwordController.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
                  );
                  return;
                }

                final nuevaEmpresa = Empresa(
                  id: 0,
                  name: nameController.text,
                  email: emailController.text,
                  password: passwordController.text,
                  phone: phoneController.text.isEmpty ? null : phoneController.text,
                  address: addressController.text.isEmpty ? null : addressController.text,
                  active: true,
                );

                try {
                  final success = await adminProvider.createEmpresa(nuevaEmpresa);
                  if (context.mounted && success) {
                    Navigator.pop(context);
                    // Recargar la lista de empresas
                    await adminProvider.loadEmpresas();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Empresa creada exitosamente. El admin puede acceder con el email y contraseña proporcionados.'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 4),
                      ),
                    );
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${adminProvider.error ?? "Error desconocido"}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 5),
                      ),
                    );
                  }
                }
              },
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditEmpresaDialog(BuildContext context, Empresa empresa, AdminProvider adminProvider) {
    final nameController = TextEditingController(text: empresa.name);
    final emailController = TextEditingController(text: empresa.email);
    final passwordController = TextEditingController();
    final phoneController = TextEditingController(text: empresa.phone ?? '');
    final addressController = TextEditingController(text: empresa.address ?? '');
    bool _obscurePassword = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Empresa'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email *',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña (opcional)',
                  border: const OutlineInputBorder(),
                  helperText: 'Dejar vacío para mantener la contraseña actual',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Teléfono',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Dirección',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre es requerido')),
                );
                return;
              }
              
              if (emailController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El email es requerido')),
                );
                return;
              }
              
              if (passwordController.text.isNotEmpty && passwordController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
                );
                return;
              }

              final empresaActualizada = empresa.copyWith(
                name: nameController.text,
                email: emailController.text,
                password: passwordController.text.isEmpty ? null : passwordController.text,
                phone: phoneController.text.isEmpty ? null : phoneController.text,
                address: addressController.text.isEmpty ? null : addressController.text,
              );

              try {
                await adminProvider.updateEmpresa(empresa.id, empresaActualizada);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Empresa actualizada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _toggleEmpresaStatus(BuildContext context, Empresa empresa, AdminProvider adminProvider) async {
    try {
      final empresaActualizada = empresa.copyWith(active: !empresa.active);
      await adminProvider.updateEmpresa(empresa.id, empresaActualizada);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              empresa.active
                  ? 'Empresa desactivada'
                  : 'Empresa activada',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmDialog(BuildContext context, Empresa empresa, AdminProvider adminProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Empresa'),
        content: Text('¿Estás seguro de que quieres eliminar "${empresa.name}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await adminProvider.deleteEmpresa(empresa.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Empresa eliminada exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

