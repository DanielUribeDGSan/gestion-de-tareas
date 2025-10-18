-- Script ULTIMATE para corregir la migración
-- Ejecutar este script en el SQL Editor de Supabase

-- 1. Verificar la estructura actual de user_profiles
SELECT 
  'ESTRUCTURA ACTUAL DE USER_PROFILES' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
ORDER BY ordinal_position;

-- 2. Eliminar la tabla user_profiles si existe (para empezar limpio)
DROP TABLE IF EXISTS user_profiles CASCADE;

-- 3. Crear la tabla user_profiles con la estructura correcta
CREATE TABLE user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- 4. Habilitar RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 5. Crear políticas
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

-- 6. Crear índices
CREATE INDEX idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX idx_user_profiles_email ON user_profiles(email);

-- 7. Verificar que assigned_to existe en tasks
SELECT 
  'VERIFICANDO ASSIGNED_TO EN TASKS' as status,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name = 'assigned_to';

-- 8. Si assigned_to no existe, agregarlo
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

-- 9. Crear índice para assigned_to
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);

-- 10. Crear función para crear perfil de usuario
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

-- 11. Insertar perfiles para usuarios existentes
INSERT INTO user_profiles (user_id, email, full_name)
SELECT 
  au.id, 
  au.email, 
  COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)) as full_name
FROM auth.users au
ON CONFLICT (user_id) DO NOTHING;

-- 12. Verificar usuarios y perfiles después de la inserción
SELECT 
  'USUARIOS Y PERFILES DESPUÉS DE INSERCIÓN' as info,
  au.email as auth_email,
  up.email as profile_email,
  up.full_name,
  CASE WHEN up.id IS NULL THEN 'SIN PERFIL' ELSE 'CON PERFIL' END as status
FROM auth.users au
LEFT JOIN user_profiles up ON au.id = up.user_id
ORDER BY au.created_at;

-- 13. Verificar la estructura final de tasks
SELECT 
  'ESTRUCTURA FINAL DE TASKS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
ORDER BY ordinal_position;

-- 14. Mostrar resumen final
SELECT 
  'MIGRACIÓN COMPLETADA EXITOSAMENTE' as status,
  'Tabla user_profiles recreada y perfiles creados' as message;
