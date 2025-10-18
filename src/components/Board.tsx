import { Plus, MoreVertical, Trash2 } from "lucide-react";
import { Column, Task } from "../lib/supabase";
import { TaskCard } from "./TaskCard";
import { useState } from "react";

interface BoardProps {
  columns: Column[];
  tasks: Task[];
  taskCounts: Record<string, { comments: number; attachments: number }>;
  onCreateColumn: () => void;
  onDeleteColumn: (columnId: string) => void;
  onCreateTask: (columnId: string) => void;
  onTaskClick: (task: Task) => void;
  onDeleteTask: (task: Task) => void;
  onDragStart: (task: Task) => void;
  onDragEnd: () => void;
  onDragOver: (e: React.DragEvent, columnId: string) => void;
  onDragLeave: () => void;
  onDrop: (columnId: string) => void;
  draggedOverColumn: string | null;
}

export function Board({
  columns,
  tasks,
  taskCounts,
  onCreateColumn,
  onDeleteColumn,
  onCreateTask,
  onTaskClick,
  onDeleteTask,
  onDragStart,
  onDragEnd,
  onDragOver,
  onDragLeave,
  onDrop,
  draggedOverColumn,
}: BoardProps) {
  const [columnMenuOpen, setColumnMenuOpen] = useState<string | null>(null);

  const getTasksForColumn = (columnId: string) => {
    return tasks
      .filter((task) => task.column_id === columnId)
      .sort((a, b) => a.position - b.position);
  };

  return (
    <div className="flex-1 overflow-x-auto bg-gradient-to-br from-gray-50 to-gray-100 p-6">
      <div className="flex gap-4 h-full min-w-max">
        {columns.map((column) => {
          const columnTasks = getTasksForColumn(column.id);
          const isDraggedOver = draggedOverColumn === column.id;

          return (
            <div key={column.id} className="flex-shrink-0 w-80">
              <div className="bg-white rounded-2xl shadow-sm border border-gray-200 h-full flex flex-col">
                <div className="p-4 border-b border-gray-200">
                  <div className="flex items-center justify-between mb-1">
                    <div className="flex items-center gap-2">
                      <div
                        className="w-3 h-3 rounded-full"
                        style={{ backgroundColor: column.color }}
                      />
                      <h2 className="font-semibold text-gray-800">
                        {column.name}
                      </h2>
                      <span className="bg-gray-100 text-gray-600 text-xs font-medium px-2 py-0.5 rounded-full">
                        {columnTasks.length}
                      </span>
                    </div>
                    <div className="relative">
                      <button
                        onClick={() =>
                          setColumnMenuOpen(
                            columnMenuOpen === column.id ? null : column.id
                          )
                        }
                        className="p-1.5 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-lg transition-all"
                      >
                        <MoreVertical className="w-4 h-4" />
                      </button>
                      {columnMenuOpen === column.id && (
                        <div className="absolute right-0 mt-2 bg-white rounded-xl shadow-lg border border-gray-200 py-1 z-10 min-w-[160px]">
                          <button
                            onClick={() => {
                              onDeleteColumn(column.id);
                              setColumnMenuOpen(null);
                            }}
                            className="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 flex items-center gap-2"
                          >
                            <Trash2 className="w-4 h-4" />
                            Eliminar Columna
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                </div>

                <div
                  onDragOver={(e) => onDragOver(e, column.id)}
                  onDragLeave={onDragLeave}
                  onDrop={() => onDrop(column.id)}
                  className={`flex-1 p-4 space-y-3 overflow-y-auto transition-colors ${
                    isDraggedOver ? "bg-blue-50" : ""
                  }`}
                >
                  {columnTasks.map((task) => (
                    <TaskCard
                      key={task.id}
                      task={task}
                      commentCount={taskCounts[task.id]?.comments || 0}
                      attachmentCount={taskCounts[task.id]?.attachments || 0}
                      onDragStart={onDragStart}
                      onDragEnd={onDragEnd}
                      onClick={() => onTaskClick(task)}
                      onDelete={onDeleteTask}
                    />
                  ))}
                </div>

                <div className="p-4 border-t border-gray-200">
                  <button
                    onClick={() => onCreateTask(column.id)}
                    className="w-full py-2 px-3 text-gray-600 hover:text-blue-600 hover:bg-blue-50 rounded-xl transition-all flex items-center justify-center gap-2 text-sm font-medium"
                  >
                    <Plus className="w-4 h-4" />
                    Agregar Tarea
                  </button>
                </div>
              </div>
            </div>
          );
        })}

        <div className="flex-shrink-0 w-80">
          <button
            onClick={onCreateColumn}
            className="w-full h-full min-h-[200px] bg-white/50 hover:bg-white border-2 border-dashed border-gray-300 hover:border-blue-400 rounded-2xl transition-all flex items-center justify-center gap-2 text-gray-500 hover:text-blue-600 font-medium"
          >
            <Plus className="w-5 h-5" />
            Nueva Columna
          </button>
        </div>
      </div>
    </div>
  );
}
