-- ================================================
-- SCHEMA SUPABASE - TransporteRural
-- ================================================

-- Habilitar extensión PostGIS para coordenadas
CREATE EXTENSION IF NOT EXISTS postgis;

-- ================================================
-- TABLA: users (Usuarios del sistema)
-- ================================================
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  name VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL DEFAULT 'user', -- 'admin', 'driver', 'user'
  notification_tokens TEXT[], -- Tokens para notificaciones push
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para users
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);

-- ================================================
-- TABLA: routes (Rutas de buses)
-- ================================================
CREATE TABLE IF NOT EXISTS routes (
  route_id VARCHAR(50) PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  schedule JSONB, -- Horarios en formato JSON
  stops JSONB, -- Paradas con coordenadas en formato JSON
  polyline TEXT, -- Polyline para dibujar la ruta en el mapa
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para routes
CREATE INDEX idx_routes_active ON routes(active);

-- ================================================
-- TABLA: bus_locations (Ubicaciones de buses en tiempo real)
-- ================================================
CREATE TABLE IF NOT EXISTS bus_locations (
  id SERIAL PRIMARY KEY,
  bus_id VARCHAR(50) NOT NULL,
  route_id VARCHAR(50) REFERENCES routes(route_id) ON DELETE SET NULL,
  driver_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  status VARCHAR(50) DEFAULT 'inactive', -- 'active', 'inactive', 'maintenance', 'en_ruta'
  last_update TIMESTAMP DEFAULT NOW(),
  created_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT unique_bus_id UNIQUE(bus_id)
);

-- Índices para bus_locations
CREATE INDEX idx_bus_locations_bus_id ON bus_locations(bus_id);
CREATE INDEX idx_bus_locations_route_id ON bus_locations(route_id);
CREATE INDEX idx_bus_locations_driver_id ON bus_locations(driver_id);
CREATE INDEX idx_bus_locations_status ON bus_locations(status);

-- Índice espacial para búsquedas geográficas
CREATE INDEX idx_bus_locations_geom ON bus_locations USING GIST (
  ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
);

-- ================================================
-- TABLA: notifications (Historial de notificaciones)
-- ================================================
CREATE TABLE IF NOT EXISTS notifications (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'global', -- 'global', 'route', 'driver'
  target_id VARCHAR(50), -- route_id o driver_id según el tipo
  sent_at TIMESTAMP DEFAULT NOW(),
  created_by INTEGER REFERENCES users(id)
);

-- Índices para notifications
CREATE INDEX idx_notifications_type ON notifications(type);
CREATE INDEX idx_notifications_sent_at ON notifications(sent_at);

-- ================================================
-- FUNCIONES: Actualizar timestamp automáticamente
-- ================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers para actualizar updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_routes_updated_at
  BEFORE UPDATE ON routes
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- DATOS DE PRUEBA (SOLO ADMINISTRADOR INICIAL)
-- ================================================

-- Insertar SOLO 2 usuarios iniciales:
-- 1. super_admin para el panel web administrativo
-- 2. usuario para la app móvil
-- 
-- NO se crean conductores, company_admin, ni empresas por defecto
-- Todos los demás datos se crearán desde el panel administrativo
INSERT INTO users (email, name, role, password) VALUES
  ('admin@transporterural.com', 'Super Administrador', 'super_admin', 'admin123'),
  ('usuario@transporterural.com', 'Usuario App Móvil', 'user', 'usuario123')
ON CONFLICT (email) DO UPDATE SET
  role = CASE 
    WHEN EXCLUDED.email = 'admin@transporterural.com' THEN 'super_admin'
    ELSE 'user'
  END,
  password = CASE 
    WHEN EXCLUDED.email = 'admin@transporterural.com' THEN 'admin123'
    ELSE 'usuario123'
  END,
  name = EXCLUDED.name;

-- ================================================
-- POLÍTICAS RLS (Row Level Security)
-- ================================================

-- Habilitar RLS en las tablas
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE routes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bus_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Políticas para users (acceso público sin autenticación de Supabase Auth)
CREATE POLICY "Users: acceso público" ON users
  FOR ALL USING (true);

-- Políticas para routes (acceso público)
CREATE POLICY "Routes: acceso público" ON routes
  FOR ALL USING (true);

-- Políticas para bus_locations (acceso público)
CREATE POLICY "Bus locations: acceso público" ON bus_locations
  FOR ALL USING (true);

-- Políticas para notifications (acceso público)
CREATE POLICY "Notifications: acceso público" ON notifications
  FOR ALL USING (true);

-- ================================================
-- VISTAS ÚTILES
-- ================================================

-- Vista: Buses activos con información completa
CREATE OR REPLACE VIEW active_buses AS
SELECT 
  bl.id,
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
LEFT JOIN users u ON bl.driver_id = u.id
WHERE bl.status IN ('active', 'en_ruta');

-- Vista: Estadísticas del sistema
CREATE OR REPLACE VIEW system_stats AS
SELECT 
  (SELECT COUNT(*) FROM bus_locations WHERE status IN ('active', 'en_ruta')) as buses_activos,
  (SELECT COUNT(*) FROM bus_locations) as total_buses,
  (SELECT COUNT(*) FROM routes WHERE active = true) as rutas_activas,
  (SELECT COUNT(*) FROM users WHERE role = 'driver') as total_conductores,
  (SELECT COUNT(*) FROM users) as total_usuarios;

-- ================================================
-- FIN DEL SCHEMA
-- ================================================
