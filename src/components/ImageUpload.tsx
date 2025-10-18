import { Upload, X, Image as ImageIcon, AlertCircle } from "lucide-react";
import { useState, useRef } from "react";

interface ImageUploadProps {
  onUpload: (file: File) => Promise<string>;
  onRemove?: (imageUrl: string) => void;
  maxSizeMB?: number;
  maxImages?: number;
  existingImages?: string[];
  className?: string;
}

export function ImageUpload({
  onUpload,
  onRemove,
  maxSizeMB = 2,
  maxImages = 5,
  existingImages = [],
  className = "",
}: ImageUploadProps) {
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const validateFile = (file: File): string | null => {
    // Validar tipo de archivo
    const allowedTypes = ["image/jpeg", "image/jpg", "image/png", "image/webp"];
    if (!allowedTypes.includes(file.type)) {
      return "Solo se permiten archivos JPG, PNG y WebP";
    }

    // Validar tamaño
    const maxSizeBytes = maxSizeMB * 1024 * 1024;
    if (file.size > maxSizeBytes) {
      return `El archivo no puede ser mayor a ${maxSizeMB}MB`;
    }

    // Validar número máximo de imágenes
    if (existingImages.length >= maxImages) {
      return `Máximo ${maxImages} imágenes permitidas`;
    }

    return null;
  };

  const handleFileSelect = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    setError(null);
    setUploading(true);

    try {
      // Validar archivo
      const validationError = validateFile(file);
      if (validationError) {
        setError(validationError);
        return;
      }

      // Subir archivo
      await onUpload(file);
    } catch (err) {
      setError("Error al subir la imagen. Inténtalo de nuevo.");
      console.error("Upload error:", err);
    } finally {
      setUploading(false);
      // Limpiar input
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
    }
  };

  const handleRemoveImage = (imageUrl: string) => {
    if (onRemove) {
      onRemove(imageUrl);
    }
  };

  const totalImages = existingImages.length;
  const canUpload = totalImages < maxImages && !uploading;

  return (
    <div className={`space-y-3 ${className}`}>
      {/* Botón de subir */}
      <div className="flex items-center gap-3">
        <label
          className={`px-3 py-2 rounded-lg text-sm font-medium transition-all cursor-pointer flex items-center gap-2 ${
            canUpload
              ? "bg-blue-50 text-blue-600 hover:bg-blue-100"
              : "bg-gray-100 text-gray-400 cursor-not-allowed"
          }`}
        >
          <Upload className="w-4 h-4" />
          {uploading ? "Subiendo..." : "Subir Imagen"}
          <input
            ref={fileInputRef}
            type="file"
            accept="image/jpeg,image/jpg,image/png,image/webp"
            onChange={handleFileSelect}
            disabled={!canUpload || uploading}
            className="hidden"
          />
        </label>

        <span className="text-xs text-gray-500">
          {totalImages}/{maxImages} imágenes • Máx {maxSizeMB}MB
        </span>
      </div>

      {/* Mensaje de error */}
      {error && (
        <div className="flex items-center gap-2 p-2 bg-red-50 border border-red-200 rounded-lg">
          <AlertCircle className="w-4 h-4 text-red-600 flex-shrink-0" />
          <span className="text-sm text-red-700">{error}</span>
        </div>
      )}

      {/* Imágenes existentes */}
      {existingImages.length > 0 && (
        <div className="grid grid-cols-2 gap-2">
          {existingImages.map((imageUrl, index) => (
            <div key={index} className="relative group">
              <img
                src={imageUrl}
                alt={`Imagen ${index + 1}`}
                className="w-full h-20 object-cover rounded-lg border border-gray-200"
              />
              {onRemove && (
                <button
                  onClick={() => handleRemoveImage(imageUrl)}
                  className="absolute top-1 right-1 p-1 bg-red-500 text-white rounded-full opacity-0 group-hover:opacity-100 transition-opacity"
                  title="Eliminar imagen"
                >
                  <X className="w-3 h-3" />
                </button>
              )}
            </div>
          ))}
        </div>
      )}

      {/* Información adicional */}
      <div className="text-xs text-gray-500 space-y-1">
        <p>• Formatos permitidos: JPG, PNG, WebP</p>
        <p>• Tamaño máximo por imagen: {maxSizeMB}MB</p>
        <p>
          • Máximo {maxImages} imágenes por{" "}
          {existingImages.length > 0 ? "comentario" : "tarea"}
        </p>
      </div>
    </div>
  );
}
