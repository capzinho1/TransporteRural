class BusLocation {
  final int? id; // ID de la tabla
  final String busId; // Cambiado a String
  final String? routeId; // Cambiado a String y nullable
  final String? nombreRuta; // Nombre de la ruta asignado al bus (para búsqueda)
  final int? driverId; // Nullable
  final int? companyId; // ID de la empresa
  final String? companyName; // Nombre de la empresa
  final String? driverName; // Nombre del conductor
  final double latitude;
  final double longitude;
  final String status;
  final String? lastUpdate; // Nullable

  BusLocation({
    this.id,
    required this.busId,
    this.routeId,
    this.nombreRuta,
    this.driverId,
    this.companyId,
    this.companyName,
    this.driverName,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.lastUpdate,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    // Manejar diferentes estructuras de respuesta del backend
    String? companyName;
    String? driverName;
    
    // Si viene como objeto anidado (formato Supabase JOIN)
    if (json['companies'] != null && json['companies'] is Map) {
      companyName = json['companies']['name'];
    } else if (json['company_name'] != null) {
      // Si viene como campo plano (después de transformación)
      companyName = json['company_name'];
    }
    
    // Intentar obtener el nombre del conductor de diferentes formas
    if (json['users'] != null && json['users'] is Map) {
      driverName = json['users']['name'];
    } else if (json['drivers'] != null && json['drivers'] is Map) {
      driverName = json['drivers']['name'];
    } else if (json['driver_name'] != null) {
      // Si viene como campo plano (después de transformación)
      driverName = json['driver_name'];
    }
    
    return BusLocation(
      id: json['id'],
      busId: json['bus_id']?.toString() ?? '',
      routeId: json['route_id']?.toString(),
      nombreRuta: json['nombre_ruta']?.toString(),
      driverId: json['driver_id'],
      companyId: json['company_id'],
      companyName: companyName,
      driverName: driverName,
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'inactive',
      lastUpdate: json['last_update'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bus_id': busId,
      'route_id': routeId,
      'nombre_ruta': nombreRuta,
      'driver_id': driverId,
      'company_id': companyId,
      'company_name': companyName,
      'driver_name': driverName,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'last_update': lastUpdate,
    };
  }

  BusLocation copyWith({
    int? id,
    String? busId,
    String? routeId,
    String? nombreRuta,
    int? driverId,
    int? companyId,
    String? companyName,
    String? driverName,
    double? latitude,
    double? longitude,
    String? status,
    String? lastUpdate,
  }) {
    return BusLocation(
      id: id ?? this.id,
      busId: busId ?? this.busId,
      routeId: routeId ?? this.routeId,
      nombreRuta: nombreRuta ?? this.nombreRuta,
      driverId: driverId ?? this.driverId,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      driverName: driverName ?? this.driverName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
    );
  }
}
