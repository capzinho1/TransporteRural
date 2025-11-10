import 'dart:convert';

class Ruta {
  final String routeId;
  final String name;
  final String schedule;
  final List<Parada> stops;
  final String polyline;
  final int? companyId; // ID de la empresa
  final bool? active; // Estado activo/inactivo

  Ruta({
    required this.routeId,
    required this.name,
    required this.schedule,
    required this.stops,
    required this.polyline,
    this.companyId,
    this.active,
  });

  factory Ruta.fromJson(Map<String, dynamic> json) {
    // Manejar schedule que puede ser String o JSONB
    String scheduleValue = '';
    if (json['schedule'] != null) {
      if (json['schedule'] is String) {
        scheduleValue = json['schedule'];
      } else {
        scheduleValue = jsonEncode(json['schedule']);
      }
    }
    
    // Manejar stops que puede ser List o JSONB
    List<Parada> stopsList = [];
    if (json['stops'] != null) {
      if (json['stops'] is List) {
        stopsList = (json['stops'] as List<dynamic>)
            .map((parada) => Parada.fromJson(parada))
            .toList();
      } else if (json['stops'] is Map) {
        // Si es un objeto JSONB, intentar convertirlo
        stopsList = [];
      }
    }
    
    return Ruta(
      routeId: json['route_id']?.toString() ?? '',
      name: json['name'] ?? '',
      schedule: scheduleValue,
      stops: stopsList,
      polyline: json['polyline'] ?? '',
      companyId: json['company_id'],
      active: json['active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'name': name,
      'schedule': schedule,
      'stops': stops.map((parada) => parada.toJson()).toList(),
      'polyline': polyline,
      if (companyId != null) 'company_id': companyId,
      if (active != null) 'active': active,
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
