import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:horas2/Frontend/Modules/Excercises/ViewModel/ExerciseViewModel.dart';
// Asegúrate de que esta ruta sea correcta en tu proyecto:
import 'package:horas2/Frontend/Modules/Excercises/Widgets/header.dart'; 
import 'package:horas2/Frontend/Modules/Excercises/Screens/ExercisesByCategoryScreen.dart';
import 'package:horas2/Frontend/Modules/Excercises/Screens/ProgressScreen.dart';

class ExcersicesScreen extends StatelessWidget {
  const ExcersicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Body();
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: Consumer<ExerciseViewModel>(
        builder: (context, vm, child) {
          // 1. SKELETON LOADING
          if (vm.isLoading && vm.categorias.isEmpty) {
            return const _SkeletonBody();
          }

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              // 2. HEADER
              SliverToBoxAdapter(
                child: ExerciseHeaderSection(
                  onProgressPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProgressScreen()),
                    );
                  },
                  onExercisePressed: () {
                    // Acción opcionalf
                  },
                ),
              ),

              // 3. TÍTULO SECCIÓN
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 25, 24, 15),
                  child: Text(
                    'Explorar Categorías',
                    style: GoogleFonts.itim(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),

              // 4. GRID DE CATEGORÍAS
              if (vm.categorias.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Column(
                        children: [
                          Icon(LucideIcons.frown, size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay ejercicios disponibles.',
                            style: GoogleFonts.itim(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, 
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.72, 
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final categoria = vm.categorias[index];
                        return _CategoryCard(
                          categoryName: categoria,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExercisesByCategoryScreen(categoryName: categoria),
                              ),
                            );
                          },
                        );
                      },
                      childCount: vm.categorias.length,
                    ),
                  ),
                ),
                
              const SliverToBoxAdapter(child: SizedBox(height: 60)), 
            ],
          );
        },
      ),
    );
  }
}

// --------------------------------------------------------------------------
// TARJETA DE CATEGORÍA (REDISEÑADA "LAVADO DE CARA")
// --------------------------------------------------------------------------
class _CategoryCard extends StatelessWidget {
  final String categoryName;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.categoryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final style = _getCategoryStyle(categoryName);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: style.color.withOpacity(0.12), // Sombra un poco más presente
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        // Usamos ClipRRect para que la decoración del fondo no se salga
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            splashColor: style.color.withOpacity(0.1),
            child: Stack(
              children: [
                // 1. FONDO DECORATIVO (Marca de agua gigante)
                Positioned(
                  right: -15,
                  top: -15,
                  child: Transform.rotate(
                    angle: 0.2, // Rotación leve
                    child: Icon(
                      style.icon,
                      size: 100, // Icono gigante
                      color: style.color.withOpacity(0.07), // Muy transparente
                    ),
                  ),
                ),
                
                // 2. DEGRADADO SUTIL DE FONDO
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0),
                          style.color.withOpacity(0.05), // Toque de color abajo derecha
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. CONTENIDO PRINCIPAL
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start, // Alineación izquierda se ve más moderna
                    children: [
                      // Icono Principal
                      Container(
                        width: 52, 
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: style.color.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                          border: Border.all(color: style.color.withOpacity(0.1), width: 1),
                        ),
                        child: Icon(
                          style.icon,
                          color: style.color,
                          size: 24,
                        ),
                      ),
                      
                      const Spacer(),

                      // Título
                      Text(
                        categoryName,
                        style: GoogleFonts.itim(
                          fontSize: 15, 
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Botón / Call to Action (Estilo Pill)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: style.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Explorar',
                              style: GoogleFonts.itim(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: style.color, // Tone on tone
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(LucideIcons.arrowRight, size: 12, color: style.color),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _CategoryStyle _getCategoryStyle(String name) {
    final lower = name.toLowerCase();
    
    if (lower.contains('ansiedad') || lower.contains('calma') || lower.contains('verde')) {
      return _CategoryStyle(const Color(0xFF4ADE80), LucideIcons.leaf); 
    } else if (lower.contains('respiración') || lower.contains('aire')) {
      return _CategoryStyle(const Color(0xFF38BDF8), LucideIcons.wind); 
    } else if (lower.contains('foco') || lower.contains('atención')) {
      return _CategoryStyle(const Color(0xFFA855F7), LucideIcons.focus); 
    } else if (lower.contains('dormir') || lower.contains('sueño')) {
      return _CategoryStyle(const Color(0xFF6366F1), LucideIcons.moon); 
    } else if (lower.contains('autoestima') || lower.contains('emocional')) {
      return _CategoryStyle(const Color(0xFFFB923C), LucideIcons.heart); 
    } else {
      return _CategoryStyle(const Color(0xFFFFB74D), LucideIcons.sparkles); 
    }
  }
}

class _CategoryStyle {
  final Color color;
  final IconData icon;
  _CategoryStyle(this.color, this.icon);
}

// --------------------------------------------------------------------------
// SKELETON LOADING (Mantenemos el mismo, funciona bien)
// --------------------------------------------------------------------------
class _SkeletonBody extends StatefulWidget {
  const _SkeletonBody();

  @override
  State<_SkeletonBody> createState() => _SkeletonBodyState();
}

class _SkeletonBodyState extends State<_SkeletonBody> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.5, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: CustomScrollView(
        physics: const ClampingScrollPhysics (), 
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                height: 180, 
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 15),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72, 
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade100),
                    ),
                  );
                },
                childCount: 6, 
              ),
            ),
          ),
        ],
      ),
    );
  }
}