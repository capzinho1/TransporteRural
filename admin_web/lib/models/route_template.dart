class RouteTemplate {
  final String id;
  final String name;
  final String description;
  final List<TemplateStop> stops;
  final List<String> scheduleOptions;
  final String category;

  RouteTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.stops,
    required this.scheduleOptions,
    required this.category,
  });
}

class TemplateStop {
  final String nombre;
  final double latitud;
  final double longitud;
  final int orden;

  TemplateStop({
    required this.nombre,
    required this.latitud,
    required this.longitud,
    required this.orden,
  });

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'latitud': latitud,
      'longitud': longitud,
      'orden': orden,
    };
  }
}

// DEPRECATED: Las plantillas ahora se basan en las rutas existentes en la base de datos
// Este archivo se mantiene solo para compatibilidad con el modelo RouteTemplate si se necesita
// Las rutas creadas en la BD se usan como plantillas para crear nuevas rutas
