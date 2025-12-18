import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// OPTIMIZACIÓN: ChatHeader ahora es completamente const
class ChatHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onMenuPressed;

  const ChatHeader({
    super.key,
    this.title = "Asistente AI",
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          stops: [0.1, 0.9],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF86A8E7).withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        bottom: 20,
        left: 16,
        right: 16,
      ),
      child: _buildHeaderContent(),
    );
  }

  Widget _buildHeaderContent() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Botón de menú hamburguesa - OPTIMIZACIÓN: Mejor tap target
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.menu_rounded,
              color: Colors.white,
              size: 26,
            ),
            onPressed: onMenuPressed,
            splashRadius: 20,
            padding: const EdgeInsets.all(8),
          ),
        ),

        // Título centrado con mejor tipografía
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Tu asistente emocional",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),

        // Espaciador para mantener balance visual
        const SizedBox(width: 48),
      ],
    );
  }
}
