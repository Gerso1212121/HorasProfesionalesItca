import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LinkedFilesWidget extends StatelessWidget {
  final String moduloId;
  final List<Map<String, dynamic>> archivos;
  final Function(String) onInsertImage;
  final Function(String) onDeleteFile;

  const LinkedFilesWidget({
    super.key,
    required this.moduloId,
    required this.archivos,
    required this.onInsertImage,
    required this.onDeleteFile,
  });

  Widget _buildFilePreview(Map<String, dynamic> archivo) {
    final tipoArchivo = archivo['tipo_archivo'] ?? 'unknown';
    final url = archivo['url'] ?? '';
    final nombreArchivo = archivo['nombre_archivo'] ?? 'archivo';

    if (tipoArchivo == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
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
        ),
      );
    } else if (tipoArchivo == 'video') {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.play_circle_outline,
            color: Colors.white, size: 32),
      );
    } else {
      return Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.insert_drive_file, size: 32),
      );
    }
  }

  String _generateMarkdownForFile(Map<String, dynamic> archivo) {
    final tipoArchivo = archivo['tipo_archivo'] ?? 'unknown';
    final url = archivo['url'] ?? '';
    final descripcion = archivo['descripcion'] ?? 'Archivo';
    final nombreArchivo = archivo['nombre_archivo'] ?? 'archivo';

    if (tipoArchivo == 'image') {
      return '![${descripcion}]($url)\n';
    } else if (tipoArchivo == 'video') {
      return '[🎥 Ver video: $nombreArchivo]($url)\n';
    } else {
      return '[📎 Descargar: $nombreArchivo]($url)\n';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (archivos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Text(
            'No hay archivos vinculados',
            style: GoogleFonts.itim(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.attach_file, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              Text(
                'Archivos vinculados (${archivos.length})',
                style: GoogleFonts.itim(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Haz clic en "Insertar" para agregar el archivo al contenido Markdown',
            style: GoogleFonts.itim(
              fontSize: 12,
              color: Colors.blue[600],
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: archivos.map((archivo) {
              final tipoArchivo = archivo['tipo_archivo'] ?? 'unknown';
              final nombreArchivo = archivo['nombre_archivo'] ?? 'archivo';

              return Container(
                width: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview del archivo
                    Container(
                      width: double.infinity,
                      height: 80,
                      child: Stack(
                        children: [
                          Center(child: _buildFilePreview(archivo)),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => onDeleteFile(archivo['id']),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Información del archivo
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombreArchivo.length > 15
                                ? '${nombreArchivo.substring(0, 15)}...'
                                : nombreArchivo,
                            style: GoogleFonts.itim(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _getTypeColor(tipoArchivo).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _getTypeLabel(tipoArchivo),
                              style: GoogleFonts.itim(
                                fontSize: 10,
                                color: _getTypeColor(tipoArchivo),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Botón insertar
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                final markdown =
                                    _generateMarkdownForFile(archivo);
                                onInsertImage(markdown);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Código Markdown insertado',
                                      style: GoogleFonts.itim(),
                                    ),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(0, 30),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                              ),
                              child: Text(
                                'Insertar',
                                style: GoogleFonts.itim(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(String tipo) {
    switch (tipo) {
      case 'image':
        return Colors.blue;
      case 'video':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getTypeLabel(String tipo) {
    switch (tipo) {
      case 'image':
        return 'IMAGEN';
      case 'video':
        return 'VIDEO';
      default:
        return 'ARCHIVO';
    }
  }
}
