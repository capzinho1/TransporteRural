-- ================================================
-- MIGRACIÓN: Agregar columna password a users
-- ================================================
-- Este script agrega la columna password a la tabla users
-- Ejecuta este script si recibes el error: "Could not find the 'password' column"

-- Agregar columna password a users (si no existe)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS password VARCHAR(255);

-- Actualizar contraseñas de usuarios existentes si no tienen una
UPDATE users 
SET password = CASE 
  WHEN role = 'admin' OR role = 'super_admin' THEN 'admin123'
  WHEN role = 'company_admin' THEN 'admin123'
  WHEN role = 'driver' THEN 'conductor123'
  WHEN role = 'user' THEN 'usuario123'
  ELSE 'usuario123'
END
WHERE password IS NULL OR password = '';

-- Verificar que la columna se agregó correctamente
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'users' AND column_name = 'password';

