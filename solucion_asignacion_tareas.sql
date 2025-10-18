-- SOLUCIÓN COMPLETA PARA ASIGNACIÓN DE TAREAS
-- Este script corrige el problema de foreign key constraint y permite asignar tareas

-- 1. Verificar estructura actual
SELECT 
  'ESTRUCTURA ACTUAL DE TASKS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
ORDER BY ordinal_position;

-- 2. Crear tabla user_profiles si no existe
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- 3. Habilitar RLS en user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 4. Crear políticas para user_profiles
DROP POLICY IF EXISTS "All users can view all user profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can create their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;

CREATE POLICY "All users can view all user profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create their own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 5. Crear índices para user_profiles
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);

-- 6. Insertar perfiles para usuarios existentes
INSERT INTO user_profiles (user_id, email, full_name)
SELECT 
  au.id, 
  au.email, 
  COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)) as full_name
FROM auth.users au
ON CONFLICT (user_id) DO UPDATE SET
  email = EXCLUDED.email,
  full_name = COALESCE(EXCLUDED.full_name, user_profiles.full_name),
  updated_at = now();

-- 7. Agregar campo assigned_to a tasks si no existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' 
        AND column_name = 'assigned_to'
    ) THEN
        ALTER TABLE tasks ADD COLUMN assigned_to uuid REFERENCES user_profiles(id) ON DELETE SET NULL;
        RAISE NOTICE 'Campo assigned_to agregado exitosamente';
    ELSE
        -- Si ya existe, verificar que la referencia sea correcta
        IF EXISTS (
            SELECT 1 FROM information_schema.table_constraints tc
            JOIN information_schema.key_column_usage kcu ON tc.constraint_name = kcu.constraint_name
            WHERE tc.table_name = 'tasks' 
            AND kcu.column_name = 'assigned_to'
            AND tc.constraint_type = 'FOREIGN KEY'
            AND tc.table_schema = 'public'
        ) THEN
            RAISE NOTICE 'Campo assigned_to ya existe con foreign key';
        ELSE
            -- Si existe pero sin foreign key, agregarla
            ALTER TABLE tasks ADD CONSTRAINT tasks_assigned_to_fkey 
            FOREIGN KEY (assigned_to) REFERENCES user_profiles(id) ON DELETE SET NULL;
            RAISE NOTICE 'Foreign key constraint agregada a assigned_to';
        END IF;
    END IF;
END $$;

-- 8. Crear índice para assigned_to
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);

-- 9. Actualizar políticas de tasks para permitir ver tareas asignadas
DROP POLICY IF EXISTS "Users can view tasks in their projects" ON tasks;
DROP POLICY IF EXISTS "Users can create tasks in their projects" ON tasks;
DROP POLICY IF EXISTS "Users can update tasks in their projects" ON tasks;
DROP POLICY IF EXISTS "Users can delete tasks from their projects" ON tasks;

-- Política para SELECT - Los usuarios pueden ver tareas de sus proyectos Y tareas asignadas a ellos
CREATE POLICY "Users can view tasks in their projects and assigned tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = tasks.project_id
      AND projects.user_id = auth.uid()
    )
    OR assigned_to IN (
      SELECT id FROM user_profiles WHERE user_id = auth.uid()
    )
  );

-- Política para INSERT - Solo el dueño del proyecto puede crear tareas
CREATE POLICY "Users can create tasks in their projects"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = tasks.project_id
      AND projects.user_id = auth.uid()
    )
  );

-- Política para UPDATE - El dueño del proyecto puede actualizar, y el asignado puede actualizar su tarea
CREATE POLICY "Users can update tasks in their projects and assigned tasks"
  ON tasks FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = tasks.project_id
      AND projects.user_id = auth.uid()
    )
    OR assigned_to IN (
      SELECT id FROM user_profiles WHERE user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = tasks.project_id
      AND projects.user_id = auth.uid()
    )
    OR assigned_to IN (
      SELECT id FROM user_profiles WHERE user_id = auth.uid()
    )
  );

-- Política para DELETE - Solo el dueño del proyecto puede eliminar tareas
CREATE POLICY "Users can delete tasks from their projects"
  ON tasks FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = tasks.project_id
      AND projects.user_id = auth.uid()
    )
  );

-- 10. Crear función para obtener usuarios disponibles para asignación
CREATE OR REPLACE FUNCTION public.get_available_users_for_assignment()
RETURNS TABLE (
  id uuid,
  email text,
  full_name text
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    up.id,
    up.email,
    up.full_name
  FROM user_profiles up
  ORDER BY up.full_name, up.email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Verificar usuarios y perfiles después de la inserción
SELECT 
  'USUARIOS Y PERFILES DESPUÉS DE INSERCIÓN' as info,
  au.email as auth_email,
  up.email as profile_email,
  up.full_name,
  CASE WHEN up.id IS NULL THEN 'SIN PERFIL' ELSE 'CON PERFIL' END as status
FROM auth.users au
LEFT JOIN user_profiles up ON au.id = up.user_id
ORDER BY au.created_at;

-- 12. Verificar la estructura final de tasks
SELECT 
  'ESTRUCTURA FINAL DE TASKS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
ORDER BY ordinal_position;

-- 13. Verificar foreign keys de tasks
SELECT 
  'FOREIGN KEYS DE TASKS' as info,
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
  AND tc.table_schema = 'public';

-- 14. Mostrar resumen final
SELECT 
  'MIGRACIÓN COMPLETADA EXITOSAMENTE' as status,
  'Tabla user_profiles creada, campo assigned_to agregado y políticas actualizadas' as message;
