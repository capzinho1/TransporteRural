const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { getUserFromRequest } = require('../middleware/auth');

// GET /api/ratings - Obtener todas las calificaciones
router.get('/', async (req, res) => {
  try {
    const user = await getUserFromRequest(req);
    let query = supabase.from('ratings').select('*');
    
    // Filtrar por empresa si es company_admin
    if (user && user.role === 'company_admin' && user.company_id) {
      query = query.eq('company_id', user.company_id);
    }
    
    query = query.order('created_at', { ascending: false });
    
    const { data: ratings, error } = await query;
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: ratings,
      count: ratings.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener calificaciones',
      message: error.message
    });
  }
});

// GET /api/ratings/driver/:driverId - Obtener calificaciones por conductor
router.get('/driver/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;
    
    const { data: ratings, error } = await supabase
      .from('ratings')
      .select('*')
      .eq('driver_id', driverId)
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    
    // Calcular promedio
    const avgRating = ratings.length > 0
      ? ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length
      : 0;
    
    res.json({
      success: true,
      data: ratings,
      count: ratings.length,
      average: avgRating
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener calificaciones del conductor',
      message: error.message
    });
  }
});

// GET /api/ratings/route/:routeId - Obtener calificaciones por ruta
router.get('/route/:routeId', async (req, res) => {
  try {
    const { routeId } = req.params;
    
    const { data: ratings, error } = await supabase
      .from('ratings')
      .select('*')
      .eq('route_id', routeId)
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    
    const avgRating = ratings.length > 0
      ? ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length
      : 0;
    
    res.json({
      success: true,
      data: ratings,
      count: ratings.length,
      average: avgRating
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener calificaciones de la ruta',
      message: error.message
    });
  }
});

// POST /api/ratings - Crear nueva calificación
router.post('/', async (req, res) => {
  try {
    const {
      user_id,
      driver_id,
      route_id,
      trip_id,
      rating,
      comment,
      punctuality_rating,
      service_rating,
      cleanliness_rating,
      safety_rating,
      company_id
    } = req.body;
    
    // Validar campos obligatorios
    if (!user_id || !rating || (rating < 1 || rating > 5)) {
      return res.status(400).json({
        success: false,
        error: 'Campos obligatorios: user_id, rating (1-5)'
      });
    }
    
    // Verificar que no exista una calificación para el mismo viaje
    if (trip_id) {
      const { data: existing } = await supabase
        .from('ratings')
        .select('id')
        .eq('user_id', user_id)
        .eq('trip_id', trip_id)
        .single();
      
      if (existing) {
        return res.status(400).json({
          success: false,
          error: 'Ya existe una calificación para este viaje'
        });
      }
    }
    
    const insertData = {
      user_id,
      driver_id: driver_id || null,
      route_id: route_id || null,
      trip_id: trip_id || null,
      company_id: company_id || null,
      rating,
      comment: comment || null,
      punctuality_rating: punctuality_rating || null,
      service_rating: service_rating || null,
      cleanliness_rating: cleanliness_rating || null,
      safety_rating: safety_rating || null
    };
    
    const { data: nuevaRating, error } = await supabase
      .from('ratings')
      .insert([insertData])
      .select()
      .single();
    
    if (error) throw error;
    
    res.status(201).json({
      success: true,
      data: nuevaRating,
      message: 'Calificación creada exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al crear calificación',
      message: error.message
    });
  }
});

// GET /api/ratings/stats/driver/:driverId - Estadísticas de calificaciones por conductor
router.get('/stats/driver/:driverId', async (req, res) => {
  try {
    const { driverId } = req.params;
    
    const { data: ratings, error } = await supabase
      .from('ratings')
      .select('*')
      .eq('driver_id', driverId);
    
    if (error) throw error;
    
    if (ratings.length === 0) {
      return res.json({
        success: true,
        data: {
          total: 0,
          average: 0,
          averagePunctuality: 0,
          averageService: 0,
          averageCleanliness: 0,
          averageSafety: 0
        }
      });
    }
    
    const stats = {
      total: ratings.length,
      average: ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length,
      averagePunctuality: ratings.filter(r => r.punctuality_rating)
        .reduce((sum, r) => sum + r.punctuality_rating, 0) / 
        ratings.filter(r => r.punctuality_rating).length || 0,
      averageService: ratings.filter(r => r.service_rating)
        .reduce((sum, r) => sum + r.service_rating, 0) / 
        ratings.filter(r => r.service_rating).length || 0,
      averageCleanliness: ratings.filter(r => r.cleanliness_rating)
        .reduce((sum, r) => sum + r.cleanliness_rating, 0) / 
        ratings.filter(r => r.cleanliness_rating).length || 0,
      averageSafety: ratings.filter(r => r.safety_rating)
        .reduce((sum, r) => sum + r.safety_rating, 0) / 
        ratings.filter(r => r.safety_rating).length || 0
    };
    
    res.json({
      success: true,
      data: stats
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener estadísticas de calificaciones',
      message: error.message
    });
  }
});

module.exports = router;

