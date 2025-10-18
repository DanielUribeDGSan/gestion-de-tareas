import { MessageCircle, Paperclip, Calendar, Trash2 } from "lucide-react";
import { Task } from "../lib/supabase";

interface TaskCardProps {
  task: Task;
  commentCount: number;
  attachmentCount: number;
  onDragStart: (task: Task) => void;
  onDragEnd: () => void;
  onClick: () => void;
  onDelete: (task: Task) => void;
}

export function TaskCard({
  task,
  commentCount,
  attachmentCount,
  onDragStart,
  onDragEnd,
  onClick,
  onDelete,
}: TaskCardProps) {
  return (
    <div
      draggable
      onDragStart={() => onDragStart(task)}
      onDragEnd={onDragEnd}
      className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 hover:shadow-md transition-all cursor-move hover:border-blue-200 group"
    >
      <div className="flex items-start justify-between gap-2 mb-2">
        <h3
          className="font-medium text-gray-800 group-hover:text-blue-700 transition-colors flex-1 cursor-pointer"
          onClick={onClick}
        >
          {task.title}
        </h3>
        <button
          onClick={(e) => {
            e.stopPropagation();
            onDelete(task);
          }}
          className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all opacity-0 group-hover:opacity-100"
          title="Eliminar tarea"
        >
          <Trash2 className="w-3.5 h-3.5" />
        </button>
      </div>

      {task.description && (
        <div
          className="text-sm text-gray-500 mb-3 line-clamp-2 prose prose-sm max-w-none cursor-pointer"
          onClick={onClick}
          dangerouslySetInnerHTML={{ __html: task.description }}
        />
      )}

      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          {commentCount > 0 && (
            <div className="flex items-center gap-1 text-gray-500">
              <MessageCircle className="w-4 h-4" />
              <span className="text-xs">{commentCount}</span>
            </div>
          )}
          {attachmentCount > 0 && (
            <div className="flex items-center gap-1 text-gray-500">
              <Paperclip className="w-4 h-4" />
              <span className="text-xs">{attachmentCount}</span>
            </div>
          )}
        </div>

        <div className="flex items-center gap-1 text-gray-400">
          <Calendar className="w-3.5 h-3.5" />
          <span className="text-xs">
            {new Date(task.created_at).toLocaleDateString("es-ES", {
              day: "numeric",
              month: "short",
            })}
          </span>
        </div>
      </div>
    </div>
  );
}
