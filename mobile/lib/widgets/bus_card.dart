import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/bus.dart';
import '../models/ruta.dart';
import '../models/user_report.dart';
import '../utils/bus_alerts.dart';
import '../utils/app_colors.dart';
import '../providers/app_provider.dart';
import '../screens/map_screen.dart';

class BusCard extends StatelessWidget {
  final BusLocation busLocation;

  const BusCard({super.key, required this.busLocation});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(
          color: isDark
              ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
              : const Color(0xFF2E7D32).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.5)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con patente y estado
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppColors.getStatusGradient(busLocation.status),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.getBusStatusColor(busLocation.status)
                            .withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus ${busLocation.busId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (busLocation.companyName != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 14,
                              color: AppColors.getCompanyColor(
                                  busLocation.companyId),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                busLocation.companyName!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.getCompanyColor(
                                      busLocation.companyId),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.getBusStatusColor(busLocation.status),
                              AppColors.getBusStatusColor(busLocation.status)
                                  .withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.getBusStatusColor(
                                      busLocation.status)
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          busLocation.status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Información del bus
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Consumer<AppProvider>(
                builder: (context, appProvider, child) {
                  // Obtener nombre de la ruta desde la lista de rutas usando routeId
                  String? routeName =
                      _getRouteNameForBus(busLocation, appProvider.rutas);

                  return Column(
                    children: [
                      // Mostrar nombre de ruta si está disponible (generado en Gestión de Ruta)
                      if (routeName != null && routeName.isNotEmpty)
                        _buildInfoRow(
                          context,
                          Icons.route,
                          'Ruta',
                          routeName,
                          AppColors.primaryGreen,
                        ),
                      if (routeName != null && routeName.isNotEmpty)
                        const SizedBox(height: 8),
                      _buildInfoRow(
                        context,
                        Icons.person,
                        'Conductor',
                        busLocation.driverName ??
                            (busLocation.driverId?.toString() ?? 'N/A'),
                        AppColors.accentBlue,
                      ),
                      if (busLocation.companyName != null) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          context,
                          Icons.business,
                          'Empresa',
                          busLocation.companyName!,
                          AppColors.getCompanyColor(busLocation.companyId),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Alertas del bus
            FutureBuilder<List<UserReport>>(
              future: Provider.of<AppProvider>(context, listen: false)
                  .getBusAlerts(busLocation.busId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  // Obtener todos los tags únicos de los reportes activos
                  final allTags = <String>{};
                  for (var report in snapshot.data!) {
                    if (report.tags != null) {
                      allTags.addAll(report.tags!);
                    }
                  }

                  if (allTags.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final isDark =
                      Theme.of(context).brightness == Brightness.dark;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.statusWarning.withValues(alpha: 0.15)
                          : AppColors.statusWarning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.statusWarning
                            .withValues(alpha: isDark ? 0.4 : 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.statusWarning,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.warning,
                                  size: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Alertas Activas',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.statusWarning,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: allTags.map((tagId) {
                            final alert = BusAlerts.getAlertById(tagId);
                            if (alert == null) return const SizedBox.shrink();

                            return Chip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(alert.icon,
                                      size: 14, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    alert.label,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: alert.color,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 4),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              elevation: 2,
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 12),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2E7D32),
                        width: 2,
                      ),
                    ),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showBusDetails(context);
                      },
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: const Text(
                        'Detalles',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: BorderSide.none,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showOnMap(context);
                      },
                      icon: const Icon(Icons.map_rounded, size: 18),
                      label: const Text(
                        'Ver Mapa',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Botón para reportar problemas
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _showReportDialog(context);
                },
                icon: const Icon(Icons.report_problem, size: 16),
                label: const Text('Reportar Problema'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: const BorderSide(color: Colors.orange),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBusDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<UserReport>>(
        future: Provider.of<AppProvider>(context, listen: false)
            .getBusAlerts(busLocation.busId),
        builder: (context, snapshot) {
          final alerts = snapshot.data ?? [];
          final allTags = <String>{};
          for (var report in alerts) {
            if (report.tags != null) {
              allTags.addAll(report.tags!);
            }
          }

          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.getStatusGradient(busLocation.status),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_bus,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus ${busLocation.busId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (busLocation.companyName != null)
                        Text(
                          busLocation.companyName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.getCompanyColor(
                                busLocation.companyId),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.getBusStatusColor(busLocation.status)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.getBusStatusColor(busLocation.status),
                      ),
                    ),
                    child: Text(
                      'Estado: ${busLocation.status}',
                      style: TextStyle(
                        color: AppColors.getBusStatusColor(busLocation.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (dialogContext) {
                      final appProvider = Provider.of<AppProvider>(
                          dialogContext,
                          listen: false);
                      final routeName =
                          _getRouteNameForBus(busLocation, appProvider.rutas);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mostrar nombre de ruta si está disponible (generado en Gestión de Ruta)
                          if (routeName != null && routeName.isNotEmpty) ...[
                            _buildDetailRow(
                              'Ruta',
                              routeName,
                              Icons.route,
                              AppColors.primaryGreen,
                            ),
                            const SizedBox(height: 16),
                          ],
                          _buildDetailRow(
                            'Conductor',
                            busLocation.driverName ??
                                (busLocation.driverId?.toString() ?? 'N/A'),
                            Icons.person,
                            AppColors.accentBlue,
                          ),
                          if (busLocation.companyName != null)
                            _buildDetailRow(
                              'Empresa',
                              busLocation.companyName!,
                              Icons.business,
                              AppColors.getCompanyColor(busLocation.companyId),
                            ),
                          _buildDetailRow(
                            'Última actualización',
                            busLocation.lastUpdate ?? 'N/A',
                            Icons.access_time,
                            AppColors.textSecondary,
                          ),
                        ],
                      );
                    },
                  ),
                  if (allTags.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Alertas Activas:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: allTags.map((tagId) {
                        final alert = BusAlerts.getAlertById(tagId);
                        if (alert == null) return const SizedBox.shrink();

                        return Chip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(alert.icon, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                alert.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: alert.color,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Helper para obtener el nombre de la ruta de un bus
  String? _getRouteNameForBus(BusLocation busLocation, List<Ruta> routes) {
    // 1. Priorizar nombreRuta si está disponible (generado en Gestión de Rutas para el bus)
    if (busLocation.nombreRuta != null && busLocation.nombreRuta!.isNotEmpty) {
      return busLocation.nombreRuta;
    }

    // 2. Buscar en la lista de rutas usando routeId (nombre de la ruta generada en Gestión de Rutas)
    if (busLocation.routeId != null && busLocation.routeId!.isNotEmpty) {
      try {
        final route = routes.firstWhere(
          (r) => r.routeId == busLocation.routeId,
        );
        return route.name;
      } catch (e) {
        // Si no se encuentra la ruta, retornar null
        return null;
      }
    }

    // 3. Si no hay ruta, retornar null (no mostrar nada)
    return null;
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label,
      String value, Color iconColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? const Color(0xFFE0E0E0) : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showOnMap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MapScreen(
          initialBusId: busLocation.busId,
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    // Importar y usar el mismo diálogo que en HomeScreen
    // Por simplicidad, crearemos un diálogo similar aquí
    String selectedType = 'complaint';
    String title = '';
    String description = '';
    String selectedPriority = 'medium';
    Set<String> selectedTags = {};

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reportar Problema'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.directions_bus,
                          size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Bus ${busLocation.busId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Alertas predefinidas
                const Text(
                  'Alertas Predefinidas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona los problemas que has observado:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: BusAlerts.predefinedAlerts.map((alert) {
                    final isSelected = selectedTags.contains(alert.id);
                    return FilterChip(
                      selected: isSelected,
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(alert.icon,
                              size: 16,
                              color: isSelected ? Colors.white : alert.color),
                          const SizedBox(width: 4),
                          Text(alert.label,
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      selectedColor: alert.color,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedTags.add(alert.id);
                          } else {
                            selectedTags.remove(alert.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: 'Resumen del problema',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    title = value;
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Descripción *',
                    hintText: 'Describe el problema...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onChanged: (value) {
                    description = value;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.isEmpty || description.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Por favor completa todos los campos obligatorios'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final success = await appProvider.createUserReport(
                  type: selectedType,
                  title: title,
                  description: description,
                  priority: selectedPriority,
                  busId: busLocation.busId,
                  tags: selectedTags.isNotEmpty ? selectedTags.toList() : null,
                );

                if (!context.mounted) return;

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Reporte creado exitosamente. Las alertas se actualizarán automáticamente.'
                          : 'Error al crear reporte',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              child: const Text('Enviar Reporte'),
            ),
          ],
        ),
      ),
    );
  }
}
