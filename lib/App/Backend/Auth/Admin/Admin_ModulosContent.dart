import 'package:ai_app_tests/App/Services/Logs/Services_Log.dart';
import 'package:ai_app_tests/App/Backend/Auth/Admin/Logic/Admin_AuditService.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../Data/DataBase/DatabaseHelper.dart';
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
      LogService.log('Error updating schema: $e');
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
      LogService.log('Error loading modulos: $e');
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
        LogService.log('Error al eliminar módulo: $e');
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
      LogService.log('Error al subir archivos: $e');
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
    final titleController =
        TextEditingController(text: modulo?['titulo'] ?? '');
    final contenidoController =
        TextEditingController(text: modulo?['contenido'] ?? '');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del diálogo
              Row(
                children: [
                  Text(
                    isEditing ? 'Editar Módulo' : 'Nuevo Módulo',
                    style: GoogleFonts.itim(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Campo del título
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'Título *',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sección de archivos vinculados (solo en modo edición)
              if (isEditing) ...[
                FutureBuilder<List<Map<String, dynamic>>>(
                  future: _databaseHelper.getModuloArchivos(modulo['id']),
                  builder: (context, snapshot) {
                    final archivos = snapshot.data ?? [];
                    return LinkedFilesWidget(
                      moduloId: modulo['id'],
                      archivos: archivos,
                      onInsertImage: (markdownText) {
                        final currentText = contenidoController.text;
                        final selection = contenidoController.selection;
                        final newText =
                            currentText.substring(0, selection.baseOffset) +
                                markdownText +
                                currentText.substring(selection.extentOffset);
                        contenidoController.text = newText;
                        contenidoController.selection =
                            TextSelection.fromPosition(
                          TextPosition(
                              offset:
                                  selection.baseOffset + markdownText.length),
                        );
                      },
                      onDeleteFile: (archivoId) {
                        _deleteFile(archivoId);
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Editor de Markdown
              Text(
                'Contenido *',
                style: GoogleFonts.itim(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: MarkdownEditor(
                  controller: contenidoController,
                  hintText: 'Escribe el contenido del módulo en Markdown...',
                  onChanged: (value) {
                    // Aquí puedes agregar lógica adicional si necesitas
                    // reaccionar a cambios en el contenido
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isEditing) ...[
                    ElevatedButton.icon(
                      onPressed: () => _pickFiles(modulo['id']),
                      icon: const Icon(Icons.attach_file),
                      label: Text('Subir archivos', style: GoogleFonts.itim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancelar', style: GoogleFonts.itim()),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty ||
                          contenidoController.text.trim().isEmpty) {
                        _showError(
                            'Título y Contenido son campos obligatorios');
                        return;
                      }

                      try {
                        if (isEditing) {
                          final moduloData = {
                            'titulo': titleController.text.trim(),
                            'contenido': contenidoController.text.trim(),
                            'fecha_actualizacion':
                                DateTime.now().toIso8601String(),
                          };
                          await _databaseHelper.updateModulo(
                              modulo['id'], moduloData);
                          _showSuccess('Módulo actualizado exitosamente');
                        } else {
                          await _databaseHelper.createModulo(
                            id: _generateId(),
                            titulo: titleController.text.trim(),
                            contenido: contenidoController.text.trim(),
                            fechaCreacion: DateTime.now(),
                            fechaActualizacion: DateTime.now(),
                          );
                          _showSuccess('Módulo creado exitosamente');
                        }
                        Navigator.of(context).pop();
                        _loadModulos();
                      } catch (e) {
                        _showError(
                            'Error al ${isEditing ? 'actualizar' : 'crear'} módulo: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                    ),
                    child: Text(
                      isEditing ? 'Actualizar' : 'Crear',
                      style: GoogleFonts.itim(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                    : ListView.builder(
                        itemCount: _filteredModulos.length,
                        itemBuilder: (context, index) {
                          final modulo = _filteredModulos[index];
                          final fechaCreacion =
                              DateTime.tryParse(modulo['fecha_creacion'] ?? '');
                          final fechaActualizacion = DateTime.tryParse(
                              modulo['fecha_actualizacion'] ?? '');

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFF10B981),
                                child: Icon(
                                  Icons.school,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                modulo['titulo'] ?? 'Sin título',
                                style: GoogleFonts.itim(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (fechaCreacion != null)
                                    Text(
                                      'Creado: ${fechaCreacion.day}/${fechaCreacion.month}/${fechaCreacion.year}',
                                      style: GoogleFonts.itim(fontSize: 12),
                                    ),
                                  if (fechaActualizacion != null &&
                                      fechaActualizacion != fechaCreacion)
                                    Text(
                                      'Actualizado: ${fechaActualizacion.day}/${fechaActualizacion.month}/${fechaActualizacion.year}',
                                      style: GoogleFonts.itim(
                                          fontSize: 12, color: Colors.orange),
                                    ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.edit, size: 16),
                                        const SizedBox(width: 8),
                                        Text('Editar',
                                            style: GoogleFonts.itim()),
                                      ],
                                    ),
                                    onTap: () => Future.delayed(
                                      Duration.zero,
                                      () => _showModuloDialog(modulo: modulo),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.attach_file, size: 16),
                                        const SizedBox(width: 8),
                                        Text('Subir archivos',
                                            style: GoogleFonts.itim()),
                                      ],
                                    ),
                                    onTap: () => Future.delayed(
                                      Duration.zero,
                                      () => _pickFiles(modulo['id']),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    child: Row(
                                      children: [
                                        const Icon(Icons.delete,
                                            size: 16, color: Colors.red),
                                        const SizedBox(width: 8),
                                        Text('Eliminar',
                                            style: GoogleFonts.itim(
                                                color: Colors.red)),
                                      ],
                                    ),
                                    onTap: () => Future.delayed(
                                      Duration.zero,
                                      () => _deleteModulo(modulo['id']),
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Contenido del módulo con renderizado Markdown
                                      Text(
                                        'Vista previa del contenido:',
                                        style: GoogleFonts.itim(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        height: 200,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                        ),
                                        child: SingleChildScrollView(
                                          child: MarkdownEditor(
                                            controller: TextEditingController(
                                                text:
                                                    modulo['contenido'] ?? ''),
                                            height: 180,
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 16),

                                      // Sección de archivos multimedia
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Archivos multimedia:',
                                            style: GoogleFonts.itim(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _pickFiles(modulo['id']),
                                            icon:
                                                const Icon(Icons.add, size: 16),
                                            label: Text('Añadir',
                                                style: GoogleFonts.itim()),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(80, 32),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Grid de archivos
                                      FutureBuilder<List<Map<String, dynamic>>>(
                                        future: _databaseHelper
                                            .getModuloArchivos(modulo['id']),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child:
                                                    CircularProgressIndicator());
                                          }

                                          final archivos = snapshot.data ?? [];

                                          if (archivos.isEmpty) {
                                            return Container(
                                              padding: const EdgeInsets.all(16),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                    color: Colors.grey[300]!),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  'No hay archivos multimedia',
                                                  style: GoogleFonts.itim(
                                                      color: Colors.grey[600]),
                                                ),
                                              ),
                                            );
                                          }

                                          return Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: archivos.map((archivo) {
                                              return Stack(
                                                children: [
                                                  _buildFilePreview(archivo),
                                                  Positioned(
                                                    top: 4,
                                                    right: 4,
                                                    child: GestureDetector(
                                                      onTap: () => _deleteFile(
                                                          archivo['id']),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(4),
                                                        decoration:
                                                            const BoxDecoration(
                                                          color: Colors.red,
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: const Icon(
                                                          Icons.close,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }).toList(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
