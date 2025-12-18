// lib/Frontend/Modules/Diary/ViewModels/DiaryScreenViewModel.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:horas2/Frontend/Modules/Diary/model/diario_entry.dart';

class DiaryScreenViewModel with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  
  // Estado
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Filtros
  DateTime? _selectedDate;
  String? _selectedMood;
  String? _searchQuery;

  // Getters
  List<Map<String, dynamic>> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  DateTime? get selectedDate => _selectedDate;
  String? get selectedMood => _selectedMood;
  String? get searchQuery => _searchQuery;

  // Setters para filtros
  void setSelectedDate(DateTime? date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setSelectedMood(String? mood) {
    _selectedMood = mood;
    notifyListeners();
  }

  void setSearchQuery(String? query) {
    _searchQuery = query;
    notifyListeners();
  }

// lib/Frontend/Modules/Diary/ViewModels/DiaryScreenViewModel.dart
// Modifica la función loadEntries y filterEntries:

Future<void> loadEntries() async {
  try {
    print('[DiaryScreenViewModel] loadEntries - Iniciando carga...');
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    final allEntries = await _databaseHelper.getAllDiaryEntries();
    print('[DiaryScreenViewModel] loadEntries - ${allEntries.length} entradas obtenidas');

    final List<Map<String, dynamic>> processedEntries = [];
    
    for (final dbEntry in allEntries) {
      try {
        final entry = DiaryEntry.fromMap(dbEntry);
        
        // Obtener rutas de imágenes de la entrada
        final imagePaths = entry.compressedImagePaths;
        final hasImages = imagePaths.isNotEmpty;
        
        // AGREGAR: Convertir rutas de imágenes a lista para la UI
        final List<String> imageList = [];
        for (final imagePath in imagePaths) {
          if (imagePath is String && imagePath.isNotEmpty) {
            imageList.add(imagePath);
          }
        }

        processedEntries.add({
          'id': entry.id,
          'fecha': entry.date,
          'titulo': entry.title,
          'contenido': _getEntrySummary(entry),
          'emoji': _extractFirstEmoji(entry.contentJson) ?? '📝',
          'imagenes': imagePaths.length, // Contador
          'imagenes_lista': imageList, // ← LISTA COMPLETA DE RUTAS
          'hora': _formatTime(entry.createdAt),
          'colorSet': _getColorSetIndex(entry.date),
          'entry': entry,
        });
        
      } catch (e, stackTrace) {
        print('[DiaryScreenViewModel] Error convirtiendo entrada: $e');
      }
    }

    _entries = processedEntries;
    _entries.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));
    
    _isLoading = false;
    notifyListeners();
  } catch (e, stackTrace) {
    print('[DiaryScreenViewModel] loadEntries - ERROR: $e');
    _isLoading = false;
    _hasError = true;
    _errorMessage = 'Error al cargar las entradas: $e';
    notifyListeners();
  }
}

// También actualiza la función filterEntries de manera similar:
Future<void> filterEntries() async {
  try {
    _isLoading = true;
    notifyListeners();

    final allEntries = await _databaseHelper.getAllDiaryEntries();
    
    List<Map<String, dynamic>> filtered = [];
    
    for (final dbEntry in allEntries) {
      try {
        final entry = DiaryEntry.fromMap(dbEntry);
        final matchesDate = _selectedDate == null || 
            _isSameDay(entry.date, _selectedDate!);
        final matchesMood = _selectedMood == null || 
            _extractFirstEmoji(entry.contentJson) == _selectedMood;
        final matchesSearch = _searchQuery == null || 
            entry.title.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
            _getEntrySummary(entry).toLowerCase().contains(_searchQuery!.toLowerCase());

        if (matchesDate && matchesMood && matchesSearch) {
          // Obtener lista de imágenes para esta entrada
          final imagePaths = entry.compressedImagePaths;
          final List<String> imageList = [];
          for (final imagePath in imagePaths) {
            if (imagePath is String && imagePath.isNotEmpty) {
              imageList.add(imagePath);
            }
          }

          filtered.add({
            'id': entry.id,
            'fecha': entry.date,
            'titulo': entry.title,
            'contenido': _getEntrySummary(entry),
            'emoji': _extractFirstEmoji(entry.contentJson) ?? '📝',
            'imagenes': imagePaths.length,
            'imagenes_lista': imageList, // ← AGREGAR LISTA
            'hora': _formatTime(entry.createdAt),
            'colorSet': _getColorSetIndex(entry.date),
            'entry': entry,
          });
        }
      } catch (e) {
        print('[DiaryScreenViewModel] Error procesando entrada para filtro: $e');
      }
    }

    _entries = filtered;
    _entries.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));
    
    _isLoading = false;
    notifyListeners();
  } catch (e) {
    print('[DiaryScreenViewModel] filterEntries - ERROR: $e');
    _isLoading = false;
    _hasError = true;
    _errorMessage = 'Error al filtrar entradas: $e';
    notifyListeners();
  }
}

  // Cargar entradas por mes
  Future<void> loadEntriesByMonth(int year, int month) async {
    try {
      print('[DiaryScreenViewModel] loadEntriesByMonth - Cargando entradas para $month/$year');
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      notifyListeners();

      final monthEntries = await _databaseHelper.getDiaryEntriesByMonth(year, month);
      print('[DiaryScreenViewModel] loadEntriesByMonth - ${monthEntries.length} entradas obtenidas');

      // Convertir a formato para la UI
      _entries = monthEntries.map((dbEntry) {
        try {
          final entry = DiaryEntry.fromMap(dbEntry);
          
          return {
            'id': entry.id,
            'fecha': entry.date,
            'titulo': entry.title,
            'contenido': _getEntrySummary(entry),
            'emoji': _extractFirstEmoji(entry.contentJson) ?? '📝',
            'imagenes': entry.compressedImagePaths.length,
            'hora': _formatTime(entry.createdAt),
            'colorSet': _getColorSetIndex(entry.date),
            'entry': entry,
          };
        } catch (e) {
          print('[DiaryScreenViewModel] Error convirtiendo entrada mensual: $e');
          return null;
        }
      }).where((entry) => entry != null).cast<Map<String, dynamic>>().toList();

      _entries.sort((a, b) => (b['fecha'] as DateTime).compareTo(a['fecha'] as DateTime));
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('[DiaryScreenViewModel] loadEntriesByMonth - ERROR: $e');
      _isLoading = false;
      _hasError = true;
      _errorMessage = 'Error al cargar las entradas del mes: $e';
      notifyListeners();
    }
  }

 
