-- ================================================
-- SCRIPT DE RESET: Limpiar base de datos y dejar solo usuarios básicos
-- ================================================
-- Este script elimina todos los datos y deja SOLO 2 usuarios:
-- - 1 super_admin para el panel web administrativo (admin@transporterural.com)
-- - 1 usuario para la app móvil (usuario@transporterural.com)
-- 
-- NO se crean conductores, company_admin, ni empresas por defecto
-- Todo se creará desde el panel administrativo después del reset

-- ================================================
-- 1. ELIMINAR DATOS DE PRUEBA
-- ================================================

-- Eliminar todas las notificaciones
DELETE FROM notifications;

-- Eliminar todas las ubicaciones de buses
DELETE FROM bus_locations;

-- Eliminar todas las rutas
DELETE FROM routes;

-- Eliminar todos los conductores (usuarios con role = 'driver')
DELETE FROM users WHERE role = 'driver';

-- Eliminar todos los company_admin
DELETE FROM users WHERE role = 'company_admin';

-- ================================================
-- 2. RESETEAR USUARIOS BÁSICOS
-- ================================================

-- Eliminar todos los usuarios excepto los básicos
DELETE FROM users 
WHERE email NOT IN ('admin@transporterural.com', 'usuario@transporterural.com');

-- Asegurar que el super_admin existe con las credenciales correctas
INSERT INTO users (email, name, role, password, company_id)
VALUES 
  ('admin@transporterural.com', 'Super Administrador', 'super_admin', 'admin123', NULL)
ON CONFLICT (email) 
DO UPDATE SET 
  role = 'super_admin',
  password = 'admin123',
  name = 'Super Administrador',
  company_id = NULL;

-- Asegurar que el usuario para la app móvil existe
INSERT INTO users (email, name, role, password, company_id)
VALUES 
  ('usuario@transporterural.com', 'Usuario App Móvil', 'user', 'usuario123', NULL)
ON CONFLICT (email) 
DO UPDATE SET 
  role = 'user',
  password = 'usuario123',
  name = 'Usuario App Móvil',
  company_id = NULL;

-- ================================================
-- 3. RESETEAR EMPRESAS
-- ================================================

-- Eliminar todas las empresas (empezar completamente de 0)
-- Las empresas se crearán desde el panel administrativo
DELETE FROM companies;

-- Los usuarios básicos no necesitan company_id
UPDATE users SET company_id = NULL WHERE email IN ('admin@transporterural.com', 'usuario@transporterural.com');

-- ================================================
-- 4. VERIFICACIÓN
-- ================================================

-- Ver usuarios restantes
SELECT id, email, name, role, company_id 
FROM users 
ORDER BY role, email;

-- Ver empresas restantes
SELECT id, name, email, active 
FROM companies;

-- Contar registros
SELECT 
  (SELECT COUNT(*) FROM users) as total_usuarios,
  (SELECT COUNT(*) FROM users WHERE role = 'super_admin') as super_admins,
  (SELECT COUNT(*) FROM users WHERE role = 'user') as usuarios,
  (SELECT COUNT(*) FROM users WHERE role = 'driver') as conductores,
  (SELECT COUNT(*) FROM users WHERE role = 'company_admin') as company_admins,
  (SELECT COUNT(*) FROM companies) as total_empresas,
  (SELECT COUNT(*) FROM routes) as total_rutas,
  (SELECT COUNT(*) FROM bus_locations) as total_buses,
  (SELECT COUNT(*) FROM notifications) as total_notificaciones;

