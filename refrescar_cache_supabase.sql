-- REFRESCAR CACHE DE SUPABASE POSTGREST
-- Este script ayuda a refrescar el cache de esquema de PostgREST

-- 1. Notificar a PostgREST que recargue el esquema
NOTIFY pgrst, 'reload schema';

-- 2. Verificar que la notificación se envió
SELECT 
  'NOTIFICACIÓN ENVIADA' as info,
  'PostgREST debería recargar el esquema automáticamente' as message;

-- 3. Verificar las relaciones de foreign key
SELECT 
  'RELACIONES DE FOREIGN KEY' as info,
  tc.constraint_name,
  tc.table_name,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
  AND tc.table_name = 'tasks'
  AND tc.table_schema = 'public'
ORDER BY kcu.column_name;

-- 4. Mostrar información del esquema
SELECT 
  'INFORMACIÓN DEL ESQUEMA' as info,
  current_database() as database,
  current_schema() as schema,
  version() as postgres_version;
