class BusLocation {
  final int? id; // ID de la tabla
  final String busId; // Cambiado a String
  final String? routeId; // Cambiado a String y nullable
  final int? driverId; // Nullable
  final int? companyId; // ID de la empresa
  final double latitude;
  final double longitude;
  final String status;
  final String? lastUpdate; // Nullable

  BusLocation({
    this.id,
    required this.busId,
    this.routeId,
    this.driverId,
    this.companyId,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.lastUpdate,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    return BusLocation(
      id: json['id'],
      busId: json['bus_id']?.toString() ?? '',
      routeId: json['route_id']?.toString(),
      driverId: json['driver_id'],
      companyId: json['company_id'],
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'inactive',
      lastUpdate: json['last_update'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'bus_id': busId,
      if (routeId != null) 'route_id': routeId,
      if (driverId != null) 'driver_id': driverId,
      if (companyId != null) 'company_id': companyId,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      if (lastUpdate != null) 'last_update': lastUpdate,
    };
  }

  BusLocation copyWith({
    int? id,
    String? busId,
    String? routeId,
    int? driverId,
    int? companyId,
    double? latitude,
    double? longitude,
    String? status,
    String? lastUpdate,
  }) {
    return BusLocation(
      id: id ?? this.id,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      driverId: driverId ?? this.driverId,
      companyId: companyId ?? this.companyId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
