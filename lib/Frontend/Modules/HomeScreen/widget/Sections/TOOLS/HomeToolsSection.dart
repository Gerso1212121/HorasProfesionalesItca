// HomeScreen/widgets/home_sections/home_psychology_section.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/ViewModels/VMcards/HomeCardsVM.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Skeleton/PsychologySectionSkeleton.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/AllModules/AllModulesScreen.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Sections/TOOLS/Cards/CardsModules.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Sections/TOOLS/Cards/MetasAcademicasCard.dart';
import 'package:provider/provider.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleDB/ModuloDetailScreen.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleAcademicas/MetasAcademicasScreen.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Utils/HomeScreenUtils.dart';

class HomeToolsSection extends StatefulWidget {
  const HomeToolsSection({super.key});

  @override
  State<HomeToolsSection> createState() => _HomeToolsSectionState();
}

class _HomeToolsSectionState extends State<HomeToolsSection> {
  // Variable para controlar si es la primera carga
  bool _isFirstLoad = true;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PsychologyViewModel(),
      child: Consumer<PsychologyViewModel>(
        builder: (context, viewModel, child) {
          // Actualizar estado de primera carga
          if (_isFirstLoad && !viewModel.isLoading) {
            _isFirstLoad = false;
          }
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con botón "Ver todos" - CORREGIDO
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Herramientas de Ayuda',
                      style: GoogleFonts.itim(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    
                    // Widget condicional para mostrar "Ver todos" - CORREGIDO
                    _buildVerTodosButton(viewModel),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Sección de módulos
              SizedBox(
                height: 250,
                child: _buildContent(context, viewModel),
              ),
            ],
          );
        },
      ),
    );
  }

  // MÉTODO NUEVO: Widget para el botón "Ver todos"
  Widget _buildVerTodosButton(PsychologyViewModel viewModel) {
    // CORRECCIÓN: Mostrar si hay más de 3 módulos (no 5)
    if (viewModel.psychologyModules.length > 3) {
      return Row(
        children: [
          // Indicador de carga si está cargando
          if (viewModel.isLoading)
            Container(
              margin: const EdgeInsets.only(right: 12),
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.grey[400],
              ),
            ),
          
          // Botón "Ver todos" - siempre visible si hay más de 3 módulos
          TextButton(
            onPressed: viewModel.isLoading 
              ? null // Deshabilitar mientras carga
              : () {
                  // Navegar a pantalla con todos los módulos
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AllModulesScreen(
                      ),
                    ),
                  );
                },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: viewModel.isLoading 
                ? Colors.grey[200]
                : const Color(0xFF3B82F6).withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Ver',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: viewModel.isLoading 
                      ? Colors.grey[500]
                      : const Color(0xFF3B82F6),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: viewModel.isLoading 
                    ? Colors.grey[500]
                    : const Color(0xFF3B82F6),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Si no hay más de 3 módulos, mostrar solo el indicador de carga si está cargando
    if (viewModel.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.grey[400],
        ),
      );
    }

    // Si no hay más de 3 módulos y no está cargando, mostrar espacio vacío
    return const SizedBox(width: 0, height: 0);
  }

  // MÉTODO NUEVO: Contador de módulos visibles
  int _getVisibleModulesCount(PsychologyViewModel viewModel) {
    final modules = viewModel.psychologyModules;
    // Mostrar máximo 3 módulos en la vista principal
    return modules.length > 3 ? 3 : modules.length;
  }

  Widget _buildContent(BuildContext context, PsychologyViewModel viewModel) {
    // Mostrar skeleton solo en la primera carga
    if (_isFirstLoad && viewModel.isLoading) {
      return const PsychologySectionSkeleton();
    }
    
    // Mostrar error si hay y no hay datos
    if (viewModel.hasError && viewModel.psychologyModules.isEmpty) {
      return _buildErrorState(viewModel);
    }
    
    // Mostrar cards con los datos (solo primeros 3)
    return _buildPsychologyCards(context, viewModel);
  }

  Widget _buildErrorState(PsychologyViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              viewModel.errorMessage ?? 'Error al cargar los módulos',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => viewModel.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPsychologyCards(BuildContext context, PsychologyViewModel viewModel) {
    final modules = viewModel.psychologyModules;
    
    // Tomar solo los primeros 3 módulos (o menos si hay menos de 3)
    final displayedModules = modules.take(3).toList();
    final bool showVerTodosCard = modules.length > 3;
    
    // DEBUG: Verificar datos
    print('DEBUG: Total módulos: ${modules.length}');
    print('DEBUG: Módulos mostrados: ${displayedModules.length}');
    print('DEBUG: ¿Mostrar "Ver todos"?: $showVerTodosCard');
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: displayedModules.isEmpty ? 2 : displayedModules.length + 1 + (showVerTodosCard ? 1 : 0),
      itemBuilder: (context, index) {
        // Primer card siempre es Metas Académicas
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(left: 20),
            child: MetasAcademicasCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MetasAcademicasScreen(),
                  ),
                );
              },
            ),
          );
        }

        final adjustedIndex = index - 1;
        
        // Si no hay módulos, mostrar card vacía
        if (displayedModules.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, right: 0),
            child: _buildEmptyModuleCard(),
          );
        }
        
        // Mostrar módulos disponibles (primeros 3)
        if (adjustedIndex < displayedModules.length) {
          final modulo = displayedModules[adjustedIndex];
          
          // Obtener título del módulo
          String title = 'Módulo de ayuda';
          final possibleTitleKeys = ['titulo', 'title', 'nombre', 'name'];
          for (var key in possibleTitleKeys) {
            if (modulo.containsKey(key) && modulo[key] != null) {
              title = modulo[key].toString();
              break;
            }
          }
          
          return Padding(
            padding: EdgeInsets.only(
              left: adjustedIndex == 0 ? 16 : 0,
              right: 16,
            ),
            child: CardsModules(
              title: title,
              description: HomeScreenUtils.getDescriptionForModule(title),
              badgeText: HomeScreenUtils.getBadgeTextForModule(adjustedIndex),
              icon: HomeScreenUtils.getIconForModule(adjustedIndex),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModuloDetailScreen(modulo: modulo),
                  ),
                );
              },
              cardColors: HomeScreenUtils.getCardColorsForModule(adjustedIndex),
            ),
          );
        }

        // Card "Ver más" si hay más de 3 módulos
        if (showVerTodosCard && adjustedIndex == displayedModules.length) {
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _buildVerMasCard(context, viewModel),
          );
        }

        return Container(); // Fallback
      },
    );
  }

  Widget _buildVerMasCard(BuildContext context, PsychologyViewModel viewModel) {
    final totalModulos = viewModel.psychologyModules.length;
    final visibleCount = _getVisibleModulesCount(viewModel);
    
    // DEBUG: Verificar cálculo
    print('DEBUG: Total: $totalModulos, Visibles: $visibleCount, Restantes: ${totalModulos - visibleCount}');
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AllModulesScreen(
             ),
          ),
        );
      },
      child: Container(
        width: 180,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  size: 30,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Ver todos',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '+${totalModulos - visibleCount} más',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyModuleCard() {
    return Container(
      width: 300,
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            Text(
              'Sin módulos disponibles',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los módulos se cargarán automáticamente',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}