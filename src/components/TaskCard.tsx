import { MessageCircle, Paperclip, Calendar } from 'lucide-react';
import { Task } from '../lib/supabase';

interface TaskCardProps {
  task: Task;
  commentCount: number;
  attachmentCount: number;
  onDragStart: (task: Task) => void;
  onDragEnd: () => void;
  onClick: () => void;
}

export function TaskCard({
  task,
  commentCount,
  attachmentCount,
  onDragStart,
  onDragEnd,
  onClick,
}: TaskCardProps) {
  return (
    <div
      draggable
      onDragStart={() => onDragStart(task)}
      onDragEnd={onDragEnd}
      onClick={onClick}
      className="bg-white rounded-xl p-4 shadow-sm border border-gray-100 hover:shadow-md transition-all cursor-move hover:border-blue-200 group"
    >
      <h3 className="font-medium text-gray-800 mb-2 group-hover:text-blue-700 transition-colors">
        {task.title}
      </h3>

      {task.description && (
        <p className="text-sm text-gray-500 mb-3 line-clamp-2">{task.description}</p>
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
            {new Date(task.created_at).toLocaleDateString('es-ES', {
              day: 'numeric',
              month: 'short',
            })}
          </span>
        </div>
      </div>
    </div>
  );
}
