-- VERIFICACIÓN FINAL DE ASIGNACIÓN DE TAREAS
-- Ejecutar este script después de solucion_asignacion_tareas.sql para verificar que todo funcione

-- 1. Verificar que user_profiles existe y tiene datos
SELECT 
  'VERIFICACIÓN USER_PROFILES' as info,
  COUNT(*) as total_usuarios,
  COUNT(CASE WHEN full_name IS NOT NULL THEN 1 END) as con_nombre
FROM user_profiles;

-- 2. Verificar que el campo assigned_to existe en tasks
SELECT 
  'VERIFICACIÓN ASSIGNED_TO EN TASKS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name = 'assigned_to';

-- 3. Verificar foreign key constraint
SELECT 
  'VERIFICACIÓN FOREIGN KEY' as info,
  tc.constraint_name,
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
  AND tc.table_schema = 'public';

-- 4. Probar la función de obtener usuarios
SELECT 
  'PRUEBA FUNCIÓN GET_USERS' as info,
  id,
  email,
  full_name
FROM public.get_available_users_for_assignment()
LIMIT 5;

-- 5. Verificar políticas de tasks
SELECT 
  'VERIFICACIÓN POLÍTICAS TASKS' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'tasks'
ORDER BY policyname;

-- 6. Mostrar usuarios disponibles para asignación
SELECT 
  'USUARIOS DISPONIBLES PARA ASIGNACIÓN' as info,
  up.id,
  up.email,
  up.full_name,
  au.created_at as fecha_registro
FROM user_profiles up
JOIN auth.users au ON up.user_id = au.id
ORDER BY up.full_name, up.email;

-- 7. Verificar que se puede insertar una tarea de prueba (opcional)
-- DESCOMENTAR LAS SIGUIENTES LÍNEAS PARA PROBAR:
/*
DO $$
DECLARE
  test_user_id uuid;
  test_project_id uuid;
  test_column_id uuid;
  test_task_id uuid;
BEGIN
  -- Obtener un usuario de prueba
  SELECT id INTO test_user_id FROM user_profiles LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    -- Obtener un proyecto de prueba
    SELECT id INTO test_project_id FROM projects LIMIT 1;
    
    IF test_project_id IS NOT NULL THEN
      -- Obtener una columna de prueba
      SELECT id INTO test_column_id FROM columns WHERE project_id = test_project_id LIMIT 1;
      
      IF test_column_id IS NOT NULL THEN
        -- Insertar tarea de prueba
        INSERT INTO tasks (column_id, project_id, title, description, position, user_id, assigned_to)
        VALUES (test_column_id, test_project_id, 'Tarea de Prueba', 'Esta es una tarea de prueba', 0, (SELECT user_id FROM user_profiles WHERE id = test_user_id), test_user_id)
        RETURNING id INTO test_task_id;
        
        RAISE NOTICE 'Tarea de prueba creada exitosamente con ID: %', test_task_id;
        
        -- Limpiar tarea de prueba
        DELETE FROM tasks WHERE id = test_task_id;
        RAISE NOTICE 'Tarea de prueba eliminada';
      ELSE
        RAISE NOTICE 'No hay columnas disponibles para la prueba';
      END IF;
    ELSE
      RAISE NOTICE 'No hay proyectos disponibles para la prueba';
    END IF;
  ELSE
    RAISE NOTICE 'No hay usuarios disponibles para la prueba';
  END IF;
END $$;
*/

-- 8. Resumen final
SELECT 
  'RESUMEN FINAL' as status,
  'Si todas las verificaciones anteriores muestran datos correctos, la asignación de tareas debería funcionar' as message;
