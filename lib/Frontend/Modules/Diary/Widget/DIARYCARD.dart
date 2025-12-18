// lib/Frontend/Modules/Diary/Widget/DIARYCARD.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/Diary/ViewModels/DiaryScreenViewModel.dart';
import 'package:provider/provider.dart';

class DiaryCardWidget extends StatelessWidget {
  final Map<String, dynamic> entry;
  final Map<String, dynamic> colors;
  final VoidCallback? onTap;
  final bool showDeleteOption;
  final Function(int)? onDelete;

  const DiaryCardWidget({
    Key? key,
    required this.entry,
    required this.colors,
    this.onTap,
    this.showDeleteOption = true,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageList = (entry['imagenes_lista'] as List?)?.cast<String>() ?? [];
    final hasImages = imageList.isNotEmpty;
    final cleanContent = _cleanContent(entry['contenido']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Contenido de la tarjeta (primero el texto)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con fecha, emoji y hora
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Fecha formateada
                      Expanded(
                        child: Text(
                          _formatDate(entry['fecha']),
                          style: GoogleFonts.inter(
                            color: colors['primary'],
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),

                      // Emoji y hora
                      Row(
                        children: [
                          if (entry['emoji'] != null &&
                              entry['emoji'].toString().isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: Text(
                                entry['emoji'],
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors['primary']!.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              entry['hora'] ?? '',
                              style: GoogleFonts.inter(
                                color: colors['primary'],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Título
                  Text(
                    entry['titulo']?.isNotEmpty == true
                        ? entry['titulo']
                        : 'Diario sin título',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF1A237E),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Contenido/descripción

                  if (cleanContent.isNotEmpty)
                    Text(
                      cleanContent,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF5F6368),
                        fontSize: 14,
                        height: 1.5,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: 12),

                  // Footer con estadísticas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Indicadores (ya no mostramos contador de imágenes aquí)

                      // Botón de acción/etiqueta
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors['primary']!,
                              colors['primary']!.withOpacity(0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Ver entrada',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sección de imágenes debajo del texto (si existen)
            if (hasImages) _buildImagesBelowText(imageList),
          ],
        ),
      ),
    );
  }

  // Construir sección de imágenes debajo del texto
  Widget _buildImagesBelowText(List<String> imageList) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título pequeño para la sección de imágenes
          Row(
            children: [
              Icon(
                Icons.photo_library_rounded,
                size: 16,
                color: colors['primary']!.withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                'Fotos adjuntas (${imageList.length})',
                style: GoogleFonts.inter(
                  color: colors['primary']!.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Galería de imágenes compacta
          SizedBox(
            height: 100, // Altura fija para todas las imágenes
            child: _buildCompactImageGallery(imageList),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactImageGallery(List<String> imageList) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: imageList.length,
      padding: const EdgeInsets.only(right: 8),
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        return Padding(
            padding: EdgeInsets.all(5),
            child: _buildCompactImageItem(imageList[index]));
      },
    );
  }

  // Construir item de imagen compacta
  Widget _buildCompactImageItem(String imagePath, {bool isSingle = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildImageContent(imagePath, isSingle: isSingle),
      ),
    );
  }

  // Construir contenido de imagen con fit apropiado
  Widget _buildImageContent(String imagePath, {bool isSingle = false}) {
    return Image.file(
      File(imagePath),
      fit: BoxFit.cover, // Cubrir el espacio sin distorsionar
      width: 100,
      height: 100,
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholder();
      },
    );
  }

  // Placeholder para imágenes faltantes
  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: const Center(
        child: Icon(
          Icons.photo_rounded,
          color: Colors.grey,
          size: 24,
        ),
      ),
    );
  }

  // Formatear fecha de manera más atractiva
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'HOY';
    } else if (difference.inDays == 1) {
      return 'AYER';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return 'HACE ${days} ${days == 1 ? 'DÍA' : 'DÍAS'}';
    } else {
      final monthNames = [
        'ENE',
        'FEB',
        'MAR',
        'ABR',
        'MAY',
        'JUN',
        'JUL',
        'AGO',
        'SEP',
        'OCT',
        'NOV',
        'DIC'
      ];
      return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
    }
  }

  // Calcular longitud del contenido
  int _getContentLength(String? content) {
    if (content == null || content.isEmpty) return 0;
    return content.length;
  }

  // Diálogo de eliminación
  Future<void> _showDeleteDialog(BuildContext context) async {
    final viewModel = context.read<DiaryScreenViewModel>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Eliminar entrada',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A237E),
          ),
        ),
        content: Text(
          '¿Estás seguro de que quieres eliminar "${entry['titulo'] ?? 'esta entrada'}"? Esta acción no se puede deshacer.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: GoogleFonts.inter(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDelete(context, viewModel);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Eliminar',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDelete(
      BuildContext context, DiaryScreenViewModel viewModel) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final success =
          await viewModel.deleteEntry(entry['id'], title: entry['titulo']);

      Navigator.pop(context);

      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Entrada eliminada exitosamente',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al eliminar la entrada',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _cleanContent(String? content) {
    if (content == null) return '';

    // Elimina caracteres invisibles y placeholders comunes de imágenes
    final cleaned = content
        // Caracteres unicode invisibles usados por editores
        .replaceAll(RegExp(r'[\uFFFC\u200B\u200C\u200D]'), '')
        // Líneas vacías repetidas
        .replaceAll(RegExp(r'\n\s*\n'), '\n')
        .trim();

    return cleaned;
  }
}
