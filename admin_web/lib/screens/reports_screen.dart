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
  String _selectedPeriod = 'month'; // 'day', 'week', 'month', 'year'
  int? _selectedCompanyId;
  String? _selectedRouteId;
  Map<String, dynamic>? _statsData;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).refreshAllData();
      _loadStats();
    });
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoadingStats = true;
    });

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final stats = await adminProvider.apiService.getComprehensiveStats(
        period: _selectedPeriod,
        companyId: _selectedCompanyId,
        routeId: _selectedRouteId,
      );
      setState(() {
        _statsData = stats;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStats = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar estadísticas: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
                                    ? 'Estadísticas y análisis de todas las empresas'
                                    : 'Estadísticas y análisis de tu empresa',
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
                                      value: 'routes',
                                      label: Text('Rutas'),
                                      icon: Icon(Icons.route, size: 16),
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
                        onPressed: _loadStats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filtros
              _buildFilters(adminProvider),
              const SizedBox(height: 24),

              // Content based on selected report
              if (_isLoadingStats)
                const Center(child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_statsData == null)
                const Center(child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Text('No hay datos disponibles'),
                ))
              else
                Consumer<AdminProvider>(
                  builder: (context, adminProvider, child) {
                    final isSuperAdmin =
                        adminProvider.currentUser?.isSuperAdmin ?? false;

                    if (_selectedReport == 'overview') {
                      return _buildOverviewReport(adminProvider, isSuperAdmin);
                    } else if (_selectedReport == 'companies' && isSuperAdmin) {
                      return _buildCompaniesReport(adminProvider);
                    } else {
                      return _buildRoutesReport(adminProvider);
                    }
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(AdminProvider adminProvider) {
    final isSuperAdmin = adminProvider.currentUser?.isSuperAdmin ?? false;
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                // Filtro por período
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Período',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'day', child: Text('Último día')),
                      DropdownMenuItem(value: 'week', child: Text('Última semana')),
                      DropdownMenuItem(value: 'month', child: Text('Último mes')),
                      DropdownMenuItem(value: 'year', child: Text('Último año')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPeriod = value;
                        });
                        _loadStats();
                      }
                    },
                  ),
                ),
                // Filtro por empresa (solo super_admin)
                if (isSuperAdmin) ...[
                  SizedBox(
                    width: 250,
                    child: DropdownButtonFormField<int?>(
                      value: _selectedCompanyId,
                      decoration: const InputDecoration(
                        labelText: 'Empresa',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todas las empresas'),
                        ),
                        ...adminProvider.empresas.map((empresa) =>
                            DropdownMenuItem<int?>(
                              value: empresa.id,
                              child: Text(empresa.name),
                            )),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCompanyId = value;
                        });
                        _loadStats();
                      },
                    ),
                  ),
                ],
                // Filtro por ruta
                SizedBox(
                  width: 250,
                  child: DropdownButtonFormField<String?>(
                    value: _selectedRouteId,
                    decoration: const InputDecoration(
                      labelText: 'Ruta',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas las rutas'),
                      ),
                      ...adminProvider.rutas.map((ruta) =>
                          DropdownMenuItem<String?>(
                            value: ruta.routeId,
                            child: Text(ruta.name),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedRouteId = value;
                      });
                      _loadStats();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewReport(AdminProvider adminProvider, bool isSuperAdmin) {
    if (_statsData == null) return const SizedBox.shrink();

    final summary = _statsData!['summary'] as Map<String, dynamic>? ?? {};
    final punctuality = _statsData!['punctuality'] as Map<String, dynamic>? ?? {};
    final passengers = _statsData!['passengers'] as Map<String, dynamic>? ?? {};
    final duration = _statsData!['duration'] as Map<String, dynamic>? ?? {};
    final byDay = _statsData!['byDay'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Métricas principales
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricCard(
              'Total Viajes',
              '${summary['total'] ?? 0}',
              Icons.directions_bus,
              Colors.blue,
              'En el período seleccionado',
            ),
            _buildMetricCard(
              'Completados',
              '${summary['completed'] ?? 0}',
              Icons.check_circle,
              Colors.green,
              '${summary['total'] != null && summary['total'] > 0 ? ((summary['completed'] ?? 0) / summary['total'] * 100).toStringAsFixed(1) : 0}% de completación',
            ),
            _buildMetricCard(
              'Puntualidad',
              '${(punctuality['punctualityRate'] ?? 0).toStringAsFixed(1)}%',
              Icons.access_time,
              Colors.orange,
              '${punctuality['onTime'] ?? 0} a tiempo, ${punctuality['delayed'] ?? 0} retrasados',
            ),
            _buildMetricCard(
              'Pasajeros',
              '${passengers['total'] ?? 0}',
              Icons.people,
              Colors.purple,
              'Promedio: ${(passengers['average'] ?? 0).toStringAsFixed(1)} por viaje',
            ),
            _buildMetricCard(
              'Duración Promedio',
              '${duration['average'] ?? 0} min',
              Icons.timer,
              Colors.teal,
              'Tiempo promedio de viaje',
            ),
            _buildMetricCard(
              'Tasa de Completación',
              '${(summary['completionRate'] ?? 0).toStringAsFixed(1)}%',
              Icons.percent,
              Colors.indigo,
              'Viajes completados vs programados',
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Gráfico de viajes por día
        const Text(
          'Viajes por Día (Últimos 30 días)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              height: 300,
              child: _buildTripsByDayChart(byDay),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Gráfico de estados de viajes
        const Text(
          'Distribución de Estados',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              height: 300,
              child: _buildStatusDistributionChart(summary),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Gráfico de puntualidad
        const Text(
          'Análisis de Puntualidad',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              height: 200,
              child: _buildPunctualityChart(punctuality),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Tabla de resumen
        const Text(
          'Resumen Detallado',
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
                const DataCell(Text('Total de viajes')),
                DataCell(Text('${summary['total'] ?? 0}')),
                DataCell(_buildStatusBadge('Normal', Colors.blue)),
              ]),
              DataRow(cells: [
                const DataCell(Text('Viajes completados')),
                DataCell(Text('${summary['completed'] ?? 0}')),
                DataCell(_buildStatusBadge('Completado', Colors.green)),
              ]),
              DataRow(cells: [
                const DataCell(Text('Viajes programados')),
                DataCell(Text('${summary['scheduled'] ?? 0}')),
                DataCell(_buildStatusBadge('Programado', Colors.orange)),
              ]),
              DataRow(cells: [
                const DataCell(Text('Viajes en progreso')),
                DataCell(Text('${summary['inProgress'] ?? 0}')),
                DataCell(_buildStatusBadge('En curso', Colors.blue)),
              ]),
              DataRow(cells: [
                const DataCell(Text('Viajes cancelados')),
                DataCell(Text('${summary['cancelled'] ?? 0}')),
                DataCell(_buildStatusBadge('Cancelado', Colors.red)),
              ]),
              DataRow(cells: [
                const DataCell(Text('Tasa de puntualidad')),
                DataCell(Text('${(punctuality['punctualityRate'] ?? 0).toStringAsFixed(1)}%')),
                DataCell(_buildStatusBadge(
                  (punctuality['punctualityRate'] ?? 0) >= 90 ? 'Excelente' : (punctuality['punctualityRate'] ?? 0) >= 70 ? 'Bueno' : 'Mejorar',
                  (punctuality['punctualityRate'] ?? 0) >= 90 ? Colors.green : (punctuality['punctualityRate'] ?? 0) >= 70 ? Colors.orange : Colors.red,
                )),
              ]),
              DataRow(cells: [
                const DataCell(Text('Retraso promedio')),
                DataCell(Text('${(punctuality['avgDelay'] ?? 0).toStringAsFixed(1)} min')),
                DataCell(_buildStatusBadge(
                  (punctuality['avgDelay'] ?? 0) <= 0 ? 'A tiempo' : 'Retrasado',
                  (punctuality['avgDelay'] ?? 0) <= 0 ? Colors.green : Colors.red,
                )),
              ]),
              DataRow(cells: [
                const DataCell(Text('Total de pasajeros')),
                DataCell(Text('${passengers['total'] ?? 0}')),
                DataCell(_buildStatusBadge('Transportados', Colors.purple)),
              ]),
              DataRow(cells: [
                const DataCell(Text('Pasajeros promedio por viaje')),
                DataCell(Text('${(passengers['average'] ?? 0).toStringAsFixed(1)}')),
                DataCell(_buildStatusBadge('Promedio', Colors.teal)),
              ]),
            ],
          ),
        ),
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
          'Comparación por Empresa',
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

  Widget _buildRoutesReport(AdminProvider adminProvider) {
    if (_statsData == null) return const SizedBox.shrink();

    final byRoute = _statsData!['byRoute'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Análisis por Rutas',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Gráfico de rutas más utilizadas
        if (byRoute.isNotEmpty) ...[
          const Text(
            'Rutas Más Utilizadas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                height: 400,
                child: _buildRoutesChart(byRoute, adminProvider),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],

        // Tabla de rutas
        const Text(
          'Estadísticas por Ruta',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Ruta')),
              DataColumn(label: Text('Total'), numeric: true),
              DataColumn(label: Text('Completados'), numeric: true),
              DataColumn(label: Text('Programados'), numeric: true),
              DataColumn(label: Text('Pasajeros'), numeric: true),
            ],
            rows: byRoute.map((route) {
              final routeData = route as Map<String, dynamic>;
              final routeId = routeData['routeId'] as String?;
              final routeName = routeId != null
                  ? adminProvider.rutas.firstWhere(
                      (r) => r.routeId == routeId,
                      orElse: () => adminProvider.rutas.first,
                    ).name
                  : 'Desconocida';
              return DataRow(
                cells: [
                  DataCell(Text(routeName)),
                  DataCell(Text('${routeData['total'] ?? 0}')),
                  DataCell(Text('${routeData['completed'] ?? 0}')),
                  DataCell(Text('${routeData['scheduled'] ?? 0}')),
                  DataCell(Text('${routeData['passengers'] ?? 0}')),
                ],
              );
            }).toList(),
          ),
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

  Widget _buildTripsByDayChart(List<dynamic> byDay) {
    if (byDay.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final spots = byDay.asMap().entries.map((entry) {
      final dayData = entry.value as Map<String, dynamic>;
      return FlSpot(
        entry.key.toDouble(),
        (dayData['completed'] ?? 0).toDouble(),
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 5 == 0 && value.toInt() < byDay.length) {
                  final dayData = byDay[value.toInt()] as Map<String, dynamic>;
                  final date = dayData['date'] as String? ?? '';
                  return Text(date.substring(5), style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: Colors.blue.withValues(alpha: 0.1)),
          ),
        ],
        minY: 0,
      ),
    );
  }

  Widget _buildStatusDistributionChart(Map<String, dynamic> summary) {
    final completed = (summary['completed'] ?? 0).toDouble();
    final scheduled = (summary['scheduled'] ?? 0).toDouble();
    final inProgress = (summary['inProgress'] ?? 0).toDouble();
    final cancelled = (summary['cancelled'] ?? 0).toDouble();

    if (completed + scheduled + inProgress + cancelled == 0) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    return PieChart(
      PieChartData(
        sections: [
          if (completed > 0)
            PieChartSectionData(
              value: completed,
              title: 'Completados\n${completed.toInt()}',
              color: Colors.green,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (scheduled > 0)
            PieChartSectionData(
              value: scheduled,
              title: 'Programados\n${scheduled.toInt()}',
              color: Colors.blue,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (inProgress > 0)
            PieChartSectionData(
              value: inProgress,
              title: 'En Progreso\n${inProgress.toInt()}',
              color: Colors.orange,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          if (cancelled > 0)
            PieChartSectionData(
              value: cancelled,
              title: 'Cancelados\n${cancelled.toInt()}',
              color: Colors.red,
              radius: 100,
              titleStyle: const TextStyle(
                fontSize: 12,
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

  Widget _buildPunctualityChart(Map<String, dynamic> punctuality) {
    final onTime = (punctuality['onTime'] ?? 0).toDouble();
    final delayed = (punctuality['delayed'] ?? 0).toDouble();

    if (onTime + delayed == 0) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (onTime + delayed) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() == 0) return const Text('A tiempo');
                if (value.toInt() == 1) return const Text('Retrasados');
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: onTime,
                color: Colors.green,
                width: 40,
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: delayed,
                color: Colors.red,
                width: 40,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoutesChart(List<dynamic> byRoute, AdminProvider adminProvider) {
    if (byRoute.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    // Ordenar por total y tomar los top 10
    final sortedRoutes = List<Map<String, dynamic>>.from(byRoute)
      ..sort((a, b) => (b['completed'] ?? 0).compareTo(a['completed'] ?? 0));
    final topRoutes = sortedRoutes.take(10).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: topRoutes.isEmpty ? 10 : (topRoutes.first['completed'] ?? 0) * 1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < topRoutes.length) {
                  final routeData = topRoutes[value.toInt()];
                  final routeId = routeData['routeId'] as String?;
                  if (routeId != null) {
                    try {
                      final route = adminProvider.rutas.firstWhere(
                        (r) => r.routeId == routeId,
                      );
                      return Text(
                        route.name.length > 10
                            ? '${route.name.substring(0, 10)}...'
                            : route.name,
                        style: const TextStyle(fontSize: 10),
                      );
                    } catch (e) {
                      return Text(routeId.substring(0, 8), style: const TextStyle(fontSize: 10));
                    }
                  }
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: topRoutes.asMap().entries.map((entry) {
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: (entry.value['completed'] ?? 0).toDouble(),
                color: Colors.blue,
                width: 20,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
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
}
