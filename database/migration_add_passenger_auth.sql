-- ================================================
-- MIGRACIÓN: Agregar campos para autenticación de pasajeros
-- ================================================
-- Esta migración agrega los campos necesarios para soportar
-- autenticación con Supabase Auth para pasajeros, mientras
-- se mantiene el sistema actual para conductores.

-- Agregar campo para identificar el proveedor de autenticación
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(50) DEFAULT 'local';

-- Agregar campo para almacenar el UUID de Supabase Auth
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS supabase_auth_id UUID;

-- Agregar campo para región (solo para pasajeros)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS region VARCHAR(100);

-- Crear índice para búsquedas por auth_provider
CREATE INDEX IF NOT EXISTS idx_users_auth_provider ON users(auth_provider);

-- Crear índice para búsquedas por supabase_auth_id
CREATE INDEX IF NOT EXISTS idx_users_supabase_auth_id ON users(supabase_auth_id);

-- Actualizar usuarios existentes para que tengan auth_provider = 'local'
UPDATE users 
SET auth_provider = 'local' 
WHERE auth_provider IS NULL;

-- Comentarios
COMMENT ON COLUMN users.auth_provider IS 'Proveedor de autenticación: local (email/password) o supabase (Supabase Auth)';
COMMENT ON COLUMN users.supabase_auth_id IS 'UUID del usuario en Supabase Auth (NULL para usuarios locales)';
COMMENT ON COLUMN users.region IS 'Región de Chile donde reside el pasajero';

