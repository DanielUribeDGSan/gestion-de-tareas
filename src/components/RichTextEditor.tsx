import { Editor } from "@tinymce/tinymce-react";
import { useRef } from "react";

interface RichTextEditorProps {
  value: string;
  onChange: (content: string) => void;
  placeholder?: string;
  height?: number;
}

export function RichTextEditor({
  value,
  onChange,
  placeholder = "Escribe aquí...",
  height = 200,
}: RichTextEditorProps) {
  const editorRef = useRef<any>(null);

  return (
    <div className="border border-gray-300 rounded-lg overflow-hidden">
      <Editor
        onInit={(evt, editor) => (editorRef.current = editor)}
        value={value}
        onEditorChange={(content) => onChange(content)}
        apiKey="h483ogy2ssh8h5ptqqvygrcqafqy8gwy42sodkjdy499q4kb"
        init={{
          height: height,
          menubar: false,
          plugins: [
            "advlist",
            "autolink",
            "lists",
            "link",
            "image",
            "charmap",
            "preview",
            "anchor",
            "searchreplace",
            "visualblocks",
            "code",
            "fullscreen",
            "insertdatetime",
            "media",
            "table",
            "help",
            "wordcount",
            "codesample",
          ],
          toolbar:
            "undo redo | blocks | " +
            "bold italic forecolor backcolor | alignleft aligncenter " +
            "alignright alignjustify | bullist numlist outdent indent | " +
            "removeformat | codesample | code | help",
          content_style:
            "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; font-size: 14px; } " +
            "h1 { font-size: 1.875rem; font-weight: 700; color: #111827; margin: 1.5rem 0 1rem 0; line-height: 1.2; } " +
            "h2 { font-size: 1.5rem; font-weight: 700; color: #111827; margin: 1.25rem 0 0.75rem 0; line-height: 1.2; } " +
            "h3 { font-size: 1.25rem; font-weight: 600; color: #111827; margin: 1rem 0 0.75rem 0; line-height: 1.2; } " +
            "h4 { font-size: 1.125rem; font-weight: 600; color: #111827; margin: 0.75rem 0 0.5rem 0; line-height: 1.2; } " +
            "h5 { font-size: 1rem; font-weight: 600; color: #111827; margin: 0.75rem 0 0.5rem 0; line-height: 1.2; } " +
            "p { color: #374151; margin-bottom: 0.75rem; line-height: 1.6; } " +
            "strong { font-weight: 600; color: #111827; } " +
            "em { font-style: italic; color: #1f2937; } " +
            "code { background-color: #f3f4f6; color: #1f2937; padding: 0.125rem 0.375rem; border-radius: 0.25rem; font-size: 0.875rem; font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace; } " +
            "pre { background-color: #111827; color: #f3f4f6; padding: 1rem; border-radius: 0.5rem; overflow-x: auto; margin-bottom: 1rem; } " +
            "pre code { background-color: transparent; color: #f3f4f6; padding: 0; } " +
            "ul { list-style-type: disc; margin-left: 1.5rem; margin-bottom: 0.75rem; } " +
            "ol { list-style-type: decimal; margin-left: 1.5rem; margin-bottom: 0.75rem; } " +
            "li { color: #374151; margin-bottom: 0.25rem; } " +
            "blockquote { border-left: 4px solid #3b82f6; padding-left: 1rem; font-style: italic; color: #6b7280; margin-bottom: 1rem; } " +
            "a { color: #2563eb; text-decoration: underline; } " +
            "a:hover { color: #1d4ed8; }",
          placeholder: placeholder,
          branding: false,
          statusbar: false,
          resize: false,
          setup: (editor) => {
            editor.on("init", () => {
              editor.getContainer().style.border = "none";
            });
          },
        }}
      />
    </div>
  );
}
