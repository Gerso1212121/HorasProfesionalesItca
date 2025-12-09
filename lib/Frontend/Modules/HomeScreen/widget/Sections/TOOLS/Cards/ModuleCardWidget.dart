import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Utils/HomeScreenUtils.dart';

class ModuleCardWidget extends StatelessWidget {
  final Map<String, dynamic> modulo;
  final int index;
  final VoidCallback onTap;

  const ModuleCardWidget({
    super.key,
    required this.modulo,
    required this.index,
    required this.onTap,
  });

  String _getModuleTitle(Map<String, dynamic> modulo) {
    final possibleTitleKeys = ['titulo', 'title', 'nombre', 'name'];
    for (var key in possibleTitleKeys) {
      if (modulo.containsKey(key) && modulo[key] != null) {
        return modulo[key].toString();
      }
    }
    return 'Módulo de ayuda';
  }

  String _extractFirstParagraph(String content) {
    final lines = content.split('\n');
    for (var line in lines) {
      final trimmed = line.trim();
      if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
        return trimmed.length > 100 
            ? '${trimmed.substring(0, 100)}...'
            : trimmed;
      }
    }
    return 'Contenido del módulo...';
  }

  @override
  Widget build(BuildContext context) {
    final title = _getModuleTitle(modulo);
    final description = _extractFirstParagraph(modulo['contenido']?.toString() ?? '');
    final colors = HomeScreenUtils.getCardColorsForModule(index);
    final badgeText = HomeScreenUtils.getBadgeTextForModule(index);
    final icon = HomeScreenUtils.getIconForModule(index);
    
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge y categoría
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors['badgeColor1']!, colors['badgeColor2']!],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      icon,
                      size: 25,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
              
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Expanded(
                        child: Text(
                          description,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Indicador de video si tiene
                      if ((modulo['contenido']?.toString() ?? '').contains('youtube.com') ||
                          (modulo['contenido']?.toString() ?? '').contains('youtu.be'))
                        Row(
                          children: [
                            Icon(
                              Icons.play_circle_filled,
                              size: 14,
                              color: const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Incluye video',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}