const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

// GET /api/routes - Obtener todas las rutas
router.get('/', async (req, res) => {
  try {
    const { data: routes, error } = await supabase
      .from('routes')
      .select('*')
      .order('created_at', { ascending: false });
    
    if (error) {
      console.error('❌ Error Supabase al obtener rutas:', error);
      throw error;
    }
    
    res.json({
      success: true,
      data: routes || [],
      count: routes ? routes.length : 0
    });
  } catch (error) {
    console.error('❌ Error al obtener rutas:', error.message);
    res.status(500).json({
      success: false,
      error: 'Error al obtener rutas',
      message: error.message,
      details: error.details || error.hint || null
    });
  }
});

// GET /api/routes/:id - Obtener ruta por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: ruta, error } = await supabase
      .from('routes')
      .select('*')
      .eq('route_id', id)
      .single();
    
    if (error) throw error;
    
    if (!ruta) {
      return res.status(404).json({
        success: false,
        error: 'Ruta no encontrada'
      });
    }
    
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

// POST /api/routes - Crear nueva ruta
router.post('/', async (req, res) => {
  try {
    const { route_id, name, schedule, stops, polyline } = req.body;
    
    const { data: nuevaRuta, error } = await supabase
      .from('routes')
      .insert([
        {
          route_id,
          name,
          schedule: schedule || null,
          stops: stops || null,
          polyline: polyline || null,
          active: true
        }
      ])
      .select()
      .single();
    
    if (error) throw error;
    
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

// PUT /api/routes/:id - Actualizar ruta
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, schedule, stops, polyline, active } = req.body;
    
    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (schedule !== undefined) updateData.schedule = schedule;
    if (stops !== undefined) updateData.stops = stops;
    if (polyline !== undefined) updateData.polyline = polyline;
    if (active !== undefined) updateData.active = active;
    
    const { data: rutaActualizada, error } = await supabase
      .from('routes')
      .update(updateData)
      .eq('route_id', id)
      .select()
      .single();
    
    if (error) throw error;
    
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

// DELETE /api/routes/:id - Eliminar ruta
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { error } = await supabase
      .from('routes')
      .delete()
      .eq('route_id', id);
    
    if (error) throw error;
    
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
