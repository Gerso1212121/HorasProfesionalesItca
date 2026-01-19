import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:horas2/Admin/Logic/Admin_AuditService.dart';
import 'package:horas2/DB/DatabaseHelper.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'Admin_MarkdownEditor.dart'; // Asegúrate de que la ruta sea correcta

class ModulosContent extends StatefulWidget {
  const ModulosContent({super.key});

  @override
  State<ModulosContent> createState() => _ModulosContentState();
}

class _ModulosContentState extends State<ModulosContent> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _modulos = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadModulos();
    _updateDatabaseSchema();
  }

  Future<void> _updateDatabaseSchema() async {
    try {
      await _databaseHelper.updateModuloImagenesSchema();
    } catch (e) {
      print('Error updating schema: $e');
      print('Error updating schema: $e');
    }
  }

  Future<void> _loadModulos() async {
    setState(() => _isLoading = true);
    try {
      final modulos = await _databaseHelper.readModulos();
      setState(() {
        _modulos = modulos;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading modulos: $e');
      setState(() => _isLoading = false);
      _showError('Error al cargar módulos: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredModulos {
    if (_searchQuery.isEmpty) return _modulos;
    return _modulos.where((modulo) {
      return modulo['titulo']
              ?.toLowerCase()
              .contains(_searchQuery.toLowerCase()) ??
          false;
    }).toList();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Future<void> _deleteModulo(String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar eliminación',
          style: GoogleFonts.itim(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar este módulo? También se eliminarán todos los archivos asociados.',
          style: GoogleFonts.itim(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: GoogleFonts.itim()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                Text('Eliminar', style: GoogleFonts.itim(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        // Eliminar archivos asociados
        final archivos = await _databaseHelper.getModuloArchivos(id);
        for (var archivo in archivos) {
          await _databaseHelper.deleteModuloImagenWithFile(archivo['id']);
        }

        final oldModulo = Map<String, dynamic>.from(
            _modulos.firstWhere((mod) => mod['id'] == id));
        // Eliminar el módulo
        await _databaseHelper.deleteModulo(id);

        // Si todo salió bien, log de auditoría
        AuditService.logAction(
          tableName: 'modulos',
          action: 'DELETE',
          recordId: id.toString(),
          oldValues: oldModulo,
          details: 'Eliminación de módulo con archivos asociados',
        );

        // Mostrar éxito al usuario
        if (mounted) {
          _showSuccess('Módulo eliminado exitosamente');
        }

        _loadModulos();
      } catch (e) {
        print('Error al eliminar módulo: $e');
        _showError('Error al eliminar módulo: $e');
      }
    }
  }

  Future<void> _pickFiles(String moduloId) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Seleccionar tipo de archivo', style: GoogleFonts.itim()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: Text('Imagen', style: GoogleFonts.itim()),
              onTap: () => Navigator.of(context).pop('image'),
            ),
            ListTile(
              leading: const Icon(Icons.videocam),
              title: Text('Video', style: GoogleFonts.itim()),
              onTap: () => Navigator.of(context).pop('video'),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: Text('Explorador de archivos', style: GoogleFonts.itim()),
              onTap: () => Navigator.of(context).pop('file'),
            ),
          ],
        ),
      ),
    );

    if (result == null) return;

    try {
      List<String> filePaths = [];

      if (result == 'image') {
        final ImagePicker picker = ImagePicker();
        final List<XFile> images = await picker.pickMultiImage();
        filePaths = images.map((image) => image.path).toList();
      } else if (result == 'video') {
        final ImagePicker picker = ImagePicker();
        final XFile? video =
            await picker.pickVideo(source: ImageSource.gallery);
        if (video != null) filePaths = [video.path];
      } else if (result == 'file') {
        FilePickerResult? fileResult = await FilePicker.platform.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: [
            'jpg',
            'jpeg',
            'png',
            'gif',
            'webp',
            'mp4',
            'avi',
            'mov',
            'wmv',
            'flv',
            'webm'
          ],
        );
        if (fileResult != null) {
          filePaths = fileResult.paths
              .where((path) => path != null)
              .cast<String>()
              .toList();
        }
      }

      if (filePaths.isEmpty) return;

      // Mostrar dialog de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Subiendo archivos...', style: GoogleFonts.itim()),
            ],
          ),
        ),
      );

      // Subir archivos
      int uploadedCount = 0;
      for (String filePath in filePaths) {
        final result = await _databaseHelper.createModuloImagenWithFile(
          filePath: filePath,
          moduloId: moduloId,
          orden: uploadedCount,
        );
        if (result != null) uploadedCount++;
      }

      Navigator.of(context).pop(); // Cerrar dialog de progreso

      if (uploadedCount > 0) {
        _showSuccess('$uploadedCount archivo(s) subido(s) exitosamente');
        setState(() {}); // Refrescar para mostrar los nuevos archivos
      } else {
        _showError('No se pudieron subir los archivos');
      }
    } catch (e) {
      print('Error al subir archivos: $e');
      Navigator.of(context).pop(); // Cerrar dialog de progreso si está abierto
      _showError('Error al subir archivos: $e');
    }
  }

  Future<void> _deleteFile(String archivoId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar eliminación', style: GoogleFonts.itim()),
        content: Text('¿Eliminar este archivo?', style: GoogleFonts.itim()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar', style: GoogleFonts.itim()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                Text('Eliminar', style: GoogleFonts.itim(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _databaseHelper.deleteModuloImagenWithFile(archivoId);
        _showSuccess('Archivo eliminado exitosamente');
        setState(() {}); // Refrescar la vista
      } catch (e) {
        _showError('Error al eliminar archivo: $e');
      }
    }
  }

