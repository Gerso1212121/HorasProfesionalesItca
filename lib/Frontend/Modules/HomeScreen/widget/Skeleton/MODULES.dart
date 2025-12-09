// AllModulesSkeleton.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class AllModulesSkeleton extends StatelessWidget {
  const AllModulesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header skeleton (igual al SliverAppBar real)
            Container(
              height: 140, // Altura del SliverAppBar con bottom
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 20, right: 20),
                child: Column(
                  children: [
                    // Título skeleton
                    Shimmer.fromColors(
                      baseColor: Colors.grey[200]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 24,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Search bar skeleton (igual a ModulesHeaderSection)
                    Row(
                      children: [
                        Expanded(
                          child: Shimmer.fromColors(
                            baseColor: Colors.grey[200]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
 
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 50),
            // Grid skeleton (igual a _buildModulesGrid)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Shimmer.fromColors(
                  baseColor: Colors.grey[200]!,
                  highlightColor: Colors.grey[100]!,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 1,
                      crossAxisSpacing: 90,
                      mainAxisSpacing: 0,
                      childAspectRatio: 1.7,
                    ),
                    itemCount: 5, // Número de skeleton cards
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header con categoría skeleton
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[200]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 24,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[200]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Título skeleton
                              Shimmer.fromColors(
                                baseColor: Colors.grey[200]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 20,
                                  width: 180,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 8),
                              
                              // Descripción skeleton (2 líneas)
                              Shimmer.fromColors(
                                baseColor: Colors.grey[200]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 16,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Shimmer.fromColors(
                                baseColor: Colors.grey[200]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  height: 16,
                                  width: 220,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              
                              const Spacer(),
                              
                              // Footer skeleton (fecha y autor)
                              Row(
                                children: [
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[200]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 12,
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey[200]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 12,
                                      width: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // FAB skeleton
      floatingActionButton: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Versión SimpleSkeleton (igual que usas en AllModulesScreen)
class AllModulesSimpleSkeleton extends StatelessWidget {
  const AllModulesSimpleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const AllModulesSkeleton();
  }
}