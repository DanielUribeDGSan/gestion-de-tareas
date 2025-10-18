# Instrucciones para Habilitar Asignación de Usuarios

## Problema Identificado

En el modal "Crear Nueva Tarea", la sección "Asignar a" solo muestra "Sin asignar" y no lista los usuarios disponibles para asignación.

## Causa del Problema

1. **Tabla faltante**: No existe la tabla `user_profiles` en la base de datos
2. **Campo faltante**: La tabla `tasks` no tiene el campo `assigned_to`
3. **Funcionalidad incompleta**: La aplicación no está configurada para manejar asignaciones

## Soluciones Implementadas

### 1. Script SQL para Base de Datos ✅

- **Archivo creado**: `create_user_profiles.sql`
- **Contenido**:
  - Crea tabla `user_profiles`
  - Agrega campo `assigned_to` a tabla `tasks`
  - Configura políticas de seguridad
  - Crea trigger para perfiles automáticos

### 2. Actualización de Tipos ✅

- **Archivo**: `src/lib/supabase.ts`
- **Cambio**: Agregado campo `assigned_to: string | null` al tipo `Task`

### 3. Actualización de Funciones ✅

- **Archivo**: `src/App.tsx`
- **Cambios**:
  - Función `handleCreateTask` actualizada para incluir `assignedTo`
  - Función `handleCreateTaskSubmit` actualizada para pasar `assignedTo`

## Pasos para Completar la Solución

### Paso 1: Ejecutar Script SQL

Ejecuta el siguiente script en el SQL Editor de Supabase:

```sql
-- Copia y pega el contenido del archivo create_user_profiles.sql
-- en el SQL Editor de Supabase
```

### Paso 2: Verificar que Funciona

1. Inicia sesión con cualquier usuario
2. Crea una nueva tarea
3. En la sección "Asignar a" deberías ver:
   - "Sin asignar" (opción por defecto)
   - Lista de todos los usuarios registrados
4. Selecciona un usuario y crea la tarea
5. Verifica que la tarea se creó con la asignación correcta

## Funcionalidades Implementadas

### ✅ **Tabla de Perfiles de Usuarios**

- Se crea automáticamente cuando un usuario se registra
- Contiene: `id`, `user_id`, `email`, `full_name`
- Políticas de seguridad configuradas

### ✅ **Campo de Asignación en Tareas**

- Campo `assigned_to` agregado a la tabla `tasks`
- Referencia a `user_profiles.id`
- Permite asignar tareas a usuarios específicos

### ✅ **Trigger Automático**

- Cuando un usuario se registra, se crea automáticamente su perfil
- No requiere intervención manual

### ✅ **Políticas de Seguridad**

- Todos los usuarios pueden ver todos los perfiles
- Los usuarios pueden modificar solo su propio perfil
- Las tareas asignadas respetan las políticas existentes

## Archivos Creados/Modificados

### Nuevos Archivos:

- `create_user_profiles.sql` - Script para configurar asignación de usuarios
- `INSTRUCCIONES_ASIGNACION_USUARIOS.md` - Esta documentación

### Archivos Modificados:

- `src/lib/supabase.ts` - Tipo `Task` actualizado
- `src/App.tsx` - Funciones de creación de tareas actualizadas

## Resultado Final

Después de ejecutar el script SQL:

1. **Los usuarios existentes** tendrán perfiles creados automáticamente
2. **Los nuevos usuarios** tendrán perfiles creados automáticamente al registrarse
3. **El modal de crear tarea** mostrará todos los usuarios disponibles para asignación
4. **Las tareas** podrán ser asignadas a usuarios específicos
5. **La funcionalidad de "Mis Tareas"** mostrará las tareas asignadas al usuario

## Notas Importantes

- Los perfiles se crean automáticamente para usuarios existentes
- Los nuevos usuarios tendrán perfiles creados al registrarse
- La asignación de tareas es opcional (puede quedar "Sin asignar")
- Todos los usuarios pueden ver y asignar tareas a cualquier usuario