// DiaryScreenViewModel.dart - Agrega estos métodos
Future<bool> deleteEntry(int id, {String? title}) async {
  try {
    print('[DiaryScreenViewModel] deleteEntry - Eliminando entrada ID: $id${title != null ? " - $title" : ""}');
    final result = await _databaseHelper.deleteDiaryEntry(id);
    
    if (result > 0) {
      // Remover de la lista local
      _entries.removeWhere((entry) => entry['id'] == id);
      notifyListeners();
      print('[DiaryScreenViewModel] deleteEntry - Entrada eliminada exitosamente');
      return true;
    } else {
      print('[DiaryScreenViewModel] deleteEntry - No se pudo eliminar la entrada');
      return false;
    }
  } catch (e) {
    print('[DiaryScreenViewModel] deleteEntry - ERROR: $e');
    _hasError = true;
    _errorMessage = 'Error al eliminar la entrada: $e';
    notifyListeners();
    return false;
  }
}

// Método para obtener la entrada por ID
Map<String, dynamic>? getEntryById(int id) {
  try {
    return _entries.firstWhere((entry) => entry['id'] == id);
  } catch (e) {
    return null;
  }
}

  // Obtener estadísticas
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      print('[DiaryScreenViewModel] getStatistics - Obteniendo estadísticas...');
      return await _databaseHelper.getDiaryStatistics();
    } catch (e) {
      print('[DiaryScreenViewModel] getStatistics - ERROR: $e');
      return {
        'total_entries': 0,
        'entries_this_month': 0,
        'most_common_mood': null,
        'writing_streak': 0,
        'total_images': 0,
        'avg_entries_per_month': 0.0,
      };
    }
  }

  // Métodos auxiliares privados
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  int _getColorSetIndex(DateTime date) {
    // Usar el día del mes para determinar el color set (0-4)
    return date.day % 5;
  }

  String? _extractFirstEmoji(dynamic content) {
    try {
      String contentString;
      
      // Manejar diferentes tipos de contenido
      if (content is String) {
        contentString = content;
      } else if (content is List) {
        // Si es una lista, convertir a JSON string
        contentString = jsonEncode(content);
      } else if (content is Map) {
        // Si es un mapa, convertir a JSON string
        contentString = jsonEncode(content);
      } else {
        return null;
      }

      // Intentar parsear como JSON
      try {
        final parsed = jsonDecode(contentString);
        if (parsed is Map && parsed.containsKey('ops')) {
          final ops = parsed['ops'] as List;
          for (final op in ops) {
            if (op is Map && op.containsKey('insert') && op['insert'] is String) {
              final text = op['insert'] as String;
              // Buscar el primer emoji en el texto
              final emojiRegex = RegExp(
                r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
                unicode: true,
              );
              final match = emojiRegex.firstMatch(text);
              if (match != null) {
                return match.group(0);
              }
            }
          }
        }
      } catch (e) {
        // Si no es JSON válido, buscar emojis directamente en el string
        final emojiRegex = RegExp(
          r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F1E0}-\u{1F1FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
          unicode: true,
        );
        final match = emojiRegex.firstMatch(contentString);
        if (match != null) {
          return match.group(0);
        }
      }
    } catch (e) {
      print('[DiaryScreenViewModel] Error extrayendo emoji: $e');
      print('[DiaryScreenViewModel] Tipo de contenido: ${content.runtimeType}');
    }
    return null;
  }

  String _getEntrySummary(DiaryEntry entry) {
    try {
      // Intentar usar el método getSummary de DiaryEntry
      return entry.getSummary();
    } catch (e) {
      // Si falla, extraer texto del contenido
      try {
        if (entry.contentJson is String) {
          final contentJsonString = entry.contentJson as String;
          if (contentJsonString.length > 100) {
            return '${contentJsonString.substring(0, 100)}...';
          }
          return contentJsonString;
        } else if (entry.contentJson is List) {
          // Si el contenido es una lista (como del editor Quill)
          final contentJsonList = entry.contentJson as List;
          final text = contentJsonList
              .where((item) => item is Map && item['insert'] is String)
              .map((item) => (item as Map)['insert'] as String)
              .join(' ');
          
          if (text.length > 100) {
            return '${text.substring(0, 100)}...';
          }
          return text;
        }
      } catch (e2) {
        print('[DiaryScreenViewModel] Error obteniendo resumen: $e2');
      }
      return 'Contenido no disponible';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  // Limpiar filtros
  void clearFilters() {
    _selectedDate = null;
    _selectedMood = null;
    _searchQuery = null;
    notifyListeners();
  }

  // Actualizar manualmente
  void refresh() {
    loadEntries();
  }
}