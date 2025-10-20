const express = require('express');
const router = express.Router();

// GET /api/bus-locations - Obtener todas las ubicaciones de buses
router.get('/', async (req, res) => {
  try {
    // TODO: Implementar consulta a base de datos
    const busLocations = [
      {
        bus_id: 1,
        route_id: 1,
        driver_id: 1,
        latitude: -33.4489,
        longitude: -70.6693,
        status: 'active',
        last_update: new Date().toISOString()
      },
      {
        bus_id: 2,
        route_id: 2,
        driver_id: 2,
        latitude: -33.4000,
        longitude: -70.6000,
        status: 'active',
        last_update: new Date().toISOString()
      },
      {
        bus_id: 3,
        route_id: 1,
        driver_id: 3,
        latitude: -33.4500,
        longitude: -70.6700,
        status: 'inactive',
        last_update: new Date().toISOString()
      }
    ];
    
    res.json({
      success: true,
      data: busLocations,
      count: busLocations.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener ubicaciones de buses',
      message: error.message
    });
  }
});

// GET /api/buses/:id - Obtener bus por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // TODO: Implementar consulta a base de datos
    const bus = {
      id: parseInt(id),
      patente: 'ABC123',
      modelo: 'Mercedes Benz OF-1724',
      capacidad: 50,
      estado: 'activo',
      ubicacion: {
        lat: -33.4489,
        lng: -70.6693,
        timestamp: new Date().toISOString()
      },
      rutaId: 1,
      conductor: {
        id: 1,
        nombre: 'Juan Pérez',
        telefono: '+56912345678'
      }
    };
    
    res.json({
      success: true,
      data: bus
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener bus',
      message: error.message
    });
  }
});

// GET /api/buses/ubicacion/:id - Obtener ubicación actual del bus
router.get('/ubicacion/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    // TODO: Implementar consulta de ubicación en tiempo real
    const ubicacion = {
      busId: parseInt(id),
      lat: -33.4489 + (Math.random() - 0.5) * 0.01,
      lng: -70.6693 + (Math.random() - 0.5) * 0.01,
      velocidad: Math.floor(Math.random() * 60) + 20,
      direccion: Math.floor(Math.random() * 360),
      timestamp: new Date().toISOString()
    };
    
    res.json({
      success: true,
      data: ubicacion
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener ubicación del bus',
      message: error.message
    });
  }
});

// POST /api/buses - Crear nuevo bus
router.post('/', async (req, res) => {
  try {
    const { patente, modelo, capacidad, rutaId } = req.body;
    
    // TODO: Implementar validación y guardado en base de datos
    const nuevoBus = {
      id: Date.now(),
      patente,
      modelo,
      capacidad,
      estado: 'activo',
      ubicacion: {
        lat: -33.4489,
        lng: -70.6693,
        timestamp: new Date().toISOString()
      },
      rutaId,
      createdAt: new Date().toISOString()
    };
    
    res.status(201).json({
      success: true,
      data: nuevoBus,
      message: 'Bus creado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al crear bus',
      message: error.message
    });
  }
});

// PUT /api/buses/:id/ubicacion - Actualizar ubicación del bus
router.put('/:id/ubicacion', async (req, res) => {
  try {
    const { id } = req.params;
    const { lat, lng, velocidad, direccion } = req.body;
    
    // TODO: Implementar actualización de ubicación en base de datos
    const ubicacionActualizada = {
      busId: parseInt(id),
      lat,
      lng,
      velocidad,
      direccion,
      timestamp: new Date().toISOString()
    };
    
    res.json({
      success: true,
      data: ubicacionActualizada,
      message: 'Ubicación actualizada exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al actualizar ubicación',
      message: error.message
    });
  }
});

module.exports = router;

