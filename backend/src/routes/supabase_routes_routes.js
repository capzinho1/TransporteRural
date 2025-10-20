const express = require('express');
const router = express.Router();
const { RoutesService, RealtimeService } = require('../services/supabase');

// =============================================
// ROUTES ROUTES
// =============================================

// GET /api/routes - Get all routes
router.get('/', async (req, res) => {
  try {
    const result = await RoutesService.getAllRoutes();
    res.json(result);
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener rutas',
      message: error.message
    });
  }
});

// GET /api/routes/:routeId - Get route by ID
router.get('/:routeId', async (req, res) => {
  try {
    const { routeId } = req.params;
    const result = await RoutesService.getRouteById(routeId);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(404).json(result);
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener ruta',
      message: error.message
    });
  }
});

// POST /api/routes - Create route
router.post('/', async (req, res) => {
  try {
    const routeData = req.body;
    const result = await RoutesService.createRoute(routeData);
    
    if (result.success) {
      res.status(201).json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al crear ruta',
      message: error.message
    });
  }
});

// PUT /api/routes/:routeId - Update route
router.put('/:routeId', async (req, res) => {
  try {
    const { routeId } = req.params;
    const routeData = req.body;
    const result = await RoutesService.updateRoute(routeId, routeData);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al actualizar ruta',
      message: error.message
    });
  }
});

// DELETE /api/routes/:routeId - Delete route
router.delete('/:routeId', async (req, res) => {
  try {
    const { routeId } = req.params;
    const result = await RoutesService.deleteRoute(routeId);
    
    if (result.success) {
      res.json(result);
    } else {
      res.status(400).json(result);
    }
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al eliminar ruta',
      message: error.message
    });
  }
});

// =============================================
// REAL-TIME ROUTES
// =============================================

// GET /api/routes/realtime/subscribe - Subscribe to route changes
router.get('/realtime/subscribe', (req, res) => {
  try {
    const subscription = RealtimeService.subscribeToRoutes((payload) => {
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
      error: 'Error al suscribirse a cambios de rutas',
      message: error.message
    });
  }
});

module.exports = router;

