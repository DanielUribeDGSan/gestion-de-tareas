import {
  X,
  MessageCircle,
  Paperclip,
  Upload,
  Trash2,
  Send,
  Edit,
} from "lucide-react";
import { Task, Comment, Attachment } from "../lib/supabase";
import { useState } from "react";
import { RichTextEditor } from "./RichTextEditor";
import { ImageModal } from "./ImageModal";

interface TaskModalProps {
  task: Task;
  comments: Comment[];
  attachments: Attachment[];
  onClose: () => void;
  onAddComment: (content: string) => void;
  onDeleteComment: (comment: Comment) => void;
  onUploadAttachment: (file: File) => void;
  onDeleteAttachment: (attachmentId: string, filePath: string) => void;
  onEditTask: (task: Task) => void;
}

export function TaskModal({
  task,
  comments,
  attachments,
  onClose,
  onAddComment,
  onDeleteComment,
  onUploadAttachment,
  onDeleteAttachment,
  onEditTask,
}: TaskModalProps) {
  const [commentText, setCommentText] = useState("");
  const [uploading, setUploading] = useState(false);
  const [showImageModal, setShowImageModal] = useState(false);
  const [selectedImageIndex, setSelectedImageIndex] = useState(0);

  const handleAddComment = () => {
    if (commentText.trim()) {
      onAddComment(commentText);
      setCommentText("");
    }
  };

  const handleFileUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setUploading(true);
      await onUploadAttachment(file);
      setUploading(false);
    }
  };

  const handleImageClick = (index: number) => {
    setSelectedImageIndex(index);
    setShowImageModal(true);
  };

  const imageUrls = attachments.map((att) => att.file_path);
  const imageNames = attachments.map((att) => att.file_name);

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-3xl max-h-[90vh] overflow-hidden flex flex-col">
        <div className="p-6 border-b border-gray-200 flex items-center justify-between">
          <h2 className="text-2xl font-bold text-gray-800">{task.title}</h2>
          <div className="flex items-center gap-2">
            <button
              onClick={() => onEditTask(task)}
              className="p-2 text-gray-400 hover:text-blue-600 hover:bg-blue-50 rounded-xl transition-all"
              title="Editar tarea"
            >
              <Edit className="w-5 h-5" />
            </button>
            <button
              onClick={onClose}
              className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-all"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {task.description && (
            <div>
              <h3 className="text-sm font-semibold text-gray-700 mb-2">
                Descripción
              </h3>
              <div
                className="text-gray-600 bg-gray-50 rounded-xl p-4 prose prose-sm max-w-none"
                dangerouslySetInnerHTML={{ __html: task.description }}
              />
            </div>
          )}

          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-sm font-semibold text-gray-700 flex items-center gap-2">
                <Paperclip className="w-4 h-4" />
                Archivos Adjuntos ({attachments.length})
              </h3>
              <label className="px-3 py-1.5 bg-blue-50 text-blue-600 rounded-lg text-sm font-medium hover:bg-blue-100 transition-all cursor-pointer flex items-center gap-2">
                <Upload className="w-4 h-4" />
                {uploading ? "Subiendo..." : "Subir"}
                <input
                  type="file"
                  onChange={handleFileUpload}
                  accept="image/*"
                  className="hidden"
                  disabled={uploading}
                />
              </label>
            </div>
            <div className="grid grid-cols-2 gap-3">
              {attachments.map((attachment, index) => (
                <div
                  key={attachment.id}
                  className="relative group bg-gray-50 rounded-xl overflow-hidden border border-gray-200"
                >
                  <img
                    src={attachment.file_path}
                    alt={attachment.file_name}
                    className="w-full h-40 object-cover cursor-pointer hover:opacity-90 transition-opacity"
                    onClick={() => handleImageClick(index)}
                    title="Haz clic para ver en tamaño completo"
                  />
                  <button
                    onClick={() =>
                      onDeleteAttachment(attachment.id, attachment.file_path)
                    }
                    className="absolute top-2 right-2 p-2 bg-red-500 text-white rounded-lg opacity-0 group-hover:opacity-100 transition-opacity"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                  <div className="p-2 bg-white">
                    <p className="text-xs text-gray-600 truncate">
                      {attachment.file_name}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div>
            <h3 className="text-sm font-semibold text-gray-700 mb-3 flex items-center gap-2">
              <MessageCircle className="w-4 h-4" />
              Comentarios ({comments.length})
            </h3>
            <div className="space-y-3 mb-4">
              {comments.map((comment) => (
                <div
                  key={comment.id}
                  className="bg-gray-50 rounded-xl p-4 group hover:bg-gray-100 transition-all"
                >
                  <div className="flex items-start justify-between gap-2">
                    <div
                      className="text-gray-700 flex-1 prose prose-sm max-w-none"
                      dangerouslySetInnerHTML={{ __html: comment.content }}
                    />
                    <button
                      onClick={() => onDeleteComment(comment)}
                      className="p-1 text-red-500 opacity-0 group-hover:opacity-100 transition-opacity"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                  <p className="text-xs text-gray-400 mt-2">
                    {new Date(comment.created_at).toLocaleString("es-ES")}
                  </p>
                </div>
              ))}
            </div>
            <div className="space-y-3">
              <RichTextEditor
                value={commentText}
                onChange={setCommentText}
                placeholder="Escribe un comentario..."
                height={150}
              />
              <div className="flex justify-end">
                <button
                  onClick={handleAddComment}
                  className="px-4 py-2.5 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-xl hover:from-blue-600 hover:to-purple-700 transition-all flex items-center gap-2"
                >
                  <Send className="w-4 h-4" />
                  Enviar Comentario
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Modal de imágenes */}
      <ImageModal
        isOpen={showImageModal}
        onClose={() => setShowImageModal(false)}
        images={imageUrls}
        initialIndex={selectedImageIndex}
        imageNames={imageNames}
      />
    </div>
  );
}
