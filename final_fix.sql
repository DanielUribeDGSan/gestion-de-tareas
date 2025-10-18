-- Script FINAL para corregir la migración
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

-- 2. Verificar si existe la restricción UNIQUE en user_id
SELECT 
  'VERIFICANDO RESTRICCIONES EN USER_PROFILES' as info,
  constraint_name,
  constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'user_profiles' 
AND constraint_type = 'UNIQUE';

-- 3. Agregar la restricción UNIQUE si no existe
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_name = 'user_profiles' 
        AND constraint_type = 'UNIQUE'
        AND constraint_name LIKE '%user_id%'
    ) THEN
        ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_user_id_unique UNIQUE (user_id);
        RAISE NOTICE 'Restricción UNIQUE agregada a user_id';
    ELSE
        RAISE NOTICE 'Restricción UNIQUE ya existe en user_id';
    END IF;
END $$;

-- 4. Eliminar políticas existentes si existen
DROP POLICY IF EXISTS "All users can view all user profiles" ON user_profiles;
DROP POLICY IF EXISTS "Users can create their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;

-- 5. Crear políticas correctamente
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

-- 6. Crear función para crear perfil de usuario
CREATE OR REPLACE FUNCTION public.create_user_profile(
  p_user_id uuid,
  p_email text,
  p_full_name text DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  profile_id uuid;
BEGIN
  -- Insertar perfil de usuario usando ON CONFLICT
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

-- 7. Insertar perfiles para usuarios existentes (usando la función)
DO $$
DECLARE
  user_record RECORD;
  profile_id uuid;
BEGIN
  FOR user_record IN 
    SELECT id, email, raw_user_meta_data
    FROM auth.users 
    WHERE id NOT IN (SELECT user_id FROM user_profiles)
  LOOP
    SELECT public.create_user_profile(
      user_record.id,
      user_record.email,
      COALESCE(user_record.raw_user_meta_data->>'full_name', split_part(user_record.email, '@', 1))
    ) INTO profile_id;
    
    RAISE NOTICE 'Perfil creado para usuario: %', user_record.email;
  END LOOP;
END $$;

-- 8. Verificar usuarios y perfiles después de la inserción
SELECT 
  'USUARIOS Y PERFILES DESPUÉS DE INSERCIÓN' as info,
  au.email as auth_email,
  up.email as profile_email,
  up.full_name,
  CASE WHEN up.id IS NULL THEN 'SIN PERFIL' ELSE 'CON PERFIL' END as status
FROM auth.users au
LEFT JOIN user_profiles up ON au.id = up.user_id
ORDER BY au.created_at;

-- 9. Verificar que assigned_to existe en tasks
SELECT 
  'VERIFICANDO ASSIGNED_TO EN TASKS' as status,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name = 'assigned_to';

-- 10. Mostrar resumen final
SELECT 
  'MIGRACIÓN COMPLETADA' as status,
  'Tabla user_profiles configurada y perfiles creados' as message;
