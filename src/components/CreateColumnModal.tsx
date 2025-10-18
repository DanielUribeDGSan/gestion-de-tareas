import { X } from 'lucide-react';
import { useState } from 'react';

interface CreateColumnModalProps {
  onClose: () => void;
  onCreate: (name: string, color: string) => void;
}

const COLORS = [
  { value: '#ef4444', label: 'Rojo' },
  { value: '#f59e0b', label: 'Naranja' },
  { value: '#eab308', label: 'Amarillo' },
  { value: '#22c55e', label: 'Verde' },
  { value: '#06b6d4', label: 'Cyan' },
  { value: '#3b82f6', label: 'Azul' },
  { value: '#8b5cf6', label: 'Morado' },
  { value: '#ec4899', label: 'Rosa' },
];

export function CreateColumnModal({ onClose, onCreate }: CreateColumnModalProps) {
  const [name, setName] = useState('');
  const [color, setColor] = useState(COLORS[5].value);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (name.trim()) {
      onCreate(name, color);
      onClose();
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md">
        <div className="p-6 border-b border-gray-200 flex items-center justify-between">
          <h2 className="text-xl font-bold text-gray-800">Crear Nueva Columna</h2>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-all"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label htmlFor="name" className="block text-sm font-medium text-gray-700 mb-2">
              Nombre de la Columna
            </label>
            <input
              id="name"
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full px-4 py-2.5 bg-gray-50 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Por hacer"
              required
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">Color</label>
            <div className="grid grid-cols-4 gap-2">
              {COLORS.map((c) => (
                <button
                  key={c.value}
                  type="button"
                  onClick={() => setColor(c.value)}
                  className={`h-10 rounded-xl transition-all ${
                    color === c.value ? 'ring-2 ring-offset-2 ring-gray-400 scale-110' : 'hover:scale-105'
                  }`}
                  style={{ backgroundColor: c.value }}
                  title={c.label}
                />
              ))}
            </div>
          </div>

          <div className="flex gap-3">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-4 py-2.5 border border-gray-300 text-gray-700 rounded-xl hover:bg-gray-50 transition-all font-medium"
            >
              Cancelar
            </button>
            <button
              type="submit"
              className="flex-1 px-4 py-2.5 bg-gradient-to-r from-blue-500 to-purple-600 text-white rounded-xl hover:from-blue-600 hover:to-purple-700 transition-all font-medium"
            >
              Crear
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
