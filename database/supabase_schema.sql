-- TransporteRural Database Schema for Supabase
-- Based on the provided data model

-- Enable PostGIS extension for geospatial queries
CREATE EXTENSION IF NOT EXISTS postgis;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================
-- 1. USERS TABLE
-- =============================================
CREATE TABLE users (
    uid UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'driver', 'admin')),
    name TEXT NOT NULL,
    fcm_tokens TEXT[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 2. ROUTES TABLE
-- =============================================
CREATE TABLE routes (
    route_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    schedule TEXT[] DEFAULT '{}',
    stops JSONB DEFAULT '[]',
    polyline TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- 3. BUS_LOCATIONS TABLE
-- =============================================
CREATE TABLE bus_locations (
    bus_id TEXT PRIMARY KEY,
    route_id TEXT REFERENCES routes(route_id) ON DELETE CASCADE,
    driver_id UUID REFERENCES users(uid) ON DELETE SET NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    location GEOGRAPHY(POINT, 4326) GENERATED ALWAYS AS (ST_Point(longitude, latitude)) STORED,
    status TEXT NOT NULL DEFAULT 'inactive' CHECK (status IN ('en_ruta', 'finalizado', 'inactive')),
    last_update TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Geospatial index for bus locations
CREATE INDEX idx_bus_locations_geom ON bus_locations USING GIST (location);

-- Index for route queries
CREATE INDEX idx_bus_locations_route ON bus_locations (route_id);

-- Index for driver queries
CREATE INDEX idx_bus_locations_driver ON bus_locations (driver_id);

-- Index for status queries
CREATE INDEX idx_bus_locations_status ON bus_locations (status);

-- Index for time-based queries
CREATE INDEX idx_bus_locations_time ON bus_locations (last_update);

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_locations ENABLE ROW LEVEL SECURITY;

-- Users can view their own data
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (auth.uid() = uid);

-- Users can update their own data
CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (auth.uid() = uid);

-- Anyone can view routes (public data)
CREATE POLICY "Anyone can view routes" ON routes
    FOR SELECT USING (true);

-- Anyone can view bus locations (public data)
CREATE POLICY "Anyone can view bus locations" ON bus_locations
    FOR SELECT USING (true);

-- Only authenticated users can insert bus locations
CREATE POLICY "Authenticated users can insert bus locations" ON bus_locations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Only drivers can update their own bus locations
CREATE POLICY "Drivers can update own bus locations" ON bus_locations
    FOR UPDATE USING (auth.uid() = driver_id);

-- =============================================
-- FUNCTIONS AND TRIGGERS
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for users table
CREATE TRIGGER update_users_updated_at 
    BEFORE UPDATE ON users 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Trigger for routes table
CREATE TRIGGER update_routes_updated_at 
    BEFORE UPDATE ON routes 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- SAMPLE DATA
-- =============================================

-- Insert sample users
INSERT INTO users (uid, email, role, name, fcm_tokens) VALUES
    ('550e8400-e29b-41d4-a716-446655440000', 'usuario@transporterural.com', 'user', 'Usuario de Prueba', '{}'),
    ('550e8400-e29b-41d4-a716-446655440001', 'conductor1@transporterural.com', 'driver', 'Conductor Juan', '{}'),
    ('550e8400-e29b-41d4-a716-446655440002', 'conductor2@transporterural.com', 'driver', 'Conductor María', '{}');

-- Insert sample routes
INSERT INTO routes (route_id, name, schedule, stops, polyline) VALUES
    ('R001', 'Ruta Centro - Norte', 
     ARRAY['06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00'],
     '[{"id": 1, "name": "Centro", "latitude": -33.4489, "longitude": -70.6693, "order": 1}, {"id": 2, "name": "Norte", "latitude": -33.4000, "longitude": -70.6000, "order": 2}]',
     'encoded_polyline_string_here'),
    ('R002', 'Ruta Sur - Este',
     ARRAY['07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00'],
     '[{"id": 3, "name": "Sur", "latitude": -33.5000, "longitude": -70.7000, "order": 1}, {"id": 4, "name": "Este", "latitude": -33.3500, "longitude": -70.5500, "order": 2}]',
     'encoded_polyline_string_here');

-- Insert sample bus locations
INSERT INTO bus_locations (bus_id, route_id, driver_id, latitude, longitude, status) VALUES
    ('BUS001', 'R001', '550e8400-e29b-41d4-a716-446655440001', -33.4489, -70.6693, 'en_ruta'),
    ('BUS002', 'R002', '550e8400-e29b-41d4-a716-446655440002', -33.4000, -70.6000, 'en_ruta'),
    ('BUS003', 'R001', '550e8400-e29b-41d4-a716-446655440001', -33.4500, -70.6700, 'finalizado');

-- =============================================
-- VIEWS FOR COMMON QUERIES
-- =============================================

-- View for active buses with route and driver info
CREATE VIEW active_buses AS
SELECT 
    bl.bus_id,
    bl.route_id,
    r.name as route_name,
    bl.driver_id,
    u.name as driver_name,
    bl.latitude,
    bl.longitude,
    bl.status,
    bl.last_update
FROM bus_locations bl
LEFT JOIN routes r ON bl.route_id = r.route_id
LEFT JOIN users u ON bl.driver_id = u.uid
WHERE bl.status = 'en_ruta';

-- View for route statistics
CREATE VIEW route_stats AS
SELECT 
    r.route_id,
    r.name,
    COUNT(bl.bus_id) as active_buses,
    COUNT(CASE WHEN bl.status = 'en_ruta' THEN 1 END) as buses_en_ruta,
    COUNT(CASE WHEN bl.status = 'finalizado' THEN 1 END) as buses_finalizados
FROM routes r
LEFT JOIN bus_locations bl ON r.route_id = bl.route_id
GROUP BY r.route_id, r.name;
