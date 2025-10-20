const express = require('express');
const router = express.Router();

// GET /api/recorridos - Obtener todos los recorridos
router.get('/', async (req, res) => {
  try {
    // TODO: Implementar consulta a base de datos
    const recorridos = [
      {
        id: 1,
        busId: 1,
        rutaId: 1,
        conductorId: 1,
        estado: 'en_progreso',
        inicio: '2024-01-20T08:00:00Z',
        fin: null,
        pasajeros: 25,
        capacidad: 50,
        ubicacionActual: {
          lat: -33.4489,
          lng: -70.6693,
          timestamp: new Date().toISOString()
        }
      },
      {
        id: 2,
        busId: 2,
        rutaId: 2,
        conductorId: 2,
        estado: 'programado',
        inicio: '2024-01-20T10:00:00Z',
        fin: null,
        pasajeros: 0,
        capacidad: 45,
        ubicacionActual: {
          lat: -33.4000,
          lng: -70.6000,
          timestamp: new Date().toISOString()
        }
      }
    ];
    
    res.json({
      success: true,
      data: recorridos,
      count: recorridos.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener recorridos',
      message: error.message
    });
  }
});

// GET /api/recorridos/:id - Obtener recorrido por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // TODO: Implementar consulta a base de datos
    const recorrido = {
      id: parseInt(id),
      busId: 1,
      rutaId: 1,
      conductorId: 1,
      estado: 'en_progreso',
      inicio: '2024-01-20T08:00:00Z',
      fin: null,
      pasajeros: 25,
      capacidad: 50,
      ubicacionActual: {
        lat: -33.4489,
        lng: -70.6693,
        timestamp: new Date().toISOString()
      },
      historialUbicaciones: [
        {
          lat: -33.4500,
          lng: -70.6700,
          timestamp: '2024-01-20T08:00:00Z'
        },
        {
          lat: -33.4495,
          lng: -70.6695,
          timestamp: '2024-01-20T08:15:00Z'
        }
      ]
    };
    
    res.json({
      success: true,
      data: recorrido
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener recorrido',
      message: error.message
    });
  }
});

// GET /api/recorridos/activos - Obtener recorridos activos
router.get('/activos', async (req, res) => {
  try {
    // TODO: Implementar consulta a base de datos
    const recorridosActivos = [
      {
        id: 1,
        busId: 1,
        rutaId: 1,
        conductorId: 1,
        estado: 'en_progreso',
        inicio: '2024-01-20T08:00:00Z',
        pasajeros: 25,
        capacidad: 50,
        ubicacionActual: {
          lat: -33.4489,
          lng: -70.6693,
          timestamp: new Date().toISOString()
        }
      }
    ];
    
    res.json({
      success: true,
      data: recorridosActivos,
      count: recorridosActivos.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener recorridos activos',
      message: error.message
    });
  }
});

// POST /api/recorridos - Crear nuevo recorrido
router.post('/', async (req, res) => {
  try {
    const { busId, rutaId, conductorId, inicio } = req.body;
    
    // TODO: Implementar validación y guardado en base de datos
    const nuevoRecorrido = {
      id: Date.now(),
      busId,
      rutaId,
      conductorId,
      estado: 'programado',
      inicio,
      fin: null,
      pasajeros: 0,
      capacidad: 50,
      ubicacionActual: {
        lat: -33.4489,
        lng: -70.6693,
        timestamp: new Date().toISOString()
      },
      createdAt: new Date().toISOString()
    };
    
    res.status(201).json({
      success: true,
      data: nuevoRecorrido,
      message: 'Recorrido creado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al crear recorrido',
      message: error.message
    });
  }
});

// PUT /api/recorridos/:id/iniciar - Iniciar recorrido
router.put('/:id/iniciar', async (req, res) => {
  try {
    const { id } = req.params;
    
    // TODO: Implementar lógica de inicio de recorrido
    const recorridoIniciado = {
      id: parseInt(id),
      estado: 'en_progreso',
      inicio: new Date().toISOString(),
      ubicacionActual: {
        lat: -33.4489,
        lng: -70.6693,
        timestamp: new Date().toISOString()
      }
    };
    
    res.json({
      success: true,
      data: recorridoIniciado,
      message: 'Recorrido iniciado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al iniciar recorrido',
      message: error.message
    });
  }
});

// PUT /api/recorridos/:id/finalizar - Finalizar recorrido
router.put('/:id/finalizar', async (req, res) => {
  try {
    const { id } = req.params;
    
    // TODO: Implementar lógica de finalización de recorrido
    const recorridoFinalizado = {
      id: parseInt(id),
      estado: 'finalizado',
      fin: new Date().toISOString()
    };
    
    res.json({
      success: true,
      data: recorridoFinalizado,
      message: 'Recorrido finalizado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al finalizar recorrido',
      message: error.message
    });
  }
});

module.exports = router;

