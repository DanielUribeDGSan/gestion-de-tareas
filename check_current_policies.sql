-- Script para verificar las políticas actuales en la base de datos
-- Ejecuta este script primero para ver qué políticas están activas

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
WHERE schemaname = 'public' 
AND tablename IN ('projects', 'columns', 'tasks', 'comments', 'attachments')
ORDER BY tablename, policyname;
