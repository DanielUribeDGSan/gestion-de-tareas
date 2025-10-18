-- Script para agregar el campo assigned_to a la tabla tasks
-- Este campo permitirá asignar tareas a usuarios específicos

-- 1. Agregar el campo assigned_to a la tabla tasks
ALTER TABLE tasks 
ADD COLUMN IF NOT EXISTS assigned_to uuid REFERENCES user_profiles(id) ON DELETE SET NULL;

-- 2. Crear índice para mejorar el rendimiento de consultas por usuario asignado
CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);

-- 3. Verificar que el campo se agregó correctamente
SELECT 
  'CAMPO ASSIGNED_TO AGREGADO' as status,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'tasks' 
AND column_name = 'assigned_to';

-- 4. Mostrar la estructura actualizada de la tabla tasks
SELECT 
  'ESTRUCTURA ACTUALIZADA DE TASKS' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'tasks' 
ORDER BY ordinal_position;
