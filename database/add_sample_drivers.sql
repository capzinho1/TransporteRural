-- Script para agregar conductores de prueba
-- Ejecutar en el SQL Editor de Supabase

-- Agregar conductores de ejemplo para Longaví y Linares
INSERT INTO users (email, name, role) VALUES
  ('pedro.gomez@transporterural.com', 'Pedro Gómez', 'driver'),
  ('maria.silva@transporterural.com', 'María Silva', 'driver'),
  ('juan.torres@transporterural.com', 'Juan Torres', 'driver'),
  ('carmen.rojas@transporterural.com', 'Carmen Rojas', 'driver'),
  ('luis.morales@transporterural.com', 'Luis Morales', 'driver'),
  ('ana.fernandez@transporterural.com', 'Ana Fernández', 'driver')
ON CONFLICT (email) DO NOTHING;

-- Mensaje de confirmación
SELECT 
  'Conductores agregados exitosamente' as mensaje,
  COUNT(*) as total_conductores
FROM users 
WHERE role = 'driver';


