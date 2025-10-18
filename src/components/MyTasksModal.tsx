import {
  X,
  User,
  Calendar,
  MessageCircle,
  Paperclip,
  ExternalLink,
  Filter,
  Search,
} from "lucide-react";
import { useState, useEffect, useCallback } from "react";
import { supabase } from "../lib/supabase";

interface TaskWithAssignee {
  id: string;
  title: string;
  description: string | null;
  created_at: string;
  updated_at: string;
  project_name: string;
  column_name: string;
  created_by_email: string | null;
  created_by_name: string | null;
  comments_count: number;
  attachments_count: number;
}

interface ProjectInfo {
  name: string;
}

interface ColumnInfo {
  name: string;
}

interface UserProfileInfo {
  email: string;
  full_name: string;
}

interface MyTasksModalProps {
  isOpen: boolean;
  onClose: () => void;
  userId: string;
  onTaskClick?: (taskId: string) => void;
}

export function MyTasksModal({
  isOpen,
  onClose,
  userId,
  onTaskClick,
}: MyTasksModalProps) {
  const [tasks, setTasks] = useState<TaskWithAssignee[]>([]);
  const [filteredTasks, setFilteredTasks] = useState<TaskWithAssignee[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchTerm, setSearchTerm] = useState("");
  const [sortBy, setSortBy] = useState<"created_at" | "title" | "project_name">(
    "created_at"
  );
  const [sortOrder, setSortOrder] = useState<"asc" | "desc">("desc");

  const loadMyTasks = useCallback(async () => {
    try {
      setLoading(true);
      setError(null);

      // Consulta para obtener tareas asignadas al usuario con información adicional
      const { data, error } = await supabase
        .from("tasks")
        .select(
          `
          id,
          title,
          description,
          created_at,
          updated_at,
          projects!inner(name),
          columns!inner(name),
          user_profiles_creator:user_id(email, full_name)
        `
        )
        .eq("user_id", userId)
        .order("created_at", { ascending: false });

      if (error) throw error;

      // Obtener conteos de comentarios y adjuntos para cada tarea
      const tasksWithCounts = await Promise.all(
        (data || []).map(async (task) => {
          // Contar comentarios
          const { count: commentsCount } = await supabase
            .from("comments")
            .select("*", { count: "exact", head: true })
            .eq("task_id", task.id);

          // Contar adjuntos
          const { count: attachmentsCount } = await supabase
            .from("attachments")
            .select("*", { count: "exact", head: true })
            .eq("task_id", task.id);

          return {
            ...task,
            project_name:
              (task.projects as unknown as ProjectInfo)?.name || "Sin proyecto",
            column_name:
              (task.columns as unknown as ColumnInfo)?.name || "Sin columna",
            assigned_to_email:
              (task.user_profiles_assigned as unknown as UserProfileInfo)
                ?.email || null,
            assigned_to_name:
              (task.user_profiles_assigned as unknown as UserProfileInfo)
                ?.full_name || null,
            created_by_email:
              (task.user_profiles_creator as unknown as UserProfileInfo)
                ?.email || null,
            created_by_name:
              (task.user_profiles_creator as unknown as UserProfileInfo)
                ?.full_name || null,
            comments_count: commentsCount || 0,
            attachments_count: attachmentsCount || 0,
          };
        })
      );

      setTasks(tasksWithCounts);
      setFilteredTasks(tasksWithCounts);
    } catch (err) {
      console.error("Error loading my tasks:", err);
      setError("Error al cargar las tareas asignadas");
    } finally {
      setLoading(false);
    }
  }, [userId]);

  useEffect(() => {
    if (isOpen && userId) {
      loadMyTasks();
    }
  }, [isOpen, userId, loadMyTasks]);

  // Efecto para filtrar y ordenar tareas
  useEffect(() => {
    let filtered = [...tasks];

    // Filtrar por término de búsqueda
    if (searchTerm.trim()) {
      const term = searchTerm.toLowerCase();
      filtered = filtered.filter(
        (task) =>
          task.title.toLowerCase().includes(term) ||
          task.description?.toLowerCase().includes(term) ||
          task.project_name.toLowerCase().includes(term) ||
          task.column_name.toLowerCase().includes(term)
      );
    }

    // Ordenar
    filtered.sort((a, b) => {
      let aValue: string | number;
      let bValue: string | number;

      switch (sortBy) {
        case "title":
          aValue = a.title.toLowerCase();
          bValue = b.title.toLowerCase();
          break;
        case "project_name":
          aValue = a.project_name.toLowerCase();
          bValue = b.project_name.toLowerCase();
          break;
        case "created_at":
        default:
          aValue = new Date(a.created_at).getTime();
          bValue = new Date(b.created_at).getTime();
          break;
      }

      if (sortOrder === "asc") {
        return aValue < bValue ? -1 : aValue > bValue ? 1 : 0;
      } else {
        return aValue > bValue ? -1 : aValue < bValue ? 1 : 0;
      }
    });

    setFilteredTasks(filtered);
  }, [tasks, searchTerm, sortBy, sortOrder]);

  const handleTaskClick = (taskId: string) => {
    if (onTaskClick) {
      onTaskClick(taskId);
    }
    onClose();
  };

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("es-ES", {
      day: "2-digit",
      month: "short",
      year: "numeric",
    });
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
        <div className="p-6 border-b border-gray-200 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="bg-gradient-to-br from-blue-500 to-purple-600 p-2.5 rounded-xl">
              <User className="w-5 h-5 text-white" />
            </div>
            <div>
              <h2 className="text-xl font-bold text-gray-800">
                Mis Tareas Asignadas
              </h2>
              <p className="text-sm text-gray-500">
                {loading
                  ? "Cargando..."
                  : `${filteredTasks.length} de ${tasks.length} tarea${
                      tasks.length !== 1 ? "s" : ""
                    } asignada${tasks.length !== 1 ? "s" : ""}`}
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-all"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Barra de búsqueda y filtros */}
        {!loading && tasks.length > 0 && (
          <div className="p-6 border-b border-gray-200 bg-gray-50">
            <div className="flex flex-col sm:flex-row gap-4">
              {/* Búsqueda */}
              <div className="flex-1 relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-4 h-4" />
                <input
                  type="text"
                  placeholder="Buscar tareas..."
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              {/* Ordenar por */}
              <div className="flex gap-2">
                <select
                  value={sortBy}
                  onChange={(e) =>
                    setSortBy(
                      e.target.value as "created_at" | "title" | "project_name"
                    )
                  }
                  className="px-3 py-2.5 bg-white border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
                >
                  <option value="created_at">Fecha</option>
                  <option value="title">Título</option>
                  <option value="project_name">Proyecto</option>
                </select>

                <button
                  onClick={() =>
                    setSortOrder(sortOrder === "asc" ? "desc" : "asc")
                  }
                  className="px-3 py-2.5 bg-white border border-gray-200 rounded-xl hover:bg-gray-50 transition-all"
                  title={`Ordenar ${
                    sortOrder === "asc" ? "descendente" : "ascendente"
                  }`}
                >
                  <Filter className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        )}

        <div className="flex-1 overflow-y-auto p-6">
          {loading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-500"></div>
              <span className="ml-3 text-gray-600">Cargando tareas...</span>
            </div>
          ) : error ? (
            <div className="text-center py-12">
              <div className="text-red-500 text-lg font-medium mb-2">Error</div>
              <p className="text-gray-600 mb-4">{error}</p>
              <button
                onClick={loadMyTasks}
                className="px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-all"
              >
                Reintentar
              </button>
            </div>
          ) : filteredTasks.length === 0 ? (
            <div className="text-center py-12">
              <User className="w-16 h-16 text-gray-300 mx-auto mb-4" />
              <h3 className="text-lg font-medium text-gray-800 mb-2">
                {searchTerm.trim()
                  ? "No se encontraron tareas"
                  : "No tienes tareas asignadas"}
              </h3>
              <p className="text-gray-500">
                {searchTerm.trim()
                  ? "Intenta con otros términos de búsqueda."
                  : "Cuando alguien te asigne una tarea, aparecerá aquí."}
              </p>
              {searchTerm.trim() && (
                <button
                  onClick={() => setSearchTerm("")}
                  className="mt-3 px-4 py-2 text-blue-600 hover:text-blue-700 text-sm font-medium"
                >
                  Limpiar búsqueda
                </button>
              )}
            </div>
          ) : (
            <div className="space-y-4">
              {filteredTasks.map((task) => (
                <div
                  key={task.id}
                  className="bg-gray-50 rounded-xl p-4 border border-gray-200 hover:bg-gray-100 transition-all cursor-pointer group"
                  onClick={() => handleTaskClick(task.id)}
                >
                  <div className="flex items-start justify-between gap-4">
                    <div className="flex-1 min-w-0">
                      <h3 className="font-medium text-gray-800 mb-2 group-hover:text-blue-600 transition-colors">
                        {task.title}
                      </h3>

                      {task.description && (
                        <p className="text-sm text-gray-600 mb-3 line-clamp-2">
                          {task.description.replace(/<[^>]*>/g, "")}
                        </p>
                      )}

                      <div className="flex items-center gap-4 text-xs text-gray-500">
                        <div className="flex items-center gap-1">
                          <Calendar className="w-3 h-3" />
                          <span>{formatDate(task.created_at)}</span>
                        </div>

                        <div className="flex items-center gap-1">
                          <span className="font-medium text-gray-700">
                            {task.project_name}
                          </span>
                          <span>•</span>
                          <span>{task.column_name}</span>
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-2">
                      {/* Contador de comentarios */}
                      {task.comments_count > 0 && (
                        <div className="flex items-center gap-1 text-gray-500">
                          <MessageCircle className="w-4 h-4" />
                          <span className="text-xs">{task.comments_count}</span>
                        </div>
                      )}

                      {/* Contador de adjuntos */}
                      {task.attachments_count > 0 && (
                        <div className="flex items-center gap-1 text-gray-500">
                          <Paperclip className="w-4 h-4" />
                          <span className="text-xs">
                            {task.attachments_count}
                          </span>
                        </div>
                      )}

                      {/* Indicador de que se puede hacer clic */}
                      <ExternalLink className="w-4 h-4 text-gray-400 opacity-0 group-hover:opacity-100 transition-opacity" />
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
