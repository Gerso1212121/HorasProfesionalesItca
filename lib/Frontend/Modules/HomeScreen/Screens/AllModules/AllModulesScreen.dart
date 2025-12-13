import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/ViewModels/AllModulesViewModel.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleDB/ModuloDetailScreen.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Sections/TOOLS/Cards/SubScreenCardModule.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Sections/TOOLS/EmptyModulesState.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Sections/TOOLS/FilterBottomSheet.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Sections/TOOLS/ModulesHeaderSection.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Skeleton/MODULES.dart';
import 'package:provider/provider.dart';

class AllModulesScreen extends StatefulWidget {
  const AllModulesScreen({super.key});

  @override
  State<AllModulesScreen> createState() => _AllModulesScreenState();
}

class _AllModulesScreenState extends State<AllModulesScreen> {
  late AllModulesViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AllModulesViewModel();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ChangeNotifierProvider.value(
          value: _viewModel,
          child: Consumer<AllModulesViewModel>(
            builder: (context, vm, child) {
              return FilterBottomSheet(
                selectedCategory: vm.selectedCategory,
                sortBy: vm.sortBy,
                categories: vm.categories,
                onCategoryChanged: (category) => vm.updateCategory(category),
                onSortByChanged: (sortBy) => vm.updateSortBy(sortBy),
                onResetFilters: () {
                  vm.resetFilters();
                  Navigator.pop(context);
                },
                onApplyFilters: () {
                  vm.applyFilters();
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return const AllModulesSimpleSkeleton(); // Usa el skeleton más simple
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
              'Error al cargar módulos',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                errorMessage,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _viewModel.refreshModules(),
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Consumer<AllModulesViewModel>(
          builder: (context, vm, child) {
            // Estado de carga
            if (vm.isLoading) {
              return _buildLoadingState();
            }
            
            // Estado de error
            if (vm.errorMessage != null && vm.filteredModules.isEmpty) {
              return _buildErrorState(vm.errorMessage!);
            }
            
            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    title: Text(
                      'Herramientas de Ayuda',
                      style: GoogleFonts.itim(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    centerTitle: true,
                    floating: true,
                    snap: true,
                    backgroundColor: Colors.white,
                    elevation: 2,
                    shadowColor: Colors.black.withOpacity(0.1),
                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(100),
                      child: ModulesHeaderSection(
                        modulesCount: vm.filteredModules.length,
                        selectedCategory: vm.selectedCategory,
                        onCategoryRemoved: (category) {
                          if (category == vm.selectedCategory) {
                            vm.updateCategory('Todas');
                          }
                        },
                        searchController: vm.searchController,
                      ),
                    ),
                  ),
                ];
              },
              body: RefreshIndicator(
                onRefresh: () => vm.refreshModules(),
                child: vm.filteredModules.isEmpty
                    ? EmptyModulesState(onResetFilters: vm.resetFilters)
                    : _buildModulesGrid(vm),
              ),
            );
          },
        ),
        floatingActionButton: Consumer<AllModulesViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) return const SizedBox();
            
            return FloatingActionButton(
              onPressed: () => _showFilterBottomSheet(context),
              backgroundColor: const Color(0xFF3B82F6),
              child: const Icon(Icons.filter_list, color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModulesGrid(AllModulesViewModel vm) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          crossAxisSpacing: 90,
          mainAxisSpacing: 0,
          childAspectRatio: 1.7,
        ),
        itemCount: vm.filteredModules.length,
        itemBuilder: (context, index) {
          final modulo = vm.filteredModules[index];
          return ModuleCardWidget(
            modulo: modulo,
            index: index,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModuloDetailScreen(
                    modulo: modulo,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}