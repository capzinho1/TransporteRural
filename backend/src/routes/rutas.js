const express = require('express');
const router = express.Router();

// GET /api/routes - Obtener todas las rutas
router.get('/', async (req, res) => {
  try {
    // TODO: Implementar consulta a base de datos
    const routes = [
      {
        route_id: 1,
        name: 'Ruta Centro - Norte',
        schedule: '06:00 - 22:00',
        stops: [
          {
            id: 1,
            name: 'Centro',
            latitude: -33.4489,
            longitude: -70.6693,
            order: 1
          },
          {
            id: 2,
            name: 'Norte',
            latitude: -33.4000,
            longitude: -70.6000,
            order: 2
          }
        ],
        polyline: 'encoded_polyline_string_here'
      },
      {
        route_id: 2,
        name: 'Ruta Sur - Este',
        schedule: '07:00 - 21:00',
        stops: [
          {
            id: 3,
            name: 'Sur',
            latitude: -33.5000,
            longitude: -70.7000,
            order: 1
          },
          {
            id: 4,
            name: 'Este',
            latitude: -33.3500,
            longitude: -70.5500,
            order: 2
          }
        ],
        polyline: 'encoded_polyline_string_here'
      }
    ];
    
    res.json({
      success: true,
      data: routes,
      count: routes.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener rutas',
      message: error.message
    });
  }
});

// GET /api/rutas/:id - Obtener ruta por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // TODO: Implementar consulta a base de datos
    const ruta = {
      id: parseInt(id),
      nombre: 'Ruta Centro - Norte',
      origen: 'Centro',
      destino: 'Norte',
      distancia: 15.5,
      duracion: 45,
      activa: true,
      paradas: [
        { id: 1, nombre: 'Parada Centro', lat: -33.4489, lng: -70.6693 },
        { id: 2, nombre: 'Parada Norte', lat: -33.4000, lng: -70.6000 }
      ]
    };
    
    res.json({
      success: true,
      data: ruta
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener ruta',
      message: error.message
    });
  }
});

// POST /api/rutas - Crear nueva ruta
router.post('/', async (req, res) => {
  try {
    const { nombre, origen, destino, distancia, duracion } = req.body;
    
    // TODO: Implementar validación y guardado en base de datos
    const nuevaRuta = {
      id: Date.now(),
      nombre,
      origen,
      destino,
      distancia,
      duracion,
      activa: true,
      createdAt: new Date().toISOString()
    };
    
    res.status(201).json({
      success: true,
      data: nuevaRuta,
      message: 'Ruta creada exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al crear ruta',
      message: error.message
    });
  }
});

// PUT /api/rutas/:id - Actualizar ruta
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { nombre, origen, destino, distancia, duracion, activa } = req.body;
    
    // TODO: Implementar actualización en base de datos
    const rutaActualizada = {
      id: parseInt(id),
      nombre,
      origen,
      destino,
      distancia,
      duracion,
      activa,
      updatedAt: new Date().toISOString()
    };
    
    res.json({
      success: true,
      data: rutaActualizada,
      message: 'Ruta actualizada exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al actualizar ruta',
      message: error.message
    });
  }
});

// DELETE /api/rutas/:id - Eliminar ruta
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // TODO: Implementar eliminación en base de datos
    res.json({
      success: true,
      message: `Ruta ${id} eliminada exitosamente`
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al eliminar ruta',
      message: error.message
    });
  }
});

module.exports = router;

