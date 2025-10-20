-- Script de inicialización de la base de datos TransporteRural
-- Este script se ejecuta automáticamente al crear el contenedor de PostgreSQL

-- Crear extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- Crear esquema principal
CREATE SCHEMA IF NOT EXISTS transporterural;

-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS usuarios (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefono VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL,
    tipo VARCHAR(20) NOT NULL CHECK (tipo IN ('admin', 'conductor', 'pasajero')),
    activo BOOLEAN DEFAULT true,
    preferencias JSONB DEFAULT '{"notificaciones": true, "idioma": "es"}',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de rutas
CREATE TABLE IF NOT EXISTS rutas (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    origen VARCHAR(100) NOT NULL,
    destino VARCHAR(100) NOT NULL,
    distancia DECIMAL(8,2) NOT NULL,
    duracion INTEGER NOT NULL, -- en minutos
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de paradas
CREATE TABLE IF NOT EXISTS paradas (
    id SERIAL PRIMARY KEY,
    ruta_id INTEGER REFERENCES rutas(id) ON DELETE CASCADE,
    nombre VARCHAR(100) NOT NULL,
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    orden INTEGER,
    activa BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de buses
CREATE TABLE IF NOT EXISTS buses (
    id SERIAL PRIMARY KEY,
    patente VARCHAR(10) UNIQUE NOT NULL,
    modelo VARCHAR(100) NOT NULL,
    capacidad INTEGER NOT NULL,
    estado VARCHAR(20) DEFAULT 'activo' CHECK (estado IN ('activo', 'inactivo', 'mantenimiento', 'en_progreso')),
    ruta_id INTEGER REFERENCES rutas(id),
    conductor_id INTEGER REFERENCES usuarios(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de ubicaciones de buses
CREATE TABLE IF NOT EXISTS ubicaciones_buses (
    id SERIAL PRIMARY KEY,
    bus_id INTEGER REFERENCES buses(id) ON DELETE CASCADE,
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    velocidad DECIMAL(5, 2), -- en km/h
    direccion DECIMAL(5, 2), -- en grados
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de recorridos
CREATE TABLE IF NOT EXISTS recorridos (
    id SERIAL PRIMARY KEY,
    bus_id INTEGER REFERENCES buses(id),
    ruta_id INTEGER REFERENCES rutas(id),
    conductor_id INTEGER REFERENCES usuarios(id),
    estado VARCHAR(20) DEFAULT 'programado' CHECK (estado IN ('programado', 'en_progreso', 'finalizado', 'cancelado')),
    inicio TIMESTAMP,
    fin TIMESTAMP,
    pasajeros INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de historial de ubicaciones de recorridos
CREATE TABLE IF NOT EXISTS historial_ubicaciones (
    id SERIAL PRIMARY KEY,
    recorrido_id INTEGER REFERENCES recorridos(id) ON DELETE CASCADE,
    lat DECIMAL(10, 8) NOT NULL,
    lng DECIMAL(11, 8) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_usuarios_email ON usuarios(email);
CREATE INDEX IF NOT EXISTS idx_usuarios_tipo ON usuarios(tipo);
CREATE INDEX IF NOT EXISTS idx_buses_patente ON buses(patente);
CREATE INDEX IF NOT EXISTS idx_buses_estado ON buses(estado);
CREATE INDEX IF NOT EXISTS idx_buses_ruta_id ON buses(ruta_id);
CREATE INDEX IF NOT EXISTS idx_ubicaciones_bus_id ON ubicaciones_buses(bus_id);
CREATE INDEX IF NOT EXISTS idx_ubicaciones_timestamp ON ubicaciones_buses(timestamp);
CREATE INDEX IF NOT EXISTS idx_recorridos_estado ON recorridos(estado);
CREATE INDEX IF NOT EXISTS idx_recorridos_bus_id ON recorridos(bus_id);
CREATE INDEX IF NOT EXISTS idx_recorridos_ruta_id ON recorridos(ruta_id);
CREATE INDEX IF NOT EXISTS idx_paradas_ruta_id ON paradas(ruta_id);

-- Datos de ejemplo
INSERT INTO usuarios (nombre, email, telefono, password_hash, tipo) VALUES
('Administrador', 'admin@transporterural.com', '+56912345678', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
('Juan Pérez', 'juan@transporterural.com', '+56987654321', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'conductor'),
('María González', 'maria@email.com', '+56911111111', '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'pasajero');

INSERT INTO rutas (nombre, origen, destino, distancia, duracion) VALUES
('Ruta Centro - Norte', 'Centro', 'Norte', 15.5, 45),
('Ruta Sur - Este', 'Sur', 'Este', 22.3, 60),
('Ruta Oeste - Centro', 'Oeste', 'Centro', 18.7, 50);

INSERT INTO paradas (ruta_id, nombre, lat, lng, orden) VALUES
(1, 'Parada Centro', -33.4489, -70.6693, 1),
(1, 'Parada Norte', -33.4000, -70.6000, 2),
(2, 'Parada Sur', -33.5000, -70.7000, 1),
(2, 'Parada Este', -33.4500, -70.5500, 2),
(3, 'Parada Oeste', -33.4500, -70.8000, 1),
(3, 'Parada Centro', -33.4489, -70.6693, 2);

INSERT INTO buses (patente, modelo, capacidad, ruta_id, conductor_id) VALUES
('ABC123', 'Mercedes Benz OF-1724', 50, 1, 2),
('DEF456', 'Volvo B270F', 45, 2, 2),
('GHI789', 'Scania K270', 55, 3, 2);

INSERT INTO ubicaciones_buses (bus_id, lat, lng, velocidad, direccion) VALUES
(1, -33.4489, -70.6693, 25.5, 45.0),
(2, -33.4000, -70.6000, 30.2, 90.0),
(3, -33.4500, -70.8000, 0.0, 0.0);

-- Función para actualizar timestamp automáticamente
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers para actualizar updated_at
CREATE TRIGGER update_usuarios_updated_at BEFORE UPDATE ON usuarios
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_rutas_updated_at BEFORE UPDATE ON rutas
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_buses_updated_at BEFORE UPDATE ON buses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recorridos_updated_at BEFORE UPDATE ON recorridos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
