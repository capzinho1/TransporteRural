class UserReport {
  final int id;
  final int? userId;
  final String? routeId;
  final String? busId;
  final int? tripId;
  final String type; // 'complaint', 'suggestion', 'compliment', 'issue', 'other'
  final String title;
  final String description;
  final String status; // 'pending', 'reviewed', 'resolved', 'rejected', 'archived'
  final String? adminResponse;
  final int? reviewedBy;
  final DateTime? reviewedAt;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final List<String>? tags; // Alertas predefinidas
  final DateTime createdAt;
  final DateTime updatedAt;

  UserReport({
    required this.id,
    this.userId,
    this.routeId,
    this.busId,
    this.tripId,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    this.adminResponse,
    this.reviewedBy,
    this.reviewedAt,
    required this.priority,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserReport.fromJson(Map<String, dynamic> json) {
    return UserReport(
      id: json['id'] ?? 0,
      userId: json['user_id'],
      routeId: json['route_id'],
      busId: json['bus_id'],
      tripId: json['trip_id'],
      type: json['type'] ?? 'other',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? 'pending',
      adminResponse: json['admin_response'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'])
          : null,
      priority: json['priority'] ?? 'medium',
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'route_id': routeId,
      'bus_id': busId,
      'trip_id': tripId,
      'type': type,
      'title': title,
      'description': description,
      'status': status,
      'admin_response': adminResponse,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'priority': priority,
      if (tags != null) 'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get typeLabel {
    switch (type) {
      case 'complaint':
        return 'Queja';
      case 'suggestion':
        return 'Sugerencia';
      case 'compliment':
        return 'Elogio';
      case 'issue':
        return 'Problema';
      case 'other':
        return 'Otro';
      default:
        return type;
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'reviewed':
        return 'Revisado';
      case 'resolved':
        return 'Resuelto';
      case 'rejected':
        return 'Rechazado';
      case 'archived':
        return 'Archivado';
      default:
        return status;
    }
  }

  String get priorityLabel {
    switch (priority) {
      case 'low':
        return 'Baja';
      case 'medium':
        return 'Media';
      case 'high':
        return 'Alta';
      case 'urgent':
        return 'Urgente';
      default:
        return priority;
    }
  }
}

