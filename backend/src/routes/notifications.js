const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

// GET /api/notifications - Obtener notificaciones para un conductor
router.get('/', async (req, res) => {
  try {
    const { driverId, routeId } = req.query;
    
    let query = supabase
      .from('notifications')
      .select('*')
      .order('sent_at', { ascending: false });
    
    // Si se especifica un conductor, filtrar por:
    // - Notificaciones globales (type = 'global')
    // - Notificaciones para todos los conductores (type = 'drivers')
    // - Notificaciones para su ruta específica (type = 'route' AND target_id = routeId)
    // - Notificaciones específicas para él (type = 'driver' AND target_id = driverId)
    if (driverId) {
      // Obtener todas las notificaciones y filtrar en JavaScript
      // porque Supabase no soporta OR complejos fácilmente
      const { data: allNotifications, error } = await supabase
        .from('notifications')
        .select('*')
        .order('sent_at', { ascending: false });
      
      if (error) throw error;
      
      // Filtrar las notificaciones según el conductor
      const filteredNotifications = (allNotifications || []).filter(notif => {
        // Notificaciones globales
        if (notif.type === 'global') return true;
        
        // Notificaciones para todos los conductores
        if (notif.type === 'drivers') return true;
        
        // Notificaciones para la ruta del conductor
        if (notif.type === 'route' && routeId && notif.target_id === routeId) {
          return true;
        }
        
        // Notificaciones específicas para este conductor
        if (notif.type === 'driver' && notif.target_id === driverId.toString()) {
          return true;
        }
        
        return false;
      });
      
      return res.json({
        success: true,
        data: filteredNotifications,
        message: 'Notificaciones obtenidas exitosamente'
      });
    } else {
      // Si no hay driverId, devolver todas las notificaciones (para admin)
      const { data, error } = await query;
      
      if (error) throw error;
      
      res.json({
        success: true,
        data: data || [],
        message: 'Notificaciones obtenidas exitosamente'
      });
    }
  } catch (error) {
    console.error('Error al obtener notificaciones:', error);
    res.status(500).json({
      success: false,
      error: 'Error al obtener notificaciones',
      message: error.message
    });
  }
});

// POST /api/notifications - Crear nueva notificación
router.post('/', async (req, res) => {
  try {
    const { title, message, type, targetId, createdBy } = req.body;
    
    // Validar campos requeridos
    if (!title || !message || !type) {
      return res.status(400).json({
        success: false,
        error: 'Campos requeridos: title, message, type'
      });
    }
    
    // Validar tipo
    const validTypes = ['global', 'drivers', 'route', 'driver'];
    if (!validTypes.includes(type)) {
      return res.status(400).json({
        success: false,
        error: `Tipo inválido. Debe ser uno de: ${validTypes.join(', ')}`
      });
    }
    
    // Si es tipo 'route' o 'driver', targetId es requerido
    if ((type === 'route' || type === 'driver') && !targetId) {
      return res.status(400).json({
        success: false,
        error: 'targetId es requerido para notificaciones de tipo route o driver'
      });
    }
    
    // Crear la notificación
    const notificationData = {
      title,
      message,
      type,
      target_id: targetId || null,
      created_by: createdBy || null,
      sent_at: new Date().toISOString()
    };
    
    const { data, error } = await supabase
      .from('notifications')
      .insert([notificationData])
      .select()
      .single();
    
    if (error) throw error;
    
    res.status(201).json({
      success: true,
      data: data,
      message: 'Notificación creada exitosamente'
    });
  } catch (error) {
    console.error('Error al crear notificación:', error);
    res.status(500).json({
      success: false,
      error: 'Error al crear notificación',
      message: error.message
    });
  }
});

// GET /api/notifications/:id - Obtener una notificación específica
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data, error } = await supabase
      .from('notifications')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) throw error;
    
    if (!data) {
      return res.status(404).json({
        success: false,
        error: 'Notificación no encontrada'
      });
    }
    
    res.json({
      success: true,
      data: data,
      message: 'Notificación obtenida exitosamente'
    });
  } catch (error) {
    console.error('Error al obtener notificación:', error);
    res.status(500).json({
      success: false,
      error: 'Error al obtener notificación',
      message: error.message
    });
  }
});

module.exports = router;

