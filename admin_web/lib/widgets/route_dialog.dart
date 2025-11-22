import 'package:flutter/material.dart';
import '../models/ruta.dart';
import 'route_map_editor.dart';

/// Widget de diálogo para crear/editar rutas con pestañas
class RouteDialog extends StatefulWidget {
  final Ruta? ruta;
  final Function(Ruta) onCreateRoute;

  const RouteDialog({
    super.key,
    this.ruta,
    required this.onCreateRoute,
  });

  @override
  State<RouteDialog> createState() => _RouteDialogState();
}

class _RouteDialogState extends State<RouteDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _routeStartController = TextEditingController(); // Inicio
  final TextEditingController _routeEndController = TextEditingController(); // Final
  final TextEditingController _scheduleController = TextEditingController();

  List<Parada> _routeStops = [];
  String? _generatedPolyline;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Actualizar UI cuando cambie de pestaña
    });

    // Cargar datos existentes si es edición
    if (widget.ruta != null) {
      _nameController.text = widget.ruta!.name;
      _scheduleController.text = widget.ruta!.schedule;
      _routeStops = List.from(widget.ruta!.stops);
      _generatedPolyline = widget.ruta!.polyline;
      
      // Si el nombre tiene formato "Inicio - Final", separarlo
      if (widget.ruta!.name.contains(' - ')) {
        final parts = widget.ruta!.name.split(' - ');
        if (parts.length >= 2) {
          _routeStartController.text = parts[0].trim();
          _routeEndController.text = parts.sublist(1).join(' - ').trim();
        } else {
          _routeStartController.text = widget.ruta!.name;
        }
      } else {
        // Si no tiene el formato, intentar inferir desde las paradas
        if (widget.ruta!.stops.isNotEmpty) {
          _routeStartController.text = widget.ruta!.stops.first.name;
          _routeEndController.text = widget.ruta!.stops.last.name;
        }
      }
    } else {
      _scheduleController.text = '06:00 - 22:00';
    }
    
    // Actualizar nombre inicial después de cargar los datos
    _updateRouteName();
  }

  // Actualizar el nombre completo cuando cambien inicio o final
  void _updateRouteName() {
    final start = _routeStartController.text.trim();
    final end = _routeEndController.text.trim();
    
    if (start.isNotEmpty && end.isNotEmpty) {
      _nameController.text = '$start - $end';
    } else if (start.isNotEmpty) {
      _nameController.text = start;
    } else if (end.isNotEmpty) {
      _nameController.text = end;
    } else {
      _nameController.text = '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _routeStartController.dispose();
    _routeEndController.dispose();
    _scheduleController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // Actualizar nombre antes de validar
    _updateRouteName();
    
    if (_routeStartController.text.trim().isEmpty || 
        _routeEndController.text.trim().isEmpty || 
        _scheduleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos obligatorios (Inicio, Final y Horario)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_routeStops.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes agregar al menos 2 paradas en el mapa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Generar routeId si no existe (para nuevas rutas)
    String routeId;
    if (widget.ruta != null) {
      routeId = widget.ruta!.routeId;
    } else {
      // Generar ID único basado en el nombre
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final namePart = _nameController.text
          .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
          .substring(0,
              _nameController.text.length > 5 ? 5 : _nameController.text.length)
          .toUpperCase();
      routeId = 'R${namePart}_$timestamp';
    }

    final newRuta = Ruta(
      routeId: routeId,
      name: _nameController.text.trim(),
      schedule: _scheduleController.text.trim(),
      stops: _routeStops,
      polyline: _generatedPolyline ?? '',
      active: widget.ruta?.active ?? true,
    );

    Navigator.pop(context);
    widget.onCreateRoute(newRuta);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 900,
        height: 700,
        child: Column(
          children: [
            // Header con título y botones
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.purple,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.ruta == null ? 'Crear Nueva Ruta' : 'Editar Ruta',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Pestañas (solo visuales, no interactivas - muestran progreso)
            IgnorePointer(
              child: TabBar(
                controller: _tabController,
                isScrollable: false,
                tabs: const [
                  Tab(icon: Icon(Icons.route), text: 'Crear Línea'),
                  Tab(icon: Icon(Icons.location_on), text: 'Agregar Paradas'),
                  Tab(icon: Icon(Icons.info), text: 'Información'),
                ],
              ),
            ),

            // Contenido de las pestañas (sin deslizar, solo navegación programática)
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics:
                    const NeverScrollableScrollPhysics(), // Deshabilitar deslizamiento
                children: [
                  // Primera pestaña: Crear línea
                  RouteMapEditor(
                    mode: RouteMapMode.createLine,
                    initialPolyline: _generatedPolyline,
                    onPolylineGenerated: (polyline) {
                      setState(() {
                        _generatedPolyline = polyline;
                      });
                    },
                    onStopsChanged: (_) {}, // No se usan paradas en este modo
                  ),

                  // Segunda pestaña: Agregar paradas
                  RouteMapEditor(
                    key: ValueKey('addStops_${_generatedPolyline ?? 'empty'}'),
                    mode: RouteMapMode.addStops,
                    initialStops: _routeStops.isEmpty ? null : _routeStops,
                    initialPolyline: _generatedPolyline,
                    onStopsChanged: (stops) {
                      setState(() {
                        _routeStops = stops;
                      });
                    },
                    onPolylineGenerated:
                        null, // No se puede cambiar la polilínea aquí
                  ),

                  // Tercera pestaña: Información
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Campo de Inicio
                        TextField(
                          controller: _routeStartController,
                          decoration: const InputDecoration(
                            labelText: 'Punto de Inicio *',
                            hintText: 'Ej: Linares',
                            prefixIcon: Icon(Icons.radio_button_checked, color: Colors.green),
                            helperText: 'Ciudad o punto de inicio de la ruta',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            _updateRouteName();
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        // Campo de Final
                        TextField(
                          controller: _routeEndController,
                          decoration: const InputDecoration(
                            labelText: 'Punto de Final *',
                            hintText: 'Ej: Talca',
                            prefixIcon: Icon(Icons.radio_button_unchecked, color: Colors.red),
                            helperText: 'Ciudad o punto final de la ruta',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            _updateRouteName();
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        // Vista previa del nombre completo (solo lectura)
                        Builder(
                          builder: (context) {
                            final start = _routeStartController.text.trim();
                            final end = _routeEndController.text.trim();
                            final previewName = start.isNotEmpty && end.isNotEmpty
                                ? '$start - $end'
                                : (start.isNotEmpty ? start : (end.isNotEmpty ? end : ''));
                            
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.route, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Nombre de Ruta:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          previewName.isNotEmpty
                                              ? previewName
                                              : 'Se generará automáticamente',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: previewName.isNotEmpty
                                                ? Colors.black87
                                                : Colors.grey[600],
                                            fontStyle: previewName.isEmpty
                                                ? FontStyle.italic
                                                : FontStyle.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Campo oculto para el nombre completo (para guardar)
                        Visibility(
                          visible: false,
                          child: TextField(
                            controller: _nameController,
                            enabled: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _scheduleController,
                          decoration: const InputDecoration(
                            labelText: 'Horario *',
                            hintText: '06:00 - 22:00',
                            prefixIcon: Icon(Icons.schedule),
                            helperText: 'Horario de operación de la ruta',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Resumen de la ruta:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (_generatedPolyline != null &&
                                  _generatedPolyline!.isNotEmpty)
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green, size: 20),
                                    SizedBox(width: 8),
                                    Text('Línea de ruta creada'),
                                  ],
                                )
                              else
                                const Row(
                                  children: [
                                    Icon(Icons.error,
                                        color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text('Línea de ruta no creada'),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    _routeStops.length >= 2
                                        ? Icons.check_circle
                                        : Icons.error,
                                    color: _routeStops.length >= 2
                                        ? Colors.green
                                        : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Paradas: ${_routeStops.length}',
                                    style: TextStyle(
                                      color: _routeStops.length >= 2
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                              if (_routeStops.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Paradas definidas:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ..._routeStops.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final stop = entry.value;
                                  return ListTile(
                                    dense: true,
                                    leading: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: index == 0
                                          ? Colors.green
                                          : index == _routeStops.length - 1
                                              ? Colors.red
                                              : Colors.blue,
                                      child: Text(
                                        '${index + 1}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    title: Text(stop.name),
                                    subtitle: Text(
                                      '${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Botones de acción
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón "Cancelar" a la izquierda
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  // Botones de la derecha
                  Row(
                    children: [
                      // Botón "Atrás" (excepto en la primera pestaña)
                      if (_tabController.index > 0) ...[
                        TextButton.icon(
                          onPressed: () {
                            _tabController.animateTo(_tabController.index - 1);
                          },
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('Atrás'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Botón "Siguiente" en las primeras dos pestañas
                      if (_tabController.index == 0)
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_generatedPolyline == null ||
                                _generatedPolyline!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Por favor crea la línea de ruta en el mapa antes de continuar'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            _tabController.animateTo(1);
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Siguiente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        )
                      else if (_tabController.index == 1)
                        ElevatedButton.icon(
                          onPressed: () {
                            if (_routeStops.length < 2) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Por favor agrega al menos 2 paradas antes de continuar'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            _tabController.animateTo(2);
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Siguiente'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      // Botón "Crear Ruta" solo en la última pestaña
                      if (_tabController.index == 2) ...[
                        ElevatedButton(
                          onPressed: _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(widget.ruta == null
                              ? 'Crear Ruta'
                              : 'Actualizar Ruta'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
