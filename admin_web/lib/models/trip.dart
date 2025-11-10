class Trip {
  final int id;
  final String busId;
  final String? routeId;
  final int? driverId;
  final int? companyId;
  final DateTime scheduledStart;
  final DateTime? actualStart;
  final DateTime? scheduledEnd;
  final DateTime? actualEnd;
  final String status; // 'scheduled', 'in_progress', 'completed', 'cancelled', 'delayed'
  final int? durationMinutes;
  final int? delayMinutes;
  final int passengerCount;
  final int? capacity;
  final Map<String, dynamic>? startLocation;
  final Map<String, dynamic>? endLocation;
  final String? notes;
  final String? issues;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.busId,
    this.routeId,
    this.driverId,
    this.companyId,
    required this.scheduledStart,
    this.actualStart,
    this.scheduledEnd,
    this.actualEnd,
    required this.status,
    this.durationMinutes,
    this.delayMinutes,
    this.passengerCount = 0,
    this.capacity,
    this.startLocation,
    this.endLocation,
    this.notes,
    this.issues,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? 0,
      busId: json['bus_id'] ?? '',
      routeId: json['route_id'],
      driverId: json['driver_id'],
      companyId: json['company_id'],
      scheduledStart: json['scheduled_start'] != null
          ? DateTime.parse(json['scheduled_start'])
          : DateTime.now(),
      actualStart: json['actual_start'] != null
          ? DateTime.parse(json['actual_start'])
          : null,
      scheduledEnd: json['scheduled_end'] != null
          ? DateTime.parse(json['scheduled_end'])
          : null,
      actualEnd: json['actual_end'] != null
          ? DateTime.parse(json['actual_end'])
          : null,
      status: json['status'] ?? 'scheduled',
      durationMinutes: json['duration_minutes'],
      delayMinutes: json['delay_minutes'],
      passengerCount: json['passenger_count'] ?? 0,
      capacity: json['capacity'],
      startLocation: json['start_location'],
      endLocation: json['end_location'],
      notes: json['notes'],
      issues: json['issues'],
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
      'bus_id': busId,
      'route_id': routeId,
      'driver_id': driverId,
      'company_id': companyId,
      'scheduled_start': scheduledStart.toIso8601String(),
      'actual_start': actualStart?.toIso8601String(),
      'scheduled_end': scheduledEnd?.toIso8601String(),
      'actual_end': actualEnd?.toIso8601String(),
      'status': status,
      'duration_minutes': durationMinutes,
      'delay_minutes': delayMinutes,
      'passenger_count': passengerCount,
      'capacity': capacity,
      'start_location': startLocation,
      'end_location': endLocation,
      'notes': notes,
      'issues': issues,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

