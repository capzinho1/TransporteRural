-- ================================================
-- MIGRACIÓN: Agregar soporte para empresas
-- ================================================

-- Crear tabla de empresas
CREATE TABLE IF NOT EXISTS companies (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  address TEXT,
  active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Agregar columna password a users (si no existe)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS password VARCHAR(255);

-- Agregar columna company_id a users
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS company_id INTEGER REFERENCES companies(id) ON DELETE SET NULL;

-- Actualizar contraseñas de usuarios existentes si no tienen una
-- (solo para usuarios que no tienen password)
UPDATE users 
SET password = CASE 
  WHEN role = 'admin' OR role = 'super_admin' THEN 'admin123'
  WHEN role = 'driver' THEN 'conductor123'
  WHEN role = 'user' THEN 'usuario123'
  ELSE 'usuario123'
END
WHERE password IS NULL OR password = '';

-- Actualizar roles permitidos: 'super_admin', 'company_admin', 'driver', 'user'
-- (El campo role ya es VARCHAR, así que no necesita cambio de tipo)

-- Agregar company_id a routes
ALTER TABLE routes 
ADD COLUMN IF NOT EXISTS company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE;

-- Agregar company_id a bus_locations (a través de route_id ya tiene relación indirecta)
-- Pero agreguemos también directamente para facilitar consultas
ALTER TABLE bus_locations 
ADD COLUMN IF NOT EXISTS company_id INTEGER REFERENCES companies(id) ON DELETE CASCADE;

-- Índices para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_users_company_id ON users(company_id);
CREATE INDEX IF NOT EXISTS idx_routes_company_id ON routes(company_id);
CREATE INDEX IF NOT EXISTS idx_bus_locations_company_id ON bus_locations(company_id);
CREATE INDEX IF NOT EXISTS idx_companies_active ON companies(active);

-- Trigger para actualizar updated_at en companies
CREATE TRIGGER update_companies_updated_at
  BEFORE UPDATE ON companies
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- NO crear empresa por defecto - las empresas se crearán desde el panel administrativo
-- Los usuarios básicos (super_admin y usuario de prueba) no necesitan company_id
-- Las rutas, buses y otros recursos se asignarán a empresas cuando se creen desde el panel

-- Actualizar el usuario admin inicial a super_admin (si existe)
UPDATE users 
SET role = 'super_admin' 
WHERE email = 'admin@transporterural.com' AND (role = 'admin' OR role IS NULL);

-- Política RLS para companies
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Companies: acceso público" ON companies
  FOR ALL USING (true);

