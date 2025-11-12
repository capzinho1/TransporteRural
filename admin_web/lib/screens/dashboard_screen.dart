import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../widgets/georu_logo.dart';
import 'routes_management_screen.dart';
import 'users_management_screen.dart';
import 'conductores_management_screen.dart';
import 'buses_management_screen.dart';
import 'realtime_map_screen.dart';
import 'reports_screen.dart';
import 'notifications_screen.dart';
import 'companies_management_screen.dart';
import 'admin_login_screen.dart';
import 'user_reports_screen.dart';
import 'trips_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Cargar datos después del primer frame para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.refreshAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        final isSuperAdmin = adminProvider.currentUser?.isSuperAdmin ?? false;

        // Pantallas diferentes según el rol
        final List<Widget> screens = isSuperAdmin
            ? [
                // Super Admin: Reportes y gestión de empresas
                _buildDashboard(),
                const ReportsScreen(),
                const CompaniesManagementScreen(),
                const RealtimeMapScreen(),
                const NotificationsScreen(),
                const UserReportsScreen(),
                const TripsHistoryScreen(),
              ]
            : [
                // Company Admin: Gestión completa de su empresa
                _buildDashboard(),
                const RoutesManagementScreen(),
                const BusesManagementScreen(),
                const ConductoresManagementScreen(),
                const RealtimeMapScreen(),
                const ReportsScreen(),
                const NotificationsScreen(),
                const UsersManagementScreen(),
                const UserReportsScreen(),
                const TripsHistoryScreen(),
              ];

        return Scaffold(
          body: Row(
            children: [
              // Sidebar fijo
              _buildFixedSidebar(adminProvider),
              // Contenido principal
              Expanded(
                child: Column(
                  children: [
                    // AppBar personalizado
                    Container(
                      height: kToolbarHeight,
                      decoration: const BoxDecoration(
                        color: Colors.deepPurple,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const GeoRuLogo(
                            size: 28,
                            showText: false,
                            showSlogan: false,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'GeoRu - Panel ${isSuperAdmin ? "Super Admin" : "Admin"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _loadData,
                            tooltip: 'Actualizar datos',
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: () {
                              _showLogoutDialog();
                            },
                            tooltip: 'Cerrar sesión',
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                    // Contenido de la pantalla seleccionada
                    Expanded(
                      child: screens[_selectedIndex],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFixedSidebar(AdminProvider adminProvider) {
    final isSuperAdmin = adminProvider.currentUser?.isSuperAdmin ?? false;
    int menuIndex = 0;

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          right: BorderSide(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header del sidebar
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    GeoRuLogo(
                      size: 48,
                      showText: false,
                      showSlogan: false,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'GeoRu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Panel Administrativo',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  adminProvider.currentUser?.name ?? 'Administrador',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSuperAdmin ? Colors.orange : Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isSuperAdmin ? 'Super Admin' : 'Admin Empresa',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Lista de menú
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Menú según el rol
                if (isSuperAdmin) ...[
                  // MENÚ SUPER ADMIN: Reportes y gestión de empresas
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard General'),
                    subtitle: const Text('Vista general del sistema'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assessment, color: Colors.green),
                    title: const Text('Reportes del Sistema'),
                    subtitle: const Text('Estadísticas a gran escala'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.business, color: Colors.deepPurple),
                    title: const Text('Gestión de Empresas'),
                    subtitle: const Text('Crear y administrar empresas'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.map),
                    title: const Text('Mapa Global'),
                    subtitle: const Text('Todas las empresas'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notificaciones Globales'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.report_problem, color: Colors.orange),
                    title: const Text('Reportes de Usuarios'),
                    subtitle: const Text('Comentarios y sugerencias'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.blue),
                    title: const Text('Historial de Viajes'),
                    subtitle: const Text('Viajes completados'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 6;
                      });
                    },
                  ),
                ] else ...[
                  // MENÚ COMPANY ADMIN: Gestión completa de su empresa
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    subtitle: const Text('Vista general de mi empresa'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.route, color: Colors.purple),
                    title: const Text('Gestión de Rutas'),
                    subtitle: const Text('Rutas, plantillas y asignaciones'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 1;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.directions_bus),
                    title: const Text('Gestión de Buses'),
                    subtitle: const Text('Flota de la empresa'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 2;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.drive_eta),
                    title: const Text('Gestión de Conductores'),
                    subtitle: const Text('Personal de la empresa'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 3;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Usuarios de la Empresa'),
                    subtitle: const Text('Gestionar usuarios'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 7;
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.map),
                    title: const Text('Mapa en Tiempo Real'),
                    subtitle: const Text('Buses de mi empresa'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 4;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.assessment),
                    title: const Text('Reportes de la Empresa'),
                    subtitle: const Text('Estadísticas internas'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 5;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notificaciones'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 6;
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading:
                        const Icon(Icons.report_problem, color: Colors.orange),
                    title: const Text('Reportes de Usuarios'),
                    subtitle: const Text('Comentarios y sugerencias'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 8;
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.history, color: Colors.blue),
                    title: const Text('Historial de Viajes'),
                    subtitle: const Text('Viajes completados'),
                    selected: _selectedIndex == menuIndex++,
                    selectedTileColor: Colors.deepPurple[50],
                    onTap: () {
                      setState(() {
                        _selectedIndex = 9;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
          // Footer con botón de cerrar sesión
          Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                _showLogoutDialog();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = adminProvider.estadisticas;

        return RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título según rol
                Consumer<AdminProvider>(
                  builder: (context, adminProvider, child) {
                    final isSuperAdmin =
                        adminProvider.currentUser?.isSuperAdmin ?? false;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isSuperAdmin
                              ? 'Panel de Control - Sistema Completo'
                              : 'Panel de Control - Mi Empresa',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isSuperAdmin
                              ? 'Vista general de todas las empresas y usuarios del sistema'
                              : 'Vista general de tu empresa: buses, rutas y personal',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Tarjetas de estadísticas
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _buildStatCard(
                      'Total Buses',
                      '${stats['totalBuses'] ?? 0}',
                      Icons.directions_bus,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Buses Activos',
                      '${stats['busesActivos'] ?? 0}',
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatCard(
                      'Buses Inactivos',
                      '${stats['busesInactivos'] ?? 0}',
                      Icons.cancel,
                      Colors.orange,
                    ),
                    _buildStatCard(
                      'Total Rutas',
                      '${stats['totalRutas'] ?? 0}',
                      Icons.route,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      'Total Usuarios',
                      '${stats['totalUsuarios'] ?? 0}',
                      Icons.people,
                      Colors.indigo,
                    ),
                    _buildStatCard(
                      'Conductores',
                      '${stats['conductores'] ?? 0}',
                      Icons.person,
                      Colors.teal,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Accesos rápidos según rol
                Consumer<AdminProvider>(
                  builder: (context, adminProvider, child) {
                    final isSuperAdmin =
                        adminProvider.currentUser?.isSuperAdmin ?? false;

                    if (isSuperAdmin) {
                      // Accesos rápidos para Super Admin
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Accesos Rápidos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildQuickAccessCard(
                                'Ver Reportes',
                                Icons.assessment,
                                Colors.green,
                                () {
                                  setState(() {
                                    _selectedIndex = 1;
                                  });
                                },
                              ),
                              _buildQuickAccessCard(
                                'Gestionar Empresas',
                                Icons.business,
                                Colors.deepPurple,
                                () {
                                  setState(() {
                                    _selectedIndex = 2;
                                  });
                                },
                              ),
                              _buildQuickAccessCard(
                                'Mapa Global',
                                Icons.map,
                                Colors.blue,
                                () {
                                  setState(() {
                                    _selectedIndex = 3;
                                  });
                                },
                              ),
                              _buildQuickAccessCard(
                                'Notificaciones',
                                Icons.notifications,
                                Colors.orange,
                                () {
                                  setState(() {
                                    _selectedIndex = 4;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    } else {
                      // Accesos rápidos para Company Admin
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Accesos Rápidos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: [
                              _buildQuickAccessCard(
                                'Agregar Bus',
                                Icons.add_circle,
                                Colors.blue,
                                () {
                                  setState(() {
                                    _selectedIndex = 3;
                                  });
                                },
                              ),
                              _buildQuickAccessCard(
                                'Crear Ruta',
                                Icons.add_road,
                                Colors.purple,
                                () {
                                  setState(() {
                                    _selectedIndex = 1;
                                  });
                                },
                              ),
                              _buildQuickAccessCard(
                                'Nuevo Conductor',
                                Icons.drive_eta,
                                Colors.orange,
                                () {
                                  setState(() {
                                    _selectedIndex = 4;
                                  });
                                },
                              ),
                              _buildQuickAccessCard(
                                'Gestionar Usuarios',
                                Icons.people,
                                Colors.indigo,
                                () {
                                  setState(() {
                                    _selectedIndex = 8;
                                  });
                                },
                              ),
                              _buildQuickAccessCard(
                                'Ver Mapa',
                                Icons.map,
                                Colors.green,
                                () {
                                  setState(() {
                                    _selectedIndex = 5;
                                  });
                                },
                              ),
                              _buildQuickAccessCard(
                                'Reportes',
                                Icons.assessment,
                                Colors.teal,
                                () {
                                  setState(() {
                                    _selectedIndex = 6;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 32),
              Text(
                value,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AdminProvider>(context, listen: false).logout();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AdminLoginScreen(),
                ),
              );
            },
            child: const Text(
              'Cerrar Sesión',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
