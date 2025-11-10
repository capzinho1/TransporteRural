import 'package:flutter/material.dart';
import 'osm_map_widget.dart';

/// Widget de mapa usando OpenStreetMap
class MapWidget extends StatelessWidget {
  const MapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const OsmMapWidget(
      showMyLocation: true,
    );
  }
}
