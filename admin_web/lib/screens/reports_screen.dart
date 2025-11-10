import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedReport = 'overview';

  Future<Map<String, dynamic>> _getPunctualityStats() async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      return await adminProvider.apiService.getPunctualityStats();
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> _getTripsStats() async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final trips = await adminProvider.apiService.getTrips();
      final completedTrips = trips.where((t) => t.status == 'completed').length;
      // Calcular promedio diario (simplificado)
      return {'dailyAverage': completedTrips ~/ 30}; // Aproximado
    } catch (e) {
      return {};
    }
  }

  Future<int> _getDriverTripsCount(int driverId) async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final trips = await adminProvider.apiService.getTripsByDriver(driverId);
      return trips.where((t) => t.status == 'completed').length;
    } catch (e) {
      return 0;
    }
  }

  Future<double> _getDriverWorkHours(int driverId) async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final trips = await adminProvider.apiService.getTripsByDriver(driverId);
      final completedTrips = trips
          .where((t) => t.status == 'completed' && t.durationMinutes != null);
      double totalMinutes = completedTrips.fold(
          0.0, (sum, trip) => sum + (trip.durationMinutes ?? 0).toDouble());
      return totalMinutes / 60; // Convertir a horas
    } catch (e) {
      return 0.0;
    }
  }

  Future<double> _getDriverRating(int driverId) async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final stats =
          await adminProvider.apiService.getDriverRatingStats(driverId);
      return stats['average'] ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).refreshAllData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        return SingleChildScrollView(
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
                      Consumer<AdminProvider>(
                        builder: (context, adminProvider, child) {
                          final isSuperAdmin =
                              adminProvider.currentUser?.isSuperAdmin ?? false;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isSuperAdmin
                                    ? 'Reportes del Sistema'
                                    : 'Reportes de la Empresa',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isSuperAdmin
                                    ? 'Estadísticas a gran escala de todas las empresas'
                                    : 'Estadísticas y métricas de tu empresa',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Consumer<AdminProvider>(
                        builder: (context, adminProvider, child) {
                          final isSuperAdmin =
                              adminProvider.currentUser?.isSuperAdmin ?? false;
                          return SegmentedButton<String>(
                            segments: isSuperAdmin
                                ? const [
                                    ButtonSegment(
                                      value: 'overview',
                                      label: Text('General'),
                                      icon: Icon(Icons.dashboard, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'companies',
                                      label: Text('Por Empresa'),
                                      icon: Icon(Icons.business, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'users',
                                      label: Text('Usuarios'),
                                      icon: Icon(Icons.people, size: 16),
                                    ),
                                  ]
                                : const [
                                    ButtonSegment(
                                      value: 'overview',
                                      label: Text('General'),
                                      icon: Icon(Icons.dashboard, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'routes',
                                      label: Text('Rutas'),
                                      icon: Icon(Icons.route, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'drivers',
                                      label: Text('Conductores'),
                                      icon: Icon(Icons.drive_eta, size: 16),
                                    ),
                                  ],
                            selected: {_selectedReport},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _selectedReport = newSelection.first;
                              });
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _exportReport,
                        icon: const Icon(Icons.download),
                        label: const Text('Exportar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Content based on selected report and role
              Consumer<AdminProvider>(
                builder: (context, adminProvider, child) {
                  final isSuperAdmin =
                      adminProvider.currentUser?.isSuperAdmin ?? false;

                  if (isSuperAdmin) {
                    // Reportes para Super Admin
                    if (_selectedReport == 'overview') {
                      return _buildSuperAdminOverviewReport(adminProvider);
                    } else if (_selectedReport == 'companies') {
                      return _buildCompaniesReport(adminProvider);
                    } else {
                      return _buildUsersReport(adminProvider);
                    }
                  } else {
                    // Reportes para Company Admin
                    if (_selectedReport == 'overview') {
                      return _buildOverviewReport(adminProvider);
                    } else if (_selectedReport == 'routes') {
                      return _buildRoutesReport(adminProvider);
                    } else {
                      return _buildDriversReport(adminProvider);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOverviewReport(AdminProvider adminProvider) {
    final stats = adminProvider.estadisticas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Métricas principales
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Buses',
              '${stats['totalBuses'] ?? 0}',
              Icons.directions_bus,
              Colors.blue,
              '+5% vs mes anterior',
            ),
            _buildMetricCard(
              'Buses Activos',
              '${stats['busesActivos'] ?? 0}',
              Icons.check_circle,
              Colors.green,
              '${((stats['busesActivos'] ?? 0) / (stats['totalBuses'] ?? 1) * 100).toStringAsFixed(1)}% operativos',
            ),
            _buildMetricCard(
              'Total Rutas',
              '${stats['totalRutas'] ?? 0}',
              Icons.route,
              Colors.purple,
              'Todas activas',
            ),
            _buildMetricCard(
              'Conductores',
              '${stats['conductores'] ?? 0}',
              Icons.drive_eta,
              Colors.orange,
              'Personal activo',
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Gráfico de distribución
        const Text(
          'Distribución de Buses',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              height: 250,
              child: _buildPieChart(stats),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Tabla de resumen
        const Text(
          'Resumen de Actividad',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Métrica')),
              DataColumn(label: Text('Valor')),
              DataColumn(label: Text('Estado')),
            ],
            rows: [
              DataRow(cells: [
                const DataCell(Text('Recorridos completados (hoy)')),
                const DataCell(Text('0')),
                DataCell(_buildStatusBadge('Normal', Colors.green)),
              ]),
              DataRow(cells: [
                const DataCell(Text('Buses en mantenimiento')),
                DataCell(Text('${stats['busesInactivos'] ?? 0}')),
                DataCell(_buildStatusBadge('Bajo', Colors.green)),
              ]),
              DataRow(cells: [
                const DataCell(Text('Promedio de recorridos/día')),
                DataCell(
                  FutureBuilder<Map<String, dynamic>>(
                    future: _getTripsStats(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final dailyAvg = snapshot.data!['dailyAverage'] ?? 0;
                        return Text(dailyAvg.toString());
                      }
                      return const Text('0');
                    },
                  ),
                ),
                DataCell(_buildStatusBadge('Normal', Colors.green)),
              ]),
              DataRow(cells: [
                const DataCell(Text('Puntualidad promedio')),
                DataCell(
                  FutureBuilder<Map<String, dynamic>>(
                    future: _getPunctualityStats(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final punctuality =
                            snapshot.data!['overallPunctuality'] ?? 0.0;
                        return Text('${punctuality.toStringAsFixed(1)}%');
                      }
                      return const Text('N/A');
                    },
                  ),
                ),
                DataCell(
                  FutureBuilder<Map<String, dynamic>>(
                    future: _getPunctualityStats(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final punctuality =
                            snapshot.data!['overallPunctuality'] ?? 0.0;
                        Color color = punctuality >= 90
                            ? Colors.green
                            : punctuality >= 70
                                ? Colors.orange
                                : Colors.red;
                        String label = punctuality >= 90
                            ? 'Excelente'
                            : punctuality >= 70
                                ? 'Bueno'
                                : 'Mejorar';
                        return _buildStatusBadge(label, color);
                      }
                      return _buildStatusBadge('Pendiente', Colors.grey);
                    },
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoutesReport(AdminProvider adminProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Análisis por Rutas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Tabla de rutas
        Card(
          elevation: 2,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Ruta')),
              DataColumn(label: Text('Buses Asignados')),
              DataColumn(label: Text('Recorridos (Hoy)')),
              DataColumn(label: Text('Demanda')),
            ],
            rows: adminProvider.rutas.map((ruta) {
              return DataRow(cells: [
                DataCell(Text(ruta.name)),
                const DataCell(Text('0')),
                const DataCell(Text('0')),
                DataCell(_buildDemandIndicator(0)),
              ]);
            }).toList(),
          ),
        ),

        const SizedBox(height: 32),

        // Rutas más utilizadas
        const Text(
          'Rutas Más Utilizadas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: adminProvider.rutas.take(5).map((ruta) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(child: Text(ruta.name)),
                      SizedBox(
                        width: 200,
                        child: LinearProgressIndicator(
                          value: 0.0,
                          backgroundColor: Colors.grey[200],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text('0 viajes'),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDriversReport(AdminProvider adminProvider) {
    final conductores =
        adminProvider.usuarios.where((u) => u.role == 'driver').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Desempeño de Conductores',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Tabla de conductores
        Card(
          elevation: 2,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Conductor')),
              DataColumn(label: Text('Recorridos')),
              DataColumn(label: Text('Horas Trabajadas')),
              DataColumn(label: Text('Calificación')),
            ],
            rows: conductores.map((conductor) {
              return DataRow(cells: [
                DataCell(Text(conductor.name)),
                DataCell(
                  FutureBuilder<int>(
                    future: _getDriverTripsCount(conductor.id),
                    builder: (context, snapshot) {
                      return Text('${snapshot.data ?? 0}');
                    },
                  ),
                ),
                DataCell(
                  FutureBuilder<double>(
                    future: _getDriverWorkHours(conductor.id),
                    builder: (context, snapshot) {
                      return Text(
                          '${(snapshot.data ?? 0).toStringAsFixed(1)}h');
                    },
                  ),
                ),
                DataCell(
                  FutureBuilder<double>(
                    future: _getDriverRating(conductor.id),
                    builder: (context, snapshot) {
                      final rating = snapshot.data ?? 0.0;
                      return _buildRatingStars(rating.round());
                    },
                  ),
                ),
              ]);
            }).toList(),
          ),
        ),

        const SizedBox(height: 32),

        // Top conductores
        const Text(
          'Conductores Destacados',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: conductores.take(3).map((conductor) {
            return Card(
              elevation: 2,
              child: Container(
                width: 250,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        conductor.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      conductor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    _buildRatingStars(0),
                    const SizedBox(height: 12),
                    const Text('0 recorridos completados'),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Card(
      elevation: 2,
      child: Container(
        width: 250,
        padding: const EdgeInsets.all(20),
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
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, dynamic> stats) {
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: (stats['busesActivos'] ?? 0).toDouble(),
            title: 'Activos',
            color: Colors.green,
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          PieChartSectionData(
            value: (stats['busesInactivos'] ?? 0).toDouble(),
            title: 'Inactivos',
            color: Colors.grey,
            radius: 100,
            titleStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 40,
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDemandIndicator(int level) {
    Color color;
    String label;

    if (level > 70) {
      color = Colors.red;
      label = 'Alta';
    } else if (level > 40) {
      color = Colors.orange;
      label = 'Media';
    } else {
      color = Colors.green;
      label = 'Baja';
    }

    return Row(
      children: [
        Icon(Icons.trending_up, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }

  // === REPORTES PARA SUPER ADMIN ===

  Widget _buildSuperAdminOverviewReport(AdminProvider adminProvider) {
    final stats = adminProvider.estadisticas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Métricas principales del sistema
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Empresas',
              '${stats['totalEmpresas'] ?? 0}',
              Icons.business,
              Colors.deepPurple,
              'Empresas registradas',
            ),
            _buildMetricCard(
              'Total Usuarios',
              '${stats['totalUsuarios'] ?? 0}',
              Icons.people,
              Colors.indigo,
              'En todo el sistema',
            ),
            _buildMetricCard(
              'Total Buses',
              '${stats['totalBuses'] ?? 0}',
              Icons.directions_bus,
              Colors.blue,
              'Flota total',
            ),
            _buildMetricCard(
              'Buses Activos',
              '${stats['busesActivos'] ?? 0}',
              Icons.check_circle,
              Colors.green,
              '${((stats['busesActivos'] ?? 0) / (stats['totalBuses'] ?? 1) * 100).toStringAsFixed(1)}% operativos',
            ),
            _buildMetricCard(
              'Total Rutas',
              '${stats['totalRutas'] ?? 0}',
              Icons.route,
              Colors.purple,
              'Rutas activas',
            ),
            _buildMetricCard(
              'Conductores',
              '${stats['conductores'] ?? 0}',
              Icons.drive_eta,
              Colors.orange,
              'Personal activo',
            ),
            _buildMetricCard(
              'Administradores',
              '${stats['administradores'] ?? 0}',
              Icons.admin_panel_settings,
              Colors.teal,
              'Super + Company Admins',
            ),
            _buildMetricCard(
              'Pasajeros',
              '${stats['pasajeros'] ?? 0}',
              Icons.person,
              Colors.cyan,
              'Usuarios registrados',
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Resumen por empresa
        const Text(
          'Resumen por Empresa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (stats['statsPorEmpresa'] != null)
          ...(stats['statsPorEmpresa'] as Map<String, dynamic>)
              .entries
              .map((entry) {
            final empresaStats = entry.value as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        Text(
                          entry.key,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 24,
                      runSpacing: 12,
                      children: [
                        _buildMiniStat('Buses',
                            '${empresaStats['totalBuses'] ?? 0}', Colors.blue),
                        _buildMiniStat(
                            'Activos',
                            '${empresaStats['busesActivos'] ?? 0}',
                            Colors.green),
                        _buildMiniStat(
                            'Rutas',
                            '${empresaStats['totalRutas'] ?? 0}',
                            Colors.purple),
                        _buildMiniStat(
                            'Usuarios',
                            '${empresaStats['totalUsuarios'] ?? 0}',
                            Colors.indigo),
                        _buildMiniStat(
                            'Conductores',
                            '${empresaStats['conductores'] ?? 0}',
                            Colors.orange),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildCompaniesReport(AdminProvider adminProvider) {
    final stats = adminProvider.estadisticas;
    final statsPorEmpresa = stats['statsPorEmpresa'] as Map<String, dynamic>?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Análisis Comparativo por Empresa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        if (statsPorEmpresa != null && statsPorEmpresa.isNotEmpty)
          Card(
            elevation: 2,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Empresa')),
                DataColumn(label: Text('Buses'), numeric: true),
                DataColumn(label: Text('Buses Activos'), numeric: true),
                DataColumn(label: Text('Rutas'), numeric: true),
                DataColumn(label: Text('Usuarios'), numeric: true),
                DataColumn(label: Text('Conductores'), numeric: true),
              ],
              rows: statsPorEmpresa.entries.map((entry) {
                final empresaStats = entry.value as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(Text(entry.key)),
                    DataCell(Text('${empresaStats['totalBuses'] ?? 0}')),
                    DataCell(Text('${empresaStats['busesActivos'] ?? 0}')),
                    DataCell(Text('${empresaStats['totalRutas'] ?? 0}')),
                    DataCell(Text('${empresaStats['totalUsuarios'] ?? 0}')),
                    DataCell(Text('${empresaStats['conductores'] ?? 0}')),
                  ],
                );
              }).toList(),
            ),
          )
        else
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('No hay datos de empresas disponibles'),
            ),
          ),
      ],
    );
  }

  Widget _buildUsersReport(AdminProvider adminProvider) {
    final stats = adminProvider.estadisticas;
    final usuarios = adminProvider.usuarios;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Distribución de usuarios por rol
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Usuarios',
              '${stats['totalUsuarios'] ?? 0}',
              Icons.people,
              Colors.indigo,
              'En todo el sistema',
            ),
            _buildMetricCard(
              'Super Admins',
              '${usuarios.where((u) => u.role == 'super_admin').length}',
              Icons.admin_panel_settings,
              Colors.orange,
              'Administradores del sistema',
            ),
            _buildMetricCard(
              'Company Admins',
              '${usuarios.where((u) => u.role == 'company_admin').length}',
              Icons.business_center,
              Colors.blue,
              'Administradores de empresa',
            ),
            _buildMetricCard(
              'Conductores',
              '${stats['conductores'] ?? 0}',
              Icons.drive_eta,
              Colors.orange,
              'Personal activo',
            ),
            _buildMetricCard(
              'Pasajeros',
              '${stats['pasajeros'] ?? 0}',
              Icons.person,
              Colors.cyan,
              'Usuarios finales',
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Distribución por empresa
        const Text(
          'Usuarios por Empresa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Empresa')),
              DataColumn(label: Text('Total Usuarios'), numeric: true),
              DataColumn(label: Text('Company Admins'), numeric: true),
              DataColumn(label: Text('Conductores'), numeric: true),
              DataColumn(label: Text('Pasajeros'), numeric: true),
            ],
            rows: adminProvider.empresas.map((empresa) {
              final usuariosEmpresa =
                  usuarios.where((u) => u.companyId == empresa.id).toList();
              return DataRow(
                cells: [
                  DataCell(Text(empresa.name)),
                  DataCell(Text('${usuariosEmpresa.length}')),
                  DataCell(Text(
                      '${usuariosEmpresa.where((u) => u.role == 'company_admin').length}')),
                  DataCell(Text(
                      '${usuariosEmpresa.where((u) => u.role == 'driver').length}')),
                  DataCell(Text(
                      '${usuariosEmpresa.where((u) => u.role == 'user').length}')),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportando reporte...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
