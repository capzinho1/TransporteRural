const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');

// Helper para obtener usuario desde header o query
const getUserFromRequest = async (req) => {
  const userId = req.headers['x-user-id'] || req.query.user_id;
  if (!userId) return null;
  
  const { data: user } = await supabase
    .from('users')
    .select('role, company_id')
    .eq('id', userId)
    .single();
  
  return user;
};

// GET /api/routes - Obtener todas las rutas
router.get('/', async (req, res) => {
  try {
    console.log('📋 Obteniendo rutas. Header x-user-id:', req.headers['x-user-id']);
    
    let query = supabase
      .from('routes')
      .select('*');
    
    // Filtrar por empresa si es company_admin
    const user = await getUserFromRequest(req);
    console.log('👤 Usuario para filtrar rutas:', user ? { role: user.role, company_id: user.company_id } : 'null');
    
    if (user && user.role === 'company_admin' && user.company_id) {
      query = query.eq('company_id', user.company_id);
      console.log('🔍 Filtrando rutas por company_id:', user.company_id);
    }
    
    query = query.order('created_at', { ascending: false });
    
    const { data: routes, error } = await query;
    
    if (error) {
      console.error('❌ Error Supabase al obtener rutas:', error);
      throw error;
    }
    
    console.log(`✅ Rutas obtenidas: ${routes ? routes.length : 0}`);
    if (routes && routes.length > 0) {
      console.log('📝 IDs de rutas:', routes.map(r => r.route_id).join(', '));
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
    const { route_id, name, schedule, stops, polyline, company_id } = req.body;
    
    console.log('📝 Creando ruta:', { route_id, name, company_id });
    console.log('🔑 Header x-user-id:', req.headers['x-user-id']);
    
    // Obtener usuario y asignar company_id automáticamente si es company_admin
    const user = await getUserFromRequest(req);
    console.log('👤 Usuario obtenido:', user ? { role: user.role, company_id: user.company_id } : 'null');
    
    let finalCompanyId = company_id;
    if (!finalCompanyId && user && user.role === 'company_admin' && user.company_id) {
      finalCompanyId = user.company_id;
      console.log('✅ Company ID asignado automáticamente:', finalCompanyId);
    }
    
    const { data: nuevaRuta, error } = await supabase
      .from('routes')
      .insert([
        {
          route_id,
          name,
          schedule: schedule || null,
          stops: stops || null,
          polyline: polyline || null,
          company_id: finalCompanyId || null,
          active: true
        }
      ])
      .select()
      .single();
    
    if (error) {
      console.error('❌ Error Supabase al crear ruta:', error);
      throw error;
    }
    
    console.log('✅ Ruta creada exitosamente:', nuevaRuta.route_id);
    
    res.status(201).json({
      success: true,
      data: nuevaRuta,
      message: 'Ruta creada exitosamente'
    });
  } catch (error) {
    console.error('❌ Error al crear ruta:', error.message);
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
    
    // Verificar permisos: company_admin solo puede modificar rutas de su empresa
    const user = await getUserFromRequest(req);
    if (user && user.role === 'company_admin' && user.company_id) {
      const { data: existingRoute } = await supabase
        .from('routes')
        .select('company_id')
        .eq('route_id', id)
        .single();
      
      if (existingRoute && existingRoute.company_id !== user.company_id) {
        return res.status(403).json({
          success: false,
          error: 'No tienes permisos para modificar esta ruta'
        });
      }
    }
    
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
