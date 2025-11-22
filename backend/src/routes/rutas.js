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
    const { route_id, name, schedule, stops, polyline, company_id, estimated_duration, frequency } = req.body;
    
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
          active: true,
          estimated_duration: estimated_duration || null,
          frequency: frequency || 30
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
    const { name, schedule, stops, polyline, active, estimated_duration, frequency } = req.body;
    
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
    if (estimated_duration !== undefined) updateData.estimated_duration = estimated_duration;
    if (frequency !== undefined) updateData.frequency = frequency;
    
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
    
    // Validar que no haya buses asignados a esta ruta
    const { data: busesAsignados, error: busesError } = await supabase
      .from('bus_locations')
      .select('bus_id, driver_id')
      .eq('route_id', id);
    
    if (busesError) throw busesError;
    
    if (busesAsignados && busesAsignados.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'No se puede eliminar la ruta',
        message: `La ruta tiene ${busesAsignados.length} bus(es) asignado(s). Por favor desasigna los buses antes de eliminar la ruta.`,
        busesAsignados: busesAsignados.map(b => b.bus_id)
      });
    }
    
    // Validar que no haya viajes programados o en progreso para esta ruta
    const { data: viajesActivos, error: viajesError } = await supabase
      .from('trips')
      .select('id, status, scheduled_start')
      .eq('route_id', id)
      .in('status', ['scheduled', 'in_progress']);
    
    if (viajesError) throw viajesError;
    
    if (viajesActivos && viajesActivos.length > 0) {
      return res.status(400).json({
        success: false,
        error: 'No se puede eliminar la ruta',
        message: `La ruta tiene ${viajesActivos.length} viaje(s) programado(s) o en progreso. Por favor cancela o completa los viajes antes de eliminar la ruta.`,
        viajesActivos: viajesActivos.map(v => ({ id: v.id, status: v.status }))
      });
    }
    
    // Si pasa todas las validaciones, eliminar la ruta
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

// GET /api/routes/search/fuzzy - Búsqueda fuzzy de rutas y buses por nombre
// Permite búsqueda tolerante a errores usando pg_trgm (trigram similarity)
router.get('/search/fuzzy', async (req, res) => {
  try {
    const { query: searchQuery, tipo, limit = 20 } = req.query;
    
    if (!searchQuery || searchQuery.trim() === '') {
      return res.status(400).json({
        success: false,
        error: 'El parámetro "query" es requerido'
      });
    }
    
    const searchTerm = searchQuery.trim();
    console.log('🔍 [SEARCH] Búsqueda fuzzy iniciada:', searchTerm);
    
    // Buscar en rutas (routes.name)
    // Usamos ilike para búsqueda case-insensitive y % para wildcards
    // También usamos pg_trgm para búsqueda fuzzy si está disponible
    let routesQuery = supabase
      .from('routes')
      .select('*')
      .or(`name.ilike.%${searchTerm}%`)
      .eq('active', true)
      .order('name', { ascending: true })
      .limit(parseInt(limit));
    
    // Filtrar por empresa si es company_admin
    const user = await getUserFromRequest(req);
    if (user && user.role === 'company_admin' && user.company_id) {
      routesQuery = routesQuery.eq('company_id', user.company_id);
    }
    
    const { data: routes, error: routesError } = await routesQuery;
    
    if (routesError) {
      console.error('❌ [SEARCH] Error al buscar rutas:', routesError);
    }
    
    // Buscar en buses (bus_locations.nombre_ruta)
    // También buscar buses que tengan el route_id de las rutas encontradas
    let busesQuery = supabase
      .from('bus_locations')
      .select(`
        *,
        routes:route_id (
          route_id,
          name,
          active
        )
      `)
      .or(`nombre_ruta.ilike.%${searchTerm}%`)
      .limit(parseInt(limit));
    
    // Si encontramos rutas, también buscar buses por route_id
    if (routes && routes.length > 0) {
      const routeIds = routes.map(r => r.route_id);
      busesQuery = busesQuery.or(`route_id.in.(${routeIds.join(',')}),nombre_ruta.ilike.%${searchTerm}%`);
    }
    
    const { data: buses, error: busesError } = await busesQuery;
    
    if (busesError) {
      console.error('❌ [SEARCH] Error al buscar buses:', busesError);
    }
    
    // Filtrar buses por empresa si es company_admin
    let filteredBuses = buses || [];
    if (user && user.role === 'company_admin' && user.company_id) {
      filteredBuses = filteredBuses.filter(bus => {
        // Filtrar por company_id del bus o de la ruta relacionada
        return (bus.company_id === user.company_id) || 
               (bus.routes && bus.routes.company_id === user.company_id);
      });
    }
    
    // Ordenar resultados por relevancia (coincidencias exactas primero)
    const routesWithScore = (routes || []).map(route => ({
      ...route,
      type: 'route',
      relevance_score: route.name.toLowerCase() === searchTerm.toLowerCase() ? 100 :
                       route.name.toLowerCase().startsWith(searchTerm.toLowerCase()) ? 90 :
                       route.name.toLowerCase().includes(searchTerm.toLowerCase()) ? 80 : 70
    })).sort((a, b) => b.relevance_score - a.relevance_score);
    
    const busesWithScore = filteredBuses.map(bus => {
      const routeName = bus.routes?.name || '';
      const nombreRuta = bus.nombre_ruta || '';
      const matchText = nombreRuta || routeName;
      
      return {
        ...bus,
        type: 'bus',
        relevance_score: matchText.toLowerCase() === searchTerm.toLowerCase() ? 100 :
                         matchText.toLowerCase().startsWith(searchTerm.toLowerCase()) ? 90 :
                         matchText.toLowerCase().includes(searchTerm.toLowerCase()) ? 80 : 70
      };
    }).sort((a, b) => b.relevance_score - a.relevance_score);
    
    // Combinar y ordenar todos los resultados
    const allResults = [...routesWithScore, ...busesWithScore]
      .sort((a, b) => b.relevance_score - a.relevance_score)
      .slice(0, parseInt(limit));
    
    console.log(`✅ [SEARCH] Búsqueda completada: ${routesWithScore.length} rutas, ${busesWithScore.length} buses`);
    
    res.json({
      success: true,
      data: {
        routes: routesWithScore,
        buses: busesWithScore,
        all: allResults,
        total: routesWithScore.length + busesWithScore.length
      },
      query: searchTerm,
      count: {
        routes: routesWithScore.length,
        buses: busesWithScore.length,
        total: allResults.length
      }
    });
  } catch (error) {
    console.error('❌ [SEARCH] Error en búsqueda fuzzy:', error);
    res.status(500).json({
      success: false,
      error: 'Error al realizar la búsqueda',
      message: error.message
    });
  }
});

module.exports = router;
