-- Script CORREGIDO para crear tabla de perfiles de usuarios y configurar asignación de tareas
-- Versión simplificada sin triggers automáticos

-- 1. CREAR TABLA DE PERFILES DE USUARIOS
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- 2. CREAR ÍNDICES
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);

-- 3. HABILITAR RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 4. CREAR POLÍTICAS PARA USER_PROFILES
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

-- 5. AGREGAR CAMPO DE ASIGNACIÓN A LA TABLA TASKS
-- Primero verificar si el campo ya existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'tasks' 
        AND column_name = 'assigned_to'
    ) THEN
        ALTER TABLE tasks ADD COLUMN assigned_to uuid REFERENCES user_profiles(id) ON DELETE SET NULL;
    END IF;
END $$;

-- 6. CREAR FUNCIÓN PARA CREAR PERFIL MANUALMENTE
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

-- 7. CREAR FUNCIÓN PARA OBTENER O CREAR PERFIL DE USUARIO ACTUAL
CREATE OR REPLACE FUNCTION public.get_or_create_user_profile()
RETURNS TABLE(
  id uuid,
  user_id uuid,
  email text,
  full_name text
) AS $$
DECLARE
  current_user_id uuid;
  current_user_email text;
  current_user_meta jsonb;
BEGIN
  -- Obtener información del usuario actual
  current_user_id := auth.uid();
  
  IF current_user_id IS NULL THEN
    RETURN;
  END IF;
  
  -- Obtener email y metadata del usuario
  SELECT email, raw_user_meta_data 
  INTO current_user_email, current_user_meta
  FROM auth.users 
  WHERE auth.users.id = current_user_id;
  
  -- Crear o actualizar perfil
  PERFORM public.create_user_profile(
    current_user_id,
    current_user_email,
    COALESCE(current_user_meta->>'full_name', split_part(current_user_email, '@', 1))
  );
  
  -- Retornar el perfil
  RETURN QUERY
  SELECT 
    up.id,
    up.user_id,
    up.email,
    up.full_name
  FROM user_profiles up
  WHERE up.user_id = current_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. INSERTAR PERFILES PARA USUARIOS EXISTENTES (si los hay)
-- Esto se ejecutará solo si no hay perfiles existentes
INSERT INTO user_profiles (user_id, email, full_name)
SELECT 
  au.id, 
  au.email, 
  COALESCE(au.raw_user_meta_data->>'full_name', split_part(au.email, '@', 1)) as full_name
FROM auth.users au
WHERE au.id NOT IN (SELECT user_id FROM user_profiles)
ON CONFLICT (user_id) DO NOTHING;

-- 9. VERIFICAR QUE TODO SE CREÓ CORRECTAMENTE
SELECT 
  'TABLA USER_PROFILES CREADA' as status,
  COUNT(*) as total_profiles
FROM user_profiles;

SELECT 
  'CAMPO ASSIGNED_TO AGREGADO' as status,
  column_name,
  data_type
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name = 'assigned_to';

-- 10. MOSTRAR USUARIOS EXISTENTES Y SUS PERFILES
SELECT 
  'USUARIOS Y PERFILES' as info,
  au.email as auth_email,
  up.email as profile_email,
  up.full_name,
  CASE WHEN up.id IS NULL THEN 'SIN PERFIL' ELSE 'CON PERFIL' END as status
FROM auth.users au
LEFT JOIN user_profiles up ON au.id = up.user_id
ORDER BY au.created_at;
