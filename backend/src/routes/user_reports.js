const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { getUserFromRequest } = require('../middleware/auth');

// GET /api/user-reports - Obtener todos los reportes
router.get('/', async (req, res) => {
  try {
    const user = await getUserFromRequest(req);
    let query = supabase.from('user_reports').select('*');
    
    // Filtrar por empresa si es company_admin
    if (user && user.role === 'company_admin' && user.company_id) {
      // Obtener rutas de la empresa y filtrar reportes
      const { data: routes } = await supabase
        .from('routes')
        .select('route_id')
        .eq('company_id', user.company_id);
      
      const routeIds = routes?.map(r => r.route_id) || [];
      if (routeIds.length > 0) {
        query = query.in('route_id', routeIds);
      } else {
        query = query.eq('route_id', 'no-routes'); // No hay rutas, no hay reportes
      }
    }
    
    query = query.order('created_at', { ascending: false });
    
    const { data: reports, error } = await query;
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: reports,
      count: reports.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener reportes',
      message: error.message
    });
  }
});

// GET /api/user-reports/:id - Obtener reporte por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: report, error } = await supabase
      .from('user_reports')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) throw error;
    
    if (!report) {
      return res.status(404).json({
        success: false,
        error: 'Reporte no encontrado'
      });
    }
    
    res.json({
      success: true,
      data: report
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener reporte',
      message: error.message
    });
  }
});

// GET /api/user-reports/pending - Obtener reportes pendientes
router.get('/pending/all', async (req, res) => {
  try {
    const user = await getUserFromRequest(req);
    let query = supabase
      .from('user_reports')
      .select('*')
      .eq('status', 'pending')
      .order('priority', { ascending: true })
      .order('created_at', { ascending: false });
    
    // Filtrar por empresa si es company_admin
    if (user && user.role === 'company_admin' && user.company_id) {
      const { data: routes } = await supabase
        .from('routes')
        .select('route_id')
        .eq('company_id', user.company_id);
      
      const routeIds = routes?.map(r => r.route_id) || [];
      if (routeIds.length > 0) {
        query = query.in('route_id', routeIds);
      } else {
        query = query.eq('route_id', 'no-routes');
      }
    }
    
    const { data: reports, error } = await query;
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: reports,
      count: reports.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener reportes pendientes',
      message: error.message
    });
  }
});

// GET /api/user-reports/bus/:busId - Obtener reportes por bus
router.get('/bus/:busId', async (req, res) => {
  try {
    const { busId } = req.params;
    
    const { data: reports, error } = await supabase
      .from('user_reports')
      .select('*')
      .eq('bus_id', busId)
      .order('created_at', { ascending: false });
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: reports,
      count: reports.length
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al obtener reportes del bus',
      message: error.message
    });
  }
});

// POST /api/user-reports - Crear nuevo reporte
router.post('/', async (req, res) => {
  try {
    const {
      user_id,
      route_id,
      bus_id,
      trip_id,
      type,
      title,
      description,
      priority,
      tags
    } = req.body;
    
    // Validar campos obligatorios
    if (!type || !title || !description) {
      return res.status(400).json({
        success: false,
        error: 'Campos obligatorios: type, title, description'
      });
    }
    
    const insertData = {
      user_id: user_id || null,
      route_id: route_id || null,
      bus_id: bus_id || null,
      trip_id: trip_id || null,
      type,
      title,
      description,
      status: 'pending',
      priority: priority || 'medium',
      tags: tags && Array.isArray(tags) ? tags : null
    };
    
    const { data: nuevoReport, error } = await supabase
      .from('user_reports')
      .insert([insertData])
      .select()
      .single();
    
    if (error) throw error;
    
    res.status(201).json({
      success: true,
      data: nuevoReport,
      message: 'Reporte creado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al crear reporte',
      message: error.message
    });
  }
});

// PUT /api/user-reports/:id/review - Revisar reporte
router.put('/:id/review', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, admin_response, priority } = req.body;
    
    const user = await getUserFromRequest(req);
    
    if (!user) {
      return res.status(401).json({
        success: false,
        error: 'No autorizado'
      });
    }
    
    const updateData = {
      status: status || 'reviewed',
      admin_response: admin_response || null,
      reviewed_by: user.id,
      reviewed_at: new Date().toISOString()
    };
    
    if (priority) updateData.priority = priority;
    
    const { data: reportActualizado, error } = await supabase
      .from('user_reports')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: reportActualizado,
      message: 'Reporte revisado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al revisar reporte',
      message: error.message
    });
  }
});

// PUT /api/user-reports/:id - Actualizar reporte
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { status, priority, admin_response } = req.body;
    
    const updateData = {};
    if (status !== undefined) updateData.status = status;
    if (priority !== undefined) updateData.priority = priority;
    if (admin_response !== undefined) updateData.admin_response = admin_response;
    
    const { data: reportActualizado, error } = await supabase
      .from('user_reports')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: reportActualizado,
      message: 'Reporte actualizado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al actualizar reporte',
      message: error.message
    });
  }
});

// DELETE /api/user-reports/:id - Eliminar reporte
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { error } = await supabase
      .from('user_reports')
      .delete()
      .eq('id', id);
    
    if (error) throw error;
    
    res.json({
      success: true,
      message: 'Reporte eliminado exitosamente'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al eliminar reporte',
      message: error.message
    });
  }
});

module.exports = router;

