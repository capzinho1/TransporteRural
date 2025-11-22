import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/notificacion.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType =
      'drivers'; // Cambiar default a 'drivers' ya que solo es para conductores
  String? _selectedRoute;
  int? _selectedDriverId;
  List<Notificacion> _notifications = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      adminProvider.loadRutas();
      adminProvider.loadUsuarios();
      _loadNotifications();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      final notifications = await adminProvider.apiService.getNotifications();

      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar notificaciones: $e'),
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
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header moderno
                Container(
                  padding: const EdgeInsets.all(20),
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
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFF59E0B),
                              Color(0xFFFFC107),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_active_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Centro de Notificaciones',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Envía notificaciones a conductores del sistema',
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
                const SizedBox(height: 20),

                // Formulario de nueva notificación
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Formulario
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Colors.grey[200]!, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF59E0B)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.add_circle_outline_rounded,
                                        color: Color(0xFFF59E0B),
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Nueva Notificación',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Tipo de notificación
                                const Text(
                                  'Tipo de Notificación',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                SegmentedButton<String>(
                                  segments: const [
                                    ButtonSegment(
                                      value: 'drivers',
                                      label: Text('Todos los Conductores'),
                                      icon: Icon(Icons.drive_eta_rounded,
                                          size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'route',
                                      label: Text('Por Ruta'),
                                      icon: Icon(Icons.route_rounded, size: 16),
                                    ),
                                    ButtonSegment(
                                      value: 'driver',
                                      label: Text('Conductor Específico'),
                                      icon:
                                          Icon(Icons.person_rounded, size: 16),
                                    ),
                                  ],
                                  selected: {_selectedType},
                                  onSelectionChanged:
                                      (Set<String> newSelection) {
                                    setState(() {
                                      _selectedType = newSelection.first;
                                      _selectedRoute = null;
                                      _selectedDriverId = null;
                                    });
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Selector de ruta (si es por ruta)
                                if (_selectedType == 'route') ...[
                                  DropdownButtonFormField<String>(
                                    initialValue: _selectedRoute,
                                    decoration: const InputDecoration(
                                      labelText: 'Seleccionar Ruta',
                                      prefixIcon: Icon(Icons.route),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: adminProvider.rutas
                                        .map((ruta) => DropdownMenuItem(
                                              value: ruta.routeId,
                                              child: Text(ruta.name),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedRoute = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (_selectedType == 'route' &&
                                          value == null) {
                                        return 'Selecciona una ruta';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Selector de conductor (si es conductor específico)
                                if (_selectedType == 'driver') ...[
                                  DropdownButtonFormField<int>(
                                    initialValue: _selectedDriverId,
                                    decoration: const InputDecoration(
                                      labelText: 'Seleccionar Conductor',
                                      prefixIcon: Icon(Icons.person),
                                      border: OutlineInputBorder(),
                                    ),
                                    items: adminProvider.usuarios
                                        .where((u) => u.role == 'driver')
                                        .map((driver) => DropdownMenuItem(
                                              value: driver.id,
                                              child: Text(
                                                  '${driver.name} (${driver.email})'),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedDriverId = value;
                                      });
                                    },
                                    validator: (value) {
                                      if (_selectedType == 'driver' &&
                                          value == null) {
                                        return 'Selecciona un conductor';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Título
                                TextFormField(
                                  controller: _titleController,
                                  decoration: const InputDecoration(
                                    labelText: 'Título',
                                    hintText: 'Ej: Cambio de Horario',
                                    prefixIcon: Icon(Icons.title),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'El título es requerido';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Mensaje
                                TextFormField(
                                  controller: _messageController,
                                  maxLines: 4,
                                  decoration: const InputDecoration(
                                    labelText: 'Mensaje',
                                    hintText:
                                        'Escribe el mensaje de la notificación...',
                                    prefixIcon: Icon(Icons.message),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'El mensaje es requerido';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),

                                // Botones
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _clearForm,
                                        icon: const Icon(Icons.clear),
                                        label: const Text('Limpiar'),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _sendNotification,
                                        icon: _isLoading
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(
                                                    Colors.white,
                                                  ),
                                                ),
                                              )
                                            : const Icon(Icons.send),
                                        label: Text(_isLoading
                                            ? 'Enviando...'
                                            : 'Enviar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 24),

                    // Vista previa
                    Expanded(
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Vista Previa',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.notifications,
                                            color: Colors.blue),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _titleController.text.isEmpty
                                                ? 'Título de la notificación'
                                                : _titleController.text,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _messageController.text.isEmpty
                                          ? 'El mensaje aparecerá aquí...'
                                          : _messageController.text,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          _getTypeIcon(),
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _getTypeLabel(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.blue, size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Los usuarios recibirán esta notificación en sus dispositivos móviles',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Historial de notificaciones
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.history_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Historial de Notificaciones',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E3A8A),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            color: const Color(0xFF3B82F6),
                            onPressed: _loadNotifications,
                            tooltip: 'Actualizar',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_notifications.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.notifications_none_rounded,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No hay notificaciones enviadas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _notifications.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey[200]!, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getTypeIconForNotification(
                                        notification.type),
                                    color: const Color(0xFF3B82F6),
                                    size: 20,
                                  ),
                                ),
                                title: Text(
                                  notification.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF1E3A8A),
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        notification.message,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF3B82F6)
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _getTypeLabelForNotification(
                                                  notification.type),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF3B82F6),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 12,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(notification.sentAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
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

  IconData _getTypeIcon() {
    switch (_selectedType) {
      case 'drivers':
        return Icons.drive_eta;
      case 'route':
        return Icons.route;
      case 'driver':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  String _getTypeLabel() {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    switch (_selectedType) {
      case 'drivers':
        return 'Para Todos los Conductores';
      case 'route':
        if (_selectedRoute != null) {
          try {
            final route = adminProvider.rutas
                .firstWhere((r) => r.routeId == _selectedRoute);
            return 'Ruta: ${route.name}';
          } catch (e) {
            return 'Notificación por Ruta';
          }
        }
        return 'Notificación por Ruta';
      case 'driver':
        if (_selectedDriverId != null) {
          try {
            final driver = adminProvider.usuarios
                .firstWhere((u) => u.id == _selectedDriverId);
            return 'Conductor: ${driver.name}';
          } catch (e) {
            return 'Conductor Específico';
          }
        }
        return 'Conductor Específico';
      default:
        return 'Notificación';
    }
  }

  IconData _getTypeIconForNotification(String type) {
    switch (type) {
      case 'drivers':
        return Icons.drive_eta;
      case 'route':
        return Icons.route;
      case 'driver':
        return Icons.person;
      default:
        return Icons.notifications;
    }
  }

  String _getTypeLabelForNotification(String type) {
    switch (type) {
      case 'drivers':
        return 'Todos los Conductores';
      case 'route':
        return 'Por Ruta';
      case 'driver':
        return 'Conductor Específico';
      default:
        return 'Desconocido';
    }
  }

  Future<void> _sendNotification() async {
    if (_formKey.currentState!.validate()) {
      // Validar que si es tipo 'route' o 'driver', tenga seleccionado el target
      if (_selectedType == 'route' && _selectedRoute == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes seleccionar una ruta'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (_selectedType == 'driver' && _selectedDriverId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debes seleccionar un conductor'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final adminProvider =
            Provider.of<AdminProvider>(context, listen: false);
        final createdBy = adminProvider.currentUser?.id;

        await adminProvider.apiService.createNotification(
          title: _titleController.text,
          message: _messageController.text,
          type: _selectedType,
          targetId: _selectedType == 'route'
              ? _selectedRoute
              : (_selectedType == 'driver'
                  ? _selectedDriverId.toString()
                  : null),
          createdBy: createdBy,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notificación enviada exitosamente'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          _clearForm();
          _loadNotifications();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al enviar notificación: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _clearForm() {
    _titleController.clear();
    _messageController.clear();
    setState(() {
      _selectedType = 'drivers';
      _selectedRoute = null;
      _selectedDriverId = null;
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'Hace unos momentos';
    }
  }
}
