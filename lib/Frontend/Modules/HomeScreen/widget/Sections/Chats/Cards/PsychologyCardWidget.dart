import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PsychologyCardWidget extends StatelessWidget {
  final Map<String, dynamic> modulo;
  final int index;
  final VoidCallback onTap;

  const PsychologyCardWidget({
    Key? key,
    required this.modulo,
    required this.index,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Colores alternos para las tarjetas
    final colors = [
      const Color(0xFFDBFFDD), // Verde claro
      const Color(0xFFD0E5F8), // Azul claro
      const Color(0xFFFFE5DB), // Naranja claro
      const Color(0xFFF0E5FF), // Morado claro
      const Color(0xFFFFE5F0), // Rosa claro
    ];

    final cardColor = colors[index % colors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 200, // Altura fija para evitar desbordamiento
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16), // Reducido de 20 a 16
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono del módulo
              Container(
                width: 45, // Reducido de 50 a 45
                height: 45, // Reducido de 50 a 45
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology_outlined,
                  color: _getIconColor(index),
                  size: 24, // Reducido de 28 a 24
                ),
              ),
              const SizedBox(height: 12), // Reducido de 16 a 12

              // Título del módulo
              Text(
                modulo['titulo'] ?? 'Módulo sin título',
                style: GoogleFonts.inter(
                  fontSize: 16, // Reducido de 18 a 16
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6), // Reducido de 8 a 6

              // Extracto del contenido - Con altura limitada
              Expanded(
                child: Text(
                  _getContentPreview(modulo['contenido']),
                  style: GoogleFonts.inter(
                    fontSize: 13, // Reducido de 14 a 13
                    color: Colors.black54,
                    height: 1.3, // Reducido de 1.4 a 1.3
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 8), // Reducido de 12 a 8

              // Footer con fecha y botón
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      _formatDate(modulo['fecha_creacion']),
                      style: GoogleFonts.inter(
                        fontSize: 11, // Reducido de 12 a 11
                        color: Colors.black45,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, // Reducido de 12 a 10
                      vertical: 5, // Reducido de 6 a 5
                    ),
                    decoration: BoxDecoration(
                      color: _getIconColor(index).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Leer más',
                      style: GoogleFonts.inter(
                        fontSize: 11, // Reducido de 12 a 11
                        fontWeight: FontWeight.w500,
                        color: _getIconColor(index),
                      ),
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

  Color _getIconColor(int index) {
    final iconColors = [
      const Color(0xFF4CAF50), // Verde
      const Color(0xFF2196F3), // Azul
      const Color(0xFFFF9800), // Naranja
      const Color(0xFF9C27B0), // Morado
      const Color(0xFFE91E63), // Rosa
    ];
    return iconColors[index % iconColors.length];
  }

  String _getContentPreview(String? content) {
    if (content == null || content.isEmpty) {
      return 'Sin contenido disponible';
    }

    // Remover markdown básico para preview
    String preview = content
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // Headers
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1') // Bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1') // Italic
        .replaceAll(RegExp(r'`(.*?)`'), r'$1') // Code
        .replaceAll(RegExp(r'\n+'), ' ') // New lines
        .replaceAll(RegExp(r'\s+'), ' '); // Multiple spaces

    // Limitar la longitud del preview
    if (preview.length > 120) {
      preview = '${preview.substring(0, 120)}...';
    }

    return preview.trim();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 30) {
        return '${date.day}/${date.month}/${date.year}';
      } else if (difference.inDays > 0) {
        return 'hace ${difference.inDays} días';
      } else if (difference.inHours > 0) {
        return 'hace ${difference.inHours} horas';
      } else {
        return 'hace poco';
      }
    } catch (e) {
      return '';
    }
  }
}
