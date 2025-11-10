const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { getUserFromRequest } = require('../middleware/auth');

// GET /api/trips - Obtener todos los viajes
router.get('/', async (req, res) => {
  try {
    const user = await getUserFromRequest(req);
    let query = supabase.from('trips').select('*');
    
    // Filtrar por empresa si es company_admin
    if (user && user.role === 'company_admin' && user.company_id) {
      query = query.eq('company_id', user.company_id);
    }
    
    query = query.order('scheduled_start', { ascending: false });
    
    const { data: trips, error } = await query;
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: trips,
      count: trips.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener viajes',
      message: error.message
    });
  }
});

// GET /api/trips/:id - Obtener viaje por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: trip, error } = await supabase
      .from('trips')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) throw error;
    
    if (!trip) {
      return res.status(404).json({
        success: false,
        error: 'Viaje no encontrado'
      });
    }
    
    res.json({
      success: true,
      data: trip
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener viaje',
      message: error.message
    });
  }
});

// GET /api/trips/completed - Obtener viajes completados
router.get('/completed/all', async (req, res) => {
  try {
    const user = await getUserFromRequest(req);
    let query = supabase
      .from('trips')
      .select('*')
      .eq('status', 'completed');
    
    // Filtrar por empresa si es company_admin
    if (user && user.role === 'company_admin' && user.company_id) {
      query = query.eq('company_id', user.company_id);
    }
    
    query = query.order('actual_end', { ascending: false });
    
    const { data: trips, error } = await query;
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: trips,
      count: trips.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener viajes completados',
      message: error.message
    });
  }
});

// GET /api/trips/driver/:driverId - Obtener viajes por conductor
router.get('/driver/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;
    
    const { data: trips, error } = await supabase
      .from('trips')
      .select('*')
      .eq('driver_id', driverId)
      .order('scheduled_start', { ascending: false });
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: trips,
      count: trips.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener viajes del conductor',
      message: error.message
    });
  }
});

// GET /api/trips/route/:routeId - Obtener viajes por ruta
router.get('/route/:routeId', async (req, res) => {
  try {
    const { routeId } = req.params;
    
    const { data: trips, error } = await supabase
      .from('trips')
      .select('*')
      .eq('route_id', routeId)
      .order('scheduled_start', { ascending: false });
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: trips,
      count: trips.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener viajes de la ruta',
      message: error.message
    });
  }
});

// POST /api/trips - Crear nuevo viaje
router.post('/', async (req, res) => {
  try {
    const {
      bus_id,
      route_id,
      driver_id,
      scheduled_start,
      scheduled_end,
      company_id,
      capacity
    } = req.body;
    
    // Validar campos obligatorios
    if (!bus_id || !route_id || !driver_id || !scheduled_start) {
      return res.status(400).json({
        success: false,
        error: 'Campos obligatorios: bus_id, route_id, driver_id, scheduled_start'
      });
    }
    
    // Obtener usuario para asignar company_id automáticamente
    const user = await getUserFromRequest(req);
    let finalCompanyId = company_id;
    if (!finalCompanyId && user && user.role === 'company_admin' && user.company_id) {
      finalCompanyId = user.company_id;
    }
    
    const insertData = {
      bus_id,
      route_id,
      driver_id,
      scheduled_start,
      scheduled_end: scheduled_end || null,
      status: 'scheduled',
      company_id: finalCompanyId || null,
      capacity: capacity || null,
      passenger_count: 0
    };
    
    const { data: nuevoTrip, error } = await supabase
      .from('trips')
      .insert([insertData])
      .select()
      .single();
    
    if (error) throw error;
    
    // Actualizar estado del conductor a 'en_ruta' si el viaje está programado para ahora
    const scheduledTime = new Date(scheduled_start);
    const now = new Date();
    if (scheduledTime <= now) {
      await supabase
        .from('users')
        .update({ driver_status: 'en_ruta' })
        .eq('id', driver_id);
    }
    
    res.status(201).json({
      success: true,
      data: nuevoTrip,
      message: 'Viaje creado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al crear viaje',
      message: error.message
    });
  }
});

