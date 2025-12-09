import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:horas2/Backend/Data/API/SupabaseService.dart';

class AllModulesViewModel extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  List<Map<String, dynamic>> _allModules = [];
  List<Map<String, dynamic>> _filteredModules = [];
  String _searchQuery = '';
  String _selectedCategory = 'Todas';
  String _sortBy = 'relevancia';
  List<String> _categories = ['Todas'];
  bool _isLoading = true;
  String? _errorMessage;
  
  final TextEditingController searchController = TextEditingController();
  
  List<Map<String, dynamic>> get allModules => _allModules;
  List<Map<String, dynamic>> get filteredModules => _filteredModules;
  String get selectedCategory => _selectedCategory;
  String get sortBy => _sortBy;
  List<String> get categories => _categories;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  AllModulesViewModel() {
    _initialize();
  }

  Future<void> _initialize() async {
    setState(() => _isLoading = true);
    _errorMessage = null;
    
    try {
      // Cargar todos los módulos desde Supabase (sin necesidad de usuario)
      await _loadAllModules();
      
      // Extraer categorías disponibles
      await _extractCategories();
      
      // Aplicar filtros iniciales
      applyFilters();
    } catch (e) {
      debugPrint('Error inicializando AllModulesViewModel: $e');
      _errorMessage = 'Error al cargar módulos: ${e.toString()}';
      _filteredModules = [];
      _allModules = [];
    } finally {
      setState(() => _isLoading = false);
    }
    
    // Escuchar cambios en el buscador
    searchController.addListener(() {
      _searchQuery = searchController.text.toLowerCase();
      applyFilters();
    });
  }

  Future<void> _loadAllModules() async {
    try {
      // Consultar módulos desde Supabase
      final modules = await _supabaseService.getModules();
      
      // Procesar cada módulo para estructurarlo correctamente
      _allModules = modules.map((module) {
        return {
          'id': module['id']?.toString() ?? '',
          'titulo': module['titulo']?.toString() ?? 'Módulo de ayuda',
          'contenido': module['contenido']?.toString() ?? '',
          'descripcion': module['descripcion']?.toString() ?? '',
          'fecha_creacion': module['fecha_creacion']?.toString() ?? '',
          'fecha_actualizacion': module['fecha_actualizacion']?.toString() ?? '',
          'metadata': module['metadata'] is String 
              ? module['metadata']
              : (module['metadata'] != null 
                  ? json.encode(module['metadata'])
                  : null),
          'categoria': module['categoria']?.toString(),
          'url_imagen': module['url_imagen']?.toString(),
          'autor': module['autor']?.toString(),
          'color': module['color']?.toString(),
          'icono': module['icono']?.toString(),
        };
      }).toList();
      
      _filteredModules = List.from(_allModules);
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error cargando módulos desde Supabase: $e');
      throw Exception('No se pudieron cargar los módulos. Verifica tu conexión a internet.');
    }
  }

  Future<void> _extractCategories() async {
    try {
      final Set<String> uniqueCategories = {'Todas'};
      
      for (var module in _allModules) {
        // Categoría directa desde la columna 'categoria'
        final categoria = module['categoria'];
        if (categoria != null && categoria.toString().isNotEmpty) {
          uniqueCategories.add(categoria.toString());
        }
        
        // Extraer de metadata si existe
        if (module['metadata'] != null) {
          try {
            final metadata = module['metadata'] is String 
                ? json.decode(module['metadata'] as String)
                : module['metadata'] as Map<String, dynamic>;
            
            if (metadata['category'] != null) {
              uniqueCategories.add(metadata['category'].toString());
            }
          } catch (e) {
            // Ignorar errores de parsing
          }
        }
      }
      
      // Ordenar alfabéticamente
      _categories = uniqueCategories.toList()..sort((a, b) => a.compareTo(b));
      notifyListeners();
      
    } catch (e) {
      debugPrint('Error extrayendo categorías: $e');
      _categories = ['Todas'];
    }
  }

  String _getModuleTitle(Map<String, dynamic> modulo) {
    return modulo['titulo']?.toString() ?? 'Módulo de ayuda';
  }

  String? _getModuleDescription(Map<String, dynamic> modulo) {
    return modulo['descripcion']?.toString() ?? modulo['contenido']?.toString();
  }

  void updateCategory(String category) {
    _selectedCategory = category;
    applyFilters();
  }

  void updateSortBy(String sortBy) {
    _sortBy = sortBy;
    applyFilters();
  }

  void resetFilters() {
    _selectedCategory = 'Todas';
    _sortBy = 'relevancia';
    searchController.clear();
    applyFilters();
  }

  void applyFilters() {
    List<Map<String, dynamic>> result = List.from(_allModules);

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      result = result.where((modulo) {
        final title = _getModuleTitle(modulo).toLowerCase();
        final descripcion = _getModuleDescription(modulo)?.toLowerCase() ?? '';
        final contenido = modulo['contenido']?.toString().toLowerCase() ?? '';
        
        return title.contains(_searchQuery) || 
               descripcion.contains(_searchQuery) ||
               contenido.contains(_searchQuery);
      }).toList();
    }

    // Filtrar por categoría
    if (_selectedCategory != 'Todas') {
      result = result.where((modulo) {
        // Verificar categoría directa
        if (modulo['categoria']?.toString() == _selectedCategory) {
          return true;
        }
        
        // Verificar en metadata
        if (modulo['metadata'] != null) {
          try {
            final metadata = modulo['metadata'] is String 
                ? json.decode(modulo['metadata'] as String)
                : modulo['metadata'] as Map<String, dynamic>;
            
            if (metadata['category']?.toString() == _selectedCategory) {
              return true;
            }
          } catch (e) {
            // Ignorar errores de parsing
          }
        }
        
        return false;
      }).toList();
    }

    // Ordenar
    result.sort((a, b) {
      switch (_sortBy) {
        case 'nombre':
          return _getModuleTitle(a).compareTo(_getModuleTitle(b));
        case 'reciente':
          try {
            final fechaA = DateTime.parse(a['fecha_creacion'] ?? '');
            final fechaB = DateTime.parse(b['fecha_creacion'] ?? '');
            return fechaB.compareTo(fechaA);
          } catch (e) {
            return 0;
          }
        case 'popular':
          return 0; // Lógica de popularidad si la agregas después
        default: // relevancia
          try {
            final fechaA = DateTime.parse(a['fecha_creacion'] ?? '');
            final fechaB = DateTime.parse(b['fecha_creacion'] ?? '');
            return fechaB.compareTo(fechaA);
          } catch (e) {
            return 0;
          }
      }
    });

    _filteredModules = result;
    notifyListeners();
  }

  Future<void> refreshModules() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await _loadAllModules();
      await _extractCategories();
      applyFilters();
    } catch (e) {
      _errorMessage = 'Error refrescando módulos: ${e.toString()}';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void setState(void Function() fn) {
    fn();
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}