import { createClient } from "@supabase/supabase-js";
import dotenv from "dotenv";

// Cargar variables de entorno
dotenv.config();

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey =
  process.env.SUPABASE_SERVICE_ROLE_KEY || process.env.VITE_SUPABASE_ANON_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error(
    "❌ Faltan variables de entorno: VITE_SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY"
  );
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function executeMigration() {
  try {
    console.log("🔄 Ejecutando migración para agregar campo assigned_to...");

    // 1. Agregar el campo assigned_to a la tabla tasks
    const { error: alterError } = await supabase.rpc("exec_sql", {
      sql: `
        ALTER TABLE tasks 
        ADD COLUMN IF NOT EXISTS assigned_to uuid REFERENCES user_profiles(id) ON DELETE SET NULL;
      `,
    });

    if (alterError) {
      console.error("❌ Error al agregar campo assigned_to:", alterError);
      return;
    }

    console.log("✅ Campo assigned_to agregado exitosamente");

    // 2. Crear índice para mejorar el rendimiento
    const { error: indexError } = await supabase.rpc("exec_sql", {
      sql: `
        CREATE INDEX IF NOT EXISTS idx_tasks_assigned_to ON tasks(assigned_to);
      `,
    });

    if (indexError) {
      console.warn(
        "⚠️ Error al crear índice (puede que ya exista):",
        indexError
      );
    } else {
      console.log("✅ Índice creado exitosamente");
    }

    // 3. Verificar que el campo se agregó correctamente
    const { data: columns, error: columnsError } = await supabase
      .from("information_schema.columns")
      .select("column_name, data_type, is_nullable")
      .eq("table_name", "tasks")
      .eq("column_name", "assigned_to");

    if (columnsError) {
      console.warn("⚠️ No se pudo verificar el campo:", columnsError);
    } else if (columns && columns.length > 0) {
      console.log("✅ Campo assigned_to verificado:", columns[0]);
    } else {
      console.log("⚠️ Campo assigned_to no encontrado en la tabla tasks");
    }

    console.log("🎉 Migración completada exitosamente");
  } catch (error) {
    console.error("💥 Error durante la migración:", error);
  }
}

executeMigration();
