-- ================================================
-- MIGRACIÓN: Agregar funcionalidades faltantes
-- ================================================
-- Esta migración agrega:
-- 1. Estados detallados de conductores
-- 2. Campo active para activar/desactivar usuarios
-- 3. Tabla de viajes/recorridos realizados
-- 4. Tabla de reportes/comentarios de usuarios
-- 5. Tabla de calificaciones
-- 6. Duración estimada de recorridos
-- 7. Análisis de demanda

-- ================================================
-- 1. AGREGAR CAMPOS A USERS
-- ================================================

-- Agregar campo active para activar/desactivar usuarios
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS active BOOLEAN DEFAULT true;

-- Agregar campo driver_status para estados detallados de conductores
ALTER TABLE users
ADD COLUMN IF NOT EXISTS driver_status VARCHAR(50) DEFAULT 'disponible'; 
-- Estados: 'disponible', 'en_ruta', 'fuera_de_servicio', 'en_descanso'

-- Índices
CREATE INDEX IF NOT EXISTS idx_users_active ON users(active);
CREATE INDEX IF NOT EXISTS idx_users_driver_status ON users(driver_status) WHERE role = 'driver';

-- ================================================
-- 2. AGREGAR CAMPO A ROUTES
-- ================================================

-- Agregar duración estimada en minutos
ALTER TABLE routes
ADD COLUMN IF NOT EXISTS estimated_duration INTEGER; 
-- Duración estimada en minutos

-- Agregar frecuencia (cada cuántos minutos sale un bus)
ALTER TABLE routes
ADD COLUMN IF NOT EXISTS frequency INTEGER DEFAULT 30; 
-- Frecuencia en minutos (default: 30 minutos)

-- ================================================
-- 3. TABLA: trips (Viajes/Recorridos realizados)
-- ================================================

