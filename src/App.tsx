import { useState, useEffect, useCallback } from "react";
import { useAuth } from "./contexts/AuthContext";
import {
  supabase,
  Project,
  Column,
  Task,
  Comment,
  Attachment,
} from "./lib/supabase";
import { Auth } from "./components/Auth";
import { Sidebar } from "./components/Sidebar";
import { Board } from "./components/Board";
import { CreateProjectModal } from "./components/CreateProjectModal";
import { CreateColumnModal } from "./components/CreateColumnModal";
import { CreateTaskModal } from "./components/CreateTaskModal";
import { EditTaskModal } from "./components/EditTaskModal";
import { TaskModal } from "./components/TaskModal";
import { DeleteProjectModal } from "./components/DeleteProjectModal";
import { DeleteCommentModal } from "./components/DeleteCommentModal";
import { DeleteTaskModal } from "./components/DeleteTaskModal";
import { MyTasksModal } from "./components/MyTasksModal";
import { useDragAndDrop } from "./hooks/useDragAndDrop";

function App() {
  const { user, loading: authLoading, signOut } = useAuth();

  // Estados principales
  const [projects, setProjects] = useState<Project[]>([]);
  const [selectedProject, setSelectedProject] = useState<Project | null>(null);
  const [columns, setColumns] = useState<Column[]>([]);
  const [tasks, setTasks] = useState<Task[]>([]);
  const [taskCounts, setTaskCounts] = useState<
    Record<string, { comments: number; attachments: number }>
  >({});

  // Estados de modales
  const [showCreateProject, setShowCreateProject] = useState(false);
  const [showCreateColumn, setShowCreateColumn] = useState(false);
  const [showCreateTask, setShowCreateTask] = useState(false);
  const [selectedColumnForTask, setSelectedColumnForTask] = useState<
    string | null
  >(null);
  const [selectedTask, setSelectedTask] = useState<Task | null>(null);
  const [taskComments, setTaskComments] = useState<Comment[]>([]);
  const [taskAttachments, setTaskAttachments] = useState<Attachment[]>([]);
  const [showDeleteProject, setShowDeleteProject] = useState(false);
  const [projectToDelete, setProjectToDelete] = useState<Project | null>(null);
  const [showEditTask, setShowEditTask] = useState(false);
  const [taskToEdit, setTaskToEdit] = useState<Task | null>(null);
  const [showDeleteComment, setShowDeleteComment] = useState(false);
  const [commentToDelete, setCommentToDelete] = useState<Comment | null>(null);
  const [showDeleteTask, setShowDeleteTask] = useState(false);
  const [taskToDelete, setTaskToDelete] = useState<Task | null>(null);
  const [showMyTasks, setShowMyTasks] = useState(false);

  // Estados de carga
  // const [loading, setLoading] = useState(true);

  // Hook para drag and drop
  const {
    draggedOverColumn,
    handleDragStart,
    handleDragOver,
    handleDragLeave,
    handleDrop,
    handleDragEnd,
  } = useDragAndDrop();

  // Estado para evitar verificaciones repetidas
  const [storageChecked, setStorageChecked] = useState(false);

  // Función para verificar configuración de Storage (solo una vez)
  const checkStorageConfiguration = useCallback(async () => {
    if (storageChecked) return;

    try {
      console.log("🔍 Verificando configuración de Storage...");
      console.log("👤 Usuario autenticado:", user?.id);

      // Listar buckets disponibles
      const { data: buckets, error: bucketsError } =
        await supabase.storage.listBuckets();

      if (bucketsError) {
        console.warn("⚠️ Error al listar buckets:", bucketsError.message);
        setStorageChecked(true);
        return;
      }

      console.log("📦 Buckets disponibles:", buckets);

      // Verificar si existe el bucket task-attachments
      const taskAttachmentsBucket = buckets?.find(
        (bucket) => bucket.name === "task-attachments"
      );

      if (!taskAttachmentsBucket) {
        console.warn("⚠️ El bucket 'task-attachments' no existe");
        console.log(
          "📋 Buckets disponibles:",
          buckets?.map((b) => b.name)
        );
        setStorageChecked(true);
        return;
      }

      console.log(
        "✅ Bucket 'task-attachments' encontrado:",
        taskAttachmentsBucket
      );
      setStorageChecked(true);
    } catch (error) {
      console.error("💥 Error verificando configuración:", error);
      setStorageChecked(true);
    }
  }, [user?.id, storageChecked]);

  // Funciones de carga
  const loadProjects = useCallback(async () => {
    if (!user?.id) return;

    try {
      console.log(
        "📂 Cargando todos los proyectos disponibles para usuario:",
        user.id
      );
      const { data, error } = await supabase
        .from("projects")
        .select("*")
        .order("created_at", { ascending: false });

      if (error) {
        console.error("❌ Error al cargar proyectos:", error);
        throw error;
      }

      console.log("✅ Proyectos cargados:", data?.length || 0);
      setProjects(data || []);

      // Seleccionar el primer proyecto si existe
      if (data && data.length > 0 && !selectedProject) {
        setSelectedProject(data[0]);
      }
    } catch (error) {
      console.error("Error loading projects:", error);
    }
  }, [user?.id, selectedProject]);

  const loadProjectData = useCallback(async (projectId: string) => {
    try {
      // Cargar columnas
      const { data: columnsData, error: columnsError } = await supabase
        .from("columns")
        .select("*")
        .eq("project_id", projectId)
        .order("position", { ascending: true });

      if (columnsError) throw columnsError;
      setColumns(columnsData || []);

      // Cargar tareas con información del usuario asignado
      const { data: tasksData, error: tasksError } = await supabase
        .from("tasks")
        .select(
          `
          *,
          assigned_user:user_profiles!assigned_to(id, email, full_name)
        `
        )
        .eq("project_id", projectId)
        .order("position", { ascending: true });

      if (tasksError) throw tasksError;
      setTasks(tasksData || []);

      // Cargar conteos de comentarios y archivos
      await loadTaskCounts(tasksData || []);
    } catch (error) {
      console.error("Error loading project data:", error);
    }
  }, []);

  // Efectos
  useEffect(() => {
    if (user && !storageChecked) {
      loadProjects();
      checkStorageConfiguration();
    }
  }, [user, loadProjects, checkStorageConfiguration, storageChecked]);

  useEffect(() => {
    if (selectedProject) {
      loadProjectData(selectedProject.id);
    } else {
      setColumns([]);
      setTasks([]);
      setTaskCounts({});
    }
  }, [selectedProject, loadProjectData]);

  const loadTaskCounts = async (tasksList: Task[]) => {
    try {
      const counts: Record<string, { comments: number; attachments: number }> =
        {};

      for (const task of tasksList) {
        // Contar comentarios
        const { count: commentsCount } = await supabase
          .from("comments")
          .select("*", { count: "exact", head: true })
          .eq("task_id", task.id);

        // Contar archivos adjuntos
        const { count: attachmentsCount } = await supabase
          .from("attachments")
          .select("*", { count: "exact", head: true })
          .eq("task_id", task.id);

        counts[task.id] = {
          comments: commentsCount || 0,
          attachments: attachmentsCount || 0,
        };
      }

      setTaskCounts(counts);
    } catch (error) {
      console.error("Error loading task counts:", error);
    }
  };

  // Funciones CRUD para Proyectos
  const handleCreateProject = async (name: string, description: string) => {
    try {
      const { data, error } = await supabase
        .from("projects")
        .insert([
          {
            name,
            description: description || null,
            user_id: user?.id,
          },
        ])
        .select()
        .single();

      if (error) throw error;

      // Actualizar estado local
      setProjects((prev) => [data, ...prev]);
      setSelectedProject(data);

      return data;
    } catch (error) {
      console.error("Error creating project:", error);
      throw error;
    }
  };

  const handleDeleteProject = async (projectId: string) => {
    try {
      // Eliminar proyecto (las columnas y tareas se eliminan automáticamente por CASCADE)
      const { error } = await supabase
        .from("projects")
        .delete()
        .eq("id", projectId);

      if (error) throw error;

      // Actualizar estado local
      setProjects((prev) => prev.filter((project) => project.id !== projectId));

      // Si el proyecto eliminado era el seleccionado, seleccionar otro o limpiar
      if (selectedProject?.id === projectId) {
        const remainingProjects = projects.filter(
          (project) => project.id !== projectId
        );
        setSelectedProject(
          remainingProjects.length > 0 ? remainingProjects[0] : null
        );
        setColumns([]);
        setTasks([]);
        setTaskCounts({});
      }
    } catch (error) {
      console.error("Error deleting project:", error);
      throw error;
    }
  };

  const handleOpenDeleteProject = (project: Project) => {
    setProjectToDelete(project);
    setShowDeleteProject(true);
  };

  const handleConfirmDeleteProject = async () => {
    if (projectToDelete) {
      await handleDeleteProject(projectToDelete.id);
      setShowDeleteProject(false);
      setProjectToDelete(null);
    }
  };

  const handleCloseDeleteProject = () => {
    setShowDeleteProject(false);
    setProjectToDelete(null);
  };

  const handleOpenEditTask = (task: Task) => {
    setTaskToEdit(task);
    setShowEditTask(true);
  };

  const handleUpdateTaskSubmit = async (title: string, description: string) => {
    if (taskToEdit) {
      await handleUpdateTask(taskToEdit.id, title, description);
      setShowEditTask(false);
      setTaskToEdit(null);
    }
  };

  const handleCloseEditTask = () => {
    setShowEditTask(false);
    setTaskToEdit(null);
  };

  const handleOpenDeleteComment = (comment: Comment) => {
    setCommentToDelete(comment);
    setShowDeleteComment(true);
  };

  const handleConfirmDeleteComment = async () => {
    if (commentToDelete) {
      await handleDeleteComment(commentToDelete.id);
      setShowDeleteComment(false);
      setCommentToDelete(null);
    }
  };

  const handleCloseDeleteComment = () => {
    setShowDeleteComment(false);
    setCommentToDelete(null);
  };

  const handleDeleteTask = async (taskId: string) => {
    try {
      // Eliminar tarea (los comentarios y archivos se eliminan automáticamente por CASCADE)
      const { error } = await supabase.from("tasks").delete().eq("id", taskId);

      if (error) throw error;

      // Actualizar estado local
      setTasks((prev) => prev.filter((task) => task.id !== taskId));

      // Si la tarea eliminada era la seleccionada, cerrar el modal
      if (selectedTask?.id === taskId) {
        setSelectedTask(null);
        setTaskComments([]);
        setTaskAttachments([]);
      }

      // Actualizar conteos
      setTaskCounts((prev) => {
        const newCounts = { ...prev };
        delete newCounts[taskId];
        return newCounts;
      });
    } catch (error) {
      console.error("Error deleting task:", error);
      throw error;
    }
  };

  const handleOpenDeleteTask = (task: Task) => {
    setTaskToDelete(task);
    setShowDeleteTask(true);
  };

  const handleConfirmDeleteTask = async () => {
    if (taskToDelete) {
      await handleDeleteTask(taskToDelete.id);
      setShowDeleteTask(false);
      setTaskToDelete(null);
    }
  };

  const handleCloseDeleteTask = () => {
    setShowDeleteTask(false);
    setTaskToDelete(null);
  };

  // Funciones CRUD para Columnas
  const handleCreateColumn = async (name: string, color: string) => {
    if (!selectedProject) return;

    try {
      const { data, error } = await supabase
        .from("columns")
        .insert([
          {
            project_id: selectedProject.id,
            name,
            color,
            position: columns.length,
          },
        ])
        .select()
        .single();

      if (error) throw error;

      // Actualizar estado local
      setColumns((prev) => [...prev, data]);

      return data;
    } catch (error) {
      console.error("Error creating column:", error);
      throw error;
    }
  };

  const handleDeleteColumn = async (columnId: string) => {
    try {
      // Eliminar tareas de la columna
      const { error: tasksError } = await supabase
        .from("tasks")
        .delete()
        .eq("column_id", columnId);

      if (tasksError) throw tasksError;

      // Eliminar columna
      const { error: columnError } = await supabase
        .from("columns")
        .delete()
        .eq("id", columnId);

      if (columnError) throw columnError;

      // Actualizar estado local
      setColumns((prev) => prev.filter((col) => col.id !== columnId));
      setTasks((prev) => prev.filter((task) => task.column_id !== columnId));

      // Actualizar conteos
      const remainingTasks = tasks.filter(
        (task) => task.column_id !== columnId
      );
      await loadTaskCounts(remainingTasks);
    } catch (error) {
      console.error("Error deleting column:", error);
      throw error;
    }
  };

  // Funciones CRUD para Tareas
  const handleCreateTask = async (
    columnId: string,
    title: string,
    description: string,
    images: string[] = [],
    assignedTo?: string
  ) => {
    if (!selectedProject) return;

    try {
      const tasksInColumn = tasks.filter((task) => task.column_id === columnId);
      const position = tasksInColumn.length;

      const { data, error } = await supabase
        .from("tasks")
        .insert([
          {
            column_id: columnId,
            project_id: selectedProject.id,
            title,
            description: description || null,
            position,
            user_id: user?.id,
            assigned_to: assignedTo || null,
          },
        ])
        .select()
        .single();

      if (error) throw error;

      // Subir imágenes si las hay
      if (images && images.length > 0) {
        for (const imageDataUrl of images) {
          try {
            // Convertir Data URL a Blob
            const response = await fetch(imageDataUrl);
            const blob = await response.blob();

            // Crear un archivo temporal
            const fileExt = blob.type.split("/")[1] || "png";
            const fileName = `task-image-${Math.random()}.${fileExt}`;
            const filePath = `attachments/${fileName}`;

            // Subir archivo a Supabase Storage
            const { error: uploadError } = await supabase.storage
              .from("task-attachments")
              .upload(filePath, blob);

            if (uploadError) {
              console.error("Error al subir imagen:", uploadError);
              continue; // Continuar con la siguiente imagen
            }

            // Obtener URL pública
            const {
              data: { publicUrl },
            } = supabase.storage
              .from("task-attachments")
              .getPublicUrl(filePath);

            // Guardar en base de datos
            await supabase.from("attachments").insert([
              {
                task_id: data.id,
                file_name: fileName,
                file_path: publicUrl,
                file_type: blob.type,
                file_size: blob.size,
                user_id: user?.id,
              },
            ]);

            console.log("Imagen subida exitosamente:", fileName);
          } catch (imageError) {
            console.error("Error al procesar imagen:", imageError);
            // Continuar con la siguiente imagen
          }
        }
      }

      // Actualizar estado local
      setTasks((prev) => [...prev, data]);

      // Actualizar conteos
      setTaskCounts((prev) => ({
        ...prev,
        [data.id]: { comments: 0, attachments: images?.length || 0 },
      }));

      return data;
    } catch (error) {
      console.error("Error creating task:", error);
      throw error;
    }
  };

  const handleUpdateTask = async (
    taskId: string,
    title: string,
    description: string
  ) => {
    try {
      const { error } = await supabase
        .from("tasks")
        .update({
          title,
          description: description || null,
          updated_at: new Date().toISOString(),
        })
        .eq("id", taskId);

      if (error) throw error;

      // Actualizar estado local
      setTasks((prev) =>
        prev.map((task) =>
          task.id === taskId
            ? {
                ...task,
                title,
                description: description || null,
              }
            : task
        )
      );

      // Si la tarea está seleccionada, actualizar también
      if (selectedTask?.id === taskId) {
        setSelectedTask((prev) =>
          prev
            ? {
                ...prev,
                title,
                description: description || null,
              }
            : null
        );
      }
    } catch (error) {
      console.error("Error updating task:", error);
      throw error;
    }
  };

  const handleMoveTask = async (taskId: string, newColumnId: string) => {
    try {
      const { error } = await supabase
        .from("tasks")
        .update({ column_id: newColumnId })
        .eq("id", taskId);

      if (error) throw error;

      // Actualizar estado local
      setTasks((prev) =>
        prev.map((task) =>
          task.id === taskId ? { ...task, column_id: newColumnId } : task
        )
      );
    } catch (error) {
      console.error("Error moving task:", error);
    }
  };

  // Funciones para el modal de tarea
  const handleTaskClick = async (task: Task) => {
    setSelectedTask(task);
    await loadTaskDetails(task.id);
  };

  const loadTaskDetails = async (taskId: string) => {
    try {
      console.log("Cargando detalles de la tarea:", taskId);

      // Cargar comentarios
      const { data: comments, error: commentsError } = await supabase
        .from("comments")
        .select("*")
        .eq("task_id", taskId)
        .order("created_at", { ascending: true });

      if (commentsError) throw commentsError;
      setTaskComments(comments || []);
      console.log("Comentarios cargados:", comments?.length || 0);

      // Cargar archivos adjuntos
      const { data: attachments, error: attachmentsError } = await supabase
        .from("attachments")
        .select("*")
        .eq("task_id", taskId)
        .order("created_at", { ascending: true });

      if (attachmentsError) {
        console.error("Error al cargar attachments:", attachmentsError);
        throw attachmentsError;
      }

      console.log("Attachments cargados:", attachments?.length || 0);
      if (attachments && attachments.length > 0) {
        console.log("Detalles de attachments:", attachments);
        attachments.forEach((att, index) => {
          console.log(`Attachment ${index + 1}:`, {
            id: att.id,
            file_name: att.file_name,
            file_path: att.file_path,
            file_type: att.file_type,
          });
        });
      }

      setTaskAttachments(attachments || []);
    } catch (error) {
      console.error("Error loading task details:", error);
    }
  };

  const handleAddComment = async (content: string) => {
    if (!selectedTask) return;

    try {
      const { data, error } = await supabase
        .from("comments")
        .insert([
          {
            task_id: selectedTask.id,
            user_id: user?.id,
            content,
          },
        ])
        .select()
        .single();

      if (error) throw error;

      // Actualizar comentarios
      setTaskComments((prev) => [...prev, data]);

      // Actualizar conteos
      setTaskCounts((prev) => ({
        ...prev,
        [selectedTask.id]: {
          ...prev[selectedTask.id],
          comments: (prev[selectedTask.id]?.comments || 0) + 1,
        },
      }));
    } catch (error) {
      console.error("Error adding comment:", error);
    }
  };

  const handleDeleteComment = async (commentId: string) => {
    if (!selectedTask) return;

    try {
      const { error } = await supabase
        .from("comments")
        .delete()
        .eq("id", commentId);

      if (error) throw error;

      // Actualizar comentarios
      setTaskComments((prev) =>
        prev.filter((comment) => comment.id !== commentId)
      );

      // Actualizar conteos
      setTaskCounts((prev) => ({
        ...prev,
        [selectedTask.id]: {
          ...prev[selectedTask.id],
          comments: Math.max((prev[selectedTask.id]?.comments || 1) - 1, 0),
        },
      }));
    } catch (error) {
      console.error("Error deleting comment:", error);
    }
  };

  const handleUploadAttachment = async (file: File) => {
    if (!selectedTask) return;

    try {
      console.log(
        "Iniciando subida de archivo:",
        file.name,
        "Tamaño:",
        file.size
      );

      // Subir archivo a Supabase Storage
      const fileExt = file.name.split(".").pop();
      const fileName = `${Math.random()}.${fileExt}`;
      const filePath = `attachments/${fileName}`;

      console.log("Subiendo archivo a:", filePath);

      const { data: uploadData, error: uploadError } = await supabase.storage
        .from("task-attachments")
        .upload(filePath, file);

      if (uploadError) {
        console.error("Error al subir archivo:", uploadError);
        throw uploadError;
      }

      console.log("Archivo subido exitosamente:", uploadData);

      // Obtener URL pública
      const {
        data: { publicUrl },
      } = supabase.storage.from("task-attachments").getPublicUrl(filePath);

      console.log("URL pública generada:", publicUrl);

      // Guardar en base de datos
      const { data, error } = await supabase
        .from("attachments")
        .insert([
          {
            task_id: selectedTask.id,
            file_name: file.name,
            file_path: publicUrl,
            file_type: file.type,
            file_size: file.size,
            user_id: user?.id,
          },
        ])
        .select()
        .single();

      if (error) {
        console.error("Error al guardar en base de datos:", error);
        throw error;
      }

      console.log("Archivo guardado en base de datos:", data);

      // Actualizar archivos adjuntos
      setTaskAttachments((prev) => [...prev, data]);

      // Actualizar conteos
      setTaskCounts((prev) => ({
        ...prev,
        [selectedTask.id]: {
          ...prev[selectedTask.id],
          attachments: (prev[selectedTask.id]?.attachments || 0) + 1,
        },
      }));

      console.log("Archivo adjunto agregado exitosamente");
    } catch (error) {
      console.error("Error uploading attachment:", error);
      const errorMessage =
        error instanceof Error ? error.message : String(error);
      alert(`Error al subir la imagen: ${errorMessage}`);
    }
  };

  const handleDeleteAttachment = async (
    attachmentId: string,
    filePath: string
  ) => {
    if (!selectedTask) return;

    try {
      // Eliminar archivo de Storage
      const fileName = filePath.split("/").pop();
      if (fileName) {
        await supabase.storage
          .from("task-attachments")
          .remove([`attachments/${fileName}`]);
      }

      // Eliminar de base de datos
      const { error } = await supabase
        .from("attachments")
        .delete()
        .eq("id", attachmentId);

      if (error) throw error;

      // Actualizar archivos adjuntos
      setTaskAttachments((prev) =>
        prev.filter((att) => att.id !== attachmentId)
      );

      // Actualizar conteos
      setTaskCounts((prev) => ({
        ...prev,
        [selectedTask.id]: {
          ...prev[selectedTask.id],
          attachments: Math.max(
            (prev[selectedTask.id]?.attachments || 1) - 1,
            0
          ),
        },
      }));
    } catch (error) {
      console.error("Error deleting attachment:", error);
    }
  };

  // Funciones de drag and drop
  const handleTaskDrop = async (columnId: string) => {
    const task = handleDrop(columnId);
    if (task && task.column_id !== columnId) {
      await handleMoveTask(task.id, columnId);
    }
  };

  // Funciones auxiliares para modales
  const handleOpenCreateTask = (columnId: string) => {
    setSelectedColumnForTask(columnId);
    setShowCreateTask(true);
  };

  const handleCreateTaskSubmit = async (
    title: string,
    description: string,
    images: string[] = [],
    assignedTo?: string
  ) => {
    if (selectedColumnForTask) {
      await handleCreateTask(
        selectedColumnForTask,
        title,
        description,
        images,
        assignedTo
      );
      setShowCreateTask(false);
      setSelectedColumnForTask(null);
    }
  };

  const handleMyTaskClick = async (taskId: string) => {
    // Buscar la tarea en el estado actual
    const task = tasks.find((t) => t.id === taskId);
    if (task) {
      await handleTaskClick(task);
    }
  };

  // Renderizado
  if (authLoading) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600">Cargando...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return <Auth />;
  }

  return (
    <div className="flex h-screen bg-gray-50">
      <Sidebar
        projects={projects}
        selectedProject={selectedProject}
        onSelectProject={setSelectedProject}
        onCreateProject={() => setShowCreateProject(true)}
        onDeleteProject={handleOpenDeleteProject}
        onSignOut={signOut}
        onShowMyTasks={() => setShowMyTasks(true)}
        userEmail={user.email || ""}
      />

      <div className="flex-1 flex flex-col">
        {selectedProject ? (
          <Board
            columns={columns}
            tasks={tasks}
            taskCounts={taskCounts}
            onCreateColumn={() => setShowCreateColumn(true)}
            onDeleteColumn={handleDeleteColumn}
            onCreateTask={handleOpenCreateTask}
            onTaskClick={handleTaskClick}
            onDeleteTask={handleOpenDeleteTask}
            onDragStart={handleDragStart}
            onDragEnd={handleDragEnd}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            onDrop={handleTaskDrop}
            draggedOverColumn={draggedOverColumn}
          />
        ) : (
          <div className="flex-1 flex items-center justify-center">
            <div className="text-center">
              <h2 className="text-2xl font-bold text-gray-800 mb-2">
                Selecciona un proyecto
              </h2>
              <p className="text-gray-600 mb-6">
                Elige un proyecto de la barra lateral o crea uno nuevo
              </p>
              <button
                onClick={() => setShowCreateProject(true)}
                className="bg-gradient-to-r from-blue-500 to-purple-600 text-white py-2 px-4 rounded-xl font-medium hover:from-blue-600 hover:to-purple-700 transition-all"
              >
                Crear Nuevo Proyecto
              </button>
            </div>
          </div>
        )}
      </div>

      {/* MODALES */}
      {showCreateProject && (
        <CreateProjectModal
          onClose={() => setShowCreateProject(false)}
          onCreate={async (name, description) => {
            await handleCreateProject(name, description);
            setShowCreateProject(false);
          }}
        />
      )}

      {showCreateColumn && (
        <CreateColumnModal
          onClose={() => setShowCreateColumn(false)}
          onCreate={async (name, color) => {
            await handleCreateColumn(name, color);
            setShowCreateColumn(false);
          }}
        />
      )}

      {showCreateTask && (
        <CreateTaskModal
          onClose={() => {
            setShowCreateTask(false);
            setSelectedColumnForTask(null);
          }}
          onCreate={handleCreateTaskSubmit}
        />
      )}

      {selectedTask && (
        <TaskModal
          task={selectedTask}
          comments={taskComments}
          attachments={taskAttachments}
          onClose={() => {
            setSelectedTask(null);
            setTaskComments([]);
            setTaskAttachments([]);
          }}
          onAddComment={handleAddComment}
          onDeleteComment={handleOpenDeleteComment}
          onUploadAttachment={handleUploadAttachment}
          onDeleteAttachment={handleDeleteAttachment}
          onEditTask={handleOpenEditTask}
        />
      )}

      <DeleteProjectModal
        project={projectToDelete}
        isOpen={showDeleteProject}
        onClose={handleCloseDeleteProject}
        onConfirm={handleConfirmDeleteProject}
      />

      {showEditTask && taskToEdit && (
        <EditTaskModal
          task={taskToEdit}
          onClose={handleCloseEditTask}
          onUpdate={handleUpdateTaskSubmit}
        />
      )}

      <DeleteCommentModal
        comment={commentToDelete}
        isOpen={showDeleteComment}
        onClose={handleCloseDeleteComment}
        onConfirm={handleConfirmDeleteComment}
      />

      <DeleteTaskModal
        task={taskToDelete}
        isOpen={showDeleteTask}
        onClose={handleCloseDeleteTask}
        onConfirm={handleConfirmDeleteTask}
      />

      <MyTasksModal
        isOpen={showMyTasks}
        onClose={() => setShowMyTasks(false)}
        userId={user?.id || ""}
        onTaskClick={handleMyTaskClick}
      />
    </div>
  );
}

export default App;