// PUT /api/trips/:id/start - Iniciar viaje
router.put('/:id/start', async (req, res) => {
  try {
    const { id } = req.params;
    const { latitude, longitude } = req.body;
    
    const actualStart = new Date().toISOString();
    const updateData = {
      status: 'in_progress',
      actual_start: actualStart,
      start_location: latitude && longitude ? { latitude, longitude } : null
    };
    
    const { data: trip, error: fetchError } = await supabase
      .from('trips')
      .select('*')
      .eq('id', id)
      .single();
    
    if (fetchError) throw fetchError;
    
    // Calcular retraso si hay hora programada
    if (trip.scheduled_start) {
      const scheduled = new Date(trip.scheduled_start);
      const actual = new Date(actualStart);
      const delayMinutes = Math.round((actual - scheduled) / (1000 * 60));
      updateData.delay_minutes = delayMinutes;
    }
    
    const { data: tripActualizado, error } = await supabase
      .from('trips')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    // Actualizar estado del conductor
    if (trip.driver_id) {
      await supabase
        .from('users')
        .update({ driver_status: 'en_ruta' })
        .eq('id', trip.driver_id);
    }
    
    res.json({
      success: true,
      data: tripActualizado,
      message: 'Viaje iniciado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al iniciar viaje',
      message: error.message
    });
  }
});

// PUT /api/trips/:id/complete - Completar viaje
router.put('/:id/complete', async (req, res) => {
  try {
    const { id } = req.params;
    const { latitude, longitude, passenger_count, notes, issues } = req.body;
    
    const actualEnd = new Date().toISOString();
    
    // Obtener el viaje actual
    const { data: trip, error: fetchError } = await supabase
      .from('trips')
      .select('*')
      .eq('id', id)
      .single();
    
    if (fetchError) throw fetchError;
    
    // Calcular duración
    let durationMinutes = null;
    if (trip.actual_start) {
      const start = new Date(trip.actual_start);
      const end = new Date(actualEnd);
      durationMinutes = Math.round((end - start) / (1000 * 60));
    }
    
    const updateData = {
      status: 'completed',
      actual_end: actualEnd,
      end_location: latitude && longitude ? { latitude, longitude } : null,
      duration_minutes: durationMinutes,
      passenger_count: passenger_count || trip.passenger_count || 0,
      notes: notes || null,
      issues: issues || null
    };
    
    const { data: tripActualizado, error } = await supabase
      .from('trips')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    // Actualizar estado del conductor a 'disponible'
    if (trip.driver_id) {
      await supabase
        .from('users')
        .update({ driver_status: 'disponible' })
        .eq('id', trip.driver_id);
    }
    
    res.json({
      success: true,
      data: tripActualizado,
      message: 'Viaje completado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al completar viaje',
      message: error.message
    });
  }
});

// PUT /api/trips/:id/cancel - Cancelar viaje
router.put('/:id/cancel', async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    
    const { data: trip, error: fetchError } = await supabase
      .from('trips')
      .select('*')
      .eq('id', id)
      .single();
    
    if (fetchError) throw fetchError;
    
    const updateData = {
      status: 'cancelled',
      notes: reason || 'Viaje cancelado'
    };
    
    const { data: tripActualizado, error } = await supabase
      .from('trips')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    // Actualizar estado del conductor a 'disponible'
    if (trip.driver_id) {
      await supabase
        .from('users')
        .update({ driver_status: 'disponible' })
        .eq('id', trip.driver_id);
    }
    
    res.json({
      success: true,
      data: tripActualizado,
      message: 'Viaje cancelado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al cancelar viaje',
      message: error.message
    });
  }
});

// GET /api/trips/stats/punctuality - Estadísticas de puntualidad
router.get('/stats/punctuality', async (req, res) => {
  try {
    const user = await getUserFromRequest(req);
    let query = supabase
      .from('trips')
      .select('*')
      .eq('status', 'completed');
    
    // Filtrar por empresa si es company_admin
    if (user && user.role === 'company_admin' && user.company_id) {
      query = query.eq('company_id', user.company_id);
    }
    
    const { data: trips, error } = await query;
    
    if (error) throw error;
    
    const stats = {
      total: trips.length,
      onTime: trips.filter(t => t.delay_minutes <= 0).length,
      delayed: trips.filter(t => t.delay_minutes > 0).length,
      avgDelay: trips.length > 0
        ? trips.reduce((sum, t) => sum + (t.delay_minutes || 0), 0) / trips.length
        : 0,
      punctualityRate: trips.length > 0
        ? (trips.filter(t => t.delay_minutes <= 0).length / trips.length) * 100
        : 0
    };
    
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener estadísticas de puntualidad',
      message: error.message
    });
  }
});

module.exports = router;

