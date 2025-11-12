import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/app_localizations.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.loadNotifications();
  }

  IconData _getTypeIcon(String type) {
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

  String _getTypeLabel(String type, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    if (localizations == null) {
      switch (type) {
        case 'drivers':
          return 'Todos los Conductores';
        case 'route':
          return 'Por Ruta';
        case 'driver':
          return 'Personal';
        default:
          return 'Desconocido';
      }
    }
    switch (type) {
      case 'drivers':
        return localizations.translate('all_drivers');
      case 'route':
        return localizations.translate('by_route');
      case 'driver':
        return localizations.translate('personal');
      default:
        return localizations.translate('unknown');
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'drivers':
        return Colors.blue;
      case 'route':
        return Colors.green;
      case 'driver':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date, BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (localizations == null) {
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

    if (difference.inDays > 0) {
      return '${localizations.translate('ago')} ${difference.inDays} ${difference.inDays > 1 ? localizations.translate('days_plural') : localizations.translate('days')}';
    } else if (difference.inHours > 0) {
      return '${localizations.translate('ago')} ${difference.inHours} ${difference.inHours > 1 ? localizations.translate('hours_plural') : localizations.translate('hours')}';
    } else if (difference.inMinutes > 0) {
      return '${localizations.translate('ago')} ${difference.inMinutes} ${difference.inMinutes > 1 ? localizations.translate('minutes_ago_plural') : localizations.translate('minutes_ago')}';
    } else {
      return localizations.translate('moments_ago');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.notifications),
            const SizedBox(width: 8),
            Text(AppLocalizations.of(context)?.translate('notifications') ?? 'Notificaciones'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
            tooltip: AppLocalizations.of(context)?.translate('refresh') ?? 'Actualizar',
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          if (appProvider.isLoading && appProvider.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (appProvider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)?.translate('no_notifications') ?? 'No hay notificaciones',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.translate('admin_notifications_here') ?? 'Las notificaciones del administrador aparecerán aquí',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadNotifications,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: appProvider.notifications.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final notification = appProvider.notifications[index];
                final typeColor = _getTypeColor(notification.type);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: typeColor.withValues(alpha: 0.1),
                      child: Icon(
                        _getTypeIcon(notification.type),
                        color: typeColor,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          notification.message,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Chip(
                              label: Text(
                                _getTypeLabel(notification.type, context),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: typeColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: typeColor.withValues(alpha: 0.1),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(notification.sentAt, context),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
