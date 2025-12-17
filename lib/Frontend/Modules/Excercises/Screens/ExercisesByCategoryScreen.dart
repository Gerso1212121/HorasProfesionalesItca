import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
// import 'package:horas2/Frontend/Constants/AppConstants.dart'; // No se usa aquí directamente
import 'package:horas2/Frontend/Modules/Excercises/Data/Models/EjercicioModel.dart';
import 'package:horas2/Frontend/Modules/Excercises/ViewModel/ExerciseViewModel.dart';
// Importamos la pantalla de detalle para navegar
import 'package:horas2/Frontend/Modules/Excercises/Screens/ExerciseDetailScreen.dart';

class ExercisesByCategoryScreen extends StatelessWidget {
  final String categoryName;

  const ExercisesByCategoryScreen({
    super.key,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(
          categoryName,
          style: GoogleFonts.itim(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Consumer<ExerciseViewModel>(
        builder: (context, vm, child) {
          // Filtramos los ejercicios usando el método del VM
          final exercises = vm.getExercisesByCategory(categoryName);

          if (exercises.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.folderOpen, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay ejercicios en esta categoría aún.',
                    style: GoogleFonts.itim(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: exercises.length,
            separatorBuilder: (c, i) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return _ExerciseListCard(
                exercise: exercise,
                onTap: () {
                  // Navegación simple al detalle
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseDetailScreen(exercise: exercise),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// Tarjeta individual de ejercicio
class _ExerciseListCard extends StatelessWidget {
  final EjercicioModel exercise;
  final VoidCallback onTap;

  const _ExerciseListCard({required this.exercise, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // 1. Obtenemos el color vibrante basado en la categoría del ejercicio
    final vibrantColor = _getVibrantColorForCategory(exercise.categoria);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            // Sombra suave con un toque del color vibrante en lugar de gris puro
            color: vibrantColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: vibrantColor.withOpacity(0.1), // Splash del color temático
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // 2. Icono temático (AHORA CON COLOR VIBRANTE)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    // Fondo pastel del color vibrante
                    color: vibrantColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    exercise.icono,
                    // Icono del color vibrante sólido
                    color: vibrantColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Textos
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.titulo,
                        style: GoogleFonts.itim(
                          fontWeight: FontWeight.w600,
                          fontSize: 16, // Ligeramente más grande
                          color: const Color(0xFF1E293B), // Slate dark, no gris aburrido
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Los iconos de utilidad se mantienen grises como pediste
                          Icon(LucideIcons.clock, size: 13, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            '${exercise.duracionMinutos} min',
                            style: GoogleFonts.itim(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Badge de Dificultad (Un poco más limpio)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            ),
                            child: Text(
                              exercise.dificultad,
                              style: GoogleFonts.itim(
                                fontSize: 11,
                               color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Flecha (se mantiene gris)
                Icon(Icons.chevron_right, color: Colors.grey[300]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Función auxiliar para obtener colores vibrantes según la categoría
// (Misma paleta que en ExcercisesScreen.dart)
Color _getVibrantColorForCategory(String categoryName) {
  final lower = categoryName.toLowerCase();
  if (lower.contains('ansiedad') || lower.contains('calma') || lower.contains('verde')) {
    return const Color(0xFF4ADE80); // Verde Menta vibrante
  } else if (lower.contains('respiración') || lower.contains('aire')) {
    return const Color(0xFF38BDF8); // Azul Cielo vibrante
  } else if (lower.contains('foco') || lower.contains('atención')) {
    return const Color(0xFFA855F7); // Púrpura/Lila vibrante
  } else if (lower.contains('dormir') || lower.contains('sueño')) {
    return const Color(0xFF6366F1); // Índigo vibrante
  } else if (lower.contains('autoestima') || lower.contains('emocional')) {
    return const Color(0xFFFB923C); // Naranja vibrante
  } else {
    // Default alegre (Amarillo/Ámbar)
    return const Color(0xFFFFB74D);
  }
}