void _showModuloDialog({Map<String, dynamic>? modulo}) {
  final isEditing = modulo != null;
  final titleController = TextEditingController(text: modulo?['titulo'] ?? '');
  final contenidoController = TextEditingController(text: modulo?['contenido'] ?? '');

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          // Ajuste al 30% del ancho de la pantalla
          width: MediaQuery.of(context).size.width * 0.4, 
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context, isEditing),
              const SizedBox(height: 24),

              // Campo del título
              TextField(
                controller: titleController,
                style: GoogleFonts.itim(),
                decoration: InputDecoration(
                  labelText: 'Título del Módulo *',
                  prefixIcon: const Icon(Icons.title, color: Colors.blue),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sección de archivos (Solo edición)
              if (isEditing) ...[
                _buildFileSection(modulo, contenidoController, setState),
                const SizedBox(height: 16),
              ],

              // Editor de Markdown
              Text(
                'Contenido del Módulo *',
                style: GoogleFonts.itim(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: MarkdownEditor(
                    controller: contenidoController,
                    hintText: 'Escribe aquí usando Markdown...',
                    onChanged: (value) => setState(() {}),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botones de acción
              _buildActionButtons(context, isEditing, modulo, titleController, contenidoController),
            ],
          ),
        ),
      ),
    ),
  );
}

// --- Widgets de Apoyo para Limpiar el Código ---

Widget _buildHeader(BuildContext context, bool isEditing) {
  return Row(
    children: [
      Icon(isEditing ? Icons.edit_note : Icons.add_task, color: Colors.blue, size: 28),
      const SizedBox(width: 10),
      Text(
        isEditing ? 'Editar Módulo' : 'Nuevo Módulo',
        style: GoogleFonts.itim(fontWeight: FontWeight.bold, fontSize: 24),
      ),
      const Spacer(),
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
        style: IconButton.styleFrom(hoverColor: Colors.red.withOpacity(0.1)),
      ),
    ],
  );
}

Widget _buildFileSection(Map<String, dynamic> modulo, TextEditingController controller, StateSetter setState) {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _databaseHelper.getModuloArchivos(modulo['id']),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const LinearProgressIndicator();
      
      return LinkedFilesWidget(
        moduloId: modulo['id'],
        archivos: snapshot.data!,
        onInsertImage: (markdownText) {
          final text = controller.text;
          final selection = controller.selection;
          final newText = text.replaceRange(
            selection.start != -1 ? selection.start : text.length,
            selection.end != -1 ? selection.end : text.length,
            markdownText,
          );
          controller.text = newText;
          setState(() {}); // Refrescar UI del diálogo
        },
        onDeleteFile: (id) => _deleteFile(id),
      );
    },
  );
}

Widget _buildActionButtons(BuildContext context, bool isEditing, dynamic modulo, TextEditingController title, TextEditingController content) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      if (isEditing) 
        OutlinedButton.icon(
          onPressed: () => _pickFiles(modulo['id']),
          icon: const Icon(Icons.attach_file),
          label: Text('Archivos', style: GoogleFonts.itim()),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
        ),
      const SizedBox(width: 12),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Cancelar', style: GoogleFonts.itim(color: Colors.grey)),
      ),
      const SizedBox(width: 12),
      ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          if (title.text.trim().isEmpty || content.text.trim().isEmpty) {
            _showError('Por favor completa los campos obligatorios');
            return;
          }
          // Lógica de guardado...
          _handleSave(context, isEditing, modulo, title.text, content.text);
        },
        child: Text(
          isEditing ? 'Guardar Cambios' : 'Crear Módulo',
          style: GoogleFonts.itim(color: Colors.white),
        ),
      ),
    ],
  );
}


