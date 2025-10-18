-- Script para agregar sistema de asignaciones de tareas
-- Ejecuta este script en el SQL Editor de Supabase Dashboard

-- 1. Agregar columna assigned_to a la tabla tasks
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS assigned_to uuid REFERENCES auth.users(id) ON DELETE SET NULL;

-- 2. Agregar índice para optimizar consultas de tareas asignadas
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);

-- 3. Crear tabla para almacenar información de usuarios (para mostrar nombres)
CREATE TABLE IF NOT EXISTS user_profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  full_name text,
  avatar_url text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- 4. Habilitar RLS en user_profiles
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- 5. Políticas para user_profiles
CREATE POLICY "All users can view all profiles"
  ON user_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create their own profile"
  ON user_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON user_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- 6. Crear función para sincronizar perfiles de usuario
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profiles (id, email, full_name)
  VALUES (
    new.id,
    new.email,
    COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1))
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Crear trigger para crear perfil automáticamente cuando se registra un usuario
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 8. Actualizar políticas existentes de tasks para incluir assigned_to
-- No necesitamos cambiar las políticas ya que las tareas siguen siendo públicas

-- 9. Crear vista para tareas con información del responsable
CREATE OR REPLACE VIEW tasks_with_assignee AS
SELECT 
  t.*,
  up_assigned.email as assigned_to_email,
  up_assigned.full_name as assigned_to_name,
  up_creator.email as created_by_email,
  up_creator.full_name as created_by_name
FROM tasks t
LEFT JOIN user_profiles up_assigned ON t.assigned_to = up_assigned.id
LEFT JOIN user_profiles up_creator ON t.user_id = up_creator.id;

-- 10. Verificar que los cambios se aplicaron correctamente
SELECT 
  column_name, 
  data_type, 
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name = 'assigned_to';

-- 11. Mostrar estructura de la nueva tabla user_profiles
SELECT 
  column_name, 
  data_type, 
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_profiles'
ORDER BY ordinal_position;
