class Ruta {
  final String routeId;
  final String name;
  final String schedule;
  final List<Parada> stops;
  final String polyline;

  Ruta({
    required this.routeId,
    required this.name,
    required this.schedule,
    required this.stops,
    required this.polyline,
  });

  factory Ruta.fromJson(Map<String, dynamic> json) {
    return Ruta(
      routeId: json['route_id']?.toString() ?? '',
      name: json['name'] ?? '',
      schedule: json['schedule'] ?? '',
      stops: (json['stops'] as List<dynamic>?)
              ?.map((parada) => Parada.fromJson(parada))
              .toList() ??
          [],
      polyline: json['polyline'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'name': name,
      'schedule': schedule,
      'stops': stops.map((parada) => parada.toJson()).toList(),
      'polyline': polyline,
    };
  }
}

class Parada {
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final int? order;

  Parada({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.order,
  });

  factory Parada.fromJson(Map<String, dynamic> json) {
    return Parada(
      id: json['id'],
      name: json['name'] ?? json['nombre'] ?? '',
      latitude: (json['latitude'] ?? json['latitud'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['longitud'] ?? 0.0).toDouble(),
      order: json['order'] ?? json['orden'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      if (order != null) 'order': order,
    };
  }
}
