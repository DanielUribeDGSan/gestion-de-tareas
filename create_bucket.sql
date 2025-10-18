-- Script para crear el bucket task-attachments en Supabase Storage
-- Ejecuta este script en el SQL Editor de Supabase Dashboard

-- 1. Crear el bucket task-attachments
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'task-attachments',
  'task-attachments', 
  true,
  52428800, -- 50MB limit
  ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'application/pdf', 'text/plain', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
);

-- 2. Crear políticas RLS para el bucket
CREATE POLICY "Allow authenticated users to upload files"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'task-attachments');

CREATE POLICY "Allow authenticated users to view files"
  ON storage.objects FOR SELECT
  TO authenticated
  USING (bucket_id = 'task-attachments');

CREATE POLICY "Allow authenticated users to update files"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'task-attachments')
  WITH CHECK (bucket_id = 'task-attachments');

CREATE POLICY "Allow authenticated users to delete files"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'task-attachments');

-- 3. Verificar que el bucket se creó correctamente
SELECT * FROM storage.buckets WHERE name = 'task-attachments';
