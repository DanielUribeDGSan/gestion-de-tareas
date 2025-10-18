-- Script para aplicar políticas de acceso compartido a proyectos
-- Este script permite que todos los usuarios autenticados vean todos los proyectos

-- 1. ELIMINAR POLÍTICAS EXISTENTES RESTRICTIVAS

-- Eliminar políticas de proyectos (si existen)
DROP POLICY IF EXISTS "Users can view their own projects" ON projects;
DROP POLICY IF EXISTS "Users can create their own projects" ON projects;
DROP POLICY IF EXISTS "Users can update their own projects" ON projects;
DROP POLICY IF EXISTS "Users can delete their own projects" ON projects;

-- Eliminar políticas de columnas (si existen)
DROP POLICY IF EXISTS "Users can view columns of their projects" ON columns;
DROP POLICY IF EXISTS "Users can create columns in their projects" ON columns;
DROP POLICY IF EXISTS "Users can update columns in their projects" ON columns;
DROP POLICY IF EXISTS "Users can delete columns from their projects" ON columns;

-- Eliminar políticas de tareas (si existen)
DROP POLICY IF EXISTS "Users can view tasks in their projects" ON tasks;
DROP POLICY IF EXISTS "Users can create tasks in their projects" ON tasks;
DROP POLICY IF EXISTS "Users can update tasks in their projects" ON tasks;
DROP POLICY IF EXISTS "Users can delete tasks from their projects" ON tasks;

-- Eliminar políticas de comentarios (si existen)
DROP POLICY IF EXISTS "Users can view comments on tasks in their projects" ON comments;
DROP POLICY IF EXISTS "Users can create comments on tasks in their projects" ON comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;

-- Eliminar políticas de adjuntos (si existen)
DROP POLICY IF EXISTS "Users can view attachments on tasks in their projects" ON attachments;
DROP POLICY IF EXISTS "Users can create attachments on tasks in their projects" ON attachments;
DROP POLICY IF EXISTS "Users can delete their own attachments" ON attachments;

-- 2. CREAR POLÍTICAS COMPARTIDAS

-- PROYECTOS: Todos pueden ver todos, pero solo el creador puede modificar
CREATE POLICY "All users can view all projects"
  ON projects FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create their own projects"
  ON projects FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own projects"
  ON projects FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own projects"
  ON projects FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- COLUMNAS: Todos pueden ver y modificar todas las columnas
CREATE POLICY "All users can view all columns"
  ON columns FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "All users can create columns"
  ON columns FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "All users can update any column"
  ON columns FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "All users can delete any column"
  ON columns FOR DELETE
  TO authenticated
  USING (true);

-- TAREAS: Todos pueden ver y modificar todas las tareas
CREATE POLICY "All users can view all tasks"
  ON tasks FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "All users can create tasks"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "All users can update any task"
  ON tasks FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "All users can delete any task"
  ON tasks FOR DELETE
  TO authenticated
  USING (true);

-- COMENTARIOS: Todos pueden ver todos, pero solo el creador puede modificar
CREATE POLICY "All users can view all comments"
  ON comments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create their own comments"
  ON comments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments"
  ON comments FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments"
  ON comments FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- ADJUNTOS: Todos pueden ver todos, pero solo el creador puede eliminar
CREATE POLICY "All users can view all attachments"
  ON attachments FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can create their own attachments"
  ON attachments FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own attachments"
  ON attachments FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- 3. VERIFICAR QUE LAS POLÍTICAS SE APLICARON CORRECTAMENTE
SELECT 
  'POLÍTICAS APLICADAS EXITOSAMENTE' as status,
  schemaname,
  tablename,
  policyname,
  cmd
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('projects', 'columns', 'tasks', 'comments', 'attachments')
ORDER BY tablename, policyname;