CREATE TABLE IF NOT EXISTS trips (
  id SERIAL PRIMARY KEY,
  bus_id VARCHAR(50) NOT NULL,
  route_id VARCHAR(50) REFERENCES routes(route_id) ON DELETE SET NULL,
  driver_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  company_id INTEGER, -- Referencia a empresas (se agregará cuando exista la tabla)
  
  -- Fechas y tiempos
  scheduled_start TIMESTAMP NOT NULL, -- Hora programada de inicio
  actual_start TIMESTAMP, -- Hora real de inicio
  scheduled_end TIMESTAMP, -- Hora programada de fin
  actual_end TIMESTAMP, -- Hora real de fin
  
  -- Estado del viaje
  status VARCHAR(50) DEFAULT 'scheduled', 
  -- Estados: 'scheduled', 'in_progress', 'completed', 'cancelled', 'delayed'
  
  -- Métricas
  duration_minutes INTEGER, -- Duración real en minutos
  delay_minutes INTEGER, -- Retraso en minutos (positivo = retraso, negativo = adelantado)
  passenger_count INTEGER DEFAULT 0, -- Número de pasajeros
  capacity INTEGER, -- Capacidad del bus
  
  -- Ubicaciones
  start_location JSONB, -- {latitude, longitude} punto de inicio
  end_location JSONB, -- {latitude, longitude} punto de fin
  
  -- Notas y comentarios
  notes TEXT, -- Notas del conductor
  issues TEXT, -- Problemas durante el viaje
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para trips
CREATE INDEX IF NOT EXISTS idx_trips_bus_id ON trips(bus_id);
CREATE INDEX IF NOT EXISTS idx_trips_route_id ON trips(route_id);
CREATE INDEX IF NOT EXISTS idx_trips_driver_id ON trips(driver_id);
CREATE INDEX IF NOT EXISTS idx_trips_company_id ON trips(company_id);
CREATE INDEX IF NOT EXISTS idx_trips_status ON trips(status);
CREATE INDEX IF NOT EXISTS idx_trips_scheduled_start ON trips(scheduled_start);
CREATE INDEX IF NOT EXISTS idx_trips_actual_start ON trips(actual_start);
CREATE INDEX IF NOT EXISTS idx_trips_actual_end ON trips(actual_end);

-- Trigger para actualizar updated_at
CREATE TRIGGER update_trips_updated_at
  BEFORE UPDATE ON trips
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- 4. TABLA: user_reports (Reportes/Comentarios de usuarios)
-- ================================================

CREATE TABLE IF NOT EXISTS user_reports (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  route_id VARCHAR(50) REFERENCES routes(route_id) ON DELETE SET NULL,
  bus_id VARCHAR(50),
  trip_id INTEGER REFERENCES trips(id) ON DELETE SET NULL,
  
  -- Tipo de reporte
  type VARCHAR(50) NOT NULL, 
  -- Tipos: 'complaint', 'suggestion', 'compliment', 'issue', 'other'
  
  -- Contenido
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  
  -- Estado
  status VARCHAR(50) DEFAULT 'pending',
  -- Estados: 'pending', 'reviewed', 'resolved', 'rejected', 'archived'
  
  -- Respuesta del administrador
  admin_response TEXT,
  reviewed_by INTEGER REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMP,
  
  -- Prioridad
  priority VARCHAR(50) DEFAULT 'medium',
  -- Prioridades: 'low', 'medium', 'high', 'urgent'
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Índices para user_reports
CREATE INDEX IF NOT EXISTS idx_user_reports_user_id ON user_reports(user_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_route_id ON user_reports(route_id);
CREATE INDEX IF NOT EXISTS idx_user_reports_status ON user_reports(status);
CREATE INDEX IF NOT EXISTS idx_user_reports_type ON user_reports(type);
CREATE INDEX IF NOT EXISTS idx_user_reports_priority ON user_reports(priority);
CREATE INDEX IF NOT EXISTS idx_user_reports_created_at ON user_reports(created_at);

-- Trigger para actualizar updated_at
CREATE TRIGGER update_user_reports_updated_at
  BEFORE UPDATE ON user_reports
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- 5. TABLA: ratings (Calificaciones)
-- ================================================

CREATE TABLE IF NOT EXISTS ratings (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Usuario que califica
  driver_id INTEGER REFERENCES users(id) ON DELETE SET NULL, -- Conductor calificado
  route_id VARCHAR(50) REFERENCES routes(route_id) ON DELETE SET NULL,
  trip_id INTEGER REFERENCES trips(id) ON DELETE SET NULL,
  company_id INTEGER, -- Referencia a empresas (se agregará cuando exista la tabla)
  
  -- Calificación (1-5 estrellas)
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  
  -- Comentario
  comment TEXT,
  
  -- Categorías de calificación
  punctuality_rating INTEGER CHECK (punctuality_rating >= 1 AND punctuality_rating <= 5),
  service_rating INTEGER CHECK (service_rating >= 1 AND service_rating <= 5),
  cleanliness_rating INTEGER CHECK (cleanliness_rating >= 1 AND cleanliness_rating <= 5),
  safety_rating INTEGER CHECK (safety_rating >= 1 AND safety_rating <= 5),
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Un usuario solo puede calificar una vez por viaje
  CONSTRAINT unique_rating_per_trip UNIQUE(user_id, trip_id)
);

-- Índices para ratings
CREATE INDEX IF NOT EXISTS idx_ratings_user_id ON ratings(user_id);
CREATE INDEX IF NOT EXISTS idx_ratings_driver_id ON ratings(driver_id);
CREATE INDEX IF NOT EXISTS idx_ratings_route_id ON ratings(route_id);
CREATE INDEX IF NOT EXISTS idx_ratings_trip_id ON ratings(trip_id);
CREATE INDEX IF NOT EXISTS idx_ratings_company_id ON ratings(company_id);
CREATE INDEX IF NOT EXISTS idx_ratings_rating ON ratings(rating);
CREATE INDEX IF NOT EXISTS idx_ratings_created_at ON ratings(created_at);

-- Trigger para actualizar updated_at
CREATE TRIGGER update_ratings_updated_at
  BEFORE UPDATE ON ratings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- 6. TABLA: route_demand (Análisis de demanda por ruta)
-- ================================================

CREATE TABLE IF NOT EXISTS route_demand (
  id SERIAL PRIMARY KEY,
  route_id VARCHAR(50) REFERENCES routes(route_id) ON DELETE CASCADE,
  company_id INTEGER, -- Referencia a empresas (se agregará cuando exista la tabla)
  
  -- Fecha y hora
  date DATE NOT NULL,
  hour INTEGER NOT NULL CHECK (hour >= 0 AND hour < 24),
  
  -- Métricas de demanda
  passenger_count INTEGER DEFAULT 0, -- Número de pasajeros en ese horario
  trip_count INTEGER DEFAULT 0, -- Número de viajes en ese horario
  average_occupancy DECIMAL(5,2) DEFAULT 0, -- Ocupación promedio (%)
  peak_demand BOOLEAN DEFAULT false, -- Si es hora pico
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  -- Una entrada por ruta, fecha y hora
  CONSTRAINT unique_route_demand UNIQUE(route_id, date, hour)
);

-- Índices para route_demand
CREATE INDEX IF NOT EXISTS idx_route_demand_route_id ON route_demand(route_id);
CREATE INDEX IF NOT EXISTS idx_route_demand_company_id ON route_demand(company_id);
CREATE INDEX IF NOT EXISTS idx_route_demand_date ON route_demand(date);
CREATE INDEX IF NOT EXISTS idx_route_demand_hour ON route_demand(hour);
CREATE INDEX IF NOT EXISTS idx_route_demand_peak ON route_demand(peak_demand);

-- Trigger para actualizar updated_at
CREATE TRIGGER update_route_demand_updated_at
  BEFORE UPDATE ON route_demand
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- 7. VISTAS ÚTILES
-- ================================================

-- Vista: Estadísticas de puntualidad por conductor
CREATE OR REPLACE VIEW driver_punctuality_stats AS
SELECT 
  u.id as driver_id,
  u.name as driver_name,
  COUNT(t.id) as total_trips,
  COUNT(CASE WHEN t.delay_minutes <= 0 THEN 1 END) as on_time_trips,
  COUNT(CASE WHEN t.delay_minutes > 0 AND t.delay_minutes <= 5 THEN 1 END) as slight_delay_trips,
  COUNT(CASE WHEN t.delay_minutes > 5 THEN 1 END) as delayed_trips,
  AVG(t.delay_minutes) as avg_delay_minutes,
  ROUND(
    (COUNT(CASE WHEN t.delay_minutes <= 0 THEN 1 END)::DECIMAL / 
     NULLIF(COUNT(t.id), 0)) * 100, 
    2
  ) as punctuality_percentage
FROM users u
LEFT JOIN trips t ON u.id = t.driver_id AND t.status = 'completed'
WHERE u.role = 'driver'
GROUP BY u.id, u.name;

-- Vista: Calificaciones promedio por conductor
CREATE OR REPLACE VIEW driver_ratings_summary AS
SELECT 
  u.id as driver_id,
  u.name as driver_name,
  COUNT(r.id) as total_ratings,
  ROUND(AVG(r.rating), 2) as avg_rating,
  ROUND(AVG(r.punctuality_rating), 2) as avg_punctuality,
  ROUND(AVG(r.service_rating), 2) as avg_service,
  ROUND(AVG(r.cleanliness_rating), 2) as avg_cleanliness,
  ROUND(AVG(r.safety_rating), 2) as avg_safety
FROM users u
LEFT JOIN ratings r ON u.id = r.driver_id
WHERE u.role = 'driver'
GROUP BY u.id, u.name;

-- Vista: Análisis de demanda por ruta
CREATE OR REPLACE VIEW route_demand_analysis AS
SELECT 
  r.route_id,
  r.name as route_name,
  rd.date,
  rd.hour,
  rd.passenger_count,
  rd.trip_count,
  rd.average_occupancy,
  rd.peak_demand,
  COUNT(DISTINCT t.id) as completed_trips
FROM routes r
LEFT JOIN route_demand rd ON r.route_id = rd.route_id
LEFT JOIN trips t ON r.route_id = t.route_id AND t.status = 'completed'
GROUP BY r.route_id, r.name, rd.date, rd.hour, rd.passenger_count, 
         rd.trip_count, rd.average_occupancy, rd.peak_demand;

-- Vista: Reportes pendientes
CREATE OR REPLACE VIEW pending_reports AS
SELECT 
  ur.id,
  ur.type,
  ur.title,
  ur.description,
  ur.priority,
  ur.status,
  ur.created_at,
  u.name as user_name,
  r.name as route_name,
  ur.bus_id
FROM user_reports ur
LEFT JOIN users u ON ur.user_id = u.id
LEFT JOIN routes r ON ur.route_id = r.route_id
WHERE ur.status = 'pending'
ORDER BY 
  CASE ur.priority
    WHEN 'urgent' THEN 1
    WHEN 'high' THEN 2
    WHEN 'medium' THEN 3
    WHEN 'low' THEN 4
  END,
  ur.created_at DESC;

-- ================================================
-- 8. POLÍTICAS RLS
-- ================================================

-- Habilitar RLS en las nuevas tablas
ALTER TABLE trips ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;
ALTER TABLE route_demand ENABLE ROW LEVEL SECURITY;

-- Políticas para trips (acceso público por ahora)
CREATE POLICY "Trips: acceso público" ON trips
  FOR ALL USING (true);

-- Políticas para user_reports (acceso público por ahora)
CREATE POLICY "User reports: acceso público" ON user_reports
  FOR ALL USING (true);

-- Políticas para ratings (acceso público por ahora)
CREATE POLICY "Ratings: acceso público" ON ratings
  FOR ALL USING (true);

-- Políticas para route_demand (acceso público por ahora)
CREATE POLICY "Route demand: acceso público" ON route_demand
  FOR ALL USING (true);

-- ================================================
-- 9. ACTUALIZAR DATOS EXISTENTES
-- ================================================

-- Marcar todos los usuarios existentes como activos
UPDATE users SET active = true WHERE active IS NULL;

-- Establecer estado de conductores existentes como 'disponible'
UPDATE users SET driver_status = 'disponible' 
WHERE role = 'driver' AND driver_status IS NULL;

-- ================================================
-- FIN DE LA MIGRACIÓN
-- ================================================

