import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

Future<bool?> showEndSessionModal(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icono de advertencia
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF57C00),
                    size: 32,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Título
              Center(
                child: Text(
                  "¿Finalizar conversación?",
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Descripción
              Text(
                "Esta conversación se guardará automáticamente en tu historial para que puedas retomarla después.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF666666),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón Cancelar
                  SizedBox(
                    width: 120,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(
                          color: Color(0xFFDDDDDD),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        "Cancelar",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF666666),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Botón Guardar y Finalizar
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save_rounded,
                              size: 18, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            "Guardar",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Nota pequeña
              Center(
                child: Text(
                  "Podrás acceder a esta conversación desde el historial",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF999999),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
