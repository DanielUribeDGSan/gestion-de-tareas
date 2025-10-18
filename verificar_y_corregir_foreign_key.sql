-- VERIFICAR Y CORREGIR FOREIGN KEY PARA ASSIGNED_TO
-- Este script verifica y corrige la relación entre tasks y user_profiles

-- 1. Verificar constraints existentes en tasks
SELECT 
  'CONSTRAINTS EXISTENTES EN TASKS' as info,
  tc.constraint_name,
  tc.constraint_type,
  kcu.column_name,
  ccu.table_name AS foreign_table_name,
  ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
  AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
  AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'tasks'
  AND tc.table_schema = 'public'
ORDER BY tc.constraint_name;

-- 2. Verificar específicamente assigned_to
SELECT 
  'VERIFICACIÓN ESPECÍFICA ASSIGNED_TO' as info,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
      WHERE tc.table_name = 'tasks' 
      AND kcu.column_name = 'assigned_to'
      AND tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'public'
    ) THEN 'FOREIGN KEY EXISTE'
    ELSE 'FOREIGN KEY NO EXISTE'
  END as estado;

-- 3. Eliminar constraint existente si está mal configurada
DO $$ 
DECLARE
    constraint_name text;
BEGIN
    -- Buscar constraint de assigned_to
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'tasks' 
    AND kcu.column_name = 'assigned_to'
    AND tc.constraint_type = 'FOREIGN KEY'
    AND tc.table_schema = 'public';
    
    -- Si existe, eliminarla
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE tasks DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Constraint % eliminada', constraint_name;
    END IF;
END $$;

-- 4. Verificar que user_profiles existe y tiene datos
SELECT 
  'VERIFICACIÓN USER_PROFILES' as info,
  COUNT(*) as total_usuarios,
  COUNT(CASE WHEN full_name IS NOT NULL THEN 1 END) as con_nombre
FROM user_profiles;

-- 5. Crear la foreign key constraint correctamente
ALTER TABLE tasks 
ADD CONSTRAINT tasks_assigned_to_fkey 
FOREIGN KEY (assigned_to) 
REFERENCES user_profiles(id) 
ON DELETE SET NULL;

-- 6. Crear índice para mejorar rendimiento
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to_fk ON tasks(assigned_to);

-- 7. Verificar que la constraint se creó correctamente
SELECT 
  'VERIFICACIÓN DESPUÉS DE CREAR CONSTRAINT' as info,
  tc.constraint_name,
  tc.constraint_type,
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
WHERE tc.table_name = 'tasks'
  AND kcu.column_name = 'assigned_to'
  AND tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public';

-- 8. Probar que la relación funciona
SELECT 
  'PRUEBA DE RELACIÓN' as info,
  t.id,
  t.title,
  t.assigned_to,
  up.email as assigned_user_email,
  up.full_name as assigned_user_name
FROM tasks t
LEFT JOIN user_profiles up ON t.assigned_to = up.id
LIMIT 5;

-- 9. Forzar actualización del cache de esquema (esto puede ayudar)
NOTIFY pgrst, 'reload schema';

-- 10. Mostrar resumen
SELECT 
  'FOREIGN KEY CORREGIDA' as status,
  'La relación entre tasks.assigned_to y user_profiles.id está configurada correctamente' as message;
