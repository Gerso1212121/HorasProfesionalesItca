import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<void> showSessionLoadedModal(
  BuildContext context,
  String tituloSesion,
) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black54,
    builder: (context) => Dialog(
      insetAnimationDuration: const Duration(milliseconds: 300),
      insetAnimationCurve: Curves.easeOutCubic,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animación de check
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),

              const SizedBox(height: 24),

              // Mensaje principal
              Text(
                "¡Conversación cargada!",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF333333),
                ),
              ),

              const SizedBox(height: 12),

              // Título de la sesión
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE9ECEF),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF6C757D),
                      size: 24,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      tituloSesion,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF495057),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botón de continuar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF86A8E7),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Continuar",
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Nota pequeña
              Text(
                "Puedes seguir conversando donde lo dejaste",
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF999999),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
