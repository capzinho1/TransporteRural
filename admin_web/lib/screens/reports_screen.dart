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
                      const Text(
                        'Reportes y Análisis',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Visualiza estadísticas y métricas del sistema',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SegmentedButton<String>(
                        segments: const [
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

              // Content based on selected report
              if (_selectedReport == 'overview')
                _buildOverviewReport(adminProvider)
              else if (_selectedReport == 'routes')
                _buildRoutesReport(adminProvider)
              else
                _buildDriversReport(adminProvider),
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
                const DataCell(Text('N/A')),
                DataCell(_buildStatusBadge('Pendiente', Colors.grey)),
              ]),
              DataRow(cells: [
                const DataCell(Text('Satisfacción usuarios')),
                const DataCell(Text('N/A')),
                DataCell(_buildStatusBadge('Pendiente', Colors.grey)),
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
                const DataCell(Text('0')),
                const DataCell(Text('0h')),
                DataCell(_buildRatingStars(0)),
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

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportando reporte...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
