class BusLocation {
  final int busId;
  final int routeId;
  final int driverId;
  final double latitude;
  final double longitude;
  final String status;
  final String lastUpdate;

  BusLocation({
    required this.busId,
    required this.routeId,
    required this.driverId,
    required this.latitude,
    required this.longitude,
    required this.status,
    required this.lastUpdate,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    return BusLocation(
      busId: json['bus_id'] ?? 0,
      routeId: json['route_id'] ?? 0,
      driverId: json['driver_id'] ?? 0,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'inactive',
      lastUpdate: json['last_update'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bus_id': busId,
      'route_id': routeId,
      'driver_id': driverId,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'last_update': lastUpdate,
    };
  }

  BusLocation copyWith({
    int? busId,
    int? routeId,
    int? driverId,
    double? latitude,
    double? longitude,
    String? status,
    String? lastUpdate,
  }) {
    return BusLocation(
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      driverId: driverId ?? this.driverId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
