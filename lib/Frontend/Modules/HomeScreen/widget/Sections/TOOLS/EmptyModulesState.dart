import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyModulesState extends StatelessWidget {
  final VoidCallback onResetFilters;

  const EmptyModulesState({super.key, required this.onResetFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 300, // Ancho máximo para el contenido
          maxHeight: MediaQuery.of(context).size.height * 0.7, // Altura máxima
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Esto es CRUCIAL
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64, // Reducido de 72 a 64
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16), // Reducido de 20 a 16
              Text(
                'No se encontraron módulos',
                style: GoogleFonts.poppins(
                  fontSize: 16, // Reducido de 18 a 16
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8), // Reducido de 12 a 8
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Intenta con otros términos o ajusta los filtros',
                  style: GoogleFonts.inter(
                    fontSize: 13, // Reducido de 14 a 13
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 16), // Reducido de 20 a 16
              ElevatedButton.icon(
                onPressed: onResetFilters,
                icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF3B82F6)), // Ícono azul
                label: const Text(
                  'Mostrar todos',
                  style: TextStyle(color: Color(0xFF3B82F6)), // Texto azul
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, // FONDO BLANCO
                  foregroundColor: const Color(0xFF3B82F6), // Color del texto e ícono
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: const Color(0xFF3B82F6).withOpacity(0.3), width: 1.5),
                  ),
                  elevation: 1,
                  shadowColor: Colors.black.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}