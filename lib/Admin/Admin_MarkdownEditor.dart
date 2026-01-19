import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownEditor extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final double height;
  final Function(String)? onChanged;

  const MarkdownEditor({
    Key? key,
    required this.controller,
    this.hintText,
    this.height = 400,
    this.onChanged,
  }) : super(key: key);

  @override
  State<MarkdownEditor> createState() => _MarkdownEditorState();
}

class _MarkdownEditorState extends State<MarkdownEditor>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isPreviewMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _isPreviewMode = _tabController.index == 1;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _insertMarkdown(String before, [String? after]) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final start = selection.baseOffset;
    final end = selection.extentOffset;

    String newText;
    int newCursorPos;

    if (start == end) {
      // No hay selección, insertar en la posición del cursor
      newText = text.substring(0, start) +
          before +
          (after ?? '') +
          text.substring(start);
      newCursorPos = start + before.length;
    } else {
      // Hay texto seleccionado, envolver la selección
      final selectedText = text.substring(start, end);
      newText = text.substring(0, start) +
          before +
          selectedText +
          (after ?? '') +
          text.substring(end);
      newCursorPos =
          start + before.length + selectedText.length + (after?.length ?? 0);
    }

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorPos),
    );

    if (widget.onChanged != null) {
      widget.onChanged!(newText);
    }
  }

  void _insertList(String prefix) {
    final text = widget.controller.text;
    final selection = widget.controller.selection;
    final start = selection.baseOffset;

    // Encontrar el inicio de la línea actual
    int lineStart = text.lastIndexOf('\n', start - 1) + 1;

    final newText =
        text.substring(0, lineStart) + prefix + ' ' + text.substring(lineStart);
    final newCursorPos = start + prefix.length + 1;

    widget.controller.text = newText;
    widget.controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newCursorPos),
    );

    if (widget.onChanged != null) {
      widget.onChanged!(newText);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                // Bold
                _buildToolbarButton(
                  icon: Icons.format_bold,
                  tooltip: 'Negrita',
                  onPressed: () => _insertMarkdown('**', '**'),
                ),
                // Italic
                _buildToolbarButton(
                  icon: Icons.format_italic,
                  tooltip: 'Cursiva',
                  onPressed: () => _insertMarkdown('*', '*'),
                ),
                const VerticalDivider(),
                // Heading 1
                _buildToolbarButton(
                  icon: Icons.title,
                  tooltip: 'Título 1',
                  onPressed: () => _insertMarkdown('# '),
                ),
                // Heading 2
                _buildToolbarButton(
                  icon: Icons.text_fields,
                  tooltip: 'Título 2',
                  onPressed: () => _insertMarkdown('## '),
                ),
                const VerticalDivider(),
                // Unordered List
                _buildToolbarButton(
                  icon: Icons.format_list_bulleted,
                  tooltip: 'Lista con viñetas',
                  onPressed: () => _insertList('-'),
                ),
                // Ordered List
                _buildToolbarButton(
                  icon: Icons.format_list_numbered,
                  tooltip: 'Lista numerada',
                  onPressed: () => _insertList('1.'),
                ),
                const VerticalDivider(),
                // Link
                _buildToolbarButton(
                  icon: Icons.link,
                  tooltip: 'Enlace',
                  onPressed: () => _insertMarkdown('[', '](url)'),
                ),
                // Image
                _buildToolbarButton(
                  icon: Icons.image,
                  tooltip: 'Imagen',
                  onPressed: () => _insertMarkdown('![', '](url)'),
                ),
                const VerticalDivider(),
                // Code
                _buildToolbarButton(
                  icon: Icons.code,
                  tooltip: 'Código',
                  onPressed: () => _insertMarkdown('`', '`'),
                ),
                // Quote
                _buildToolbarButton(
                  icon: Icons.format_quote,
                  tooltip: 'Cita',
                  onPressed: () => _insertMarkdown('> '),
                ),
                const Spacer(),
                // Tab Controller
                SizedBox(
                  width: 120,
                  child: TabBar(
                    controller: _tabController,
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.grey,
                    tabs: const [
                      Tab(text: 'Editar'),
                      Tab(text: 'Vista'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content Area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Editor Tab
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: widget.controller,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: GoogleFonts.sourceCodePro(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: widget.hintText ??
                          'Escribe tu contenido en Markdown...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey[400]),
                    ),
                    onChanged: widget.onChanged,
                  ),
                ),
                // Preview Tab
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Markdown(
                    data: widget.controller.text.isEmpty
                        ? '*Vista previa del contenido...*'
                        : widget.controller.text,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.inter(fontSize: 14),
                      h1: GoogleFonts.inter(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      h2: GoogleFonts.inter(
                          fontSize: 20, fontWeight: FontWeight.bold),
                      h3: GoogleFonts.inter(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      code: GoogleFonts.sourceCodePro(
                        fontSize: 12,
                        backgroundColor: Colors.grey[100],
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: const EdgeInsets.all(4),
        splashRadius: 16,
      ),
    );
  }
}

// Widget auxiliar para mostrar archivos vinculados durante la edición
class LinkedFilesWidget extends StatelessWidget {
  final String moduloId;
  final List<Map<String, dynamic>> archivos;
  final Function(String) onInsertImage;
  final Function(String) onDeleteFile;

  const LinkedFilesWidget({
    Key? key,
    required this.moduloId,
    required this.archivos,
    required this.onInsertImage,
    required this.onDeleteFile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (archivos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            'No hay archivos vinculados a este módulo',
            style: GoogleFonts.itim(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.attachment, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Archivos vinculados (${archivos.length})',
                  style: GoogleFonts.itim(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  'Haz clic para insertar en el contenido',
                  style:
                      GoogleFonts.itim(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: archivos.map((archivo) {
                final tipoArchivo = archivo['tipo_archivo'] ?? 'unknown';
                final url = archivo['url'] ?? '';
                final nombre = archivo['nombre_archivo'] ?? 'archivo';

                return Tooltip(
                  message:
                      'Clic: insertar en contenido\nClic largo: eliminar archivo',
                  child: GestureDetector(
                    onTap: () {
                      if (tipoArchivo == 'image') {
                        onInsertImage('![Imagen]($url)');
                      } else if (tipoArchivo == 'video') {
                        onInsertImage('[![Video]($url)]($url)');
                      }
                    },
                    onLongPress: () => onDeleteFile(archivo['id']),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildFilePreview(tipoArchivo, url),
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(8),
                                  bottomRight: Radius.circular(8),
                                ),
                              ),
                              child: Text(
                                _getFileExtension(nombre),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(String tipoArchivo, String url) {
    if (tipoArchivo == 'image') {
      return Image.network(
        url,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 80,
          height: 80,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image),
        ),
      );
    } else if (tipoArchivo == 'video') {
      return Container(
        width: 80,
        height: 80,
        color: Colors.black87,
        child: const Icon(Icons.play_circle_outline,
            color: Colors.white, size: 30),
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        color: Colors.grey[300],
        child: const Icon(Icons.insert_drive_file, size: 30),
      );
    }
  }

  String _getFileExtension(String fileName) {
    return fileName.split('.').last.toUpperCase();
  }
}
