// lib/Frontend/Modules/Diary/Widgets/EmptyDiaryState.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyDiaryState extends StatelessWidget {
  final VoidCallback? onCreateEntry;

  const EmptyDiaryState({super.key, this.onCreateEntry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustración
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4285F4).withOpacity(0.1),
                  const Color(0xFF34A853).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.bookmark_add_rounded,
                size: 80,
                color: const Color(0xFF4285F4),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Texto motivacional
          Text(
            'Tu diario personal',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A237E),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Comienza a documentar tus días,\nreflexiones y momentos especiales',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          // Beneficios
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildBenefitItem(
                  icon: Icons.auto_awesome_rounded,
                  text: 'Reflexiona sobre tu crecimiento',
                  color: const Color(0xFF4285F4),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  icon: Icons.photo_library_rounded,
                  text: 'Guarda fotos de momentos especiales',
                  color: const Color(0xFF34A853),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  icon: Icons.timeline_rounded,
                  text: 'Visualiza tu progreso personal',
                  color: const Color(0xFFFBBC05),
                ),
              ],
            ),
          ),

          // Botón de creación
          if (onCreateEntry != null) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onCreateEntry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4285F4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Crear primera entrada',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5A5A5A),
            ),
          ),
        ),
      ],
    );
  }
}