# Configuración de Supabase Storage para Imágenes

## Problema Identificado

Las imágenes no se muestran en las tareas porque el bucket de Supabase Storage `task-attachments` no está configurado correctamente.

## Solución Rápida

### Opción 1: Script SQL Automático (Recomendado)

1. Ve a tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard)
2. Navega a **SQL Editor** en el menú lateral
3. Copia y pega el contenido del archivo `setup_storage.sql`
4. Haz clic en **Run** para ejecutar el script
5. Verifica que aparezca el mensaje de éxito

### Opción 2: Configuración Manual

#### 1. Crear el Bucket en Supabase Dashboard

1. Ve a tu proyecto en [Supabase Dashboard](https://supabase.com/dashboard)
2. Navega a **Storage** en el menú lateral
3. Haz clic en **New bucket**
4. Configura el bucket con:
   - **Name**: `task-attachments`
   - **Public bucket**: ✅ (marcado)
   - **File size limit**: 50MB (o el límite que prefieras)
   - **Allowed MIME types**: `image/*`

#### 2. Configurar Políticas de Storage

Ejecuta estas políticas en el **SQL Editor** de Supabase:

```sql
-- Política para ver archivos
CREATE POLICY "Users can view attachments"
ON storage.objects FOR SELECT
USING (bucket_id = 'task-attachments');

-- Política para subir archivos
CREATE POLICY "Users can upload attachments"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'task-attachments' AND auth.uid() IS NOT NULL);

-- Política para eliminar archivos
CREATE POLICY "Users can delete own attachments"
ON storage.objects FOR DELETE
USING (bucket_id = 'task-attachments' AND auth.uid() IS NOT NULL);
```

## Verificación

### 1. Verificar la Configuración

1. Abre la consola del navegador (F12)
2. Inicia sesión en la aplicación
3. Busca los mensajes de verificación de Storage en la consola
4. Deberías ver: `✅ Bucket 'task-attachments' encontrado`

### 2. Probar la Subida de Imágenes

1. Crea una tarea
2. Abre la tarea haciendo clic en ella
3. Haz clic en "Subir" en la sección de Archivos Adjuntos
4. Selecciona una imagen
5. Verifica en la consola que aparezcan los mensajes de subida exitosa

## Mensajes de Debug Agregados

La aplicación ahora incluye logging detallado para diagnosticar problemas:

- ✅ Verificación automática del bucket al cargar la aplicación
- ✅ Logging de cada paso del proceso de subida
- ✅ Verificación de URLs públicas generadas
- ✅ Logging de archivos cargados al abrir tareas
- ✅ Alertas automáticas si el bucket no está configurado

## Solución de Problemas

### Si el bucket no existe:

- Crea el bucket `task-attachments` en Supabase Dashboard
- Asegúrate de que sea público
- Usa el script `setup_storage.sql` para configuración automática

### Si las políticas fallan:

- Verifica que las políticas de Storage estén configuradas correctamente
- Asegúrate de que el usuario esté autenticado
- Ejecuta el script SQL completo

### Si las imágenes no se cargan:

- Verifica en la consola del navegador los mensajes de error
- Comprueba que las URLs públicas se generen correctamente
- Verifica que el archivo se haya subido al bucket

## Archivos Creados/Modificados

- `src/App.tsx`: Agregado logging y verificación de Storage
- `src/components/TaskModal.tsx`: Ya incluía la funcionalidad de mostrar imágenes
- `src/components/ImageUpload.tsx`: Componente para subir imágenes (nuevo)
- `setup_storage.sql`: Script SQL para configuración automática
- `STORAGE_SETUP.md`: Esta documentación

## Próximos Pasos

1. **Ejecuta el script SQL** `setup_storage.sql` en Supabase Dashboard
2. **Recarga la aplicación** y verifica en la consola
3. **Prueba subir una imagen** en una tarea
4. **Verifica que aparezca** en la sección de Archivos Adjuntos
5. Si persisten problemas, revisa la consola del navegador para más detalles
