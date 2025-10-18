import {
  LayoutDashboard,
  Plus,
  LogOut,
  FolderKanban,
  Trash2,
} from "lucide-react";
import { Project } from "../lib/supabase";

interface SidebarProps {
  projects: Project[];
  selectedProject: Project | null;
  onSelectProject: (project: Project) => void;
  onCreateProject: () => void;
  onDeleteProject: (project: Project) => void;
  onSignOut: () => void;
  userEmail: string;
}

export function Sidebar({
  projects,
  selectedProject,
  onSelectProject,
  onCreateProject,
  onDeleteProject,
  onSignOut,
  userEmail,
}: SidebarProps) {
  return (
    <div className="w-72 bg-white border-r border-gray-200 flex flex-col h-screen">
      <div className="p-6 border-b border-gray-200">
        <div className="flex items-center gap-3 mb-6">
          <div className="bg-gradient-to-br from-blue-500 to-purple-600 p-2.5 rounded-xl">
            <LayoutDashboard className="w-5 h-5 text-white" />
          </div>
          <h1 className="text-xl font-bold text-gray-800">Capital Devs</h1>
        </div>

        <button
          onClick={onCreateProject}
          className="w-full bg-gradient-to-r from-blue-500 to-purple-600 text-white py-2.5 px-4 rounded-xl font-medium hover:from-blue-600 hover:to-purple-700 transition-all flex items-center justify-center gap-2 shadow-lg shadow-blue-500/25"
        >
          <Plus className="w-4 h-4" />
          Nuevo Proyecto
        </button>
      </div>

      <div className="flex-1 overflow-y-auto p-4">
        <h2 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-3 px-2">
          Mis Proyectos
        </h2>
        <div className="space-y-1">
          {projects.map((project) => (
            <div
              key={project.id}
              className={`w-full px-3 py-2.5 rounded-xl transition-all flex items-center gap-3 group ${
                selectedProject?.id === project.id
                  ? "bg-gradient-to-r from-blue-50 to-purple-50 text-blue-700 font-medium"
                  : "text-gray-700 hover:bg-gray-50"
              }`}
            >
              <button
                onClick={() => onSelectProject(project)}
                className="flex items-center gap-3 flex-1 text-left"
              >
                <FolderKanban
                  className={`w-4 h-4 ${
                    selectedProject?.id === project.id
                      ? "text-blue-600"
                      : "text-gray-400 group-hover:text-gray-600"
                  }`}
                />
                <span className="truncate">{project.name}</span>
              </button>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onDeleteProject(project);
                }}
                className="p-1.5 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all opacity-0 group-hover:opacity-100"
                title="Eliminar proyecto"
              >
                <Trash2 className="w-3.5 h-3.5" />
              </button>
            </div>
          ))}
        </div>
      </div>

      <div className="p-4 border-t border-gray-200">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-gradient-to-br from-blue-500 to-purple-600 rounded-full flex items-center justify-center">
              <span className="text-white text-sm font-medium">
                {userEmail.charAt(0).toUpperCase()}
              </span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-700 truncate">
                {userEmail}
              </p>
            </div>
          </div>
          <button
            onClick={onSignOut}
            className="p-2 text-gray-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-all"
            title="Cerrar sesión"
          >
            <LogOut className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}
