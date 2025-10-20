const express = require('express');
const router = express.Router();
const { BusLocationsService, RealtimeService } = require('../services/supabase');

// =============================================
// BUS LOCATIONS ROUTES
// =============================================

// GET /api/bus-locations - Get all bus locations
router.get('/', async (req, res) => {
  try {
    const result = await BusLocationsService.getAllBusLocations();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener ubicaciones de buses',
      message: error.message
    });
  }
});

// GET /api/bus-locations/active - Get active buses
router.get('/active', async (req, res) => {
  try {
    const result = await BusLocationsService.getActiveBuses();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener buses activos',
      message: error.message
    });
  }
});

// GET /api/bus-locations/:busId - Get bus location by ID
router.get('/:busId', async (req, res) => {
  try {
    const { busId } = req.params;
    const result = await BusLocationsService.getBusLocationById(busId);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(404).json(result);
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener ubicación del bus',
      message: error.message
    });
  }
});

// GET /api/bus-locations/route/:routeId - Get buses by route
router.get('/route/:routeId', async (req, res) => {
  try {
    const { routeId } = req.params;
    const result = await BusLocationsService.getBusesByRoute(routeId);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener buses por ruta',
      message: error.message
    });
  }
});

// GET /api/bus-locations/driver/:driverId - Get buses by driver
router.get('/driver/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;
    const result = await BusLocationsService.getBusesByDriver(driverId);
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener buses por conductor',
      message: error.message
    });
  }
});

// GET /api/bus-locations/nearby/:lat/:lng/:radius - Get buses within radius
router.get('/nearby/:lat/:lng/:radius?', async (req, res) => {
  try {
    const { lat, lng, radius = 5 } = req.params;
    const result = await BusLocationsService.getBusesWithinRadius(
      parseFloat(lat), 
      parseFloat(lng), 
      parseFloat(radius)
    );
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener buses cercanos',
      message: error.message
    });
  }
});

// PUT /api/bus-locations/:busId - Update bus location
router.put('/:busId', async (req, res) => {
  try {
    const { busId } = req.params;
    const locationData = req.body;
    const result = await BusLocationsService.updateBusLocation(busId, locationData);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al actualizar ubicación del bus',
      message: error.message
    });
  }
});

// POST /api/bus-locations/:busId/update - Update bus location (alternative endpoint)
router.post('/:busId/update', async (req, res) => {
  try {
    const { busId } = req.params;
    const { latitude, longitude, status, routeId, driverId } = req.body;
    
    const locationData = {
      latitude,
      longitude,
      status,
      route_id: routeId,
      driver_id: driverId
    };
    
    const result = await BusLocationsService.updateBusLocation(busId, locationData);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al actualizar ubicación del bus',
      message: error.message
    });
  }
});

// =============================================
// REAL-TIME ROUTES
// =============================================

// GET /api/bus-locations/realtime/subscribe - Subscribe to real-time updates
router.get('/realtime/subscribe', (req, res) => {
  try {
    const subscription = RealtimeService.subscribeToBusLocations((payload) => {
      // Enviar actualización via Server-Sent Events
      res.write(`data: ${JSON.stringify(payload)}\n\n`);
    });
    
    req.on('close', () => {
      subscription.unsubscribe();
    });
    
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Cache-Control'
    });
    
    res.write('data: {"type": "connected"}\n\n');
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al suscribirse a actualizaciones en tiempo real',
      message: error.message
    });
  }
});

module.exports = router;

