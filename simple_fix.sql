-- Script SIMPLE para corregir el problema
-- Ejecutar este script en el SQL Editor de Supabase

-- 1. Verificar si user_profiles existe y su estructura
SELECT 
  'VERIFICANDO USER_PROFILES' as status,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
ORDER BY ordinal_position;

-- 2. Si user_profiles no existe, crearla con la estructura correcta
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id)
);

-- 3. Habilitar RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 4. Crear políticas básicas
CREATE POLICY IF NOT EXISTS "All users can view all user profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY IF NOT EXISTS "Users can create their own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- 5. Crear índices
CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_profiles_email ON user_profiles(email);

-- 6. Verificar que assigned_to existe en tasks
SELECT 
  'VERIFICANDO ASSIGNED_TO EN TASKS' as status,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name = 'assigned_to';

-- 7. Si assigned_to no existe, agregarlo
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

-- 9. Verificar resultado final
SELECT 
  'MIGRACIÓN COMPLETADA' as status,
  'Tabla user_profiles y campo assigned_to configurados correctamente' as message;
