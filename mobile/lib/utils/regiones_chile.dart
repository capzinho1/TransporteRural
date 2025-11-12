/// Lista de regiones de Chile para el selector de registro
class RegionesChile {
  static const List<Region> regiones = [
    Region(codigo: 'XV', nombre: 'Arica y Parinacota'),
    Region(codigo: 'I', nombre: 'Tarapacá'),
    Region(codigo: 'II', nombre: 'Antofagasta'),
    Region(codigo: 'III', nombre: 'Atacama'),
    Region(codigo: 'IV', nombre: 'Coquimbo'),
    Region(codigo: 'V', nombre: 'Valparaíso'),
    Region(codigo: 'VI', nombre: "O'Higgins"),
    Region(codigo: 'VII', nombre: 'Maule'),
    Region(codigo: 'VIII', nombre: 'Biobío'),
    Region(codigo: 'IX', nombre: 'La Araucanía'),
    Region(codigo: 'XIV', nombre: 'Los Ríos'),
    Region(codigo: 'X', nombre: 'Los Lagos'),
    Region(codigo: 'XI', nombre: 'Aysén'),
    Region(codigo: 'XII', nombre: 'Magallanes'),
    Region(codigo: 'XIII', nombre: 'Metropolitana'),
    Region(codigo: 'XVI', nombre: 'Ñuble'),
  ];

  static List<String> get nombres => regiones.map((r) => r.nombre).toList();
}

class Region {
  final String codigo;
  final String nombre;

  const Region({
    required this.codigo,
    required this.nombre,
  });
}

