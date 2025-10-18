import { X, ChevronLeft, ChevronRight, Download } from "lucide-react";
import { useState, useEffect } from "react";

interface ImageModalProps {
  isOpen: boolean;
  onClose: () => void;
  images: string[];
  initialIndex?: number;
  imageNames?: string[];
}

export function ImageModal({
  isOpen,
  onClose,
  images,
  initialIndex = 0,
  imageNames = [],
}: ImageModalProps) {
  const [currentIndex, setCurrentIndex] = useState(initialIndex);

  // Actualizar el índice cuando cambie initialIndex
  useEffect(() => {
    setCurrentIndex(initialIndex);
  }, [initialIndex]);

  // Manejar navegación con teclado
  useEffect(() => {
    if (!isOpen) return;

    const handleKeyDown = (e: KeyboardEvent) => {
      switch (e.key) {
        case "Escape":
          onClose();
          break;
        case "ArrowLeft":
          e.preventDefault();
          goToPrevious();
          break;
        case "ArrowRight":
          e.preventDefault();
          goToNext();
          break;
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [isOpen, onClose]);

  const goToPrevious = () => {
    setCurrentIndex((prev) => (prev > 0 ? prev - 1 : images.length - 1));
  };

  const goToNext = () => {
    setCurrentIndex((prev) => (prev < images.length - 1 ? prev + 1 : 0));
  };

  const handleDownload = async () => {
    try {
      const imageUrl = images[currentIndex];
      const response = await fetch(imageUrl);
      const blob = await response.blob();

      const url = window.URL.createObjectURL(blob);
      const link = document.createElement("a");
      link.href = url;

      // Usar el nombre del archivo si está disponible, sino un nombre genérico
      const fileName = imageNames[currentIndex] || `imagen-${currentIndex + 1}`;
      link.download = fileName;

      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      window.URL.revokeObjectURL(url);
    } catch (error) {
      console.error("Error al descargar imagen:", error);
    }
  };

  if (!isOpen || images.length === 0) return null;

  const currentImage = images[currentIndex];
  const currentName = imageNames[currentIndex] || `Imagen ${currentIndex + 1}`;

  return (
    <div className="fixed inset-0 bg-black/90 backdrop-blur-sm flex items-center justify-center z-[60] p-4">
      <div className="relative w-full h-full max-w-7xl max-h-full flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-4 bg-black/50 text-white">
          <div className="flex items-center gap-4">
            <span className="text-sm font-medium">
              {currentIndex + 1} de {images.length}
            </span>
            <span className="text-sm text-gray-300 truncate max-w-md">
              {currentName}
            </span>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={handleDownload}
              className="p-2 text-gray-300 hover:text-white hover:bg-white/10 rounded-lg transition-all"
              title="Descargar imagen"
            >
              <Download className="w-5 h-5" />
            </button>
            <button
              onClick={onClose}
              className="p-2 text-gray-300 hover:text-white hover:bg-white/10 rounded-lg transition-all"
              title="Cerrar"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Imagen principal */}
        <div className="flex-1 flex items-center justify-center relative overflow-hidden">
          <img
            src={currentImage}
            alt={currentName}
            className="max-w-full max-h-full object-contain"
            style={{ maxHeight: "calc(100vh - 120px)" }}
          />

          {/* Navegación */}
          {images.length > 1 && (
            <>
              {/* Botón anterior */}
              <button
                onClick={goToPrevious}
                className="absolute left-4 top-1/2 -translate-y-1/2 p-3 bg-black/50 text-white rounded-full hover:bg-black/70 transition-all backdrop-blur-sm"
                title="Imagen anterior"
              >
                <ChevronLeft className="w-6 h-6" />
              </button>

              {/* Botón siguiente */}
              <button
                onClick={goToNext}
                className="absolute right-4 top-1/2 -translate-y-1/2 p-3 bg-black/50 text-white rounded-full hover:bg-black/70 transition-all backdrop-blur-sm"
                title="Imagen siguiente"
              >
                <ChevronRight className="w-6 h-6" />
              </button>
            </>
          )}
        </div>

        {/* Miniaturas */}
        {images.length > 1 && (
          <div className="p-4 bg-black/50 flex justify-center">
            <div className="flex gap-2 max-w-full overflow-x-auto">
              {images.map((image, index) => (
                <button
                  key={index}
                  onClick={() => setCurrentIndex(index)}
                  className={`relative flex-shrink-0 w-16 h-16 rounded-lg overflow-hidden border-2 transition-all ${
                    index === currentIndex
                      ? "border-blue-500 ring-2 ring-blue-500/50"
                      : "border-gray-600 hover:border-gray-400"
                  }`}
                >
                  <img
                    src={image}
                    alt={`Miniatura ${index + 1}`}
                    className="w-full h-full object-cover"
                  />
                </button>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
