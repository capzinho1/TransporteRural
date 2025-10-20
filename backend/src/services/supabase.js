const { createClient } = require('@supabase/supabase-js');
require('dotenv').config();

// Supabase configuration
const supabaseUrl = process.env.SUPABASE_URL || 'https://aghbbmbbfcgtpipnrjev.supabase.co';
const supabaseKey = process.env.SUPABASE_ANON_KEY;

if (!supabaseKey) {
  console.error('❌ SUPABASE_ANON_KEY no está configurada en las variables de entorno');
  process.exit(1);
}

// Create Supabase client
const supabase = createClient(supabaseUrl, supabaseKey);

// =============================================
// USERS SERVICE
// =============================================

class UsersService {
  // Get all users
  static async getAllUsers() {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return { success: true, data, count: data.length };
    } catch (error) {
      console.error('Error getting users:', error);
      return { success: false, error: error.message };
    }
  }

  // Get user by ID
  static async getUserById(uid) {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('uid', uid)
        .single();

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Error getting user:', error);
      return { success: false, error: error.message };
    }
  }

  // Create user
  static async createUser(userData) {
    try {
      const { data, error } = await supabase
        .from('users')
        .insert([userData])
        .select()
        .single();

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Error creating user:', error);
      return { success: false, error: error.message };
    }
  }

  // Update user
  static async updateUser(uid, userData) {
    try {
      const { data, error } = await supabase
        .from('users')
        .update(userData)
        .eq('uid', uid)
        .select()
        .single();

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Error updating user:', error);
      return { success: false, error: error.message };
    }
  }

  // Delete user
  static async deleteUser(uid) {
    try {
      const { error } = await supabase
        .from('users')
        .delete()
        .eq('uid', uid);

      if (error) throw error;
      return { success: true };
    } catch (error) {
      console.error('Error deleting user:', error);
      return { success: false, error: error.message };
    }
  }
}

// =============================================
// ROUTES SERVICE
// =============================================

class RoutesService {
  // Get all routes
  static async getAllRoutes() {
    try {
      const { data, error } = await supabase
        .from('routes')
        .select('*')
        .order('created_at', { ascending: false });

      if (error) throw error;
      return { success: true, data, count: data.length };
    } catch (error) {
      console.error('Error getting routes:', error);
      return { success: false, error: error.message };
    }
  }

  // Get route by ID
  static async getRouteById(routeId) {
    try {
      const { data, error } = await supabase
        .from('routes')
        .select('*')
        .eq('route_id', routeId)
        .single();

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Error getting route:', error);
      return { success: false, error: error.message };
    }
  }

  // Create route
  static async createRoute(routeData) {
    try {
      const { data, error } = await supabase
        .from('routes')
        .insert([routeData])
        .select()
        .single();

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Error creating route:', error);
      return { success: false, error: error.message };
    }
  }

  // Update route
  static async updateRoute(routeId, routeData) {
    try {
      const { data, error } = await supabase
        .from('routes')
        .update(routeData)
        .eq('route_id', routeId)
        .select()
        .single();

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Error updating route:', error);
      return { success: false, error: error.message };
    }
  }

  // Delete route
  static async deleteRoute(routeId) {
    try {
      const { error } = await supabase
        .from('routes')
        .delete()
        .eq('route_id', routeId);

      if (error) throw error;
      return { success: true };
    } catch (error) {
      console.error('Error deleting route:', error);
      return { success: false, error: error.message };
    }
  }
}

// =============================================
// BUS LOCATIONS SERVICE
// =============================================

class BusLocationsService {
  // Get all bus locations
  static async getAllBusLocations() {
    try {
      const { data, error } = await supabase
        .from('bus_locations')
        .select(`
          *,
          routes:route_id(name),
          users:driver_id(name)
        `)
        .order('last_update', { ascending: false });

      if (error) throw error;
      return { success: true, data, count: data.length };
    } catch (error) {
      console.error('Error getting bus locations:', error);
      return { success: false, error: error.message };
    }
  }

