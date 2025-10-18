/*
  # Task Management System Schema - Sistema de Gestión de Tareas tipo Trello

  ## Descripción General
  Este esquema crea una base de datos completa para un sistema de gestión de tareas tipo Trello,
  con soporte para proyectos, columnas personalizables, tareas arrastrables, comentarios e imágenes.

  ## 1. Nuevas Tablas

  ### `projects` - Proyectos
  - `id` (uuid, primary key) - Identificador único del proyecto
  - `name` (text) - Nombre del proyecto
  - `description` (text, nullable) - Descripción del proyecto
  - `user_id` (uuid) - ID del usuario propietario
  - `created_at` (timestamptz) - Fecha de creación
  - `updated_at` (timestamptz) - Fecha de última actualización

  ### `columns` - Columnas/Apartados (Ej: En Desarrollo, En Revisión, Completado)
  - `id` (uuid, primary key) - Identificador único de la columna
  - `project_id` (uuid) - ID del proyecto al que pertenece
  - `name` (text) - Nombre de la columna
  - `position` (integer) - Orden de la columna
  - `color` (text) - Color de la columna (opcional)
  - `created_at` (timestamptz) - Fecha de creación

  ### `tasks` - Tareas/Cards
  - `id` (uuid, primary key) - Identificador único de la tarea
  - `column_id` (uuid) - ID de la columna donde está la tarea
  - `project_id` (uuid) - ID del proyecto (para queries más eficientes)
  - `title` (text) - Título de la tarea
  - `description` (text, nullable) - Descripción detallada
  - `position` (integer) - Orden dentro de la columna
  - `user_id` (uuid) - ID del usuario que creó la tarea
  - `created_at` (timestamptz) - Fecha de creación
  - `updated_at` (timestamptz) - Fecha de última actualización

  ### `comments` - Comentarios en las tareas
  - `id` (uuid, primary key) - Identificador único del comentario
  - `task_id` (uuid) - ID de la tarea
  - `user_id` (uuid) - ID del usuario que comentó
  - `content` (text) - Contenido del comentario
  - `created_at` (timestamptz) - Fecha de creación

  ### `attachments` - Archivos adjuntos (imágenes)
  - `id` (uuid, primary key) - Identificador único del adjunto
  - `task_id` (uuid) - ID de la tarea
  - `file_name` (text) - Nombre del archivo
  - `file_path` (text) - Ruta en Supabase Storage
  - `file_type` (text) - Tipo MIME del archivo
  - `file_size` (integer) - Tamaño en bytes
  - `user_id` (uuid) - ID del usuario que subió el archivo
  - `created_at` (timestamptz) - Fecha de creación

  ## 2. Seguridad
  - RLS habilitado en todas las tablas
  - Los usuarios solo pueden ver y modificar sus propios proyectos y datos relacionados
  - Políticas separadas para SELECT, INSERT, UPDATE y DELETE
  - Autenticación requerida para todas las operaciones

  ## 3. Índices
  - Índices en claves foráneas para optimizar queries
  - Índices en campos de posición para ordenamiento rápido

  ## 4. Consideraciones Importantes
  - Las columnas tienen posiciones para mantener el orden
  - Las tareas tienen posiciones dentro de cada columna
  - Soporte para tiempo real con Supabase subscriptions
  - Storage bucket para imágenes se configurará por separado
*/

-- Crear tabla de proyectos
CREATE TABLE IF NOT EXISTS projects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  description text,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Crear tabla de columnas
CREATE TABLE IF NOT EXISTS columns (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name text NOT NULL,
  position integer NOT NULL DEFAULT 0,
  color text DEFAULT '#6366f1',
  created_at timestamptz DEFAULT now()
);

-- Crear tabla de tareas
CREATE TABLE IF NOT EXISTS tasks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  column_id uuid NOT NULL REFERENCES columns(id) ON DELETE CASCADE,
  project_id uuid NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  title text NOT NULL,
  description text,
  position integer NOT NULL DEFAULT 0,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Crear tabla de comentarios
CREATE TABLE IF NOT EXISTS comments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  content text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- Crear tabla de adjuntos
CREATE TABLE IF NOT EXISTS attachments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id uuid NOT NULL REFERENCES tasks(id) ON DELETE CASCADE,
  file_name text NOT NULL,
  file_path text NOT NULL,
  file_type text NOT NULL,
  file_size integer NOT NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now()
);

-- Crear índices para mejorar el rendimiento
CREATE INDEX IF NOT EXISTS idx_projects_user_id ON projects(user_id);
CREATE INDEX IF NOT EXISTS idx_columns_project_id ON columns(project_id);
CREATE INDEX IF NOT EXISTS idx_columns_position ON columns(project_id, position);
CREATE INDEX IF NOT EXISTS idx_tasks_column_id ON tasks(column_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project_id ON tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_position ON tasks(column_id, position);
CREATE INDEX IF NOT EXISTS idx_comments_task_id ON comments(task_id);
CREATE INDEX IF NOT EXISTS idx_attachments_task_id ON attachments(task_id);

-- Habilitar RLS en todas las tablas
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE columns ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE attachments ENABLE ROW LEVEL SECURITY;

-- Políticas para PROJECTS
CREATE POLICY "Users can view their own projects"
  ON projects FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

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

-- Políticas para COLUMNS
CREATE POLICY "Users can view columns of their projects"
  ON columns FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = columns.project_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create columns in their projects"
  ON columns FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = columns.project_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update columns in their projects"
  ON columns FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = columns.project_id
      AND projects.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = columns.project_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete columns from their projects"
  ON columns FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = columns.project_id
      AND projects.user_id = auth.uid()
    )
  );

-- Políticas para TASKS
CREATE POLICY "Users can view tasks in their projects"
  ON tasks FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = tasks.project_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create tasks in their projects"
  ON tasks FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = tasks.project_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update tasks in their projects"
  ON tasks FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = tasks.project_id
      AND projects.user_id = auth.uid()
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = tasks.project_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete tasks from their projects"
  ON tasks FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM projects
      WHERE projects.id = tasks.project_id
      AND projects.user_id = auth.uid()
    )
  );

-- Políticas para COMMENTS
CREATE POLICY "Users can view comments on tasks in their projects"
  ON comments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      JOIN projects ON projects.id = tasks.project_id
      WHERE tasks.id = comments.task_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create comments on tasks in their projects"
  ON comments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tasks
      JOIN projects ON projects.id = tasks.project_id
      WHERE tasks.id = comments.task_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can update their own comments"
  ON comments FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments"
  ON comments FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Políticas para ATTACHMENTS
CREATE POLICY "Users can view attachments on tasks in their projects"
  ON attachments FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM tasks
      JOIN projects ON projects.id = tasks.project_id
      WHERE tasks.id = attachments.task_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can create attachments on tasks in their projects"
  ON attachments FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM tasks
      JOIN projects ON projects.id = tasks.project_id
      WHERE tasks.id = attachments.task_id
      AND projects.user_id = auth.uid()
    )
  );

CREATE POLICY "Users can delete their own attachments"
  ON attachments FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);