import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/trip.dart';

class TripsHistoryScreen extends StatefulWidget {
  const TripsHistoryScreen({super.key});

  @override
  State<TripsHistoryScreen> createState() => _TripsHistoryScreenState();
}

class _TripsHistoryScreenState extends State<TripsHistoryScreen> {
  String _selectedFilter =
      'all'; // 'all', 'completed', 'in_progress', 'scheduled'
  int? _selectedDriverId;
  String? _selectedRouteId;
  List<Trip> _trips = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await Future.wait([
      adminProvider.loadUsuarios(),
      adminProvider.loadRutas(),
      adminProvider.loadBuses(),
    ]);
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      List<Trip> trips;

      if (_selectedFilter == 'completed') {
        trips = await adminProvider.apiService.getCompletedTrips();
      } else {
        trips = await adminProvider.apiService.getTrips();
      }

      // Filtrar por conductor
      if (_selectedDriverId != null) {
        trips = trips.where((t) => t.driverId == _selectedDriverId).toList();
      }

      // Filtrar por ruta
      if (_selectedRouteId != null) {
        trips = trips.where((t) => t.routeId == _selectedRouteId).toList();
      }

      // Filtrar por estado
      if (_selectedFilter == 'in_progress') {
        trips = trips.where((t) => t.status == 'in_progress').toList();
      } else if (_selectedFilter == 'scheduled') {
        trips = trips.where((t) => t.status == 'scheduled').toList();
      }

