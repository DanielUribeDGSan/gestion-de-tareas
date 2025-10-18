-- VERIFICACIÓN SIMPLE DESPUÉS DE LA CORRECCIÓN
-- Ejecutar este script para confirmar que todo funciona

-- 1. Verificar que user_profiles existe y tiene datos
SELECT 
  'User Profiles' as tabla,
  COUNT(*) as total_registros
FROM user_profiles;

-- 2. Verificar que assigned_to existe en tasks
SELECT 
  'Campo assigned_to en tasks' as verificacion,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.columns 
      WHERE table_name = 'tasks' AND column_name = 'assigned_to'
    ) THEN 'EXISTE'
    ELSE 'NO EXISTE'
  END as estado;

-- 3. Verificar foreign key constraint
SELECT 
  'Foreign Key assigned_to' as verificacion,
  CASE 
    WHEN EXISTS (
      SELECT 1 FROM information_schema.table_constraints tc
      JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
      WHERE tc.table_name = 'tasks' 
      AND kcu.column_name = 'assigned_to'
      AND tc.constraint_type = 'FOREIGN KEY'
    ) THEN 'CONFIGURADA'
    ELSE 'NO CONFIGURADA'
  END as estado;

-- 4. Verificar políticas de tasks
SELECT 
  'Políticas de tasks' as verificacion,
  COUNT(*) as total_politicas
FROM pg_policies 
WHERE tablename = 'tasks';

-- 5. Mostrar algunos usuarios disponibles
SELECT 
  'Usuarios disponibles para asignación' as info,
  id,
  email,
  full_name
FROM user_profiles
LIMIT 5;

-- 6. Verificar estructura final de tasks
SELECT 
  'Estructura de tasks' as info,
  column_name,
  data_type
FROM information_schema.columns 
WHERE table_name = 'tasks' 
ORDER BY ordinal_position;
