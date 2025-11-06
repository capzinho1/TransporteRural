import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'global';
  String? _selectedRoute;

  final List<Map<String, dynamic>> _sentNotifications = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadRutas();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
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
              const Text(
                'Centro de Notificaciones',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Envía notificaciones a usuarios del sistema',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 32),

              // Formulario de nueva notificación
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Formulario
                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Nueva Notificación',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Tipo de notificación
                              const Text(
                                'Tipo de Notificación',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'global',
                                    label: Text('Global'),
                                    icon: Icon(Icons.public, size: 16),
                                  ),
                                  ButtonSegment(
                                    value: 'route',
                                    label: Text('Por Ruta'),
                                    icon: Icon(Icons.route, size: 16),
                                  ),
                                  ButtonSegment(
                                    value: 'drivers',
                                    label: Text('Conductores'),
                                    icon: Icon(Icons.drive_eta, size: 16),
                                  ),
                                ],
                                selected: {_selectedType},
                                onSelectionChanged: (Set<String> newSelection) {
                                  setState(() {
                                    _selectedType = newSelection.first;
                                    _selectedRoute = null;
                                  });
                                },
                              ),

                              const SizedBox(height: 24),

                              // Selector de ruta (si es por ruta)
                              if (_selectedType == 'route') ...[
                                DropdownButtonFormField<String>(
                                  value: _selectedRoute,
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
                                    if (value == null) {
                                      return 'Selecciona una ruta';
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
                                      onPressed: _sendNotification,
                                      icon: const Icon(Icons.send),
                                      label: const Text('Enviar'),
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
              const Text(
                'Historial de Notificaciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              if (_sentNotifications.isEmpty)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.notifications_none,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay notificaciones enviadas',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Card(
                  elevation: 2,
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sentNotifications.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final notification = _sentNotifications[
                          _sentNotifications.length - 1 - index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Icon(
                            _getTypeIconForNotification(notification['type']),
                            color: Colors.blue,
                          ),
                        ),
                        title: Text(
                          notification['title'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification['message']),
                            const SizedBox(height: 4),
                            Text(
                              notification['timestamp'],
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        trailing: Chip(
                          label: Text(
                            _getTypeLabelForNotification(notification['type']),
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue[100],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getTypeIcon() {
    switch (_selectedType) {
      case 'global':
        return Icons.public;
      case 'route':
        return Icons.route;
      case 'drivers':
        return Icons.drive_eta;
      default:
        return Icons.notifications;
    }
  }

  String _getTypeLabel() {
    switch (_selectedType) {
      case 'global':
        return 'Notificación Global';
      case 'route':
        return _selectedRoute != null
            ? 'Ruta: $_selectedRoute'
            : 'Notificación por Ruta';
      case 'drivers':
        return 'Para Conductores';
      default:
        return 'Notificación';
    }
  }

  IconData _getTypeIconForNotification(String type) {
    switch (type) {
      case 'global':
        return Icons.public;
      case 'route':
        return Icons.route;
      case 'drivers':
        return Icons.drive_eta;
      default:
        return Icons.notifications;
    }
  }

  String _getTypeLabelForNotification(String type) {
    switch (type) {
      case 'global':
        return 'Global';
      case 'route':
        return 'Por Ruta';
      case 'drivers':
        return 'Conductores';
      default:
        return 'Desconocido';
    }
  }

  void _sendNotification() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _sentNotifications.add({
          'title': _titleController.text,
          'message': _messageController.text,
          'type': _selectedType,
          'route': _selectedRoute,
          'timestamp': DateTime.now().toString().substring(0, 16),
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificación enviada exitosamente'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      _clearForm();
    }
  }

  void _clearForm() {
    _titleController.clear();
    _messageController.clear();
    setState(() {
      _selectedType = 'global';
      _selectedRoute = null;
    });
  }
}
