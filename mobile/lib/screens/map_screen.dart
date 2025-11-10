import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/enhanced_map_widget.dart';
import '../models/bus.dart';
import '../models/ruta.dart';
import '../models/user_report.dart';
import '../utils/bus_alerts.dart';
import '../utils/app_colors.dart';

// Clase auxiliar para mantener el estado del diálogo de filtros
class _FilterDialogState {
  String? routeId;
  String? busId;
  int? companyId;
  bool showRoutes;
  bool showStops;
  bool showAlerts;

  _FilterDialogState({
    required this.routeId,
    required this.busId,
    required this.companyId,
    required this.showRoutes,
    required this.showStops,
    required this.showAlerts,
  });
}

class MapScreen extends StatefulWidget {
  final String? initialBusId;
  final String? initialRouteId;

  const MapScreen({
    super.key,
    this.initialBusId,
    this.initialRouteId,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  String? _selectedRouteId;
  String? _selectedBusId;
  int? _selectedCompanyId;
  bool _showRoutes = true;
  bool _showStops = true;
  bool _showAlerts = true;

  @override
  void initState() {
    super.initState();
    _selectedRouteId = widget.initialRouteId;
    _selectedBusId = widget.initialBusId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.getCurrentLocation();
    await appProvider.loadBusLocations();
    await appProvider.loadRutas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Buses - GeoRu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtros',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar ubicaciones',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Filtrar buses si hay filtro seleccionado
          List<BusLocation> filteredBuses = appProvider.busLocations;

          // Aplicar filtros en orden: empresa, ruta, bus
          if (_selectedCompanyId != null) {
            filteredBuses = filteredBuses
                .where((bus) => bus.companyId == _selectedCompanyId)
                .toList();
          }

          if (_selectedRouteId != null) {
            filteredBuses = filteredBuses
                .where((bus) => bus.routeId == _selectedRouteId)
                .toList();
          }

          if (_selectedBusId != null) {
            filteredBuses = filteredBuses
                .where((bus) => bus.busId == _selectedBusId)
                .toList();
          }

          // Filtrar rutas según los filtros aplicados
          List<Ruta> filteredRoutes = appProvider.rutas;

          // Si hay un filtro de empresa, solo mostrar rutas de esa empresa
          if (_selectedCompanyId != null) {
            final companyRouteIds = filteredBuses
                .map((bus) => bus.routeId)
                .where((routeId) => routeId != null)
                .toSet();
            filteredRoutes = filteredRoutes
                .where((route) => companyRouteIds.contains(route.routeId))
                .toList();
          }

          // Si hay un filtro de ruta específica, mostrar solo esa ruta
          if (_selectedRouteId != null) {
            filteredRoutes = filteredRoutes
                .where((route) => route.routeId == _selectedRouteId)
                .toList();
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              EnhancedMapWidget(
                showMyLocation: true,
                buses: filteredBuses,
                routes: _showRoutes ? filteredRoutes : [],
                showStops: _showStops,
                showAlerts: _showAlerts,
                initialBusId: widget.initialBusId,
                onBusTap: (busLocation) {
                  _showBusDetails(context, busLocation);
                },
              ),
              if (_selectedRouteId != null ||
                  _selectedBusId != null ||
                  _selectedCompanyId != null)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: SafeArea(
                    bottom: false,
                    child: Material(
                      elevation: 4,
                      color: AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryGreen
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.filter_alt,
                                color: AppColors.primaryGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Filtros activos:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _getFilterLabel(appProvider),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedRouteId = null;
                                  _selectedBusId = null;
                                  _selectedCompanyId = null;
                                });
                              },
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.close,
                                  size: 20,
                                  color: AppColors.textSecondary,
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
          );
        },
      ),
    );
  }

  String _getRouteName(String routeId, List<Ruta> routes) {
    try {
      final route = routes.firstWhere((r) => r.routeId == routeId);
      return route.name;
    } catch (e) {
      return routeId;
    }
  }

  String _getCompanyName(int? companyId, List<BusLocation> buses) {
    if (companyId == null) return '';
    try {
      final bus = buses.firstWhere((b) => b.companyId == companyId);
      return bus.companyName ?? 'Empresa $companyId';
    } catch (e) {
      return 'Empresa $companyId';
    }
  }

  String _getFilterLabel(AppProvider appProvider) {
    final filters = <String>[];

    if (_selectedCompanyId != null) {
      final companyName =
          _getCompanyName(_selectedCompanyId, appProvider.busLocations);
      filters.add('Empresa: $companyName');
    }

    if (_selectedRouteId != null) {
      filters
          .add('Ruta: ${_getRouteName(_selectedRouteId!, appProvider.rutas)}');
    }

    if (_selectedBusId != null) {
      filters.add('Bus: $_selectedBusId');
    }

    return filters.isEmpty ? '' : filters.join(' • ');
  }

  List<MapEntry<int, String>> _getUniqueCompanies(List<BusLocation> buses) {
    final companiesMap = <int, String>{};
    for (final bus in buses) {
      if (bus.companyId != null && bus.companyName != null) {
        companiesMap[bus.companyId!] = bus.companyName!;
      }
    }
    final companiesList = companiesMap.entries.toList();
    companiesList.sort((a, b) => a.value.compareTo(b.value));
    return companiesList;
  }

  void _showFilterDialog() {
    final appProvider = Provider.of<AppProvider>(context, listen: false);

    // Obtener empresas únicas de los buses
    final uniqueCompanies = _getUniqueCompanies(appProvider.busLocations);

    showDialog(
      context: context,
      builder: (context) {
        // Crear un objeto mutable para almacenar el estado temporal
        final filterState = _FilterDialogState(
          routeId: _selectedRouteId,
          busId: _selectedBusId,
          companyId: _selectedCompanyId,
          showRoutes: _showRoutes,
          showStops: _showStops,
          showAlerts: _showAlerts,
        );

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            // Calcular buses y rutas disponibles según la empresa seleccionada
            List<BusLocation> availableBuses = appProvider.busLocations;
            List<Ruta> availableRoutes = appProvider.rutas;

            if (filterState.companyId != null) {
              availableBuses = availableBuses
                  .where((bus) => bus.companyId == filterState.companyId)
                  .toList();

              // Filtrar rutas disponibles según los buses de la empresa
              final companyRouteIds = availableBuses
                  .map((bus) => bus.routeId)
                  .where((routeId) => routeId != null)
                  .toSet();
              availableRoutes = availableRoutes
                  .where((route) => companyRouteIds.contains(route.routeId))
                  .toList();
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.filter_list, color: AppColors.primaryGreen),
                  SizedBox(width: 8),
                  Text('Filtros del Mapa'),
                ],
              ),
              contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 24.0),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
                  maxWidth: MediaQuery.of(dialogContext).size.width * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filtrar por Empresa:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<int?>(
                        value: filterState.companyId,
                        decoration: const InputDecoration(
                          labelText: 'Empresa',
                          border: OutlineInputBorder(),
                          hintText: 'Todas las empresas',
                          prefixIcon: Icon(Icons.business,
                              color: AppColors.primaryGreen),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todas las empresas'),
                          ),
                          ...uniqueCompanies.map((company) {
                            return DropdownMenuItem<int?>(
                              value: company.key,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppColors.getCompanyColor(
                                          company.key),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    company.value,
                                    style: TextStyle(
                                      color: AppColors.getCompanyColor(
                                          company.key),
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            filterState.companyId = value;
                            // Limpiar selecciones incompatibles
                            if (value != null) {
                              // Verificar si el bus seleccionado pertenece a esta empresa
                              final busBelongsToCompany =
                                  appProvider.busLocations.any((bus) =>
                                      bus.busId == filterState.busId &&
                                      bus.companyId == value);
                              if (!busBelongsToCompany) {
                                filterState.busId = null;
                              }
                              // Verificar si la ruta seleccionada pertenece a esta empresa
                              final routeBelongsToCompany =
                                  appProvider.busLocations.any((bus) =>
                                      bus.routeId == filterState.routeId &&
                                      bus.companyId == value);
                              if (!routeBelongsToCompany) {
                                filterState.routeId = null;
                              }
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Filtrar por Ruta:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        value: filterState.routeId,
                        decoration: const InputDecoration(
                          labelText: 'Ruta',
                          border: OutlineInputBorder(),
                          hintText: 'Todas las rutas',
                          prefixIcon: Icon(Icons.route),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todas las rutas'),
                          ),
                          ...availableRoutes.map((route) {
                            return DropdownMenuItem<String?>(
                              value: route.routeId,
                              child: Text(route.name),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            filterState.routeId = value;
                            if (value != null) {
                              filterState.busId = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Filtrar por Bus:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        value: filterState.busId,
                        decoration: const InputDecoration(
                          labelText: 'Bus',
                          border: OutlineInputBorder(),
                          hintText: 'Todos los buses',
                          prefixIcon: Icon(Icons.directions_bus),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos los buses'),
                          ),
                          ...availableBuses.map((bus) {
                            return DropdownMenuItem<String?>(
                              value: bus.busId,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Bus ${bus.busId}'),
                                  if (bus.companyName != null) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '• ${bus.companyName!}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.getCompanyColor(
                                            bus.companyId),
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            filterState.busId = value;
                            if (value != null) {
                              filterState.routeId = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Mostrar en el mapa:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        title: const Text('Rutas'),
                        value: filterState.showRoutes,
                        onChanged: (value) {
                          setDialogState(() {
                            filterState.showRoutes = value ?? true;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Paradas'),
                        value: filterState.showStops,
                        onChanged: (value) {
                          setDialogState(() {
                            filterState.showStops = value ?? true;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Alertas de buses'),
                        value: filterState.showAlerts,
                        onChanged: (value) {
                          setDialogState(() {
                            filterState.showAlerts = value ?? true;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    setDialogState(() {
                      filterState.routeId = null;
                      filterState.busId = null;
                      filterState.companyId = null;
                    });
                  },
                  child: Text(
                    'Limpiar',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedRouteId = filterState.routeId;
                      _selectedBusId = filterState.busId;
                      _selectedCompanyId = filterState.companyId;
                      _showRoutes = filterState.showRoutes;
                      _showStops = filterState.showStops;
                      _showAlerts = filterState.showAlerts;
                    });
                    Navigator.of(dialogContext).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Aplicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBusDetails(BuildContext context, BusLocation busLocation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BusDetailsSheet(
        busLocation: busLocation,
        onReportProblem: () => _showReportDialog(context, busLocation),
      ),
    );
  }

  void _showReportDialog(BuildContext context, BusLocation busLocation) {
    String selectedType = 'complaint';
    String title = '';
    String description = '';
    String selectedPriority = 'medium';
    Set<String> selectedTags = {};

    final appProvider = Provider.of<AppProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                        'Reportando sobre: Bus ${busLocation.busId}',
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
                  'Selecciona las alertas que aplican:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
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
                          Text(alert.label),
                        ],
                      ),
                      selectedColor: alert.color,
                      checkmarkColor: Colors.white,
                      onSelected: (selected) {
                        setDialogState(() {
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
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Título *',
                    hintText: 'Título del reporte',
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
                          ? 'Reporte creado exitosamente'
                          : 'Error al crear reporte',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
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

class BusDetailsSheet extends StatelessWidget {
  final BusLocation busLocation;
  final VoidCallback? onReportProblem;

  const BusDetailsSheet({
    super.key,
    required this.busLocation,
    this.onReportProblem,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient:
                                AppColors.getStatusGradient(busLocation.status),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.getBusStatusColor(
                                        busLocation.status)
                                    .withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.directions_bus,
                              color: Colors.white),
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
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.getBusStatusColor(
                                          busLocation.status)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.getBusStatusColor(
                                        busLocation.status),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  busLocation.status,
                                  style: TextStyle(
                                    color: AppColors.getBusStatusColor(
                                        busLocation.status),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow('Ruta', busLocation.routeId ?? 'N/A'),
                    _buildDetailRow(
                      'Conductor',
                      busLocation.driverName ??
                          (busLocation.driverId?.toString() ?? 'N/A'),
                      icon: Icons.person,
                      iconColor: AppColors.accentBlue,
                    ),
                    if (busLocation.companyName != null)
                      _buildDetailRow(
                        'Empresa',
                        busLocation.companyName!,
                        icon: Icons.business,
                        iconColor:
                            AppColors.getCompanyColor(busLocation.companyId),
                      ),
                    _buildDetailRow(
                      'Ubicación',
                      'Lat: ${busLocation.latitude.toStringAsFixed(6)}\n'
                          'Lng: ${busLocation.longitude.toStringAsFixed(6)}',
                    ),
                    _buildDetailRow(
                      'Última actualización',
                      busLocation.lastUpdate ?? 'N/A',
                    ),
                    // Alertas del bus
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    FutureBuilder<List<UserReport>>(
                      future: Provider.of<AppProvider>(context, listen: false)
                          .getBusAlerts(busLocation.busId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final allTags = <String>{};
                          for (var report in snapshot.data!) {
                            if (report.tags != null) {
                              allTags.addAll(report.tags!);
                            }
                          }
                          if (allTags.isNotEmpty) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                    if (alert == null) {
                                      return Chip(
                                        label: Text(
                                          tagId,
                                          style: const TextStyle(fontSize: 11),
                                        ),
                                        backgroundColor: Colors.orange[200],
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4),
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      );
                                    }
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
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: alert.color,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    );
                                  }).toList(),
                                ),
                              ],
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onReportProblem?.call();
                            },
                            icon: const Icon(Icons.report_problem),
                            label: const Text('Reportar Problema'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            label: const Text('Cerrar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {IconData? icon, Color? iconColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: iconColor ?? AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 100,
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
}
