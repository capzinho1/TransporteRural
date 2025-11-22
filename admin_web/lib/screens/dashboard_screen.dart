import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/admin_provider.dart';
import '../widgets/georu_logo.dart';
import '../config/app_config.dart';
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
  Timer? _refreshTimer;
  int? _selectedCompanyFilter; // Filtro por empresa para super admin

  @override
  void initState() {
    super.initState();
    // Cargar datos después del primer frame para evitar setState durante build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
    // Actualizar dashboard automáticamente con frecuencia unificada
    _refreshTimer = Timer.periodic(
      Duration(seconds: AppConfig.dashboardRefreshIntervalSeconds),
      (_) {
        if (mounted && _selectedIndex == 0) {
          // Solo actualizar si estamos en el dashboard
          _loadData();
        }
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.refreshAllData();
    // Si hay un filtro de empresa, recargar estadísticas filtradas
    if (_selectedCompanyFilter != null) {
      setState(() {}); // Actualizar UI para mostrar estadísticas filtradas
    }
  }
  
  // Obtener estadísticas filtradas por empresa
  Map<String, dynamic> _getFilteredStats(AdminProvider adminProvider) {
    final stats = adminProvider.estadisticas;
    
    // Si no hay filtro o no es super admin, retornar todas las estadísticas
    if (_selectedCompanyFilter == null || !(adminProvider.currentUser?.isSuperAdmin ?? false)) {
      return stats;
    }
    
    // Filtrar estadísticas por empresa
    final statsPorEmpresa = stats['statsPorEmpresa'] as Map<String, dynamic>? ?? {};
    
    // Buscar la empresa en statsPorEmpresa
    String? empresaName;
    for (final entry in statsPorEmpresa.entries) {
      if (entry.value['empresaId'] == _selectedCompanyFilter) {
        empresaName = entry.key;
        break;
      }
    }
    
    if (empresaName == null || !statsPorEmpresa.containsKey(empresaName)) {
      return stats; // Si no se encuentra, retornar todas
    }
    
    final empresaStats = statsPorEmpresa[empresaName] as Map<String, dynamic>;
    
    // Retornar estadísticas filtradas
    return {
      'totalBuses': empresaStats['totalBuses'] ?? 0,
      'busesActivos': empresaStats['busesActivos'] ?? 0,
      'busesInactivos': (empresaStats['totalBuses'] ?? 0) - (empresaStats['busesActivos'] ?? 0),
      'totalRutas': empresaStats['totalRutas'] ?? 0,
      'totalUsuarios': empresaStats['totalUsuarios'] ?? 0,
      'conductores': empresaStats['conductores'] ?? 0,
      'totalEmpresas': 1, // Solo la empresa seleccionada
    };
  }

  // Cambiar de pantalla y recargar datos si es necesario
  void _changeScreen(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Recargar datos al cambiar de pantalla (excepto si ya estamos en esa pantalla)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
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
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1E3A8A), // Azul oscuro
                            const Color(0xFF3B82F6), // Azul medio
                            const Color(0xFF60A5FA), // Azul claro
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: screens,
                      ),
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

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        border: Border(
          right: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del sidebar compacto
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1E3A8A), // Azul oscuro
                  const Color(0xFF3B82F6), // Azul medio
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const GeoRuLogo(
                        size: 28,
                        showText: false,
                        showSlogan: false,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'GeoRu',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            isSuperAdmin ? 'Super Admin' : 'Admin',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Text(
                              adminProvider.currentUser?.name ?? 'Admin',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: isSuperAdmin
                                    ? Colors.orange[700]
                                    : Colors.blue[800],
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                isSuperAdmin ? 'Super' : 'Empresa',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de menú compacta
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                if (isSuperAdmin) ...[
                  // === SUPER ADMIN MENU ===
                  _buildMenuSection(
                    '📊 Panel Principal',
                    [
                      _buildMenuItem(
                        icon: Icons.dashboard_rounded,
                        title: 'Dashboard General',
                        subtitle: 'Vista general del sistema',
                        color: const Color(0xFF2196F3),
                        isSelected: _selectedIndex == 0,
                        onTap: () => _changeScreen(0),
                      ),
                      _buildMenuItem(
                        icon: Icons.assessment_rounded,
                        title: 'Reportes del Sistema',
                        subtitle: 'KPIs y estadísticas globales',
                        color: const Color(0xFF4CAF50),
                        isSelected: _selectedIndex == 1,
                        onTap: () => _changeScreen( 1),
                      ),
                    ],
                  ),
                  _buildMenuSection(
                    '🏢 Gestión de Empresas',
                    [
                      _buildMenuItem(
                        icon: Icons.business_rounded,
                        title: 'Gestión de Empresas',
                        subtitle: 'Crear y administrar empresas',
                        color: const Color(0xFF9C27B0),
                        isSelected: _selectedIndex == 2,
                        onTap: () => _changeScreen( 2),
                      ),
                    ],
                  ),
                  _buildMenuSection(
                    '🗺️ Visualización',
                    [
                      _buildMenuItem(
                        icon: Icons.map_rounded,
                        title: 'Mapa Global',
                        subtitle: 'Todas las empresas en tiempo real',
                        color: const Color(0xFF00BCD4),
                        isSelected: _selectedIndex == 3,
                        onTap: () => _changeScreen( 3),
                      ),
                    ],
                  ),
                  _buildMenuSection(
                    '🔔 Comunicación',
                    [
                      _buildMenuItem(
                        icon: Icons.notifications_active_rounded,
                        title: 'Notificaciones Globales',
                        subtitle: 'Alertas y avisos del sistema',
                        color: const Color(0xFFFF9800),
                        isSelected: _selectedIndex == 4,
                        onTap: () => _changeScreen( 4),
                      ),
                    ],
                  ),
                  _buildMenuSection(
                    '📋 Análisis y Reportes',
                    [
                      _buildMenuItem(
                        icon: Icons.report_problem_rounded,
                        title: 'Reportes de Usuarios',
                        subtitle: 'Comentarios y sugerencias',
                        color: const Color(0xFFFF5722),
                        isSelected: _selectedIndex == 5,
                        onTap: () => _changeScreen( 5),
                      ),
                      _buildMenuItem(
                        icon: Icons.history_rounded,
                        title: 'Historial de Viajes',
                        subtitle: 'Registro de viajes completados',
                        color: const Color(0xFF3F51B5),
                        isSelected: _selectedIndex == 6,
                        onTap: () => _changeScreen( 6),
                      ),
                    ],
                  ),
                ] else ...[
                  // === COMPANY ADMIN MENU ===
                  _buildMenuSection(
                    '📊 Panel Principal',
                    [
                      _buildMenuItem(
                        icon: Icons.dashboard_rounded,
                        title: 'Dashboard',
                        subtitle: 'Vista general de mi empresa',
                        color: const Color(0xFF2196F3),
                        isSelected: _selectedIndex == 0,
                        onTap: () => _changeScreen(0),
                      ),
                    ],
                  ),
                  _buildMenuSection(
                    '🚌 Gestión Operativa',
                    [
                      _buildMenuItem(
                        icon: Icons.route_rounded,
                        title: 'Gestión de Rutas',
                        subtitle: 'Rutas, plantillas y asignaciones',
                        color: const Color(0xFF9C27B0),
                        isSelected: _selectedIndex == 1,
                        onTap: () => _changeScreen( 1),
                      ),
                      _buildMenuItem(
                        icon: Icons.directions_bus_rounded,
                        title: 'Gestión de Buses',
                        subtitle: 'Flota de la empresa',
                        color: const Color(0xFF2196F3),
                        isSelected: _selectedIndex == 2,
                        onTap: () => _changeScreen( 2),
                      ),
                      _buildMenuItem(
                        icon: Icons.drive_eta_rounded,
                        title: 'Gestión de Conductores',
                        subtitle: 'Personal de la empresa',
                        color: const Color(0xFFFF9800),
                        isSelected: _selectedIndex == 3,
                        onTap: () => _changeScreen( 3),
                      ),
                      _buildMenuItem(
                        icon: Icons.people_rounded,
                        title: 'Usuarios de la Empresa',
                        subtitle: 'Gestionar usuarios',
                        color: const Color(0xFF4CAF50),
                        isSelected: _selectedIndex == 7,
                        onTap: () => _changeScreen( 7),
                      ),
                    ],
                  ),
                  _buildMenuSection(
                    '🗺️ Visualización',
                    [
                      _buildMenuItem(
                        icon: Icons.map_rounded,
                        title: 'Mapa en Tiempo Real',
                        subtitle: 'Buses de mi empresa',
                        color: const Color(0xFF00BCD4),
                        isSelected: _selectedIndex == 4,
                        onTap: () => _changeScreen( 4),
                      ),
                    ],
                  ),
                  _buildMenuSection(
                    '📈 Análisis y Reportes',
                    [
                      _buildMenuItem(
                        icon: Icons.assessment_rounded,
                        title: 'Reportes de la Empresa',
                        subtitle: 'KPIs y estadísticas internas',
                        color: const Color(0xFF4CAF50),
                        isSelected: _selectedIndex == 5,
                        onTap: () => _changeScreen( 5),
                      ),
                    ],
                  ),
                  _buildMenuSection(
                    '🔔 Comunicación',
                    [
                      _buildMenuItem(
                        icon: Icons.notifications_active_rounded,
                        title: 'Notificaciones',
                        subtitle: 'Alertas y avisos',
                        color: const Color(0xFFFF9800),
                        isSelected: _selectedIndex == 6,
                        onTap: () => _changeScreen( 6),
                      ),
                    ],
                  ),
                  _buildMenuSection(
                    '📋 Reportes de Usuarios',
                    [
                      _buildMenuItem(
                        icon: Icons.report_problem_rounded,
                        title: 'Reportes de Usuarios',
                        subtitle: 'Comentarios y sugerencias',
                        color: const Color(0xFFFF5722),
                        isSelected: _selectedIndex == 8,
                        onTap: () => _changeScreen( 8),
                      ),
                      _buildMenuItem(
                        icon: Icons.history_rounded,
                        title: 'Historial de Viajes',
                        subtitle: 'Registro de viajes completados',
                        color: const Color(0xFF3F51B5),
                        isSelected: _selectedIndex == 9,
                        onTap: () => _changeScreen( 9),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Footer mejorado con botón de cerrar sesión
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              border: Border(
                top: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showLogoutDialog(),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFD32F2F),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Cerrar Sesión',
                          style: TextStyle(
                            color: Color(0xFFD32F2F),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye una sección del menú con título
  Widget _buildMenuSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...items,
        const SizedBox(height: 4),
      ],
    );
  }

  /// Construye un item del menú compacto
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.2)
                        : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? color : color.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                          color: isSelected
                              ? color
                              : Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 3,
                    height: 24,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        if (adminProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = _getFilteredStats(adminProvider);

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header compacto del dashboard con filtro para super admin
              Consumer<AdminProvider>(
                builder: (context, adminProvider, child) {
                  final isSuperAdmin =
                      adminProvider.currentUser?.isSuperAdmin ?? false;
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
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
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color(0xFF1E3A8A),
                                    const Color(0xFF3B82F6),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.dashboard_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isSuperAdmin
                                        ? 'Panel de Control'
                                        : 'Mi Empresa',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E3A8A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isSuperAdmin
                                        ? 'Vista general del sistema'
                                        : 'Gestión de tu operación',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Filtro por empresa para super admin
                      if (isSuperAdmin) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.filter_list,
                                  color: Color(0xFF3B82F6)),
                              const SizedBox(width: 12),
                              const Text(
                                'Filtrar por empresa:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<int?>(
                                  value: _selectedCompanyFilter,
                                  decoration: const InputDecoration(
                                    hintText: 'Todas las empresas',
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('Todas las empresas'),
                                    ),
                                    ...adminProvider.empresas.map((empresa) {
                                      return DropdownMenuItem<int?>(
                                        value: empresa.id,
                                        child: Text(empresa.name),
                                      );
                                    }),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCompanyFilter = value;
                                    });
                                    _loadData();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Tarjetas de estadísticas en grid fijo (2 filas)
              SizedBox(
                height: 200,
                child: GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: [
                    _buildStatCard(
                      'Total Buses',
                      '${stats['totalBuses'] ?? 0}',
                      Icons.directions_bus_rounded,
                      const Color(0xFF3B82F6),
                    ),
                    _buildStatCard(
                      'Buses Activos',
                      '${stats['busesActivos'] ?? 0}',
                      Icons.check_circle_rounded,
                      const Color(0xFF10B981),
                    ),
                    _buildStatCard(
                      'Buses Inactivos',
                      '${stats['busesInactivos'] ?? 0}',
                      Icons.cancel_rounded,
                      const Color(0xFFF59E0B),
                    ),
                    _buildStatCard(
                      'Total Rutas',
                      '${stats['totalRutas'] ?? 0}',
                      Icons.route_rounded,
                      const Color(0xFF8B5CF6),
                    ),
                    _buildStatCard(
                      'Total Usuarios',
                      '${stats['totalUsuarios'] ?? 0}',
                      Icons.people_rounded,
                      const Color(0xFF6366F1),
                    ),
                    _buildStatCard(
                      'Conductores',
                      '${stats['conductores'] ?? 0}',
                      Icons.person_rounded,
                      const Color(0xFF14B8A6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Accesos rápidos
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.flash_on_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Accesos Rápidos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _buildQuickAccessCard(
                          icon: Icons.directions_bus_rounded,
                          title: 'Gestión de Buses',
                          color: const Color(0xFF3B82F6),
                          onTap: () => _changeScreen( (adminProvider.currentUser?.isSuperAdmin ?? false) ? 2 : 2),
                        ),
                        _buildQuickAccessCard(
                          icon: Icons.route_rounded,
                          title: 'Gestión de Rutas',
                          color: const Color(0xFF8B5CF6),
                          onTap: () => _changeScreen( (adminProvider.currentUser?.isSuperAdmin ?? false) ? 2 : 1),
                        ),
                        _buildQuickAccessCard(
                          icon: Icons.drive_eta_rounded,
                          title: 'Conductores',
                          color: const Color(0xFFFF9800),
                          onTap: () => _changeScreen( (adminProvider.currentUser?.isSuperAdmin ?? false) ? 2 : 3),
                        ),
                        _buildQuickAccessCard(
                          icon: Icons.map_rounded,
                          title: 'Mapa en Tiempo Real',
                          color: const Color(0xFF00BCD4),
                          onTap: () => _changeScreen( (adminProvider.currentUser?.isSuperAdmin ?? false) ? 3 : 4),
                        ),
                        _buildQuickAccessCard(
                          icon: Icons.notifications_active_rounded,
                          title: 'Notificaciones',
                          color: const Color(0xFFFF5722),
                          onTap: () => _changeScreen( (adminProvider.currentUser?.isSuperAdmin ?? false) ? 4 : 6),
                        ),
                        _buildQuickAccessCard(
                          icon: Icons.assessment_rounded,
                          title: 'Reportes',
                          color: const Color(0xFF10B981),
                          onTap: () => _changeScreen( (adminProvider.currentUser?.isSuperAdmin ?? false) ? 1 : 5),
                        ),
                      ],
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

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
