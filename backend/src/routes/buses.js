const express = require('express');
const router = express.Router();
const { supabase } = require('../config/supabase');
const { addCompanyFilter } = require('../middleware/auth');

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

// GET /api/bus-locations - Obtener todas las ubicaciones de buses
router.get('/', async (req, res) => {
  try {
    // Obtener información de buses con JOINs para empresa y conductor
    let query = supabase
      .from('bus_locations')
      .select(`
        *,
        companies:company_id(id, name),
        users!bus_locations_driver_id_fkey(id, name)
      `);
    
    // Filtrar por empresa si es company_admin
    const user = await getUserFromRequest(req);
    if (user && user.role === 'company_admin' && user.company_id) {
      query = query.eq('company_id', user.company_id);
    }
    
    // Ordenar por última actualización (más recientes primero)
    query = query.order('last_update', { ascending: false });
    
    const { data: busLocations, error } = await query;
    
    if (error) {
      console.error('❌ Error Supabase al obtener buses:', error);
      throw error;
    }
    
    // Transformar datos para incluir nombres de forma plana
    const transformedBuses = (busLocations || []).map(bus => {
      const company = bus.companies;
      // Supabase devuelve la relación como 'users' cuando se usa la foreign key
      const driver = bus.users || null;
      
      // Crear nuevo objeto sin los objetos anidados
      const { companies, users, ...busData } = bus;
      
      return {
        ...busData,
        company_name: company?.name || null,
        driver_name: driver?.name || null,
      };
    });
    
    // Log para debugging (opcional, puede remover en producción)
    if (process.env.NODE_ENV === 'development') {
      console.log(`✅ Obtenidas ${transformedBuses?.length || 0} ubicaciones de buses`);
    }
    
    res.json({
      success: true,
      data: transformedBuses,
      count: transformedBuses ? transformedBuses.length : 0
    });
  } catch (error) {
    console.error('❌ Error al obtener buses:', error.message);
    res.status(500).json({
      success: false,
      error: 'Error al obtener ubicaciones de buses',
      message: error.message,
      details: error.details || error.hint || null
    });
  }
});

// GET /api/bus-locations/:id - Obtener bus por ID
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { data: bus, error } = await supabase
      .from('bus_locations')
      .select('*')
      .eq('id', id)
      .single();
    
    if (error) throw error;
    
    if (!bus) {
      return res.status(404).json({
        success: false,
        error: 'Bus no encontrado'
      });
    }
    
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

// POST /api/bus-locations - Crear nuevo bus
router.post('/', async (req, res) => {
  try {
    const { bus_id, route_id, driver_id, latitude, longitude, status, company_id } = req.body;
    
    // Obtener usuario y asignar company_id automáticamente si es company_admin
    const user = await getUserFromRequest(req);
    let finalCompanyId = company_id;
    if (!finalCompanyId && user && user.role === 'company_admin' && user.company_id) {
      finalCompanyId = user.company_id;
    }
    
    const { data: nuevoBus, error } = await supabase
      .from('bus_locations')
      .insert([
        {
          bus_id,
          route_id: route_id || null,
          driver_id: driver_id || null,
          latitude,
          longitude,
          status: status || 'inactive',
          company_id: finalCompanyId || null,
          last_update: new Date().toISOString()
        }
      ])
      .select()
      .single();
    
    if (error) throw error;
    
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

// PUT /api/bus-locations/:id - Actualizar bus
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { bus_id, route_id, driver_id, latitude, longitude, status } = req.body;
    
    // Obtener el bus existente para preservar company_id y otros datos
    const { data: existingBus, error: fetchError } = await supabase
      .from('bus_locations')
      .select('*')
      .eq('id', id)
      .single();
    
    if (fetchError) {
      console.error('❌ Error al obtener bus existente:', fetchError);
      throw fetchError;
    }
    
    if (!existingBus) {
      return res.status(404).json({
        success: false,
        error: 'Bus no encontrado'
      });
    }
    
    // Verificar permisos: company_admin solo puede modificar buses de su empresa
    const user = await getUserFromRequest(req);
    if (user && user.role === 'company_admin' && user.company_id) {
      if (existingBus.company_id !== user.company_id) {
        return res.status(403).json({
          success: false,
          error: 'No tienes permisos para modificar este bus'
        });
      }
    }
    
    // Construir datos de actualización, preservando company_id si existe
    const updateData = { 
      last_update: new Date().toISOString() 
    };
    
    // Solo actualizar campos que se proporcionaron explícitamente
    if (bus_id !== undefined) updateData.bus_id = bus_id;
    if (route_id !== undefined) updateData.route_id = route_id;
    if (driver_id !== undefined) updateData.driver_id = driver_id;
    if (latitude !== undefined) updateData.latitude = latitude;
    if (longitude !== undefined) updateData.longitude = longitude;
    if (status !== undefined) updateData.status = status;
    
    // Preservar company_id si existe (no se debe cambiar desde la actualización)
    if (existingBus.company_id) {
      updateData.company_id = existingBus.company_id;
    }
    
    const { data: busActualizado, error } = await supabase
      .from('bus_locations')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) {
      console.error('❌ Error al actualizar bus:', error);
      throw error;
    }
    
    // Log para debugging (opcional, puede remover en producción)
    if (process.env.NODE_ENV === 'development') {
      console.log(`✅ Bus ${id} actualizado:`, {
        bus_id: busActualizado.bus_id,
        company_id: busActualizado.company_id,
        status: busActualizado.status,
        latitude: busActualizado.latitude,
        longitude: busActualizado.longitude,
        last_update: busActualizado.last_update
      });
    }
    
    res.json({
      success: true,
      data: busActualizado,
      message: 'Bus actualizado exitosamente'
    });
  } catch (error) {
    console.error('❌ Error completo al actualizar bus:', error);
    res.status(500).json({
      success: false,
      error: 'Error al actualizar bus',
      message: error.message
    });
  }
});

// PUT /api/bus-locations/:id/ubicacion - Actualizar solo ubicación del bus
router.put('/:id/ubicacion', async (req, res) => {
  try {
    const { id } = req.params;
    const { latitude, longitude, status } = req.body;
    
    const updateData = {
      latitude,
      longitude,
      last_update: new Date().toISOString()
    };
    
    if (status !== undefined) updateData.status = status;
    
    const { data: busActualizado, error } = await supabase
      .from('bus_locations')
      .update(updateData)
      .eq('id', id)
      .select()
      .single();
    
    if (error) throw error;
    
    res.json({
      success: true,
      data: busActualizado,
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

// DELETE /api/bus-locations/:id - Eliminar bus
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const { error } = await supabase
      .from('bus_locations')
      .delete()
      .eq('id', id);
    
    if (error) throw error;
    
    res.json({
      success: true,
      message: `Bus ${id} eliminado exitosamente`
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: 'Error al eliminar bus',
      message: error.message
    });
  }
});

module.exports = router;
