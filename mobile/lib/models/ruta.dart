class Ruta {
  final int routeId;
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
      routeId: json['route_id'] ?? 0,
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

  Ruta copyWith({
    int? routeId,
    String? name,
    String? schedule,
    List<Parada>? stops,
    String? polyline,
  }) {
    return Ruta(
      routeId: routeId ?? this.routeId,
      name: name ?? this.name,
      schedule: schedule ?? this.schedule,
      stops: stops ?? this.stops,
      polyline: polyline ?? this.polyline,
    );
  }
}

class Parada {
  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int? order;

  Parada({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.order,
  });

  factory Parada.fromJson(Map<String, dynamic> json) {
    return Parada(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      order: json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'order': order,
    };
  }
}
