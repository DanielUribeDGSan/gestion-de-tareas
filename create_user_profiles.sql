-- Script para crear tabla de perfiles de usuarios y configurar asignación de tareas

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

-- 6. CREAR FUNCIÓN PARA CREAR PERFIL AUTOMÁTICAMENTE
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (user_id, email, full_name)
  VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name');
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. CREAR TRIGGER PARA CREAR PERFIL AUTOMÁTICAMENTE
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 8. INSERTAR PERFILES PARA USUARIOS EXISTENTES (si los hay)
-- Esto se ejecutará solo si no hay perfiles existentes
INSERT INTO user_profiles (user_id, email, full_name)
SELECT 
  id, 
  email, 
  COALESCE(raw_user_meta_data->>'full_name', split_part(email, '@', 1)) as full_name
FROM auth.users
WHERE id NOT IN (SELECT user_id FROM user_profiles);

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
