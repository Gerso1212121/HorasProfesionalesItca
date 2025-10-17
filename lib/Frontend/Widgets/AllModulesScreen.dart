import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../App/Data/DataBase/DatabaseHelper.dart';
import 'PsychologyCardWidget.dart';
import 'MODULODETAILSSCREEN.dart';

class AllModulesScreen extends StatefulWidget {
  const AllModulesScreen({Key? key}) : super(key: key);

  @override
  State<AllModulesScreen> createState() => _AllModulesScreenState();
}

class _AllModulesScreenState extends State<AllModulesScreen> {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _allModulos = [];
  List<Map<String, dynamic>> _filteredModulos = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllModulos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllModulos() async {
    setState(() => _isLoading = true);
    try {
      final modulos = await _databaseHelper.readModulos();
      setState(() {
        _allModulos = modulos;
        _filteredModulos = modulos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cargando módulos: $e'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  void _filterModulos(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredModulos = _allModulos;
      } else {
        _filteredModulos = _allModulos
            .where((modulo) =>
                modulo['titulo']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()) ||
                modulo['contenido']
                    .toString()
                    .toLowerCase()
                    .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  Future<void> _refreshModulos() async {
    try {
      // Sincronizar con Supabase
      await _databaseHelper.syncAllData();
      await _loadAllModulos();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Módulos actualizados'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error actualizando: $e'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: CustomScrollView(
        slivers: [
          // App Bar personalizado
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF86A8E7),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Módulos de Psicología',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Icon(
                        Icons.psychology_outlined,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_allModulos.length} módulos disponibles',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Barra de búsqueda y filtros
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Barra de búsqueda
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterModulos,
                      decoration: InputDecoration(
                        hintText: 'Buscar módulos...',
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey[400],
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[400],
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: Colors.grey[400],
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterModulos('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón de actualizar
                  Row(
                    children: [
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _refreshModulos,
                        icon:
                            const Icon(Icons.refresh, color: Color(0xFF86A8E7)),
                        label: Text(
                          'Actualizar',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF86A8E7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Lista de módulos
          _isLoading
              ? const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : _filteredModulos.isEmpty
                  ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : Icons.psychology_outlined,
                              size: 80,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No se encontraron módulos'
                                  : 'No hay módulos disponibles',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              Text(
                                'para "$_searchQuery"',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            const SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: _refreshModulos,
                              icon: const Icon(Icons.refresh,
                                  color: Colors.white),
                              label: const Text('Actualizar módulos'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF86A8E7),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 2.5,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final modulo = _filteredModulos[index];
                            return PsychologyCardWidget(
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
                          childCount: _filteredModulos.length,
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}
