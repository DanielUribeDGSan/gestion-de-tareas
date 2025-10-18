-- Script para configurar Supabase Storage para el sistema de gestión de tareas
-- Ejecuta este script en el SQL Editor de Supabase Dashboard

-- 1. Crear el bucket task-attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'task-attachments',
  'task-attachments', 
  true,
  52428800, -- 50MB en bytes
  ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 52428800,
  allowed_mime_types = ARRAY['image/jpeg', 'image/jpg', 'image/png', 'image/webp', 'image/gif'];

-- 2. Configurar políticas de Storage

-- Política para ver archivos (público)
DROP POLICY IF EXISTS "Users can view attachments" ON storage.objects;
CREATE POLICY "Users can view attachments" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'task-attachments');

-- Política para subir archivos
DROP POLICY IF EXISTS "Users can upload attachments" ON storage.objects;
CREATE POLICY "Users can upload attachments" 
ON storage.objects FOR INSERT 
WITH CHECK (
  bucket_id = 'task-attachments' 
  AND auth.uid() IS NOT NULL
);

-- Política para eliminar archivos propios
DROP POLICY IF EXISTS "Users can delete own attachments" ON storage.objects;
CREATE POLICY "Users can delete own attachments" 
ON storage.objects FOR DELETE 
USING (
  bucket_id = 'task-attachments' 
  AND auth.uid() IS NOT NULL
);

-- 3. Verificar que el bucket se creó correctamente
SELECT 
  id, 
  name, 
  public, 
  file_size_limit, 
  allowed_mime_types,
  created_at
FROM storage.buckets 
WHERE id = 'task-attachments';

-- 4. Verificar las políticas creadas
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND policyname LIKE '%attachments%';
