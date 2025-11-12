class Ruta {
  final String routeId; // Cambiado de int a String
  final String name;
  final dynamic schedule; // Cambiado a dynamic para soportar String o Map
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
    print('📦 [RUTA_MODEL] Parseando ruta desde JSON');
    print('   route_id: ${json['route_id']}');
    print('   name: ${json['name']}');
    print('   polyline: ${json['polyline'] != null ? (json['polyline'] is String ? "String (${(json['polyline'] as String).length} chars)" : "No es String: ${json['polyline'].runtimeType}") : "null"}');
    print('   stops: ${json['stops'] != null ? (json['stops'] is List ? "List (${(json['stops'] as List).length} items)" : "No es List: ${json['stops'].runtimeType}") : "null"}');
    
    final stopsList = (json['stops'] as List<dynamic>?)
            ?.map((parada) => Parada.fromJson(parada))
            .toList() ??
        [];
    
    final polylineValue = json['polyline'] ?? '';
    final polylineStr = polylineValue is String ? polylineValue : '';
    
    print('   stops parseadas: ${stopsList.length}');
    print('   polyline final: ${polylineStr.isNotEmpty ? "Sí (${polylineStr.length} chars)" : "No"}');
    
    return Ruta(
      routeId: json['route_id']?.toString() ?? '',
      name: json['name'] ?? '',
      schedule: json['schedule'] ?? '',
      stops: stopsList,
      polyline: polylineStr,
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
    String? routeId,
    String? name,
    dynamic schedule,
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
  final int? id;
  final String name;
  final double latitude;
  final double longitude;
  final int? order;
  final int? orden; // Soporte para ambos nombres

  Parada({
    this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.order,
    this.orden,
  });

  factory Parada.fromJson(Map<String, dynamic> json) {
    return Parada(
      id: json['id'],
      name: json['name'] ?? json['nombre'] ?? '',
      latitude: (json['latitude'] ?? json['latitud'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? json['longitud'] ?? 0.0).toDouble(),
      order: json['order'] ?? json['orden'],
      orden: json['orden'] ?? json['order'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'order': order ?? orden,
    };
  }
}
