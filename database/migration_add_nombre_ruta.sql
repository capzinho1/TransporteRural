-- ================================================
-- MIGRACIÓN: Agregar campo nombre_ruta a bus_locations
-- ================================================
-- Este campo permitirá que los buses tengan un nombre de ruta asignado
-- que puede ser diferente del route_id, facilitando la búsqueda para usuarios

-- Agregar columna nombre_ruta a bus_locations
ALTER TABLE bus_locations 
ADD COLUMN IF NOT EXISTS nombre_ruta VARCHAR(255);

-- Crear índice para búsquedas rápidas por nombre de ruta
CREATE INDEX IF NOT EXISTS idx_bus_locations_nombre_ruta ON bus_locations(nombre_ruta);

-- Agregar índice para búsqueda de texto (fuzzy search)
-- Usaremos trigram para búsqueda tolerante a errores
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- Crear índice GIN para búsqueda fuzzy usando trigramas
CREATE INDEX IF NOT EXISTS idx_bus_locations_nombre_ruta_trgm ON bus_locations 
USING GIN (nombre_ruta gin_trgm_ops);

-- También agregar índice GIN para el nombre de las rutas
-- (esto requiere un join con routes, pero podemos hacerlo en el endpoint)
-- Por ahora solo creamos el índice en routes.name
CREATE INDEX IF NOT EXISTS idx_routes_name_trgm ON routes 
USING GIN (name gin_trgm_ops);

-- Comentario para documentar el campo
COMMENT ON COLUMN bus_locations.nombre_ruta IS 'Nombre de la ruta asignado al bus. Permite búsqueda más intuitiva para usuarios. Puede ser diferente del route_id.';

-- ================================================
-- FIN DE LA MIGRACIÓN
-- ================================================

