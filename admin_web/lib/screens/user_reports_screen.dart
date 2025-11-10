import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/user_report.dart';

class UserReportsScreen extends StatefulWidget {
  const UserReportsScreen({super.key});

  @override
  State<UserReportsScreen> createState() => _UserReportsScreenState();
}

class _UserReportsScreenState extends State<UserReportsScreen> {
  String _selectedFilter = 'pending'; // 'pending', 'all', 'resolved'
  List<UserReport> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReports();
    });
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      List<UserReport> reports;

      if (_selectedFilter == 'pending') {
        reports = await adminProvider.apiService.getPendingReports();
      } else {
        reports = await adminProvider.apiService.getUserReports();
      }

      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar reportes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'complaint':
        return Icons.report_problem;
      case 'suggestion':
        return Icons.lightbulb;
      case 'compliment':
        return Icons.thumb_up;
      case 'issue':
        return Icons.warning;
      default:
        return Icons.message;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    'Reportes de Usuarios',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Comentarios, sugerencias y reportes de usuarios',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showCreateReportDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Reporte'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Filtros
          Row(
            children: [
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'pending', label: Text('Pendientes')),
                  ButtonSegment(value: 'all', label: Text('Todos')),
                  ButtonSegment(value: 'resolved', label: Text('Resueltos')),
                ],
                selected: {_selectedFilter},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedFilter = newSelection.first;
                  });
                  _loadReports();
                },
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadReports,
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lista de reportes
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_reports.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'No hay reportes ${_selectedFilter == 'pending' ? 'pendientes' : 'disponibles'}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            ..._reports.map((report) => _buildReportCard(report)),
        ],
      ),
    );
  }

  Widget _buildReportCard(UserReport report) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPriorityColor(report.priority).withOpacity(0.2),
          child: Icon(
            _getTypeIcon(report.type),
            color: _getPriorityColor(report.priority),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                report.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Chip(
              label: Text(
                report.priority.toUpperCase(),
                style: const TextStyle(fontSize: 10, color: Colors.white),
              ),
              backgroundColor: _getPriorityColor(report.priority),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(report.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(report.type),
                  backgroundColor: Colors.blue[100],
                ),
                Chip(
                  label: Text(report.status),
                  backgroundColor:
                      _getStatusColor(report.status).withOpacity(0.2),
                ),
                if (report.routeId != null)
                  Chip(
                    label: Text('Ruta: ${report.routeId}'),
                    backgroundColor: Colors.purple[100],
                  ),
                if (report.busId != null)
                  Chip(
                    label: Text('Bus: ${report.busId}'),
                    backgroundColor: Colors.green[100],
                  ),
              ],
            ),
            if (report.tags != null && report.tags!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: report.tags!.map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: Colors.orange[200],
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
            if (report.adminResponse != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Respuesta del Administrador:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(report.adminResponse!),
                  ],
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('Ver Detalles'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'review',
              child: Row(
                children: [
                  Icon(Icons.check, size: 20),
                  SizedBox(width: 8),
                  Text('Revisar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'resolve',
              child: Row(
                children: [
                  Icon(Icons.done, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Marcar como Resuelto'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'view') {
              _showReportDetails(report);
            } else if (value == 'review') {
              _showReviewDialog(report);
            } else if (value == 'resolve') {
              _resolveReport(report);
            }
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showReportDetails(UserReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(report.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tipo', report.type),
              _buildDetailRow('Prioridad', report.priority),
              _buildDetailRow('Estado', report.status),
              if (report.routeId != null)
                _buildDetailRow('Ruta', report.routeId!),
              if (report.busId != null) _buildDetailRow('Bus', report.busId!),
              if (report.tags != null && report.tags!.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Alertas:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: report.tags!.map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: Colors.orange[200],
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),
              const Text(
                'Descripción:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(report.description),
              if (report.adminResponse != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Respuesta:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(report.adminResponse!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          if (report.status == 'pending')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showReviewDialog(report);
              },
              child: const Text('Revisar'),
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
            width: 100,
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

  void _showReviewDialog(UserReport report) {
    final responseController = TextEditingController();
    String selectedStatus = report.status;
    String selectedPriority = report.priority;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Revisar Reporte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'pending', child: Text('Pendiente')),
                    DropdownMenuItem(
                        value: 'reviewed', child: Text('Revisado')),
                    DropdownMenuItem(
                        value: 'resolved', child: Text('Resuelto')),
                    DropdownMenuItem(
                        value: 'rejected', child: Text('Rechazado')),
                    DropdownMenuItem(
                        value: 'archived', child: Text('Archivado')),
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
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Prioridad',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Baja')),
                    DropdownMenuItem(value: 'medium', child: Text('Media')),
                    DropdownMenuItem(value: 'high', child: Text('Alta')),
                    DropdownMenuItem(value: 'urgent', child: Text('Urgente')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() {
                        selectedPriority = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: responseController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Respuesta',
                    hintText: 'Escribe una respuesta al usuario...',
                    border: OutlineInputBorder(),
                  ),
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
                final adminProvider =
                    Provider.of<AdminProvider>(context, listen: false);
                try {
                  await adminProvider.apiService.reviewReport(
                    report.id,
                    status: selectedStatus,
                    adminResponse: responseController.text.isEmpty
                        ? null
                        : responseController.text,
                    priority: selectedPriority,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reporte revisado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadReports();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al revisar reporte: $e'),
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
      ),
    );
  }

  Future<void> _resolveReport(UserReport report) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    try {
      await adminProvider.apiService.reviewReport(
        report.id,
        status: 'resolved',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte marcado como resuelto'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al resolver reporte: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCreateReportDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'complaint';
    String selectedPriority = 'medium';
    String? selectedRouteId;
    String? selectedBusId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Crear Nuevo Reporte'),
          content: SingleChildScrollView(
            child: Consumer<AdminProvider>(
              builder: (context, adminProvider, child) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Reporte *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'complaint', child: Text('Queja')),
                        DropdownMenuItem(
                            value: 'suggestion', child: Text('Sugerencia')),
                        DropdownMenuItem(
                            value: 'compliment', child: Text('Elogio')),
                        DropdownMenuItem(
                            value: 'issue', child: Text('Problema')),
                        DropdownMenuItem(value: 'other', child: Text('Otro')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedType = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        hintText: 'Ej: Bus con retraso',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        hintText: 'Describe el problema o sugerencia...',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Prioridad *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.priority_high),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Baja')),
                        DropdownMenuItem(value: 'medium', child: Text('Media')),
                        DropdownMenuItem(value: 'high', child: Text('Alta')),
                        DropdownMenuItem(
                            value: 'urgent', child: Text('Urgente')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedPriority = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: selectedRouteId,
                      decoration: const InputDecoration(
                        labelText: 'Ruta (opcional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.route),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Ninguna'),
                        ),
                        ...adminProvider.rutas.map((ruta) => DropdownMenuItem(
                              value: ruta.routeId,
                              child: Text(ruta.name),
                            )),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          selectedRouteId = value;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    descriptionController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Por favor completa todos los campos obligatorios'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final adminProvider =
                    Provider.of<AdminProvider>(context, listen: false);
                try {
                  await adminProvider.apiService.createUserReport({
                    'type': selectedType,
                    'title': titleController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'priority': selectedPriority,
                    'route_id': selectedRouteId,
                    'bus_id': selectedBusId,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reporte creado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadReports();
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al crear reporte: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Crear Reporte'),
            ),
          ],
        ),
      ),
    );
  }
}