  // Get bus location by ID
  static async getBusLocationById(busId) {
    try {
      const { data, error } = await supabase
        .from('bus_locations')
        .select(`
          *,
          routes:route_id(name),
          users:driver_id(name)
        `)
        .eq('bus_id', busId)
        .single();

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Error getting bus location:', error);
      return { success: false, error: error.message };
    }
  }

  // Get active buses
  static async getActiveBuses() {
    try {
      const { data, error } = await supabase
        .from('active_buses')
        .select('*')
        .order('last_update', { ascending: false });

      if (error) throw error;
      return { success: true, data, count: data.length };
    } catch (error) {
      console.error('Error getting active buses:', error);
      return { success: false, error: error.message };
    }
  }

  // Update bus location
  static async updateBusLocation(busId, locationData) {
    try {
      const { data, error } = await supabase
        .from('bus_locations')
        .upsert({
          bus_id: busId,
          ...locationData,
          last_update: new Date().toISOString()
        })
        .select()
        .single();

      if (error) throw error;
      return { success: true, data };
    } catch (error) {
      console.error('Error updating bus location:', error);
      return { success: false, error: error.message };
    }
  }

  // Get buses by route
  static async getBusesByRoute(routeId) {
    try {
      const { data, error } = await supabase
        .from('bus_locations')
        .select(`
          *,
          routes:route_id(name),
          users:driver_id(name)
        `)
        .eq('route_id', routeId)
        .order('last_update', { ascending: false });

      if (error) throw error;
      return { success: true, data, count: data.length };
    } catch (error) {
      console.error('Error getting buses by route:', error);
      return { success: false, error: error.message };
    }
  }

  // Get buses by driver
  static async getBusesByDriver(driverId) {
    try {
      const { data, error } = await supabase
        .from('bus_locations')
        .select(`
          *,
          routes:route_id(name),
          users:driver_id(name)
        `)
        .eq('driver_id', driverId)
        .order('last_update', { ascending: false });

      if (error) throw error;
      return { success: true, data, count: data.length };
    } catch (error) {
      console.error('Error getting buses by driver:', error);
      return { success: false, error: error.message };
    }
  }

  // Get buses within radius
  static async getBusesWithinRadius(lat, lng, radiusKm = 5) {
    try {
      const { data, error } = await supabase
        .from('bus_locations')
        .select(`
          *,
          routes:route_id(name),
          users:driver_id(name)
        `)
        .filter('location', 'st_dwithin', `POINT(${lng} ${lat}),${radiusKm * 1000}`)
        .order('last_update', { ascending: false });

      if (error) throw error;
      return { success: true, data, count: data.length };
    } catch (error) {
      console.error('Error getting buses within radius:', error);
      return { success: false, error: error.message };
    }
  }
}

// =============================================
// REAL-TIME SUBSCRIPTIONS
// =============================================

class RealtimeService {
  // Subscribe to bus locations changes
  static subscribeToBusLocations(callback) {
    return supabase
      .channel('bus_locations_changes')
      .on('postgres_changes', 
        { 
          event: '*', 
          schema: 'public', 
          table: 'bus_locations' 
        }, 
        callback
      )
      .subscribe();
  }

  // Subscribe to specific bus location changes
  static subscribeToBusLocation(busId, callback) {
    return supabase
      .channel(`bus_location_${busId}`)
      .on('postgres_changes', 
        { 
          event: '*', 
          schema: 'public', 
          table: 'bus_locations',
          filter: `bus_id=eq.${busId}`
        }, 
        callback
      )
      .subscribe();
  }

  // Subscribe to route changes
  static subscribeToRoutes(callback) {
    return supabase
      .channel('routes_changes')
      .on('postgres_changes', 
        { 
          event: '*', 
          schema: 'public', 
          table: 'routes' 
        }, 
        callback
      )
      .subscribe();
  }
}

module.exports = {
  supabase,
  UsersService,
  RoutesService,
  BusLocationsService,
  RealtimeService
};