      setState(() {
        _trips = trips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar viajes: $e'),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Historial de Viajes / Recorridos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consulta el historial de todos los recorridos realizados por tus buses',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Este es el historial de viajes. Para crear nuevos viajes, ve a "Gestión de Rutas" y programa un viaje desde la ruta correspondiente.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Información sobre estados
              Card(
                color: Colors.grey[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline,
                              color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Estados de los Viajes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildWorkflowStep(
                              '📅',
                              'Programado',
                              'Viaje programado para una fecha/hora específica',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildWorkflowStep(
                              '🚌',
                              'En Progreso',
                              'El bus está realizando el recorrido',
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildWorkflowStep(
                              '✅',
                              'Completado',
                              'El viaje fue completado exitosamente',
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildWorkflowStep(
                              '❌',
                              'Cancelado',
                              'El viaje fue cancelado',
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Filtros
              Row(
                children: [
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'all', label: Text('Todos')),
                        ButtonSegment(
                            value: 'completed', label: Text('Completados')),
                        ButtonSegment(
                            value: 'in_progress', label: Text('En Progreso')),
                        ButtonSegment(
                            value: 'scheduled', label: Text('Programados')),
                      ],
                      selected: {_selectedFilter},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _selectedFilter = newSelection.first;
                        });
                        _loadTrips();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Filtro por conductor
                  DropdownButton<int?>(
                    value: _selectedDriverId,
                    hint: const Text('Todos los conductores'),
                    items: adminProvider.usuarios
                        .where((u) => u.role == 'driver')
                        .map((driver) => DropdownMenuItem(
                              value: driver.id,
                              child: Text(driver.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDriverId = value;
                      });
                      _loadTrips();
                    },
                  ),
                  const SizedBox(width: 16),
                  // Filtro por ruta
                  DropdownButton<String?>(
                    value: _selectedRouteId,
                    hint: const Text('Todas las rutas'),
                    items: adminProvider.rutas
                        .map((ruta) => DropdownMenuItem(
                              value: ruta.routeId,
                              child: Text(ruta.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRouteId = value;
                      });
                      _loadTrips();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Lista de viajes
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_trips.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.directions_bus_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay viajes ${_selectedFilter == 'all' ? 'registrados' : _selectedFilter == 'completed' ? 'completados' : _selectedFilter == 'in_progress' ? 'en progreso' : 'programados'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No hay viajes registrados aún.\n'
                            'Para crear viajes, ve a "Gestión de Rutas" y programa un viaje desde una ruta.',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._trips.map((trip) => _buildTripCard(trip)),
            ],
          ),
        );
      },
    );
  }

  String _getDriverName(int? driverId, AdminProvider adminProvider) {
    if (driverId == null) return 'Sin asignar';
    try {
      final driver = adminProvider.usuarios.firstWhere(
        (u) => u.id == driverId && u.role == 'driver',
      );
      return driver.name;
    } catch (e) {
      return 'Conductor #$driverId';
    }
  }

  String _getRouteName(String? routeId, AdminProvider adminProvider) {
    if (routeId == null) return 'Sin ruta';
    try {
      final route = adminProvider.rutas.firstWhere(
        (r) => r.routeId == routeId,
      );
      return route.name;
    } catch (e) {
      return routeId;
    }
  }

  Widget _buildTripCard(Trip trip) {
    return Consumer<AdminProvider>(
      builder: (context, adminProvider, child) {
        Color statusColor;
        IconData statusIcon;
        String statusLabel;
        String statusDescription;

        switch (trip.status) {
          case 'scheduled':
            statusColor = Colors.blue;
            statusIcon = Icons.schedule;
            statusLabel = 'Programado';
            statusDescription =
                'El viaje está programado pero aún no ha comenzado';
            break;
          case 'in_progress':
            statusColor = Colors.orange;
            statusIcon = Icons.directions_bus;
            statusLabel = 'En Progreso';
            statusDescription = 'El bus está realizando el recorrido';
            break;
          case 'completed':
            statusColor = Colors.green;
            statusIcon = Icons.check_circle;
            statusLabel = 'Completado';
            statusDescription = 'El viaje fue completado exitosamente';
            break;
          case 'cancelled':
            statusColor = Colors.red;
            statusIcon = Icons.cancel;
            statusLabel = 'Cancelado';
            statusDescription = 'El viaje fue cancelado';
            break;
          default:
            statusColor = Colors.grey;
            statusIcon = Icons.help;
            statusLabel = trip.status;
            statusDescription = 'Estado desconocido';
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.2),
              child: Icon(statusIcon, color: statusColor),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Viaje #${trip.id}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRouteName(trip.routeId, adminProvider),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(statusLabel),
                  backgroundColor: statusColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(color: statusColor, fontSize: 12),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions_bus,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Bus: ${trip.busId}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _getDriverName(trip.driverId, adminProvider),
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Programado: ${_formatDateTime(trip.scheduledStart)}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Información del estado
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(statusIcon, color: statusColor, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              statusDescription,
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detalles del viaje
                    const Text(
                      'Detalles del Viaje',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        'Ruta', _getRouteName(trip.routeId, adminProvider)),
                    _buildInfoRow('Bus', trip.busId),
                    _buildInfoRow('Conductor',
                        _getDriverName(trip.driverId, adminProvider)),
                    _buildInfoRow('Programado para',
                        _formatDateTime(trip.scheduledStart)),

                    if (trip.actualStart != null)
                      _buildInfoRow(
                          'Iniciado a las', _formatDateTime(trip.actualStart!)),

                    if (trip.actualEnd != null)
                      _buildInfoRow(
                          'Completado a las', _formatDateTime(trip.actualEnd!)),

                    if (trip.durationMinutes != null)
                      _buildInfoRow(
                          'Duración total', '${trip.durationMinutes} minutos'),

                    if (trip.delayMinutes != null && trip.delayMinutes != 0)
                      _buildInfoRow(
                        'Retraso',
                        '${trip.delayMinutes} minutos',
                        color:
                            trip.delayMinutes! > 0 ? Colors.red : Colors.green,
                      ),

                    _buildInfoRow(
                      'Pasajeros',
                      '${trip.passengerCount}${trip.capacity != null ? ' de ${trip.capacity}' : ''}',
                    ),

                    if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.note, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                trip.notes!,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blue[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (trip.issues != null && trip.issues!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning,
                                size: 16, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                trip.issues!,
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red[900]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Acciones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _showTripDetails(trip),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Ver Detalles'),
                        ),
                        if (trip.status == 'scheduled') ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _startTrip(trip),
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text('Iniciar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _cancelTrip(trip),
                            icon: const Icon(Icons.cancel, size: 18),
                            label: const Text('Cancelar'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                        if (trip.status == 'in_progress') ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showCompleteTripDialog(trip),
                            icon: const Icon(Icons.check_circle, size: 18),
                            label: const Text('Completar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
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

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStep(
      String icon, String title, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _showTripDetails(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Viaje #${trip.id}'),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Estado
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          _getStatusColor(trip.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(_getStatusIcon(trip.status),
                            color: _getStatusColor(trip.status)),
                        const SizedBox(width: 8),
                        Text(
                          _getStatusLabel(trip.status),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(trip.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Información principal
                  const Text(
                    'Información del Viaje',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                      'Ruta', _getRouteName(trip.routeId, adminProvider)),
                  _buildDetailRow('Bus', trip.busId),
                  _buildDetailRow('Conductor',
                      _getDriverName(trip.driverId, adminProvider)),

                  const SizedBox(height: 16),
                  const Text(
                    'Horarios',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                      'Programado para', _formatDateTime(trip.scheduledStart)),
                  if (trip.actualStart != null)
                    _buildDetailRow(
                        'Iniciado a las', _formatDateTime(trip.actualStart!)),
                  if (trip.actualEnd != null)
                    _buildDetailRow(
                        'Completado a las', _formatDateTime(trip.actualEnd!)),
                  if (trip.durationMinutes != null)
                    _buildDetailRow(
                        'Duración', '${trip.durationMinutes} minutos'),
                  if (trip.delayMinutes != null && trip.delayMinutes != 0)
                    _buildDetailRow(
                      'Retraso',
                      '${trip.delayMinutes} minutos',
                      color: trip.delayMinutes! > 0 ? Colors.red : Colors.green,
                    ),

                  const SizedBox(height: 16),
                  const Text(
                    'Pasajeros',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Pasajeros transportados',
                    '${trip.passengerCount}${trip.capacity != null ? ' de ${trip.capacity} capacidad' : ''}',
                  ),

                  if (trip.notes != null && trip.notes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Notas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(trip.notes!),
                    ),
                  ],

                  if (trip.issues != null && trip.issues!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Problemas Reportados',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(trip.issues!),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scheduled':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'scheduled':
        return Icons.schedule;
      case 'in_progress':
        return Icons.directions_bus;
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return 'Programado';
      case 'in_progress':
        return 'En Progreso';
      case 'completed':
        return 'Completado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status;
    }
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startTrip(Trip trip) async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    try {
      await adminProvider.apiService.startTrip(trip.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viaje iniciado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadTrips();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al iniciar viaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCompleteTripDialog(Trip trip) {
    final passengerCountController =
        TextEditingController(text: trip.passengerCount.toString());
    final notesController = TextEditingController(text: trip.notes ?? '');
    final issuesController = TextEditingController(text: trip.issues ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Viaje'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passengerCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Número de Pasajeros',
                  prefixIcon: Icon(Icons.people),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas (opcional)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: issuesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Problemas (opcional)',
                  prefixIcon: Icon(Icons.warning),
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
                await adminProvider.apiService.completeTrip(
                  trip.id,
                  passengerCount: passengerCountController.text.isNotEmpty
                      ? int.tryParse(passengerCountController.text)
                      : null,
                  notes: notesController.text.isEmpty
                      ? null
                      : notesController.text,
                  issues: issuesController.text.isEmpty
                      ? null
                      : issuesController.text,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Viaje completado exitosamente'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadTrips();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al completar viaje: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Completar'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelTrip(Trip trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Viaje'),
        content: const Text('¿Estás seguro de que deseas cancelar este viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed == true) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      try {
        await adminProvider.apiService.cancelTrip(trip.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Viaje cancelado exitosamente'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadTrips();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar viaje: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
