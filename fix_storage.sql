-- Script para solucionar el problema del bucket task-attachments
-- Ejecuta este script en el SQL Editor de Supabase Dashboard

-- 1. Eliminar el bucket existente si hay problemas
DELETE FROM storage.buckets WHERE id = 'task-attachments';

-- 2. Crear el bucket desde cero
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'task-attachments',
  'task-attachments', 
  true,
  52428800, -- 50MB
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif']
);

-- 3. Eliminar todas las políticas existentes
DROP POLICY IF EXISTS "Users can view attachments" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload attachments" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete own attachments" ON storage.objects;
DROP POLICY IF EXISTS "Public read access for task attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload task attachments" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can delete task attachments" ON storage.objects;

-- 4. Crear políticas muy permisivas
CREATE POLICY "Allow all operations on task-attachments" 
ON storage.objects 
FOR ALL 
USING (bucket_id = 'task-attachments');

-- 5. Verificar que todo esté configurado
SELECT 
  id, 
  name, 
  public, 
  file_size_limit, 
  allowed_mime_types,
  created_at
FROM storage.buckets 
WHERE id = 'task-attachments';

-- 6. Verificar las políticas
SELECT 
  policyname,
  cmd,
  qual
FROM pg_policies 
WHERE tablename = 'objects' 
AND policyname LIKE '%task%';
