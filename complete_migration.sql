-- Script completo para corregir la base de datos
-- Ejecutar este script en el SQL Editor de Supabase

-- 1. Verificar si el campo assigned_to existe en tasks
SELECT 
  'VERIFICANDO CAMPO ASSIGNED_TO' as status,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name = 'assigned_to';

-- 2. Agregar el campo assigned_to si no existe
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
        RAISE NOTICE 'Campo assigned_to ya existe';
    END IF;
END $$;

-- 3. Crear índice para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);

-- 4. Verificar que user_profiles tiene datos
SELECT 
  'VERIFICANDO USER_PROFILES' as status,
  COUNT(*) as total_profiles
FROM user_profiles;

-- 5. Si no hay perfiles, crear perfiles para usuarios existentes
INSERT INTO user_profiles (user_id, email, full_name)
SELECT 
  au.id, 
  au.email, 
  COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)) as full_name
FROM auth.users au
WHERE au.id NOT IN (SELECT user_id FROM user_profiles)
ON CONFLICT (user_id) DO NOTHING;

-- 6. Verificar la estructura final de tasks
SELECT 
  'ESTRUCTURA FINAL DE TASKS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
ORDER BY ordinal_position;

-- 7. Mostrar usuarios y sus perfiles
SELECT 
  'USUARIOS Y PERFILES' as info,
  au.email as auth_email,
  up.email as profile_email,
  up.full_name,
  CASE WHEN up.id IS NULL THEN 'SIN PERFIL' ELSE 'CON PERFIL' END as status
FROM auth.users au
LEFT JOIN user_profiles up ON au.id = up.user_id
ORDER BY au.created_at;
