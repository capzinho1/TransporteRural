import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/rating.dart';

class RatingsScreen extends StatefulWidget {
  const RatingsScreen({super.key});

  @override
  State<RatingsScreen> createState() => _RatingsScreenState();
}

class _RatingsScreenState extends State<RatingsScreen> {
  List<Rating> _ratings = [];
  bool _isLoading = false;
  int? _selectedDriverId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.loadUsuarios();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      List<Rating> ratings;

      if (_selectedDriverId != null) {
        ratings = await adminProvider.apiService.getRatingsByDriver(_selectedDriverId!);
      } else {
        ratings = await adminProvider.apiService.getRatings();
      }

      setState(() {
        _ratings = ratings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar calificaciones: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 20,
        );
      }),
    );
  }

  String _getDriverName(int? driverId) {
    if (driverId == null) return 'Desconocido';
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final driver = adminProvider.usuarios.firstWhere(
        (u) => u.id == driverId && u.role == 'driver',
      );
      return driver.name;
    } catch (e) {
      return 'Conductor #$driverId';
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
                        const Text(
                          'Calificaciones de Conductores',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Calificaciones dadas por los usuarios pasajeros',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Filtro por conductor
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int?>(
                        value: _selectedDriverId,
                        decoration: const InputDecoration(
                          labelText: 'Filtrar por conductor',
                          prefixIcon: Icon(Icons.drive_eta),
                          border: OutlineInputBorder(),
                          helperText: 'Ver calificaciones de usuarios pasajeros',
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todos los conductores'),
                          ),
                          ...adminProvider.usuarios
                              .where((u) => u.role == 'driver')
                              .map((driver) => DropdownMenuItem(
                                    value: driver.id,
                                    child: Text(driver.name),
                                  )),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedDriverId = value;
                          });
                          _loadRatings();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _loadRatings,
                      tooltip: 'Actualizar',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Estadísticas si hay un conductor seleccionado
                if (_selectedDriverId != null) _buildDriverStats(_selectedDriverId!),

                const SizedBox(height: 24),

                // Lista de calificaciones
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (_ratings.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No hay calificaciones${_selectedDriverId != null ? ' para este conductor' : ''}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Las calificaciones son creadas por los usuarios pasajeros\n'
                              'desde la aplicación móvil después de completar un viaje.',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ..._ratings.map((rating) => _buildRatingCard(rating)),
              ],
            ),
          );
        },
      );
  }

  Widget _buildDriverStats(int driverId) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Provider.of<AdminProvider>(context, listen: false)
          .apiService.getDriverRatingStats(driverId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final stats = snapshot.data!;
        final total = stats['total'] ?? 0;
        final avgRating = stats['average'] ?? 0.0;

        if (total == 0) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Colors.amber[50],
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDriverName(driverId),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStars(avgRating.round()),
                          const SizedBox(width: 8),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '($total calificaciones)',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      if (stats['averagePunctuality'] != null &&
                          stats['averagePunctuality'] > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Puntualidad: ${(stats['averagePunctuality'] as double).toStringAsFixed(1)}/5',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingCard(Rating rating) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber[100],
          child: _buildStars(rating.rating),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDriverName(rating.driverId),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (rating.userId != null)
                    Text(
                      'Usuario #${rating.userId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${rating.rating}/5',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            if (rating.comment != null && rating.comment!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comentario:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(rating.comment!),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (rating.punctualityRating != null)
                  Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.schedule, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text('Puntualidad: ${rating.punctualityRating}/5'),
                      ],
                    ),
                    backgroundColor: Colors.blue[100],
                  ),
                if (rating.serviceRating != null)
                  Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.room_service, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text('Servicio: ${rating.serviceRating}/5'),
                      ],
                    ),
                    backgroundColor: Colors.green[100],
                  ),
                if (rating.cleanlinessRating != null)
                  Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cleaning_services, size: 16, color: Colors.purple),
                        const SizedBox(width: 4),
                        Text('Limpieza: ${rating.cleanlinessRating}/5'),
                      ],
                    ),
                    backgroundColor: Colors.purple[100],
                  ),
                if (rating.safetyRating != null)
                  Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.security, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text('Seguridad: ${rating.safetyRating}/5'),
                      ],
                    ),
                    backgroundColor: Colors.orange[100],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(rating.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

}

