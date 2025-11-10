-- ================================================
-- MIGRACIÓN: Agregar sistema de alertas predefinidas para buses
-- ================================================

-- Agregar columna tags a user_reports para almacenar alertas predefinidas
ALTER TABLE user_reports 
ADD COLUMN IF NOT EXISTS tags TEXT[];

-- Agregar índice para búsqueda por tags
CREATE INDEX IF NOT EXISTS idx_user_reports_tags ON user_reports USING GIN(tags);

-- Agregar índice para búsqueda por bus_id (si no existe)
CREATE INDEX IF NOT EXISTS idx_user_reports_bus_id ON user_reports(bus_id);

-- Actualizar reportes existentes para tener tags vacío si es null
UPDATE user_reports SET tags = ARRAY[]::TEXT[] WHERE tags IS NULL;

-- ================================================
-- FIN DE LA MIGRACIÓN
-- ================================================

