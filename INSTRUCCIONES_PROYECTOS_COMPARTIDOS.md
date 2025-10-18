# Instrucciones para Habilitar Proyectos Compartidos

## Problema Identificado

Los usuarios 1 y 2 no pueden ver los proyectos que crearon juntos, solo pueden ver los proyectos que cada uno creó individualmente.

## Causa del Problema

1. **En la aplicación**: La función `loadProjects` en `App.tsx` estaba filtrando proyectos solo por `user_id` del usuario actual
2. **En la base de datos**: Las políticas de Supabase estaban configuradas para acceso restrictivo (solo propietarios)

## Soluciones Aplicadas

### 1. Modificación en la Aplicación ✅

- **Archivo**: `src/App.tsx`
- **Cambio**: Eliminé el filtro `.eq("user_id", user.id)` en la función `loadProjects`
- **Resultado**: Ahora la aplicación carga todos los proyectos disponibles

### 2. Políticas de Base de Datos (Pendiente de Aplicar)

- **Archivo creado**: `apply_shared_policies.sql`
- **Contenido**: Script SQL para aplicar políticas de acceso compartido

## Pasos para Completar la Solución

### Paso 1: Aplicar las Políticas de Supabase

Ejecuta el siguiente script en tu consola de Supabase SQL Editor:

```sql
-- Copia y pega el contenido del archivo apply_shared_policies.sql
-- en el SQL Editor de Supabase
```

### Paso 2: Verificar que Funciona

1. Inicia sesión con el Usuario 1
2. Verifica que puede ver todos los proyectos (incluyendo los del Usuario 2)
3. Inicia sesión con el Usuario 2
4. Verifica que puede ver todos los proyectos (incluyendo los del Usuario 1)

## Políticas Aplicadas

### Proyectos

- ✅ **Ver**: Todos los usuarios pueden ver todos los proyectos
- ✅ **Crear**: Solo el creador puede crear proyectos
- ✅ **Modificar**: Solo el propietario puede modificar sus proyectos
- ✅ **Eliminar**: Solo el propietario puede eliminar sus proyectos

### Columnas y Tareas

- ✅ **Ver**: Todos los usuarios pueden ver todas las columnas y tareas
- ✅ **Crear**: Todos los usuarios pueden crear columnas y tareas
- ✅ **Modificar**: Todos los usuarios pueden modificar cualquier columna o tarea
- ✅ **Eliminar**: Todos los usuarios pueden eliminar cualquier columna o tarea

### Comentarios y Adjuntos

- ✅ **Ver**: Todos los usuarios pueden ver todos los comentarios y adjuntos
- ✅ **Crear**: Solo el creador puede crear comentarios y adjuntos
- ✅ **Modificar**: Solo el creador puede modificar sus comentarios
- ✅ **Eliminar**: Solo el creador puede eliminar sus comentarios y adjuntos

## Archivos Modificados

- `src/App.tsx` - Función `loadProjects` actualizada
- `apply_shared_policies.sql` - Script para aplicar políticas compartidas

## Notas Importantes

- Los proyectos siguen siendo propiedad del usuario que los creó
- Solo el propietario puede eliminar un proyecto
- Todos los usuarios pueden colaborar en columnas y tareas
- Los comentarios y adjuntos mantienen la propiedad del creador
