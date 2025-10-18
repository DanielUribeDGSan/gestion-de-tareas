-- Script para corregir el campo assigned_to en la tabla tasks
-- Ejecutar este script en el SQL Editor de Supabase

-- 1. Verificar si el campo assigned_to existe
SELECT 
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name = 'assigned_to';

-- 2. Si no existe, agregarlo
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

-- 4. Verificar la estructura final
SELECT 
  'ESTRUCTURA FINAL DE TASKS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
ORDER BY ordinal_position;
