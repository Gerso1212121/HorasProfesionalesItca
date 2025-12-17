import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:horas2/Frontend/Modules/Excercises/Data/Models/EjercicioModel.dart';
import 'package:horas2/Frontend/Modules/Excercises/Screens/ExerciseRunnerScreen.dart';

class ExerciseDetailScreen extends StatelessWidget {
  final EjercicioModel exercise;

  const ExerciseDetailScreen({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    // 1. CORRECCIÓN DEFINITIVA DEL COLOR
    // Calculamos el color vibrante para asegurar que no sea gris.
    final Color vibrantThemeColor = _getVibrantColorForCategory(exercise.categoria);

    // Fondo: Tinte muy suave
    final backgroundColor = Color.alphaBlend(
      vibrantThemeColor.withOpacity(0.08), 
      Colors.white
    );

    final textDark = const Color(0xFF2D3142); 
    final textSoft = const Color(0xFF4F5D75); 

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER (Altura reducida de 260 a 220)
          SliverAppBar(
            expandedHeight: 220, 
            pinned: true,
            backgroundColor: vibrantThemeColor,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: vibrantThemeColor.withOpacity(0.3), 
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), // Icono más pequeño
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: vibrantThemeColor),
                  
                  // Decoración ajustada en tamaño
                  Positioned(
                    top: -60,
                    right: -40,
                    child: Container(
                      width: 200, // Reducido de 250
                      height: 200,
                      decoration: BoxDecoration(
                        color: vibrantThemeColor.withOpacity(0.3), 
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -20,
                    left: -10,
                    child: Container(
                      width: 100, // Reducido de 120
                      height: 100,
                      decoration: BoxDecoration(
                        color: vibrantThemeColor.withOpacity(0.2), 
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Icono Central (Reducido de 90 a 72)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        Icon(
                          exercise.icono,
                          size: 72, 
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // CONTENIDO
          SliverToBoxAdapter(
            child: Padding(
              // Padding reducido de 24 a 20
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TÍTULO (Reducido de 30 a 24)
                  Text(
                    exercise.titulo,
                    style: GoogleFonts.itim(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold,
                      color: textDark, 
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // CHIPS
                  Row(
                    children: [
                      _VibrantChip(
                        icon: LucideIcons.clock,
                        label: '${exercise.duracionMinutos} min',
                        color: vibrantThemeColor, 
                      ),
                      const SizedBox(width: 10),
                      _VibrantChip(
                        icon: LucideIcons.trophy,
                        label: exercise.dificultad,
                        color: vibrantThemeColor,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24), // Espacio reducido de 32

                  // DESCRIPCIÓN
                  _GlowCard(
                    glowColor: vibrantThemeColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.sparkles, size: 18, color: vibrantThemeColor),
                            const SizedBox(width: 8),
                            Text(
                              "De qué trata",
                              style: GoogleFonts.itim(
                                fontSize: 18, // Reducido de 20
                                fontWeight: FontWeight.bold,
                                color: textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          exercise.descripcion,
                          style: GoogleFonts.itim(
                            fontSize: 15, // Reducido de 17
                            color: textSoft,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16), // Espacio reducido de 24

                  // OBJETIVOS
                  if (exercise.objetivos.isNotEmpty)
                    _GlowCard(
                      glowColor: vibrantThemeColor,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.target, size: 18, color: vibrantThemeColor),
                              const SizedBox(width: 8),
                              Text(
                                "Tus beneficios",
                                style: GoogleFonts.itim(
                                  fontSize: 18, // Reducido de 20
                                  fontWeight: FontWeight.bold,
                                  color: textDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...exercise.objetivos.map((obj) => Padding(
                            padding: const EdgeInsets.only(bottom: 8), // Reducido padding
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3), // Círculo más pequeño
                                  decoration: BoxDecoration(
                                    color: vibrantThemeColor.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.check, 
                                    size: 10, // Icono check más pequeño
                                    color: vibrantThemeColor
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    obj,
                                    style: GoogleFonts.itim(
                                      fontSize: 14, // Reducido de 16
                                      color: textSoft,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // BOTÓN FLOTANTE (Altura reducida de 64 a 54)
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20), // Margen lateral ajustado
        child: Container(
          height: 54, 
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), // Radio ajustado
            gradient: LinearGradient(
              colors: [
                vibrantThemeColor, 
                vibrantThemeColor.withOpacity(0.85), 
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: vibrantThemeColor.withOpacity(0.4), // Sombra un poco más sutil
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ExerciseRunnerScreen(exercise: exercise),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.play, color: Colors.white, size: 22, fill: 1.0),
                const SizedBox(width: 10),
                Text(
                  'Iniciar Actividad',
                  style: GoogleFonts.itim(
                    fontSize: 18, // Reducido de 20
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Lógica de color (Idéntica para mantener consistencia)
  Color _getVibrantColorForCategory(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('ansiedad') || lower.contains('calma') || lower.contains('verde')) {
      return const Color(0xFF4ADE80); 
    } else if (lower.contains('respiración') || lower.contains('aire')) {
      return const Color(0xFF38BDF8); 
    } else if (lower.contains('foco') || lower.contains('atención')) {
      return const Color(0xFFA855F7); 
    } else if (lower.contains('dormir') || lower.contains('sueño')) {
      return const Color(0xFF6366F1); 
    } else if (lower.contains('autoestima') || lower.contains('emocional')) {
      return const Color(0xFFFB923C); 
    } else {
      return const Color(0xFFFFB74D); 
    }
  }
}

// ---------------- WIDGETS AUXILIARES ----------------

class _GlowCard extends StatelessWidget {
  final Widget child;
  final Color glowColor;

  const _GlowCard({required this.child, required this.glowColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20), // Padding interno reducido de 24 a 20
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24), // Radio reducido de 28
        boxShadow: [
          BoxShadow(
            color: glowColor.withOpacity(0.12),
            blurRadius: 20, // Blur reducido
            offset: const Offset(0, 6),
            spreadRadius: -2,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _VibrantChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _VibrantChip({
    required this.icon, 
    required this.label, 
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Padding reducido
      decoration: BoxDecoration(
        color: color.withOpacity(0.1), 
        borderRadius: BorderRadius.circular(16), // Radio reducido
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color), // Icono reducido de 18
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.itim(
              fontSize: 13, // Reducido de 15
              fontWeight: FontWeight.bold,
              color: color, 
            ),
          ),
        ],
      ),
    );
  }
}