Future<void> _handleSave(
  BuildContext context, 
  bool isEditing, 
  dynamic modulo, 
  String titulo, 
  String contenido
) async {
  try {
    // 1. Mostrar indicador de carga si la operación es lenta
    // (Opcional: podrías usar un CircularProgressIndicator)

    if (isEditing) {
      // Lógica de Actualización
      final moduloData = {
        'titulo': titulo.trim(),
        'contenido': contenido.trim(),
        'fecha_actualizacion': DateTime.now().toIso8601String(),
      };

      await _databaseHelper.updateModulo(modulo['id'], moduloData);
      _showSuccess('Módulo actualizado exitosamente');
    } else {
      // Lógica de Creación
      await _databaseHelper.createModulo(
        id: _generateId(), // Asegúrate de tener esta función definida
        titulo: titulo.trim(),
        contenido: contenido.trim(),
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );
      _showSuccess('Módulo creado exitosamente');
    }

    // 2. Cerrar el diálogo
    Navigator.of(context).pop();

    // 3. Refrescar la lista principal
    _loadModulos(); 

  } catch (e) {
    // Manejo de errores detallado
    debugPrint('Error en _handleSave: $e');
    _showError('Error al ${isEditing ? 'actualizar' : 'crear'} el módulo. Inténtalo de nuevo.');
  }
}
  Widget _buildFilePreview(Map<String, dynamic> archivo) {
    final tipoArchivo = archivo['tipo_archivo'] ?? 'unknown';
    final url = archivo['url'] ?? '';

    if (tipoArchivo == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: 100,
            height: 100,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image),
          ),
        ),
      );
    } else if (tipoArchivo == 'video') {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.play_circle_outline,
            color: Colors.white, size: 40),
      );
    } else {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.insert_drive_file, size: 40),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Header con búsqueda y botón crear
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Buscar módulos...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showModuloDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('Nuevo Módulo',
                    style: GoogleFonts.itim(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lista de módulos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredModulos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.school,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay módulos disponibles'
                                  : 'No se encontraron módulos',
                              style: GoogleFonts.itim(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, // <--- Aquí defines las 3 columnas
                          crossAxisSpacing:
                              16, // Espacio horizontal entre cards
                          mainAxisSpacing: 16, // Espacio vertical entre cards
                          childAspectRatio:
                              2, // Ajusta esto para cambiar el alto de la card
                        ),
                        itemCount: _filteredModulos.length,
                        itemBuilder: (context, index) {
                          final modulo = _filteredModulos[index];
                          final fechaCreacion =
                              DateTime.tryParse(modulo['fecha_creacion'] ?? '');

                          return Card(
                            elevation: 4,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            child: InkWell(
                              // Hace que toda la card sea clickeable
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _showModuloDialog(modulo: modulo),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Icono y Menú de opciones
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: const Icon(Icons.school,
                                              color: Color(0xFF10B981),
                                              size: 28),
                                        ),
                                        _buildPopupMenu(
                                            modulo), // Extraído para limpieza
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Título
                                    Text(
                                      modulo['titulo'] ?? 'Sin título',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.itim(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const Spacer(),

                                    // Fecha
                                    if (fechaCreacion != null)
                                      Row(
                                        children: [
                                          Icon(Icons.calendar_today,
                                              size: 12,
                                              color: Colors.green[400]),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${fechaCreacion.day}/${fechaCreacion.month}/${fechaCreacion.year}',
                                            style: GoogleFonts.itim(
                                              fontSize: 12,
                                              color: Colors.green[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopupMenu(Map<String, dynamic> modulo) {
    return PopupMenuButton(
      icon: const Icon(Icons.more_vert, size: 20, color: Colors.green),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [
        _buildMenuItem(Icons.edit, 'Editar', Colors.blue,
            () => _showModuloDialog(modulo: modulo)),
        _buildMenuItem(Icons.attach_file, 'Archivos', Colors.orange,
            () => _pickFiles(modulo['id'])),
        _buildMenuItem(Icons.delete, 'Eliminar', Colors.red,
            () => _deleteModulo(modulo['id'])),
      ],
    );
  }

  PopupMenuItem _buildMenuItem(
      IconData icon, String text, Color color, VoidCallback onTap) {
    return PopupMenuItem(
      onTap: () => Future.delayed(Duration.zero, onTap),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.itim()),
        ],
      ),
    );
  }
}
