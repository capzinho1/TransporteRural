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

// Plantillas predefinidas para Región del Maule (Longaví - Linares)
class RouteTemplates {
  static final List<RouteTemplate> templates = [
    // Rutas desde Longaví
    RouteTemplate(
      id: 'LONGAVI-CHALET',
      name: 'Longaví - Chalet Quemado',
      description: 'Ruta entre Longaví y Chalet Quemado',
      category: 'Longaví',
      scheduleOptions: ['07:00', '09:00', '12:00', '15:00', '18:00', '20:00'],
      stops: [
        TemplateStop(
            nombre: 'Terminal Longaví',
            latitud: -36.0053,
            longitud: -71.6850,
            orden: 1),
        TemplateStop(
            nombre: 'Plaza de Longaví',
            latitud: -36.0040,
            longitud: -71.6820,
            orden: 2),
        TemplateStop(
            nombre: 'Cruce Camino Rural',
            latitud: -36.0200,
            longitud: -71.7000,
            orden: 3),
        TemplateStop(
            nombre: 'Chalet Quemado',
            latitud: -36.0400,
            longitud: -71.7200,
            orden: 4),
      ],
    ),
    RouteTemplate(
      id: 'CHALET-LONGAVI',
      name: 'Chalet Quemado - Longaví',
      description: 'Ruta de regreso desde Chalet Quemado a Longaví',
      category: 'Longaví',
      scheduleOptions: ['07:30', '09:30', '12:30', '15:30', '18:30', '20:30'],
      stops: [
        TemplateStop(
            nombre: 'Chalet Quemado',
            latitud: -36.0400,
            longitud: -71.7200,
            orden: 1),
        TemplateStop(
            nombre: 'Cruce Camino Rural',
            latitud: -36.0200,
            longitud: -71.7000,
            orden: 2),
        TemplateStop(
            nombre: 'Plaza de Longaví',
            latitud: -36.0040,
            longitud: -71.6820,
            orden: 3),
        TemplateStop(
            nombre: 'Terminal Longaví',
            latitud: -36.0053,
            longitud: -71.6850,
            orden: 4),
      ],
    ),
    RouteTemplate(
      id: 'LONGAVI-ROSAS',
      name: 'Longaví - Las Rosas',
      description: 'Ruta entre Longaví y Las Rosas',
      category: 'Longaví',
      scheduleOptions: ['06:30', '08:30', '11:00', '14:00', '17:00', '19:00'],
      stops: [
        TemplateStop(
            nombre: 'Terminal Longaví',
            latitud: -36.0053,
            longitud: -71.6850,
            orden: 1),
        TemplateStop(
            nombre: 'Salida Norte Longaví',
            latitud: -35.9950,
            longitud: -71.6800,
            orden: 2),
        TemplateStop(
            nombre: 'Camino a Las Rosas',
            latitud: -35.9700,
            longitud: -71.6900,
            orden: 3),
        TemplateStop(
            nombre: 'Las Rosas',
            latitud: -35.9500,
            longitud: -71.7000,
            orden: 4),
      ],
    ),
    RouteTemplate(
      id: 'ROSAS-LONGAVI',
      name: 'Las Rosas - Longaví',
      description: 'Ruta de regreso desde Las Rosas a Longaví',
      category: 'Longaví',
      scheduleOptions: ['07:00', '09:00', '11:30', '14:30', '17:30', '19:30'],
      stops: [
        TemplateStop(
            nombre: 'Las Rosas',
            latitud: -35.9500,
            longitud: -71.7000,
            orden: 1),
        TemplateStop(
            nombre: 'Camino a Las Rosas',
            latitud: -35.9700,
            longitud: -71.6900,
            orden: 2),
        TemplateStop(
            nombre: 'Salida Norte Longaví',
            latitud: -35.9950,
            longitud: -71.6800,
            orden: 3),
        TemplateStop(
            nombre: 'Terminal Longaví',
            latitud: -36.0053,
            longitud: -71.6850,
            orden: 4),
      ],
    ),
    RouteTemplate(
      id: 'LONGAVI-CRISTALES',
      name: 'Longaví - Los Cristales',
      description: 'Ruta entre Longaví y Los Cristales',
      category: 'Longaví',
      scheduleOptions: ['06:00', '08:00', '10:30', '13:30', '16:30', '19:00'],
      stops: [
        TemplateStop(
            nombre: 'Terminal Longaví',
            latitud: -36.0053,
            longitud: -71.6850,
            orden: 1),
        TemplateStop(
            nombre: 'Salida Sur Longaví',
            latitud: -36.0150,
            longitud: -71.6850,
            orden: 2),
        TemplateStop(
            nombre: 'Puente Los Cristales',
            latitud: -36.0350,
            longitud: -71.6750,
            orden: 3),
        TemplateStop(
            nombre: 'Los Cristales',
            latitud: -36.0500,
            longitud: -71.6650,
            orden: 4),
      ],
    ),
    RouteTemplate(
      id: 'CRISTALES-LONGAVI',
      name: 'Los Cristales - Longaví',
      description: 'Ruta de regreso desde Los Cristales a Longaví',
      category: 'Longaví',
      scheduleOptions: ['06:30', '08:30', '11:00', '14:00', '17:00', '19:30'],
      stops: [
        TemplateStop(
            nombre: 'Los Cristales',
            latitud: -36.0500,
            longitud: -71.6650,
            orden: 1),
        TemplateStop(
            nombre: 'Puente Los Cristales',
            latitud: -36.0350,
            longitud: -71.6750,
            orden: 2),
        TemplateStop(
            nombre: 'Salida Sur Longaví',
            latitud: -36.0150,
            longitud: -71.6850,
            orden: 3),
        TemplateStop(
            nombre: 'Terminal Longaví',
            latitud: -36.0053,
            longitud: -71.6850,
            orden: 4),
      ],
    ),

    // Rutas desde Linares
    RouteTemplate(
      id: 'LINARES-MAITENCILLO',
      name: 'Linares - Maitencillo',
      description: 'Ruta entre Linares y Maitencillo',
      category: 'Linares',
      scheduleOptions: ['06:30', '08:30', '11:00', '14:00', '17:00', '19:30'],
      stops: [
        TemplateStop(
            nombre: 'Terminal Linares',
            latitud: -35.8450,
            longitud: -71.5950,
            orden: 1),
        TemplateStop(
            nombre: 'Plaza de Armas Linares',
            latitud: -35.8470,
            longitud: -71.5970,
            orden: 2),
        TemplateStop(
            nombre: 'Salida Norte Linares',
            latitud: -35.8300,
            longitud: -71.6000,
            orden: 3),
        TemplateStop(
            nombre: 'Cruce Maitencillo',
            latitud: -35.8000,
            longitud: -71.6200,
            orden: 4),
        TemplateStop(
            nombre: 'Maitencillo',
            latitud: -35.7800,
            longitud: -71.6400,
            orden: 5),
      ],
    ),
    RouteTemplate(
      id: 'MAITENCILLO-LINARES',
      name: 'Maitencillo - Linares',
      description: 'Ruta de regreso desde Maitencillo a Linares',
      category: 'Linares',
      scheduleOptions: ['07:00', '09:00', '11:30', '14:30', '17:30', '20:00'],
      stops: [
        TemplateStop(
            nombre: 'Maitencillo',
            latitud: -35.7800,
            longitud: -71.6400,
            orden: 1),
        TemplateStop(
            nombre: 'Cruce Maitencillo',
            latitud: -35.8000,
            longitud: -71.6200,
            orden: 2),
        TemplateStop(
            nombre: 'Salida Norte Linares',
            latitud: -35.8300,
            longitud: -71.6000,
            orden: 3),
        TemplateStop(
            nombre: 'Plaza de Armas Linares',
            latitud: -35.8470,
            longitud: -71.5970,
            orden: 4),
        TemplateStop(
            nombre: 'Terminal Linares',
            latitud: -35.8450,
            longitud: -71.5950,
            orden: 5),
      ],
    ),
    RouteTemplate(
      id: 'LINARES-CABRAS',
      name: 'Linares - Las Cabras',
      description: 'Ruta entre Linares y Las Cabras',
      category: 'Linares',
      scheduleOptions: ['06:00', '08:00', '10:30', '13:30', '16:30', '19:00'],
      stops: [
        TemplateStop(
            nombre: 'Terminal Linares',
            latitud: -35.8450,
            longitud: -71.5950,
            orden: 1),
        TemplateStop(
            nombre: 'Mercado Linares',
            latitud: -35.8460,
            longitud: -71.5980,
            orden: 2),
        TemplateStop(
            nombre: 'Camino Rural Las Cabras',
            latitud: -35.8600,
            longitud: -71.6200,
            orden: 3),
        TemplateStop(
            nombre: 'Las Cabras',
            latitud: -35.8750,
            longitud: -71.6400,
            orden: 4),
      ],
    ),
    RouteTemplate(
      id: 'CABRAS-LINARES',
      name: 'Las Cabras - Linares',
      description: 'Ruta de regreso desde Las Cabras a Linares',
      category: 'Linares',
      scheduleOptions: ['06:30', '08:30', '11:00', '14:00', '17:00', '19:30'],
      stops: [
        TemplateStop(
            nombre: 'Las Cabras',
            latitud: -35.8750,
            longitud: -71.6400,
            orden: 1),
        TemplateStop(
            nombre: 'Camino Rural Las Cabras',
            latitud: -35.8600,
            longitud: -71.6200,
            orden: 2),
        TemplateStop(
            nombre: 'Mercado Linares',
            latitud: -35.8460,
            longitud: -71.5980,
            orden: 3),
        TemplateStop(
            nombre: 'Terminal Linares',
            latitud: -35.8450,
            longitud: -71.5950,
            orden: 4),
      ],
    ),
    RouteTemplate(
      id: 'LINARES-SEMILLERO',
      name: 'Linares - Semillero',
      description: 'Ruta entre Linares y Semillero',
      category: 'Linares',
      scheduleOptions: ['05:30', '07:30', '10:00', '13:00', '16:00', '18:30'],
      stops: [
        TemplateStop(
            nombre: 'Terminal Linares',
            latitud: -35.8450,
            longitud: -71.5950,
            orden: 1),
        TemplateStop(
            nombre: 'Hospital Linares',
            latitud: -35.8500,
            longitud: -71.5900,
            orden: 2),
        TemplateStop(
            nombre: 'Salida Este Linares',
            latitud: -35.8550,
            longitud: -71.5750,
            orden: 3),
        TemplateStop(
            nombre: 'Cruce Semillero',
            latitud: -35.8700,
            longitud: -71.5500,
            orden: 4),
        TemplateStop(
            nombre: 'Semillero',
            latitud: -35.8850,
            longitud: -71.5300,
            orden: 5),
      ],
    ),
    RouteTemplate(
      id: 'SEMILLERO-LINARES',
      name: 'Semillero - Linares',
      description: 'Ruta de regreso desde Semillero a Linares',
      category: 'Linares',
      scheduleOptions: ['06:00', '08:00', '10:30', '13:30', '16:30', '19:00'],
      stops: [
        TemplateStop(
            nombre: 'Semillero',
            latitud: -35.8850,
            longitud: -71.5300,
            orden: 1),
        TemplateStop(
            nombre: 'Cruce Semillero',
            latitud: -35.8700,
            longitud: -71.5500,
            orden: 2),
        TemplateStop(
            nombre: 'Salida Este Linares',
            latitud: -35.8550,
            longitud: -71.5750,
            orden: 3),
        TemplateStop(
            nombre: 'Hospital Linares',
            latitud: -35.8500,
            longitud: -71.5900,
            orden: 4),
        TemplateStop(
            nombre: 'Terminal Linares',
            latitud: -35.8450,
            longitud: -71.5950,
            orden: 5),
      ],
    ),
  ];

  static List<String> get categories {
    return templates.map((t) => t.category).toSet().toList()..sort();
  }

  static List<RouteTemplate> getByCategory(String category) {
    return templates.where((t) => t.category == category).toList();
  }
}
