-- Script para verificar la estructura de user_profiles
-- Ejecutar este script en el SQL Editor de Supabase

-- 1. Verificar la estructura de user_profiles
SELECT 
  'ESTRUCTURA DE USER_PROFILES' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'user_profiles' 
ORDER BY ordinal_position;

-- 2. Verificar si la tabla user_profiles existe
SELECT 
  'TABLA USER_PROFILES EXISTE' as status,
  COUNT(*) as total_columns
FROM information_schema.columns 
WHERE table_name = 'user_profiles';

-- 3. Mostrar los datos actuales de user_profiles
SELECT 
  'DATOS ACTUALES DE USER_PROFILES' as info,
  COUNT(*) as total_profiles
FROM user_profiles;
