import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/ruta.dart';
import '../config/openstreetmap_config.dart';
import '../services/geocoding_service.dart';
import '../services/routing_service.dart';

/// Tipo de parada
enum StopType {
  inicio,
  intermedia,
  final_,
}

/// Modo de operación del editor
enum RouteMapMode {
  createLine, // Solo crear la línea/polilínea
  addStops, // Solo agregar paradas (la línea ya debe existir)
}

/// Widget de mapa interactivo para crear/editar rutas
/// Permite primero crear la polilínea y luego agregar paradas
class RouteMapEditor extends StatefulWidget {
  final List<Parada>? initialStops;
  final String? initialPolyline;
  final Function(List<Parada>) onStopsChanged;
  final Function(String?)? onPolylineGenerated;
  final RouteMapMode mode;

  const RouteMapEditor({
    super.key,
    this.initialStops,
    this.initialPolyline,
    required this.onStopsChanged,
    this.onPolylineGenerated,
    this.mode = RouteMapMode.createLine,
  });

  @override
  State<RouteMapEditor> createState() => _RouteMapEditorState();
}

class _RouteMapEditorState extends State<RouteMapEditor> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  // Puntos para crear la polilínea
  final List<LatLng> _routePoints = [];
  List<LatLng>? _polylinePoints; // Polilínea decodificada para mostrar

  // Paradas
  List<Parada> _stops = [];
  Map<int, StopType> _stopTypes = {}; // Mapa de índice de parada a tipo

  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();

    // Si hay polilínea inicial, cargarla
    if (widget.initialPolyline != null && widget.initialPolyline!.isNotEmpty) {
      final decoded = RoutingService.decodePolyline(widget.initialPolyline!);
      if (decoded != null) {
        setState(() {
          _polylinePoints = decoded;
        });
        print(
            '✅ [ROUTE_MAP_EDITOR] Polilínea inicial cargada en initState: ${decoded.length} puntos (modo: ${widget.mode})');
      }
    } else if (widget.mode == RouteMapMode.addStops) {
      print(
          '⚠️ [ROUTE_MAP_EDITOR] Modo addStops pero no hay polilínea inicial');
    }

    // Si hay paradas iniciales, cargarlas
    if (widget.initialStops != null && widget.initialStops!.isNotEmpty) {
      _stops = List.from(widget.initialStops!);
      // Determinar tipos de paradas basado en el orden
      for (int i = 0; i < _stops.length; i++) {
        if (i == 0) {
          _stopTypes[i] = StopType.inicio;
        } else if (i == _stops.length - 1) {
          _stopTypes[i] = StopType.final_;
        } else {
          _stopTypes[i] = StopType.intermedia;
        }
      }
    }
  }

  @override
  void didUpdateWidget(RouteMapEditor oldWidget) {
    super.didUpdateWidget(oldWidget);

    // En modo addStops, siempre cargar la polilínea si está disponible
    if (widget.mode == RouteMapMode.addStops) {
      // Si la polilínea cambió o si no tenemos polilínea pero ahora sí hay una
      if ((widget.initialPolyline != oldWidget.initialPolyline ||
              (_polylinePoints == null || _polylinePoints!.isEmpty)) &&
          widget.initialPolyline != null &&
          widget.initialPolyline!.isNotEmpty) {
        final decoded = RoutingService.decodePolyline(widget.initialPolyline!);
        if (decoded != null) {
          setState(() {
            _polylinePoints = decoded;
          });
          print(
              '✅ [ROUTE_MAP_EDITOR] Polilínea cargada en modo addStops: ${decoded.length} puntos');
        }
      }
    }
    // En modo createLine, no sobrescribir la polilínea que el usuario está extendiendo
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    // En modo addStops, solo agregar paradas
    if (widget.mode == RouteMapMode.addStops) {
      if (_polylinePoints == null || _polylinePoints!.isEmpty) {
        // No debería pasar, pero por si acaso
        return;
      }
      // Buscar el punto más cercano en la polilínea
      final nearestPoint = _findNearestPointOnPolyline(point);

      final newStop = Parada(
        name: 'Parada ${_stops.length + 1}',
        latitude: nearestPoint.latitude,
        longitude: nearestPoint.longitude,
        order: _stops.length,
      );

      setState(() {
        _stops.add(newStop);
        // Por defecto, primera es inicio, última es final, resto intermedias
        if (_stops.length == 1) {
          _stopTypes[_stops.length - 1] = StopType.inicio;
        } else {
          // Cambiar la anterior final a intermedia si existe
          final lastIndex = _stops.length - 2;
          if (_stopTypes[lastIndex] == StopType.final_) {
            _stopTypes[lastIndex] = StopType.intermedia;
          }
          _stopTypes[_stops.length - 1] = StopType.final_;
        }
      });

      widget.onStopsChanged(_stops);
      return;
    }

    // En modo createLine, solo agregar puntos de ruta
    if (widget.mode == RouteMapMode.createLine) {
      setState(() {
        _routePoints.add(point);
      });

      // Solo generar polilínea automáticamente cuando hay exactamente 2 puntos
      // Después de eso, solo se mostrará la línea temporal que conecta todos los puntos
      if (_routePoints.length == 2) {
        _generatePolyline();
      }
      // Si ya hay polilínea y se agregan más puntos, extender la polilínea
      else if (_routePoints.length > 2 &&
          _polylinePoints != null &&
          _polylinePoints!.isNotEmpty) {
        _extendPolyline(point);
      }
      return;
    }

    // Lógica antigua (compatibilidad hacia atrás)
    // Si ya hay polilínea, agregar parada automáticamente
    if (_polylinePoints != null && _polylinePoints!.isNotEmpty) {
      // Buscar el punto más cercano en la polilínea
      final nearestPoint = _findNearestPointOnPolyline(point);

      final newStop = Parada(
        name: 'Parada ${_stops.length + 1}',
        latitude: nearestPoint.latitude,
        longitude: nearestPoint.longitude,
        order: _stops.length,
      );

      setState(() {
        _stops.add(newStop);
        // Por defecto, primera es inicio, última es final, resto intermedias
        if (_stops.length == 1) {
          _stopTypes[_stops.length - 1] = StopType.inicio;
        } else {
          // Cambiar la anterior final a intermedia si existe
          final lastIndex = _stops.length - 2;
          if (_stopTypes[lastIndex] == StopType.final_) {
            _stopTypes[lastIndex] = StopType.intermedia;
          }
          _stopTypes[_stops.length - 1] = StopType.final_;
        }
      });

      widget.onStopsChanged(_stops);
    } else {
      // Si no hay polilínea, agregar punto a la ruta
      setState(() {
        _routePoints.add(point);
      });

      // Si hay 2 o más puntos, generar polilínea automáticamente
      if (_routePoints.length >= 2) {
        _generatePolyline();
      }
    }
  }

  LatLng _findNearestPointOnPolyline(LatLng point) {
    if (_polylinePoints == null || _polylinePoints!.isEmpty) {
      return point;
    }

    double minDistance = double.infinity;
    LatLng nearestPoint = point;

    for (final polyPoint in _polylinePoints!) {
      final distance = _calculateDistance(
        point.latitude,
        point.longitude,
        polyPoint.latitude,
        polyPoint.longitude,
      );

      if (distance < minDistance) {
        minDistance = distance;
        nearestPoint = polyPoint;
      }
    }

    return nearestPoint;
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const distance = Distance();
    return distance.as(
      LengthUnit.Meter,
      LatLng(lat1, lon1),
      LatLng(lat2, lon2),
    );
  }

  /// Extiende la polilínea existente agregando un nuevo segmento desde el último punto hasta el nuevo punto
  Future<void> _extendPolyline(LatLng newPoint) async {
    if (_polylinePoints == null ||
        _polylinePoints!.isEmpty ||
        _routePoints.length < 2) {
      print(
          '⚠️ [ROUTE_MAP_EDITOR] No se puede extender: polilínea vacía o puntos insuficientes');
      return;
    }

    // Usar el último punto de _routePoints (el punto que el usuario realmente agregó)
    // en lugar del último punto de la polilínea decodificada, que puede tener coordenadas incorrectas
    if (_routePoints.isEmpty) {
      print('❌ [ROUTE_MAP_EDITOR] No hay puntos de ruta disponibles');
      return;
    }

    final lastRoutePoint = _routePoints.last;

    print(
        '🔄 [ROUTE_MAP_EDITOR] Extendiendo polilínea desde último punto hasta nuevo punto');
    print(
        '   Último punto de ruta: ${lastRoutePoint.latitude}, ${lastRoutePoint.longitude}');
    print('   Nuevo punto: ${newPoint.latitude}, ${newPoint.longitude}');
    print('   Puntos actuales en polilínea: ${_polylinePoints!.length}');

    setState(() {
      _isSearching = true;
    });

    try {
      // Guardar una copia de la polilínea actual antes de extender
      final currentPolyline = List<LatLng>.from(_polylinePoints!);

      // Generar solo el segmento desde el último punto de ruta hasta el nuevo punto
      final segment = await RoutingService.generatePolyline([
        lastRoutePoint,
        newPoint,
      ]);

      if (segment != null) {
        final decoded = RoutingService.decodePolyline(segment);
        if (decoded != null && decoded.length >= 2) {
          // Crear una nueva lista con los puntos existentes + los nuevos puntos
          final extendedPolyline = List<LatLng>.from(currentPolyline);
          extendedPolyline.addAll(
              decoded.sublist(1)); // Omitir el primero que es el último punto

          setState(() {
            _polylinePoints = extendedPolyline;
          });

          // Regenerar la polilínea codificada completa para guardarla
          final fullPolyline = RoutingService.encodePolyline(extendedPolyline);
          if (fullPolyline != null && widget.onPolylineGenerated != null) {
            widget.onPolylineGenerated!(fullPolyline);
          }

          print(
              '✅ [ROUTE_MAP_EDITOR] Polilínea extendida: ${_polylinePoints!.length} puntos totales');
        } else {
          print('⚠️ [ROUTE_MAP_EDITOR] No se pudo decodificar el segmento');
        }
      } else {
        print('⚠️ [ROUTE_MAP_EDITOR] No se pudo generar el segmento');
      }
    } catch (e) {
      print('❌ [ROUTE_MAP_EDITOR] Error al extender polilínea: $e');
      print('   Stack trace: ${StackTrace.current}');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _generatePolyline() async {
    if (_routePoints.length < 2) {
      return;
    }

    print(
        '🔄 [ROUTE_MAP_EDITOR] Generando polilínea con ${_routePoints.length} puntos');
    for (int i = 0; i < _routePoints.length; i++) {
      print(
          '   Punto ${i + 1}: ${_routePoints[i].latitude}, ${_routePoints[i].longitude}');
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final polyline = await RoutingService.generatePolyline(_routePoints);

      if (polyline != null) {
        final decoded = RoutingService.decodePolyline(polyline);
        print(
            '✅ [ROUTE_MAP_EDITOR] Polilínea generada: ${decoded?.length ?? 0} puntos decodificados');
        setState(() {
          _polylinePoints = decoded;
          // NO cambiar automáticamente a modo paradas - el usuario lo hará manualmente
          // NO limpiar _routePoints - deben seguir visibles
        });

        if (widget.onPolylineGenerated != null) {
          widget.onPolylineGenerated!(polyline);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.mode == RouteMapMode.createLine
                  ? 'Línea de ruta generada. Presiona "Siguiente" para agregar paradas.'
                  : 'Línea de ruta generada. Ahora puedes hacer clic en el mapa para agregar paradas sobre la línea.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        print('❌ [ROUTE_MAP_EDITOR] Error: Polilínea es null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Error al generar línea: No se pudo crear la polilínea'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ [ROUTE_MAP_EDITOR] Excepción al generar polilínea: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al generar línea: $e')),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final results = await GeocodingService.searchPlaces(query, limit: 5);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al buscar: $e')),
        );
      }
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final latLng = result['latLng'] as LatLng;
    final name = result['name'] as String;

    // En modo addStops, solo agregar paradas
    if (widget.mode == RouteMapMode.addStops) {
      if (_polylinePoints == null || _polylinePoints!.isEmpty) {
        return;
      }
      final nearestPoint = _findNearestPointOnPolyline(latLng);

      final newStop = Parada(
        name: name,
        latitude: nearestPoint.latitude,
        longitude: nearestPoint.longitude,
        order: _stops.length,
      );

      setState(() {
        _stops.add(newStop);
        if (_stops.length == 1) {
          _stopTypes[_stops.length - 1] = StopType.inicio;
        } else {
          final lastIndex = _stops.length - 2;
          if (_stopTypes[lastIndex] == StopType.final_) {
            _stopTypes[lastIndex] = StopType.intermedia;
          }
          _stopTypes[_stops.length - 1] = StopType.final_;
        }
        _searchResults = [];
        _searchController.clear();
      });

      widget.onStopsChanged(_stops);
      _mapController.move(latLng, 15.0);
      return;
    }

    // En modo createLine, solo agregar puntos de ruta
    if (widget.mode == RouteMapMode.createLine) {
      setState(() {
        _routePoints.add(latLng);
        _searchResults = [];
        _searchController.clear();
      });

      if (_routePoints.length >= 2) {
        _generatePolyline();
      }
      _mapController.move(latLng, 15.0);
      return;
    }

    // Lógica antigua (compatibilidad hacia atrás) - solo para modo createLine
    // Si estamos en modo addStops, no deberíamos llegar aquí, pero por seguridad:
    if (widget.mode == RouteMapMode.addStops) {
      // En modo addStops, solo agregar paradas
      if (_polylinePoints == null || _polylinePoints!.isEmpty) {
        print(
            '⚠️ [ROUTE_MAP_EDITOR] Modo addStops pero no hay polilínea disponible');
        return;
      }
      final nearestPoint = _findNearestPointOnPolyline(latLng);

      final newStop = Parada(
        name: name,
        latitude: nearestPoint.latitude,
        longitude: nearestPoint.longitude,
        order: _stops.length,
      );

      setState(() {
        _stops.add(newStop);
        if (_stops.length == 1) {
          _stopTypes[_stops.length - 1] = StopType.inicio;
        } else {
          final lastIndex = _stops.length - 2;
          if (_stopTypes[lastIndex] == StopType.final_) {
            _stopTypes[lastIndex] = StopType.intermedia;
          }
          _stopTypes[_stops.length - 1] = StopType.final_;
        }
        _searchResults = [];
        _searchController.clear();
      });

      widget.onStopsChanged(_stops);
      _mapController.move(latLng, 15.0);
      return;
    }

    // Solo en modo createLine (compatibilidad hacia atrás)
    // Si ya hay polilínea, agregar punto a la ruta para extender
    setState(() {
      _routePoints.add(latLng);
      _searchResults = [];
      _searchController.clear();
    });

    // Solo generar polilínea si hay exactamente 2 puntos, o extender si hay más
    if (_routePoints.length == 2) {
      _generatePolyline();
    } else if (_routePoints.length > 2 &&
        _polylinePoints != null &&
        _polylinePoints!.isNotEmpty) {
      _extendPolyline(latLng);
    }
    _mapController.move(latLng, 15.0);
  }

  void _removeStop(int index) {
    setState(() {
      _stops.removeAt(index);
      _stopTypes.remove(index);

      // Reordenar tipos
      final newStopTypes = <int, StopType>{};
      for (int i = 0; i < _stops.length; i++) {
        final oldType = _stopTypes[i + 1] ?? _stopTypes[i];
        if (i == 0) {
          newStopTypes[i] = StopType.inicio;
        } else if (i == _stops.length - 1) {
          newStopTypes[i] = StopType.final_;
        } else {
          newStopTypes[i] = oldType ?? StopType.intermedia;
        }
      }
      _stopTypes = newStopTypes;

      // Reordenar paradas
      for (int i = 0; i < _stops.length; i++) {
        _stops[i] = Parada(
          id: _stops[i].id,
          name: _stops[i].name,
          latitude: _stops[i].latitude,
          longitude: _stops[i].longitude,
          order: i,
        );
      }
    });

    widget.onStopsChanged(_stops);
  }

  void _changeStopType(int index, StopType newType) {
    setState(() {
      _stopTypes[index] = newType;

      // Si se cambia a inicio, el anterior inicio pasa a intermedia
      if (newType == StopType.inicio && index > 0) {
        _stopTypes[0] = StopType.intermedia;
      }

      // Si se cambia a final, el anterior final pasa a intermedia
      if (newType == StopType.final_ && index < _stops.length - 1) {
        final lastIndex = _stops.length - 1;
        if (_stopTypes[lastIndex] == StopType.final_) {
          _stopTypes[lastIndex] = StopType.intermedia;
        }
      }
    });

    widget.onStopsChanged(_stops);
  }

  void _removeLastPoint() {
    if (widget.mode == RouteMapMode.createLine) {
      // En modo createLine, eliminar el último punto de ruta
      if (_routePoints.isEmpty) return;

      setState(() {
        _routePoints.removeLast();

        // Si quedan 2 o más puntos, regenerar la polilínea
        if (_routePoints.length >= 2) {
          _generatePolyline();
        } else {
          // Si hay menos de 2 puntos, limpiar la polilínea y paradas
          _polylinePoints = null;
          _stops.clear();
          _stopTypes.clear();
          widget.onStopsChanged(_stops);
          if (widget.onPolylineGenerated != null) {
            widget.onPolylineGenerated!(null);
          }
        }
      });
    } else if (widget.mode == RouteMapMode.addStops) {
      // En modo addStops, eliminar la última parada
      if (_stops.isEmpty) return;

      setState(() {
        final removedIndex = _stops.length - 1;
        _stops.removeLast();
        _stopTypes.remove(removedIndex);

        // Si quedan paradas, actualizar los tipos
        if (_stops.isNotEmpty) {
          // La última parada ahora es final
          _stopTypes[_stops.length - 1] = StopType.final_;
        }

        widget.onStopsChanged(_stops);
      });
    }
  }

  bool get _canUndo {
    if (widget.mode == RouteMapMode.createLine) {
      return _routePoints.isNotEmpty;
    } else if (widget.mode == RouteMapMode.addStops) {
      return _stops.isNotEmpty;
    }
    return false;
  }

  void _clearStops() {
    setState(() {
      _stops.clear();
      _stopTypes.clear();
    });
    widget.onStopsChanged(_stops);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barra de búsqueda simplificada
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        _polylinePoints != null && _polylinePoints!.isNotEmpty
                            ? 'Buscar lugar para agregar parada'
                            : 'Buscar lugar para agregar punto de ruta',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _isSearching
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onSubmitted: (_) => _searchPlace(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _searchPlace,
                icon: const Icon(Icons.search),
                label: const Text('Buscar'),
              ),
            ],
          ),
        ),

        // Resultados de búsqueda (solo en modo addStops)
        if (widget.mode == RouteMapMode.addStops && _searchResults.isNotEmpty)
          Container(
            height: 150,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.red),
                  title: Text(result['name'] as String),
                  onTap: () => _selectSearchResult(result),
                );
              },
            ),
          ),

        // Mapa
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _stops.isNotEmpty
                      ? LatLng(_stops.first.latitude, _stops.first.longitude)
                      : _routePoints.isNotEmpty
                          ? _routePoints.first
                          : const LatLng(
                              OpenStreetMapConfig.defaultLatitude,
                              OpenStreetMapConfig.defaultLongitude,
                            ),
                  initialZoom: _stops.isNotEmpty || _routePoints.isNotEmpty
                      ? 13.0
                      : OpenStreetMapConfig.defaultZoom,
                  minZoom: OpenStreetMapConfig.minZoom,
                  maxZoom: OpenStreetMapConfig.maxZoom,
                  onTap: _handleMapTap,
                ),
                children: [
                  TileLayer(
                    urlTemplate: OpenStreetMapConfig.tileLayerUrlTemplate,
                    userAgentPackageName: 'com.transporterural.georu.admin',
                    maxZoom: OpenStreetMapConfig.maxZoom,
                    maxNativeZoom: OpenStreetMapConfig.maxNativeZoom,
                  ),

                  // Puntos de la ruta (siempre visibles en modo createLine)
                  if (widget.mode == RouteMapMode.createLine &&
                      _routePoints.isNotEmpty)
                    MarkerLayer(
                      markers: _routePoints.asMap().entries.map((entry) {
                        final index = entry.key;
                        final point = entry.value;
                        return Marker(
                          point: point,
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  // Línea temporal conectando puntos mientras se crea (solo si no hay polilínea generada)
                  if (widget.mode == RouteMapMode.createLine &&
                      (_polylinePoints == null || _polylinePoints!.isEmpty) &&
                      _routePoints.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints,
                          strokeWidth: 3,
                          color: Colors.orange.withValues(alpha: 0.6),
                          borderStrokeWidth: 1,
                          borderColor: Colors.orange,
                          pattern:
                              StrokePattern.dashed(segments: const [10, 5]),
                        ),
                      ],
                    ),

                  // Polilínea generada (siempre visible cuando existe)
                  if (_polylinePoints != null && _polylinePoints!.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _polylinePoints!,
                          strokeWidth: 4,
                          color: Colors.blue,
                        ),
                      ],
                    ),

                  // Marcadores de paradas
                  MarkerLayer(
                    markers: _buildStopMarkers(),
                  ),

                  const RichAttributionWidget(
                    alignment: AttributionAlignment.bottomRight,
                    attributions: [
                      TextSourceAttribution(
                        OpenStreetMapConfig.attribution,
                        textStyle: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),

              // Controles flotantes
              Positioned(
                top: 8,
                right: 8,
                child: Column(
                  children: [
                    // Botón para generar/actualizar línea (solo si hay puntos pero no polilínea)
                    if ((_polylinePoints == null || _polylinePoints!.isEmpty) &&
                        _routePoints.length >= 2)
                      FloatingActionButton.small(
                        heroTag: 'generate_line',
                        onPressed: _generatePolyline,
                        backgroundColor: Colors.green,
                        tooltip: 'Generar línea de ruta',
                        child: _isSearching
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check, color: Colors.white),
                      ),
                    // Botón para deshacer (eliminar último punto/parada)
                    if (_canUndo) ...[
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: widget.mode == RouteMapMode.createLine
                            ? 'remove_last_point'
                            : 'remove_last_stop',
                        onPressed: _removeLastPoint,
                        backgroundColor: Colors.orange,
                        tooltip: widget.mode == RouteMapMode.createLine
                            ? 'Eliminar último punto (Deshacer)'
                            : 'Eliminar última parada (Deshacer)',
                        child: const Icon(Icons.undo, color: Colors.white),
                      ),
                    ],
                    // Botón para limpiar paradas (solo en modo addStops y si hay paradas)
                    if (widget.mode == RouteMapMode.addStops &&
                        _stops.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'clear_stops',
                        onPressed: _clearStops,
                        backgroundColor: Colors.red,
                        tooltip: 'Limpiar todas las paradas',
                        child:
                            const Icon(Icons.location_off, color: Colors.white),
                      ),
                    ],
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'center',
                      onPressed: () {
                        if (_stops.isNotEmpty) {
                          final firstStop = _stops.first;
                          _mapController.move(
                            LatLng(firstStop.latitude, firstStop.longitude),
                            13.0,
                          );
                        } else if (_routePoints.isNotEmpty) {
                          _mapController.move(_routePoints.first, 13.0);
                        }
                      },
                      backgroundColor: Colors.blue,
                      tooltip: 'Centrar mapa',
                      child: const Icon(Icons.center_focus_strong,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Lista de puntos de ruta o paradas
        Container(
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: widget.mode == RouteMapMode.createLine
              ? (_routePoints.isEmpty
                  ? Center(
                      child: Text(
                        'Haz clic en el mapa o busca lugares para agregar puntos de la ruta.\nLa línea se generará automáticamente con 2 o más puntos.',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _routePoints.length,
                      itemBuilder: (context, index) {
                        final point = _routePoints[index];
                        return Container(
                          width: 150,
                          margin: const EdgeInsets.only(right: 8),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange,
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text('Punto ${index + 1}'),
                              subtitle: Text(
                                '${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ),
                        );
                      },
                    ))
              : (_stops.isEmpty
                  ? Center(
                      child: Text(
                        'Haz clic en el mapa o busca lugares para agregar paradas sobre la línea',
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _stops.length,
                      itemBuilder: (context, index) {
                        final stop = _stops[index];
                        final stopType =
                            _stopTypes[index] ?? StopType.intermedia;

                        Color typeColor;
                        String typeText;
                        IconData typeIcon;

                        switch (stopType) {
                          case StopType.inicio:
                            typeColor = Colors.green;
                            typeText = 'Inicio';
                            typeIcon = Icons.play_circle;
                            break;
                          case StopType.final_:
                            typeColor = Colors.red;
                            typeText = 'Final';
                            typeIcon = Icons.stop_circle;
                            break;
                          case StopType.intermedia:
                            typeColor = Colors.blue;
                            typeText = 'Intermedia';
                            typeIcon = Icons.location_on;
                            break;
                        }

                        return Container(
                          width: 220,
                          margin: const EdgeInsets.only(right: 8),
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: typeColor,
                                child: Icon(typeIcon,
                                    color: Colors.white, size: 20),
                              ),
                              title: Text(
                                stop.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    typeText,
                                    style: TextStyle(
                                      color: typeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                  Text(
                                    '${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}',
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<StopType>(
                                icon: const Icon(Icons.more_vert),
                                onSelected: (type) =>
                                    _changeStopType(index, type),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: StopType.inicio,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.play_circle,
                                            color: Colors.green, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Inicio'),
                                        if (stopType == StopType.inicio)
                                          const Icon(Icons.check, size: 16),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: StopType.intermedia,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            color: Colors.blue, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Intermedia'),
                                        if (stopType == StopType.intermedia)
                                          const Icon(Icons.check, size: 16),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: StopType.final_,
                                    child: Row(
                                      children: [
                                        const Icon(Icons.stop_circle,
                                            color: Colors.red, size: 20),
                                        const SizedBox(width: 8),
                                        const Text('Final'),
                                        if (stopType == StopType.final_)
                                          const Icon(Icons.check, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              onLongPress: () => _removeStop(index),
                            ),
                          ),
                        );
                      },
                    )),
        ),
      ],
    );
  }

  List<Marker> _buildStopMarkers() {
    return _stops.asMap().entries.map((entry) {
      final index = entry.key;
      final stop = entry.value;
      final stopType = _stopTypes[index] ?? StopType.intermedia;

      Color markerColor;
      IconData markerIcon;

      switch (stopType) {
        case StopType.inicio:
          markerColor = Colors.green;
          markerIcon = Icons.play_circle;
          break;
        case StopType.final_:
          markerColor = Colors.red;
          markerIcon = Icons.stop_circle;
          break;
        case StopType.intermedia:
          markerColor = Colors.blue;
          markerIcon = Icons.location_on;
          break;
      }

      return Marker(
        point: LatLng(stop.latitude, stop.longitude),
        width: 50,
        height: 50,
        child: GestureDetector(
          onTap: () {
            _mapController.move(LatLng(stop.latitude, stop.longitude), 15.0);
          },
          child: Container(
            decoration: BoxDecoration(
              color: markerColor,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              markerIcon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      );
    }).toList();
  }
}
