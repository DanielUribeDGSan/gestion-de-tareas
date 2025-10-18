import { createClient } from "@supabase/supabase-js";

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export type Project = {
  id: string;
  name: string;
  description: string | null;
  user_id: string;
  created_at: string;
  updated_at: string;
};

export type Column = {
  id: string;
  project_id: string;
  name: string;
  position: number;
  color: string;
  created_at: string;
};

export type Task = {
  id: string;
  column_id: string;
  project_id: string;
  title: string;
  description: string | null;
  position: number;
  user_id: string;
  assigned_to: string | null;
  created_at: string;
  updated_at: string;
  assigned_user?: {
    id: string;
    email: string;
    full_name: string | null;
  };
};

export type Comment = {
  id: string;
  task_id: string;
  user_id: string;
  content: string;
  created_at: string;
};

export type Attachment = {
  id: string;
  task_id: string;
  file_name: string;
  file_path: string;
  file_type: string;
  file_size: number;
  user_id: string;
  created_at: string;
};
