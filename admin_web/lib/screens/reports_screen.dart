import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/user_report.dart';
import '../models/rating.dart';
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

  // Datos adicionales para KPIs
  List<UserReport> _userReports = [];
  List<Rating> _ratings = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).refreshAllData();
      _loadStats();
      _loadAdditionalData();
    });
  }

  Future<void> _loadAdditionalData() async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final reports = await adminProvider.apiService.getUserReports();
      final ratings = await adminProvider.apiService.getRatings();

      if (mounted) {
        setState(() {
          _userReports = reports;
          _ratings = ratings;
        });
      }
    } catch (e) {
      print('⚠️ Error al cargar datos adicionales: $e');
    }
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
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(48.0),
                  child: CircularProgressIndicator(),
                ))
              else if (_statsData == null)
                const Center(
                    child: Padding(
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
                    initialValue: _selectedPeriod,
                    decoration: const InputDecoration(
                      labelText: 'Período',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'day', child: Text('Último día')),
                      DropdownMenuItem(
                          value: 'week', child: Text('Última semana')),
                      DropdownMenuItem(
                          value: 'month', child: Text('Último mes')),
                      DropdownMenuItem(
                          value: 'year', child: Text('Último año')),
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
                      initialValue: _selectedCompanyId,
                      decoration: const InputDecoration(
                        labelText: 'Empresa',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Todas las empresas'),
                        ),
                        ...adminProvider.empresas
                            .map((empresa) => DropdownMenuItem<int?>(
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
                    initialValue: _selectedRouteId,
                    decoration: const InputDecoration(
                      labelText: 'Ruta',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Todas las rutas'),
                      ),
                      ...adminProvider.rutas
                          .map((ruta) => DropdownMenuItem<String?>(
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
    final punctuality =
        _statsData!['punctuality'] as Map<String, dynamic>? ?? {};
    final passengers = _statsData!['passengers'] as Map<String, dynamic>? ?? {};
    final byDay = _statsData!['byDay'] as List<dynamic>? ?? [];

    // Calcular KPIs adicionales
    final busUtilization = _calculateBusUtilization(adminProvider);
    final reportAnalysis = _analyzeReports(_userReports);
    final ratingAnalysis = _analyzeRatings(_ratings);
    final responseTime = _calculateAverageResponseTime(_userReports);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // KPIs principales - Eficiencia Operativa
        const Text(
          '📊 Indicadores de Eficiencia Operativa',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildEnhancedMetricCard(
              'Tasa de Utilización de Buses',
              '${busUtilization['utilizationRate']}%',
              Icons.speed,
              _getStatusColor(busUtilization['utilizationRate'] as double),
              '${busUtilization['activeBuses']} activos / ${busUtilization['totalBuses']} totales',
              'Optimización de recursos',
            ),
            _buildEnhancedMetricCard(
              'Puntualidad del Servicio',
              '${(punctuality['punctualityRate'] ?? 0).toStringAsFixed(1)}%',
              Icons.access_time,
              _getPunctualityColor(
                  punctuality['punctualityRate'] as double? ?? 0),
              '${punctuality['onTime'] ?? 0} a tiempo, ${punctuality['delayed'] ?? 0} retrasados',
              'Cumplimiento de horarios',
            ),
            _buildEnhancedMetricCard(
              'Tasa de Completación',
              '${(summary['completionRate'] ?? 0).toStringAsFixed(1)}%',
              Icons.check_circle_outline,
              _getCompletionColor(summary['completionRate'] as double? ?? 0),
              '${summary['completed'] ?? 0} de ${summary['total'] ?? 0} viajes',
              'Confiabilidad del servicio',
            ),
            _buildEnhancedMetricCard(
              'Ocupación Promedio',
              '${(passengers['average'] ?? 0).toStringAsFixed(1)}',
              Icons.event_seat,
              _getCapacityColor((passengers['average'] as double? ?? 0)),
              'Pasajeros por viaje en promedio',
              'Optimización de capacidad',
            ),
          ],
        ),

        const SizedBox(height: 32),

        // KPIs principales - Satisfacción del Cliente
        const Text(
          '⭐ Satisfacción del Cliente',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildEnhancedMetricCard(
              'Calificación General',
              ratingAnalysis['averageRating'] != null
                  ? '${ratingAnalysis['averageRating']!.toStringAsFixed(1)}/5.0'
                  : 'N/A',
              Icons.star,
              _getRatingColor(ratingAnalysis['averageRating'] as double?),
              ratingAnalysis['totalRatings'] != null &&
                      ratingAnalysis['totalRatings']! > 0
                  ? '${ratingAnalysis['totalRatings']} calificaciones'
                  : 'Sin calificaciones',
              'Percepción del servicio',
            ),
            _buildEnhancedMetricCard(
              'Puntualidad (Cliente)',
              ratingAnalysis['avgPunctuality'] != null
                  ? '${ratingAnalysis['avgPunctuality']!.toStringAsFixed(1)}/5.0'
                  : 'N/A',
              Icons.schedule,
              _getRatingColor(ratingAnalysis['avgPunctuality'] as double?),
              'Basado en feedback',
              'Opinión sobre horarios',
            ),
            _buildEnhancedMetricCard(
              'Servicio',
              ratingAnalysis['avgService'] != null
                  ? '${ratingAnalysis['avgService']!.toStringAsFixed(1)}/5.0'
                  : 'N/A',
              Icons.room_service,
              _getRatingColor(ratingAnalysis['avgService'] as double?),
              'Atención y calidad',
              'Experiencia del cliente',
            ),
            _buildEnhancedMetricCard(
              'Seguridad',
              ratingAnalysis['avgSafety'] != null
                  ? '${ratingAnalysis['avgSafety']!.toStringAsFixed(1)}/5.0'
                  : 'N/A',
              Icons.security,
              _getRatingColor(ratingAnalysis['avgSafety'] as double?),
              'Percepción de seguridad',
              'Confianza del cliente',
            ),
          ],
        ),

        const SizedBox(height: 32),

        // KPIs principales - Gestión de Problemas
        const Text(
          '⚠️ Gestión de Problemas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildEnhancedMetricCard(
              'Reportes Pendientes',
              '${reportAnalysis['pendingReports']}',
              Icons.report_problem,
              reportAnalysis['pendingReports'] > 10
                  ? Colors.red
                  : Colors.orange,
              '${reportAnalysis['urgentReports']} urgentes, ${reportAnalysis['highPriorityReports']} alta prioridad',
              'Requieren atención',
            ),
            _buildEnhancedMetricCard(
              'Tiempo Promedio de Respuesta',
              responseTime['averageHours'] != null
                  ? '${responseTime['averageHours']!.toStringAsFixed(1)}h'
                  : 'N/A',
              Icons.timer_outlined,
              _getResponseTimeColor(responseTime['averageHours'] as double?),
              responseTime['averageHours'] != null &&
                      responseTime['averageHours']! < 24
                  ? 'Excelente respuesta'
                  : 'Necesita mejorar',
              'Eficiencia de atención',
            ),
            _buildEnhancedMetricCard(
              'Tasa de Resolución',
              reportAnalysis['resolutionRate'] != null
                  ? '${reportAnalysis['resolutionRate']!.toStringAsFixed(1)}%'
                  : '0%',
              Icons.task_alt,
              _getResolutionColor(
                  reportAnalysis['resolutionRate'] as double? ?? 0),
              '${reportAnalysis['resolvedReports']} resueltos / ${reportAnalysis['totalReports']} totales',
              'Problemas solucionados',
            ),
            _buildEnhancedMetricCard(
              'Problemas por Tipo',
              '${reportAnalysis['topIssueType'] ?? "N/A"}',
              Icons.category,
              Colors.indigo,
              'Tipo más reportado',
              'Análisis de problemas',
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Gráficos de Análisis
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gráfico de viajes por día
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📈 Tendencia de Viajes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        height: 350,
                        child: _buildTripsByDayChart(byDay),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Gráfico de distribución de estados
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Estado de Viajes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        height: 350,
                        child: _buildStatusDistributionChart(summary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Gráfico de Análisis de Reportes
        const Text(
          '⚠️ Análisis de Reportes de Problemas',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Distribución por tipo
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reportes por Tipo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: _buildReportsByTypeChart(_userReports),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Distribución por prioridad
            Expanded(
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reportes por Prioridad',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: _buildReportsByPriorityChart(_userReports),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // Gráfico de Calificaciones
        const Text(
          '⭐ Análisis de Calificaciones',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Calificaciones por Categoría',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: _buildRatingsByCategoryChart(_ratings),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Gráfico de Puntualidad
        const Text(
          '⏰ Análisis de Puntualidad',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              height: 250,
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
                DataCell(Text(
                    '${(punctuality['punctualityRate'] ?? 0).toStringAsFixed(1)}%')),
                DataCell(_buildStatusBadge(
                  (punctuality['punctualityRate'] ?? 0) >= 90
                      ? 'Excelente'
                      : (punctuality['punctualityRate'] ?? 0) >= 70
                          ? 'Bueno'
                          : 'Mejorar',
                  (punctuality['punctualityRate'] ?? 0) >= 90
                      ? Colors.green
                      : (punctuality['punctualityRate'] ?? 0) >= 70
                          ? Colors.orange
                          : Colors.red,
                )),
              ]),
              DataRow(cells: [
                const DataCell(Text('Retraso promedio')),
                DataCell(Text(
                    '${(punctuality['avgDelay'] ?? 0).toStringAsFixed(1)} min')),
                DataCell(_buildStatusBadge(
                  (punctuality['avgDelay'] ?? 0) <= 0
                      ? 'A tiempo'
                      : 'Retrasado',
                  (punctuality['avgDelay'] ?? 0) <= 0
                      ? Colors.green
                      : Colors.red,
                )),
              ]),
              DataRow(cells: [
                const DataCell(Text('Total de pasajeros')),
                DataCell(Text('${passengers['total'] ?? 0}')),
                DataCell(_buildStatusBadge('Transportados', Colors.purple)),
              ]),
              DataRow(cells: [
                const DataCell(Text('Pasajeros promedio por viaje')),
                DataCell(
                    Text('${(passengers['average'] ?? 0).toStringAsFixed(1)}')),
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
                  ? adminProvider.rutas
                      .firstWhere(
                        (r) => r.routeId == routeId,
                        orElse: () => adminProvider.rutas.first,
                      )
                      .name
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
                  return Text(date.substring(5),
                      style: const TextStyle(fontSize: 10));
                }
                return const Text('');
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
                show: true, color: Colors.blue.withValues(alpha: 0.1)),
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
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
        maxY:
            topRoutes.isEmpty ? 10 : (topRoutes.first['completed'] ?? 0) * 1.2,
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
                      return Text(routeId.substring(0, 8),
                          style: const TextStyle(fontSize: 10));
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
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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

  // === MÉTODOS PARA CALCULAR KPIs ===

  /// Calcula la tasa de utilización de buses
  Map<String, dynamic> _calculateBusUtilization(AdminProvider adminProvider) {
    final buses = adminProvider.buses;
    final totalBuses = buses.length;
    final activeBuses = buses
        .where((b) => b.status == 'active' || b.status == 'en_ruta')
        .length;

    final utilizationRate =
        totalBuses > 0 ? (activeBuses / totalBuses * 100) : 0.0;

    return {
      'totalBuses': totalBuses,
      'activeBuses': activeBuses,
      'utilizationRate': utilizationRate,
    };
  }

  /// Analiza los reportes de usuarios
  Map<String, dynamic> _analyzeReports(List<UserReport> reports) {
    if (reports.isEmpty) {
      return {
        'totalReports': 0,
        'pendingReports': 0,
        'resolvedReports': 0,
        'urgentReports': 0,
        'highPriorityReports': 0,
        'resolutionRate': 0.0,
        'topIssueType': 'N/A',
      };
    }

    final pending = reports.where((r) => r.status == 'pending').length;
    final resolved = reports.where((r) => r.status == 'resolved').length;
    final urgent = reports.where((r) => r.priority == 'urgent').length;
    final highPriority = reports.where((r) => r.priority == 'high').length;

    // Contar reportes por tipo
    final typeCount = <String, int>{};
    for (var report in reports) {
      typeCount[report.type] = (typeCount[report.type] ?? 0) + 1;
    }
    final topIssueType = typeCount.isEmpty
        ? 'N/A'
        : typeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final resolutionRate =
        reports.isNotEmpty ? (resolved / reports.length * 100) : 0.0;

    return {
      'totalReports': reports.length,
      'pendingReports': pending,
      'resolvedReports': resolved,
      'urgentReports': urgent,
      'highPriorityReports': highPriority,
      'resolutionRate': resolutionRate,
      'topIssueType': topIssueType,
    };
  }

  /// Analiza las calificaciones de usuarios
  Map<String, dynamic> _analyzeRatings(List<Rating> ratings) {
    if (ratings.isEmpty) {
      return {
        'totalRatings': 0,
        'averageRating': null,
        'avgPunctuality': null,
        'avgService': null,
        'avgCleanliness': null,
        'avgSafety': null,
      };
    }

    final avgRating =
        ratings.map((r) => r.rating).reduce((a, b) => a + b) / ratings.length;

    final punctualityRatings = ratings
        .where((r) => r.punctualityRating != null)
        .map((r) => r.punctualityRating!)
        .toList();
    final avgPunctuality = punctualityRatings.isNotEmpty
        ? punctualityRatings.reduce((a, b) => a + b) / punctualityRatings.length
        : null;

    final serviceRatings = ratings
        .where((r) => r.serviceRating != null)
        .map((r) => r.serviceRating!)
        .toList();
    final avgService = serviceRatings.isNotEmpty
        ? serviceRatings.reduce((a, b) => a + b) / serviceRatings.length
        : null;

    final cleanlinessRatings = ratings
        .where((r) => r.cleanlinessRating != null)
        .map((r) => r.cleanlinessRating!)
        .toList();
    final avgCleanliness = cleanlinessRatings.isNotEmpty
        ? cleanlinessRatings.reduce((a, b) => a + b) / cleanlinessRatings.length
        : null;

    final safetyRatings = ratings
        .where((r) => r.safetyRating != null)
        .map((r) => r.safetyRating!)
        .toList();
    final avgSafety = safetyRatings.isNotEmpty
        ? safetyRatings.reduce((a, b) => a + b) / safetyRatings.length
        : null;

    return {
      'totalRatings': ratings.length,
      'averageRating': avgRating,
      'avgPunctuality': avgPunctuality,
      'avgService': avgService,
      'avgCleanliness': avgCleanliness,
      'avgSafety': avgSafety,
    };
  }

  /// Calcula el tiempo promedio de respuesta a reportes
  Map<String, dynamic> _calculateAverageResponseTime(List<UserReport> reports) {
    final reviewedReports = reports.where((r) => r.reviewedAt != null).toList();

    if (reviewedReports.isEmpty) {
      return {
        'averageHours': null,
        'averageDays': null,
      };
    }

    double totalHours = 0;
    for (var report in reviewedReports) {
      final difference = report.reviewedAt!.difference(report.createdAt);
      totalHours += difference.inHours.toDouble();
    }

    final averageHours = totalHours / reviewedReports.length;
    final averageDays = averageHours / 24;

    return {
      'averageHours': averageHours,
      'averageDays': averageDays,
    };
  }

  // === MÉTODOS PARA COLORES SEGÚN KPIs ===

  Color _getStatusColor(double value) {
    if (value >= 80) return Colors.green;
    if (value >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _getPunctualityColor(double value) {
    if (value >= 90) return Colors.green;
    if (value >= 70) return Colors.orange;
    return Colors.red;
  }

  Color _getCompletionColor(double value) {
    if (value >= 95) return Colors.green;
    if (value >= 80) return Colors.orange;
    return Colors.red;
  }

  Color _getCapacityColor(double value) {
    // Asumiendo capacidad promedio de 50 pasajeros
    final capacityPercent = (value / 50) * 100;
    if (capacityPercent >= 80)
      return Colors.orange; // Muy lleno, necesita optimizar
    if (capacityPercent >= 60) return Colors.green; // Óptimo
    return Colors.blue; // Bajo, puede mejorar utilización
  }

  Color _getRatingColor(double? value) {
    if (value == null) return Colors.grey;
    if (value >= 4.5) return Colors.green;
    if (value >= 3.5) return Colors.orange;
    return Colors.red;
  }

  Color _getResponseTimeColor(double? value) {
    if (value == null) return Colors.grey;
    if (value <= 24) return Colors.green; // < 24 horas
    if (value <= 48) return Colors.orange; // < 48 horas
    return Colors.red; // > 48 horas
  }

  Color _getResolutionColor(double value) {
    if (value >= 80) return Colors.green;
    if (value >= 60) return Colors.orange;
    return Colors.red;
  }

  // === TARJETA DE MÉTRICA MEJORADA ===

  Widget _buildEnhancedMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
    String insight,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'KPI',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, size: 16, color: color),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontStyle: FontStyle.italic,
                      ),
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

  // === GRÁFICOS ADICIONALES PARA REPORTES Y RATINGS ===

  /// Gráfico de reportes por tipo
  Widget _buildReportsByTypeChart(List<UserReport> reports) {
    if (reports.isEmpty) {
      return const Center(child: Text('No hay reportes disponibles'));
    }

    final typeCount = <String, int>{};
    for (var report in reports) {
      typeCount[report.type] = (typeCount[report.type] ?? 0) + 1;
    }

    if (typeCount.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final colors = {
      'complaint': Colors.red,
      'issue': Colors.orange,
      'suggestion': Colors.blue,
      'compliment': Colors.green,
      'other': Colors.grey,
    };

    final sections = typeCount.entries.map((entry) {
      final type = entry.key;
      final count = entry.value;
      final total = typeCount.values.reduce((a, b) => a + b);
      final percentage = (count / total * 100);

      return PieChartSectionData(
        value: count.toDouble(),
        title:
            '${_formatReportType(type)}\n${count}\n(${percentage.toStringAsFixed(1)}%)',
        color: colors[type] ?? Colors.grey,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 50,
      ),
    );
  }

  /// Gráfico de reportes por prioridad
  Widget _buildReportsByPriorityChart(List<UserReport> reports) {
    if (reports.isEmpty) {
      return const Center(child: Text('No hay reportes disponibles'));
    }

    final priorityCount = <String, int>{};
    for (var report in reports) {
      priorityCount[report.priority] =
          (priorityCount[report.priority] ?? 0) + 1;
    }

    if (priorityCount.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final colors = {
      'urgent': Colors.red,
      'high': Colors.orange,
      'medium': Colors.blue,
      'low': Colors.green,
    };

    final sections = priorityCount.entries.map((entry) {
      final priority = entry.key;
      final count = entry.value;
      final total = priorityCount.values.reduce((a, b) => a + b);
      final percentage = (count / total * 100);

      return PieChartSectionData(
        value: count.toDouble(),
        title:
            '${_formatPriority(priority)}\n${count}\n(${percentage.toStringAsFixed(1)}%)',
        color: colors[priority] ?? Colors.grey,
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        sectionsSpace: 2,
        centerSpaceRadius: 50,
      ),
    );
  }

  /// Gráfico de calificaciones por categoría
  Widget _buildRatingsByCategoryChart(List<Rating> ratings) {
    if (ratings.isEmpty) {
      return const Center(child: Text('No hay calificaciones disponibles'));
    }

    final categories = <String, double>{};

    // Calcular promedios por categoría
    final punctualityRatings = ratings
        .where((r) => r.punctualityRating != null)
        .map((r) => r.punctualityRating!)
        .toList();
    if (punctualityRatings.isNotEmpty) {
      categories['Puntualidad'] = punctualityRatings.reduce((a, b) => a + b) /
          punctualityRatings.length;
    }

    final serviceRatings = ratings
        .where((r) => r.serviceRating != null)
        .map((r) => r.serviceRating!)
        .toList();
    if (serviceRatings.isNotEmpty) {
      categories['Servicio'] =
          serviceRatings.reduce((a, b) => a + b) / serviceRatings.length;
    }

    final cleanlinessRatings = ratings
        .where((r) => r.cleanlinessRating != null)
        .map((r) => r.cleanlinessRating!)
        .toList();
    if (cleanlinessRatings.isNotEmpty) {
      categories['Limpieza'] = cleanlinessRatings.reduce((a, b) => a + b) /
          cleanlinessRatings.length;
    }

    final safetyRatings = ratings
        .where((r) => r.safetyRating != null)
        .map((r) => r.safetyRating!)
        .toList();
    if (safetyRatings.isNotEmpty) {
      categories['Seguridad'] =
          safetyRatings.reduce((a, b) => a + b) / safetyRatings.length;
    }

    if (categories.isEmpty) {
      return const Center(child: Text('No hay datos disponibles'));
    }

    final colors = {
      'Puntualidad': Colors.blue,
      'Servicio': Colors.purple,
      'Limpieza': Colors.green,
      'Seguridad': Colors.orange,
    };

    final bars = categories.entries.map((entry) {
      final category = entry.key;
      final rating = entry.value;

      return BarChartGroupData(
        x: categories.keys.toList().indexOf(category),
        barRods: [
          BarChartRodData(
            toY: rating,
            color: colors[category] ?? Colors.grey,
            width: 40,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 5.5,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < categories.length) {
                  final category = categories.keys.toList()[value.toInt()];
                  return Text(
                    category.length > 10 ? category.substring(0, 10) : category,
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
              reservedSize: 40,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() <= 5) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        barGroups: bars,
        gridData: const FlGridData(show: true),
      ),
    );
  }

  /// Formatea el tipo de reporte para mostrar
  String _formatReportType(String type) {
    switch (type) {
      case 'complaint':
        return 'Queja';
      case 'issue':
        return 'Problema';
      case 'suggestion':
        return 'Sugerencia';
      case 'compliment':
        return 'Elogio';
      case 'other':
        return 'Otro';
      default:
        return type;
    }
  }

  /// Formatea la prioridad para mostrar
  String _formatPriority(String priority) {
    switch (priority) {
      case 'urgent':
        return 'Urgente';
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Media';
      case 'low':
        return 'Baja';
      default:
        return priority;
    }
  }
}
