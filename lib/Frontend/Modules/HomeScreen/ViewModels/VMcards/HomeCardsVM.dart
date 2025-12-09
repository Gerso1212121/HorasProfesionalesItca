// HomeScreen/ViewModels/PsychologyViewModel.dart
import 'package:flutter/material.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';

class PsychologyViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  
  // Estados
  List<Map<String, dynamic>> _psychologyModules = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  
  // Getters
  List<Map<String, dynamic>> get psychologyModules => _psychologyModules;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String? get errorMessage => _errorMessage;
  
  PsychologyViewModel() {
    // Cargar datos inmediatamente al crear el ViewModel
    _loadModules();
  }
  
  Future<void> _loadModules() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Obtener módulos de la base de datos local
      final modules = await _db.readModulos();
      
      // Convertir a formato Map si es necesario
      _psychologyModules = modules is List<Map<String, dynamic>> 
          ? modules 
          : modules.map((modulo) {
              // Convertir objeto Modulo a Map si es necesario
              if (modulo is Map<String, dynamic>) {
                return modulo;
              } else {
                // Si tienes una clase Modulo, convertirla aquí
                return {
                  'id': modulo['id'],
                  'titulo': modulo['titulo'],
                  'contenido': modulo['contenido'],
                  'fecha_creacion': modulo['fechaCreacion']?.toIso8601String(),
                  'fecha_actualizacion': modulo['fechaActualizacion']?.toIso8601String(),
                  'sincronizado': modulo['sincronizado'],
                  'metadata': modulo['metadata'],
                };
              }
            }).toList();
      
      _hasError = false;
      _errorMessage = null;
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Error al cargar los módulos';
      print('Error en _loadModules: $e');
      _psychologyModules = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> refresh() async {
    await _loadModules();
  }
  
  // Método para buscar módulos
  List<Map<String, dynamic>> searchModules(String query) {
    if (query.isEmpty) return _psychologyModules;
    
    final lowerQuery = query.toLowerCase();
    return _psychologyModules.where((module) {
      final title = module['titulo']?.toString().toLowerCase() ?? '';
      final content = module['contenido']?.toString().toLowerCase() ?? '';
      
      return title.contains(lowerQuery) || content.contains(lowerQuery);
    }).toList();
  }
  
  // Obtener módulo por ID
  Map<String, dynamic>? getModuleById(String id) {
    try {
      return _psychologyModules.firstWhere(
        (module) => module['id'] == id,
      );
    } catch (e) {
      return null;
    }
  }
}