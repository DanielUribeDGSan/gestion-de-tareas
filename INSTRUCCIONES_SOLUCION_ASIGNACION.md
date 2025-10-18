# 🔧 SOLUCIÓN PARA ASIGNACIÓN DE TAREAS

## ❌ Problema Identificado

El error que estás viendo:

```
"insert or update on table "tasks" violates foreign key constraint "tasks_assigned_to_fkey"
Key is not present in table "users"."
```

Indica que:

1. La tabla `tasks` tiene un campo `assigned_to` que referencia una tabla que no existe o no tiene datos
2. El campo `assigned_to` debe referenciar `user_profiles(id)`, no `auth.users(id)`
3. La tabla `user_profiles` no existe o no tiene los datos necesarios

## ✅ Solución

### Paso 1: Ejecutar Script de Corrección

1. Ve al **SQL Editor** de Supabase
2. Copia y ejecuta el contenido del archivo `solucion_asignacion_tareas.sql`
3. Este script:
   - Crea la tabla `user_profiles` si no existe
   - Agrega el campo `assigned_to` a la tabla `tasks` si no existe
   - Configura la foreign key correcta
   - Actualiza las políticas de seguridad
   - Inserta perfiles para usuarios existentes

### Paso 2: Verificar la Corrección

1. Ejecuta el contenido del archivo `verificar_asignacion_tareas.sql`
2. Verifica que todas las consultas muestren datos correctos
3. Si hay errores, revisa los mensajes y ejecuta las correcciones necesarias

## 🎯 Qué se Corrige

### 1. Estructura de Base de Datos

- ✅ Tabla `user_profiles` creada con estructura correcta
- ✅ Campo `assigned_to` agregado a `tasks` con foreign key correcta
- ✅ Índices creados para optimizar consultas

### 2. Políticas de Seguridad

- ✅ Los usuarios pueden ver tareas de sus proyectos
- ✅ Los usuarios pueden ver tareas asignadas a ellos
- ✅ Los usuarios pueden actualizar tareas asignadas a ellos
- ✅ Solo el dueño del proyecto puede crear/eliminar tareas

### 3. Funcionalidad

- ✅ Asignación de tareas a usuarios específicos
- ✅ Visibilidad de tareas asignadas para todos los usuarios relevantes
- ✅ Función para obtener usuarios disponibles para asignación

## 🔍 Verificaciones Importantes

Después de ejecutar la corrección, verifica que:

1. **La tabla `user_profiles` existe y tiene datos**
2. **El campo `assigned_to` existe en `tasks`**
3. **La foreign key constraint está configurada correctamente**
4. **Las políticas de seguridad permiten la visibilidad correcta**

## 🚀 Cómo Funciona Ahora

### Para el Usuario que Crea la Tarea:

- Puede asignar la tarea a cualquier usuario registrado
- La tarea aparece en su proyecto

### Para el Usuario Asignado:

- Puede ver la tarea en el proyecto donde fue creada
- Puede actualizar la tarea (mover, editar, etc.)
- Recibe notificaciones de cambios

### Para Otros Usuarios del Proyecto:

- Pueden ver todas las tareas del proyecto, incluyendo las asignadas
- Pueden ver quién está asignado a cada tarea

## 📝 Notas Importantes

- La asignación de tareas usa `user_profiles.id`, no `auth.users.id`
- Las tareas asignadas son visibles para todos los usuarios del proyecto
- El usuario asignado puede actualizar la tarea pero no eliminarla
- Solo el dueño del proyecto puede eliminar tareas

## 🆘 Si Sigues Teniendo Problemas

1. Verifica que ejecutaste el script completo
2. Revisa los mensajes de error en el SQL Editor
3. Ejecuta el script de verificación para diagnosticar problemas
4. Asegúrate de que hay usuarios registrados en `auth.users`

---

**¡Después de ejecutar estos scripts, la asignación de tareas debería funcionar correctamente!** 🎉
