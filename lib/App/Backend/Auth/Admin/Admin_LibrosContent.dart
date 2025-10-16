import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Data/DataBase/DatabaseHelper.dart';

class LibrosContent extends StatefulWidget {
  const LibrosContent({super.key});

  @override
  State<LibrosContent> createState() => _LibrosContentState();
}

class _LibrosContentState extends State<LibrosContent> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _libros = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadLibros();
  }

  Future<void> _loadLibros() async {
    setState(() => _isLoading = true);
    try {
      final libros = await _databaseHelper.readLibros();
      setState(() {
        _libros = libros;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Error al cargar libros: $e');
    }
  }

  List<Map<String, dynamic>> get _filteredLibros {
    if (_searchQuery.isEmpty) return _libros;
    return _libros.where((libro) {
      return libro['nombre']
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

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Future<void> _deleteLibro(String id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmar eliminación',
          style: GoogleFonts.itim(fontWeight: FontWeight.bold),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar este libro?',
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
        await _databaseHelper.deleteLibro(id);
        _showSuccess('Libro eliminado exitosamente');
        _loadLibros();
      } catch (e) {
        _showError('Error al eliminar libro: $e');
      }
    }
  }

  void _showLibroDialog({Map<String, dynamic>? libro}) {
    final isEditing = libro != null;
    final nombreController =
        TextEditingController(text: libro?['nombre'] ?? '');
    final contenidoController =
        TextEditingController(text: libro?['contenido'] ?? '');
    final tamanoController =
        TextEditingController(text: libro?['tamaño']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEditing ? 'Editar Libro' : 'Nuevo Libro',
          style: GoogleFonts.itim(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del libro *',
                    prefixIcon: const Icon(Icons.book),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tamanoController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Tamaño en bytes *',
                    prefixIcon: const Icon(Icons.storage),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    helperText: 'Tamaño del archivo en bytes',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contenidoController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Contenido/Descripción *',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignLabelWithHint: true,
                    helperText: 'Descripción del libro o contenido textual',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: GoogleFonts.itim()),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreController.text.trim().isEmpty ||
                  contenidoController.text.trim().isEmpty ||
                  tamanoController.text.trim().isEmpty) {
                _showError('Todos los campos son obligatorios');
                return;
              }

              final tamano = int.tryParse(tamanoController.text.trim());
              if (tamano == null || tamano <= 0) {
                _showError('El tamaño debe ser un número válido mayor a 0');
                return;
              }

              try {
                if (isEditing) {
                  final libroData = {
                    'nombre': nombreController.text.trim(),
                    'contenido': contenidoController.text.trim(),
                    'tamaño': tamano,
                  };
                  await _databaseHelper.updateLibro(libro['id'], libroData);
                  _showSuccess('Libro actualizado exitosamente');
                } else {
                  await _databaseHelper.createLibro(
                    id: _generateId(),
                    nombre: nombreController.text.trim(),
                    contenido: contenidoController.text.trim(),
                    fechaSubido: DateTime.now(),
                    tamano: tamano,
                  );
                  _showSuccess('Libro creado exitosamente');
                }
                Navigator.of(context).pop();
                _loadLibros();
              } catch (e) {
                _showError(
                    'Error al ${isEditing ? 'actualizar' : 'crear'} libro: $e');
              }
            },
            child: Text(
              isEditing ? 'Actualizar' : 'Crear',
              style: GoogleFonts.itim(color: Colors.white),
            ),
          ),
        ],
      ),
    );
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
                    hintText: 'Buscar libros...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _showLibroDialog(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text('Nuevo Libro',
                    style: GoogleFonts.itim(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lista de libros
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLibros.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'No hay libros disponibles'
                                  : 'No se encontraron libros',
                              style: GoogleFonts.itim(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredLibros.length,
                        itemBuilder: (context, index) {
                          final libro = _filteredLibros[index];
                          final fechaSubido =
                              DateTime.tryParse(libro['fecha_subido'] ?? '');
                          final tamano = libro['tamaño'] ?? 0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEF4444),
                                child: Icon(
                                  Icons.menu_book,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                libro['nombre'] ?? 'Sin nombre',
                                style: GoogleFonts.itim(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.storage,
                                          size: 14, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatFileSize(tamano),
                                        style: GoogleFonts.itim(fontSize: 12),
                                      ),
                                      const SizedBox(width: 16),
                                      if (fechaSubido != null) ...[
                                        Icon(Icons.calendar_today,
                                            size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${fechaSubido.day}/${fechaSubido.month}/${fechaSubido.year}',
                                          style: GoogleFonts.itim(fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        libro['sincronizado'] == 1
                                            ? Icons.cloud_done
                                            : Icons.cloud_off,
                                        size: 14,
                                        color: libro['sincronizado'] == 1
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        libro['sincronizado'] == 1
                                            ? 'Sincronizado'
                                            : 'No sincronizado',
                                        style: GoogleFonts.itim(
                                          fontSize: 12,
                                          color: libro['sincronizado'] == 1
                                              ? Colors.green
                                              : Colors.orange,
                                        ),
                                      ),
                                    ],
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
                                      () => _showLibroDialog(libro: libro),
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
                                      () => _deleteLibro(libro['id']),
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
                                      Text(
                                        'Contenido/Descripción:',
                                        style: GoogleFonts.itim(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: Colors.grey[300]!),
                                        ),
                                        child: Text(
                                          libro['contenido'] ?? 'Sin contenido',
                                          style: GoogleFonts.itim(),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Text(
                                            'ID: ',
                                            style: GoogleFonts.itim(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            libro['id'] ?? 'N/A',
                                            style: GoogleFonts.itim(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
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
