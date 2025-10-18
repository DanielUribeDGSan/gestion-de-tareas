-- Script para hacer que los proyectos sean VISIBLES para todos los usuarios
-- pero solo el creador puede editarlos/eliminarlos
-- Ejecuta este script en el SQL Editor de Supabase Dashboard

-- 1. Eliminar las políticas existentes de PROJECTS
DROP POLICY IF EXISTS "Users can view their own projects" ON projects;
DROP POLICY IF EXISTS "Users can create their own projects" ON projects;
DROP POLICY IF EXISTS "Users can update their own projects" ON projects;
DROP POLICY IF EXISTS "Users can delete their own projects" ON projects;

-- 2. Crear nuevas políticas para PROJECTS (visibles para todos, editables solo por el creador)
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

-- 3. Eliminar las políticas existentes de COLUMNS
DROP POLICY IF EXISTS "Users can view columns of their projects" ON columns;
DROP POLICY IF EXISTS "Users can create columns in their projects" ON columns;
DROP POLICY IF EXISTS "Users can update columns in their projects" ON columns;
DROP POLICY IF EXISTS "Users can delete columns from their projects" ON columns;

-- 4. Crear nuevas políticas para COLUMNS (visibles para todos, editables por todos)
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

-- 5. Eliminar las políticas existentes de TASKS
DROP POLICY IF EXISTS "Users can view tasks in their projects" ON tasks;
DROP POLICY IF EXISTS "Users can create tasks in their projects" ON tasks;
DROP POLICY IF EXISTS "Users can update tasks in their projects" ON tasks;
DROP POLICY IF EXISTS "Users can delete tasks from their projects" ON tasks;

-- 6. Crear nuevas políticas para TASKS (visibles para todos, editables por todos)
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

-- 7. Eliminar las políticas existentes de COMMENTS
DROP POLICY IF EXISTS "Users can view comments on tasks in their projects" ON comments;
DROP POLICY IF EXISTS "Users can create comments on tasks in their projects" ON comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;

-- 8. Crear nuevas políticas para COMMENTS (visibles para todos, editables por el creador)
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

-- 9. Eliminar las políticas existentes de ATTACHMENTS
DROP POLICY IF EXISTS "Users can view attachments on tasks in their projects" ON attachments;
DROP POLICY IF EXISTS "Users can create attachments on tasks in their projects" ON attachments;
DROP POLICY IF EXISTS "Users can delete their own attachments" ON attachments;

-- 10. Crear nuevas políticas para ATTACHMENTS (visibles para todos, editables por el creador)
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

-- 11. Verificar que las políticas se aplicaron correctamente
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
