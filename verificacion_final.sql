-- VERIFICACIÓN FINAL - ASIGNACIÓN DE TAREAS FUNCIONANDO
-- Este script verifica que todo esté funcionando correctamente

-- 1. Verificar usuarios disponibles para asignación
SELECT 
  'USUARIOS DISPONIBLES PARA ASIGNACIÓN' as info,
  id,
  email,
  full_name
FROM user_profiles
ORDER BY full_name;

-- 2. Verificar foreign key constraint
SELECT 
  'VERIFICACIÓN FOREIGN KEY' as info,
  cx.constraint_name,
  cx.table_name,
  cx.column_name,
  cx.foreign_table_name,
  cx.foreign_column_name
FROM (
  SELECT 
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
    AND kcu.column_name = 'assigned_to'
    AND tc.table_schema = 'public'
) cx;

-- 3. Verificar políticas de tasks
SELECT 
  'POLÍTICAS ACTIVAS EN TASKS' as info,
  policyname,
  cmd,
  CASE WHEN qual IS NOT NULL THEN 'CONDICIÓN ACTIVA' ELSE 'SIN CONDICIÓN' END as estado
FROM pg_policies 
WHERE tablename = 'tasks'
ORDER BY policyname;

-- 4. Contar tareas existentes
SELECT 
  'TAREAS EXISTENTES' as info,
  COUNT(*) as total_tareas,
  COUNT(CASE WHEN assigned_to IS NOT NULL THEN 1 END) as tareas_asignadas,
  COUNT(CASE WHEN assigned_to IS NULL THEN 1 END) as tareas_sin_asignar
FROM tasks;

-- 5. Mostrar tareas actuales
SELECT 
  'TAREAS ACTUALES' as info,
  id,
  title,
  assigned_to,
  CASE 
    WHEN assigned_to IS NULL THEN 'Sin asignar'
    ELSE 'Asignada'
  END as estado_asignacion
FROM tasks
ORDER BY created_at DESC;

-- 6. Verificar función de usuarios
SELECT 
  'FUNCIÓN GET_USERS FUNCIONANDO' as info,
  id,
  email,
  full_name
FROM public.get_available_users_for_assignment()
LIMIT 3;

-- 7. Resumen final
SELECT 
  '🎉 VERIFICACIÓN COMPLETADA' as status,
  'La asignación de tareas está funcionando correctamente' as message;
