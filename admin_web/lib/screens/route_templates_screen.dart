import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../models/route_template.dart';
import '../models/ruta.dart';

class RouteTemplatesScreen extends StatefulWidget {
  const RouteTemplatesScreen({super.key});

  @override
  State<RouteTemplatesScreen> createState() => _RouteTemplatesScreenState();
}

class _RouteTemplatesScreenState extends State<RouteTemplatesScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final categories = ['Todos', ...RouteTemplates.categories];

    final filteredTemplates =
        _selectedCategory == null || _selectedCategory == 'Todos'
            ? RouteTemplates.templates
            : RouteTemplates.getByCategory(_selectedCategory!);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Plantillas de Rutas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Crea rutas rápidamente desde plantillas predefinidas',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                _buildStats(filteredTemplates.length),
              ],
            ),

            const SizedBox(height: 24),

            // Filtros
            _buildCategoryFilter(categories),

            const SizedBox(height: 24),

            // Grid de plantillas
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredTemplates.length,
                itemBuilder: (context, index) {
                  final template = filteredTemplates[index];
                  return _buildTemplateCard(template);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            '$count plantillas disponibles',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    return Wrap(
      spacing: 8,
      children: categories.map((category) {
        final isSelected = _selectedCategory == category ||
            (_selectedCategory == null && category == 'Todos');

        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCategory = category == 'Todos' ? null : category;
            });
          },
          selectedColor: Colors.blue,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTemplateCard(RouteTemplate template) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showTemplatePreview(template),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con categoría
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(template.category),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      template.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(Icons.favorite_border,
                      color: Colors.grey[400], size: 20),
                ],
              ),

              const SizedBox(height: 12),

              // Nombre
              Text(
                template.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Descripción
              Text(
                template.description,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const Spacer(),

              // Estadísticas
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${template.stops.length} paradas',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${template.scheduleOptions.length} horarios',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Botón de crear
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _createRouteFromTemplate(template),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Crear Ruta'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Longaví':
        return Colors.blue;
      case 'Linares':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showTemplatePreview(RouteTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getCategoryColor(template.category),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                template.category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                template.name,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  template.description,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Paradas:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                ...template.stops.map((stop) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.blue,
                            child: Text(
                              '${stop.orden}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              stop.nombre,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                const Text(
                  'Horarios sugeridos:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: template.scheduleOptions
                      .map((time) => Chip(
                            label: Text(time),
                            backgroundColor: Colors.blue[50],
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _createRouteFromTemplate(template);
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear Ruta'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _createRouteFromTemplate(RouteTemplate template) {
    showDialog(
      context: context,
      builder: (context) => _CreateRouteFromTemplateDialog(template: template),
    );
  }
}

class _CreateRouteFromTemplateDialog extends StatefulWidget {
  final RouteTemplate template;

  const _CreateRouteFromTemplateDialog({required this.template});

  @override
  State<_CreateRouteFromTemplateDialog> createState() =>
      _CreateRouteFromTemplateDialogState();
}

class _CreateRouteFromTemplateDialogState
    extends State<_CreateRouteFromTemplateDialog> {
  late TextEditingController _routeIdController;
  late TextEditingController _nameController;
  List<String> _selectedSchedule = [];

  @override
  void initState() {
    super.initState();
    _routeIdController = TextEditingController(text: widget.template.id);
    _nameController = TextEditingController(text: widget.template.name);
    _selectedSchedule = List.from(widget.template.scheduleOptions);
  }

  @override
  void dispose() {
    _routeIdController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear Ruta desde Plantilla'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _routeIdController,
                decoration: const InputDecoration(
                  labelText: 'ID de Ruta *',
                  hintText: 'RUTA-001',
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de Ruta *',
                  prefixIcon: Icon(Icons.route),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Selecciona horarios:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: widget.template.scheduleOptions.map((time) {
                  final isSelected = _selectedSchedule.contains(time);
                  return FilterChip(
                    label: Text(time),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedSchedule.add(time);
                        } else {
                          _selectedSchedule.remove(time);
                        }
                      });
                    },
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                '${widget.template.stops.length} paradas incluidas',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _createRoute,
          icon: const Icon(Icons.check),
          label: const Text('Crear Ruta'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _createRoute() async {
    if (_routeIdController.text.isEmpty || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final newRoute = Ruta(
      routeId: _routeIdController.text,
      name: _nameController.text,
      schedule: jsonEncode({'horarios': _selectedSchedule}),
      stops: widget.template.stops
          .map((s) => Parada(
                id: null,
                name: s.nombre,
                latitude: s.latitud,
                longitude: s.longitud,
                order: s.orden,
              ))
          .toList(),
      polyline: '',
    );

    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    final success = await adminProvider.createRuta(newRoute);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Ruta creada exitosamente desde plantilla'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}
