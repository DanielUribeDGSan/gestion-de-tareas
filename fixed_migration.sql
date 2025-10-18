-- Script CORREGIDO para la migración completa
-- Ejecutar este script en el SQL Editor de Supabase

-- 1. Verificar la estructura actual de user_profiles
SELECT 
  'ESTRUCTURA ACTUAL DE USER_PROFILES' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
ORDER BY ordinal_position;

-- 2. Verificar si el campo assigned_to ya existe en tasks
SELECT 
  'VERIFICANDO CAMPO ASSIGNED_TO EN TASKS' as status,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name = 'assigned_to';

-- 3. Si user_profiles no existe, crearla
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- 4. Habilitar RLS en user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 5. Crear políticas para user_profiles
DROP POLICY IF EXISTS "All users can view all user profiles" ON user_profiles;
CREATE POLICY "All users can view all user profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (true);

DROP POLICY IF EXISTS "Users can create their own profile" ON user_profiles;
CREATE POLICY "Users can create their own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
CREATE POLICY "Users can update their own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 6. Crear índices para user_profiles
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);

-- 7. Agregar el campo assigned_to a tasks si no existe
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

-- 8. Crear índice para assigned_to
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);

-- 9. Crear función para crear perfil de usuario
CREATE OR REPLACE FUNCTION public.create_user_profile(
  p_user_id uuid,
  p_email text,
  p_full_name text DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  profile_id uuid;
BEGIN
  -- Insertar perfil de usuario
  INSERT INTO user_profiles (user_id, email, full_name)
  VALUES (p_user_id, p_email, p_full_name)
  ON CONFLICT (user_id) DO UPDATE SET
    email = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, user_profiles.full_name),
    updated_at = now()
  RETURNING id INTO profile_id;
  
  RETURN profile_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Insertar perfiles para usuarios existentes
INSERT INTO user_profiles (user_id, email, full_name)
SELECT 
  au.id, 
  au.email, 
  COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)) as full_name
FROM auth.users au
WHERE au.id NOT IN (SELECT user_id FROM user_profiles)
ON CONFLICT (user_id) DO NOTHING;

-- 11. Verificar la estructura final
SELECT 
  'ESTRUCTURA FINAL DE TASKS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
ORDER BY ordinal_position;

-- 12. Verificar usuarios y perfiles
SELECT 
  'USUARIOS Y PERFILES' as info,
  au.email as auth_email,
  up.email as profile_email,
  up.full_name,
  CASE WHEN up.id IS NULL THEN 'SIN PERFIL' ELSE 'CON PERFIL' END as status
FROM auth.users au
LEFT JOIN user_profiles up ON au.id = up.user_id
ORDER BY au.created_at;
