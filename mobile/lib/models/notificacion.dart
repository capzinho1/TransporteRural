class Notificacion {
  final int id;
  final String title;
  final String message;
  final String type; // 'global', 'drivers', 'route', 'driver'
  final String? targetId; // route_id o driver_id según el tipo
  final DateTime sentAt;
  final int? createdBy;

  Notificacion({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.targetId,
    required this.sentAt,
    this.createdBy,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'global',
      targetId: json['target_id']?.toString(),
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : DateTime.now(),
      createdBy: json['created_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'target_id': targetId,
      'sent_at': sentAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  String get typeLabel {
    switch (type) {
      case 'global':
        return 'Global';
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
}

