// lib/Frontend/Modules/Diary/ViewModels/NoteViewModel.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:horas2/Frontend/Modules/Diary/model/diario_entry.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class NoteViewModel with ChangeNotifier {
  // Streams para fecha y estado de ánimo
  final StreamController<DateTime> _selectedDateController =
      StreamController<DateTime>.broadcast();
  final StreamController<String> _selectedMoodController =
      StreamController<String>.broadcast();

  // Controllers
  late QuillController _quillController;
  late TextEditingController _titleController;

  // Estado
  DiaryEntry? _currentEntry;
  bool _isLoading = false;

  // Dependencias
  final ImagePicker _imagePicker = ImagePicker();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Callbacks para mensajes (se asignan desde el NoteScreen)
  late Function(String) _showSuccessMessage;
  late Function(String) _showErrorMessage;

  // Getters
  Stream<DateTime> get selectedDateStream => _selectedDateController.stream;
  Stream<String> get selectedMoodStream => _selectedMoodController.stream;
  QuillController get quillController => _quillController;
  TextEditingController get titleController => _titleController;
  bool get isLoading => _isLoading;
  DiaryEntry? get currentEntry => _currentEntry;

  // Métodos para asignar callbacks
  void setMessageCallbacks({
    required Function(String) onSuccess,
    required Function(String) onError,
  }) {
    print('[NoteViewModel] setMessageCallbacks - Callbacks asignados');
    _showSuccessMessage = onSuccess;
    _showErrorMessage = onError;
  }

// Agrega estas variables privadas para almacenar el estado actual
  DateTime? _currentSelectedDate;
  String? _currentSelectedMood;

  Future<void> updateDate(DateTime newDate) async {
    print('[NoteViewModel] updateDate - Nueva fecha: $newDate');
    _currentSelectedDate = newDate; // Guardar el estado actual
    _selectedDateController.add(newDate);
  }

  Future<void> updateMood(String newMood) async {
    print('[NoteViewModel] updateMood - Nuevo estado de ánimo: $newMood');
    _currentSelectedMood = newMood; // Guardar el estado actual
    _selectedMoodController.add(newMood);
  }

// Reemplaza los métodos _getCurrentDate y _getCurrentMood:
  Future<DateTime> _getCurrentDate() async {
    print('[NoteViewModel] _getCurrentDate - Obteniendo fecha...');

    // Si tenemos una fecha guardada, usarla
    if (_currentSelectedDate != null) {
      print(
          '[NoteViewModel] _getCurrentDate - Usando fecha guardada: $_currentSelectedDate');
      return _currentSelectedDate!;
    }

    // Si no hay fecha guardada, intentar obtener del stream
    try {
      print(
          '[NoteViewModel] _getCurrentDate - Intentando obtener fecha del stream...');
      final completer = Completer<DateTime>();
      final subscription = selectedDateStream.listen(
        (date) {
          if (!completer.isCompleted) {
            print(
                '[NoteViewModel] _getCurrentDate - Fecha recibida del stream: $date');
            completer.complete(date);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            print('[NoteViewModel] _getCurrentDate - Error en stream: $error');
            completer.complete(DateTime.now());
          }
        },
        cancelOnError: true,
      );

      // Esperar un momento por si hay un valor pendiente
      await Future.delayed(Duration(milliseconds: 100));

      if (!completer.isCompleted) {
        // Si no recibimos nada, usar fecha actual
        print(
            '[NoteViewModel] _getCurrentDate - No se recibió fecha del stream, usando actual');
        completer.complete(DateTime.now());
      }

      final date = await completer.future;
      await subscription.cancel();
      print('[NoteViewModel] _getCurrentDate - Fecha final: $date');
      return date;
    } catch (e) {
      print('[NoteViewModel] _getCurrentDate - Error: $e, usando fecha actual');
      return DateTime.now();
    }
  }

  Future<String> _getCurrentMood() async {
    print('[NoteViewModel] _getCurrentMood - Obteniendo estado de ánimo...');

    // Si tenemos un estado de ánimo guardado, usarlo
    if (_currentSelectedMood != null) {
      print(
          '[NoteViewModel] _getCurrentMood - Usando estado de ánimo guardado: $_currentSelectedMood');
      return _currentSelectedMood!;
    }

    // Si no hay estado de ánimo guardado, intentar obtener del stream
    try {
      print(
          '[NoteViewModel] _getCurrentMood - Intentando obtener estado de ánimo del stream...');
      final completer = Completer<String>();
      final subscription = selectedMoodStream.listen(
        (mood) {
          if (!completer.isCompleted) {
            print(
                '[NoteViewModel] _getCurrentMood - Estado de ánimo recibido del stream: $mood');
            completer.complete(mood);
          }
        },
        onError: (error) {
          if (!completer.isCompleted) {
            print('[NoteViewModel] _getCurrentMood - Error en stream: $error');
            completer.complete('😊'); // Valor por defecto
          }
        },
        cancelOnError: true,
      );

      // Esperar un momento por si hay un valor pendiente
      await Future.delayed(Duration(milliseconds: 100));

      if (!completer.isCompleted) {
        // Si no recibimos nada, usar valor por defecto
        print(
            '[NoteViewModel] _getCurrentMood - No se recibió estado de ánimo del stream, usando por defecto');
        completer.complete('😊');
      }

      final mood = await completer.future;
      await subscription.cancel();
      print('[NoteViewModel] _getCurrentMood - Estado de ánimo final: $mood');
      return mood;
    } catch (e) {
      print('[NoteViewModel] _getCurrentMood - Error: $e, usando por defecto');
      return '😊';
    }
  }

  // Métodos públicos
  Future<void> initialize({DiaryEntry? existingEntry}) async {
    print(
        '[NoteViewModel] initialize - Iniciando, existingEntry: ${existingEntry != null}');
    _isLoading = true;
    print('[NoteViewModel] initialize - _isLoading = true');
    notifyListeners();

    try {
      if (existingEntry != null) {
        print(
            '[NoteViewModel] initialize - Editando entrada existente: ${existingEntry.title}');
        _currentEntry = existingEntry;
        _titleController = TextEditingController(text: existingEntry.title);
        _quillController = QuillController(
          document: existingEntry.getDocument(),
          selection: const TextSelection.collapsed(offset: 0),
        );
        _selectedDateController.add(existingEntry.date);
        _selectedMoodController.add(existingEntry.mood);
      } else {
        print('[NoteViewModel] initialize - Creando nueva entrada');
        _titleController = TextEditingController(text: 'Mi entrada del día');
        _quillController = QuillController(
          document: Document(),
          selection: const TextSelection.collapsed(offset: 0),
        );
        _selectedDateController.add(DateTime.now());
        _selectedMoodController.add('😊');
      }

      _isLoading = false;
      print('[NoteViewModel] initialize - _isLoading = false');
      notifyListeners();
      print('[NoteViewModel] initialize - Completado exitosamente');
    } catch (e) {
      print('[NoteViewModel] initialize - ERROR: $e');
      print('[NoteViewModel] initialize - StackTrace: ${e.toString()}');
      _isLoading = false;
      print('[NoteViewModel] initialize - _isLoading = false (por error)');
      notifyListeners();

      if (_showErrorMessage != null) {
        print('[NoteViewModel] initialize - Llamando _showErrorMessage');
        _showErrorMessage('Error al inicializar: $e');
      } else {
        print('[NoteViewModel] initialize - _showErrorMessage es null!');
      }
    }
  }
Future<void> saveEntry() async {
  print('[NoteViewModel] saveEntry - INICIANDO guardado');
  _isLoading = true;
  notifyListeners();

  try {
    final currentDate = await _getCurrentDate();
    final currentMood = await _getCurrentMood();

    // Guardar la selección actual ANTES de procesar
    final currentSelection = _quillController.selection;
    print('[NoteViewModel] saveEntry - Selección actual: $currentSelection');

    print('[NoteViewModel] saveEntry - Procesando imágenes en documento...');
    final processedDocument = await _processImagesInDocument(
      _quillController.document,
    );
    print('[NoteViewModel] saveEntry - Documento procesado');

    // ⚠️ ESTA ES LA PARTE PROBLEMÁTICA ⚠️
    // NO reemplazar el documento directamente. En su lugar:
    
    // 1. Obtener el contenido del documento procesado como JSON
    final processedContent = jsonEncode(processedDocument.toDelta().toJson());
    
    // 2. Para la visualización actual, podemos actualizar el documento
    // pero de manera segura
    if (processedContent != jsonEncode(_quillController.document.toDelta().toJson())) {
      // Solo actualizar si hay cambios reales
      try {
        // Guardar el estado actual del cursor
        final savedSelection = _quillController.selection;
        
        // Crear un nuevo controlador con el documento procesado
        final newController = QuillController(
          document: processedDocument,
          selection: const TextSelection.collapsed(offset: 0),
        );
        
        // Disposer el controlador antiguo
        _quillController.dispose();
        
        // Asignar el nuevo controlador
        _quillController = newController;
        
        // Restaurar la selección si es válida
        final safeOffset = savedSelection.baseOffset.clamp(
          0,
          _quillController.document.length,
        );
        
        // Verificar que el offset sea válido (0, 1 o -1)
        if (safeOffset == 0 || safeOffset == 1 || safeOffset == -1) {
          _quillController.updateSelection(
            TextSelection.collapsed(offset: safeOffset),
            ChangeSource.local,
          );
        } else {
          // Si no es válido, usar una posición por defecto
          _quillController.updateSelection(
            TextSelection.collapsed(offset: 0),
            ChangeSource.local,
          );
        }
      } catch (e) {
        print('[NoteViewModel] saveEntry - Error al actualizar controlador: $e');
        // Si falla, mantener el controlador actual
      }
    }

    print('[NoteViewModel] saveEntry - Creando objeto DiaryEntry...');
    
    // Crear entrada
    final entry = DiaryEntry(
      id: _currentEntry?.id,
      title: _titleController.text.trim(),
      date: currentDate,
      mood: currentMood,
      contentJson: processedContent, // Usar el contenido procesado
      compressedImagePaths: await _extractImagePaths(processedDocument),
      createdAt: _currentEntry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    print('[NoteViewModel] saveEntry - Entry creada: ${entry.title}');

    if (entry.id == null) {
      print('[NoteViewModel] saveEntry - Insertando NUEVA entrada...');
      final result = await _databaseHelper.insertDiaryEntry(
        title: entry.title,
        date: entry.date,
        mood: entry.mood,
        contentJson: entry.toMap()['content_json'],
        compressedImagePaths: entry.compressedImagePaths,
      );

      _currentEntry = DiaryEntry(
        id: result,
        title: entry.title,
        date: entry.date,
        mood: entry.mood,
        contentJson: entry.contentJson,
        compressedImagePaths: entry.compressedImagePaths,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
      );

      if (_showSuccessMessage != null) {
        _showSuccessMessage('Nota creada exitosamente');
      }
    } else {
      print('[NoteViewModel] saveEntry - Actualizando entrada existente');
      final rowsAffected = await _databaseHelper.updateDiaryEntry(
        id: entry.id!,
        title: entry.title,
        date: entry.date,
        mood: entry.mood,
        contentJson: entry.toMap()['content_json'],
        compressedImagePaths: entry.compressedImagePaths,
      );
      print('Filas afectadas: $rowsAffected');

      if (_showSuccessMessage != null) {
        _showSuccessMessage('Nota actualizada exitosamente');
      }
    }

    // Actualizar entrada actual
    _currentEntry = entry;
    print('[NoteViewModel] saveEntry - _currentEntry actualizado');

    _isLoading = false;
    notifyListeners();
    print('[NoteViewModel] saveEntry - GUARDADO COMPLETADO CON ÉXITO');
  } catch (e, stackTrace) {
    print('[NoteViewModel] saveEntry - ERROR CAPTURADO: $e');
    print('[NoteViewModel] saveEntry - STACK TRACE: $stackTrace');

    _isLoading = false;
    notifyListeners();

    if (_showErrorMessage != null) {
      _showErrorMessage('Error al guardar: ${e.toString()}');
    }
  }
}

  // Métodos para imágenes
  Future<void> insertImageFromGallery() async {
    print('[NoteViewModel] insertImageFromGallery - Iniciando');
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        print(
            '[NoteViewModel] insertImageFromGallery - Imagen seleccionada: ${image.path}');
        await _insertImageFile(image);
      } else {
        print(
            '[NoteViewModel] insertImageFromGallery - No se seleccionó imagen');
      }
    } catch (e) {
      print('[NoteViewModel] insertImageFromGallery - ERROR: $e');
      _showErrorMessage('Error al seleccionar imagen: $e');
    }
  }

  Future<void> insertImageFromCamera() async {
    print('[NoteViewModel] insertImageFromCamera - Iniciando');
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image != null) {
        print(
            '[NoteViewModel] insertImageFromCamera - Foto tomada: ${image.path}');
        await _insertImageFile(image);
      } else {
        print('[NoteViewModel] insertImageFromCamera - No se tomó foto');
      }
    } catch (e) {
      print('[NoteViewModel] insertImageFromCamera - ERROR: $e');
      _showErrorMessage('Error al tomar foto: $e');
    }
  }

  Future<void> insertDrawing(Uint8List drawingBytes) async {
    print(
        '[NoteViewModel] insertDrawing - Iniciando, tamaño bytes: ${drawingBytes.length}');
    try {
      final compressedBytes = await _compressImage(drawingBytes);
      print(
          '[NoteViewModel] insertDrawing - Bytes comprimidos a: ${compressedBytes.length}');
      await _insertImageBytes(compressedBytes);
    } catch (e) {
      print('[NoteViewModel] insertDrawing - ERROR: $e');
      _showErrorMessage('Error al insertar dibujo: $e');
    }
  }

  void insertEmoji(String emoji) {
    print('[NoteViewModel] insertEmoji - Insertando: $emoji');
    final offset = _quillController.selection.baseOffset;
    print('[NoteViewModel] insertEmoji - Offset: $offset');
    final safeOffset = offset.clamp(
      0,
      _quillController.document.length,
    );

    _quillController.document.insert(safeOffset, emoji);
    print('[NoteViewModel] insertEmoji - Emoji insertado');
  }

  Future<String> _compressAndMoveImage(String originalPath) async {
    print(
        '[NoteViewModel] _compressAndMoveImage - Iniciando, ruta original: $originalPath');
    try {
      // Leer la imagen original
      final originalFile = File(originalPath);
      final fileExists = await originalFile.exists();
      print(
          '[NoteViewModel] _compressAndMoveImage - Archivo existe: $fileExists');

      if (!fileExists) {
        throw Exception('Archivo no encontrado: $originalPath');
      }

      final originalBytes = await originalFile.readAsBytes();
      print(
          '[NoteViewModel] _compressAndMoveImage - Bytes originales: ${originalBytes.length}');

      // Comprimir la imagen
      final compressedBytes = await _compressImage(originalBytes);
      print(
          '[NoteViewModel] _compressAndMoveImage - Bytes comprimidos: ${compressedBytes.length}');

      // Guardar en directorio de documentos
      final appDir = await getApplicationDocumentsDirectory();
      final diaryImagesDir = Directory(path.join(appDir.path, 'diary_images'));

      final dirExists = await diaryImagesDir.exists();
      print(
          '[NoteViewModel] _compressAndMoveImage - Directorio existe: $dirExists');

      if (!dirExists) {
        print('[NoteViewModel] _compressAndMoveImage - Creando directorio...');
        await diaryImagesDir.create(recursive: true);
      }

      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedPath = path.join(diaryImagesDir.path, fileName);
      print(
          '[NoteViewModel] _compressAndMoveImage - Ruta destino: $compressedPath');

      await File(compressedPath).writeAsBytes(compressedBytes);
      print('[NoteViewModel] _compressAndMoveImage - Archivo guardado');

      // Eliminar archivo temporal si existe
      if (originalPath.contains('temp')) {
        print(
            '[NoteViewModel] _compressAndMoveImage - Eliminando archivo temporal...');
        await originalFile.delete();
      }

      print(
          '[NoteViewModel] _compressAndMoveImage - Completado, ruta final: $compressedPath');
      return compressedPath;
    } catch (e) {
      print('[NoteViewModel] _compressAndMoveImage - ERROR: $e');
      print(
          '[NoteViewModel] _compressAndMoveImage - StackTrace: ${e.toString()}');
      throw Exception('Error al comprimir imagen: $e');
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    print(
        '[NoteViewModel] _compressImage - Comprimiendo, tamaño original: ${bytes.length} bytes');
    // Implementación básica de compresión
    if (bytes.length > 1024 * 1024) {
      // Si es mayor a 1MB
      print(
          '[NoteViewModel] _compressImage - Imagen grande (>1MB), recortando...');
      // Aquí podrías usar un paquete de compresión de imágenes
      // Por ahora, simplemente limitamos el tamaño
      final result =
          bytes.sublist(0, min(bytes.length, 1024 * 512)); // 512KB máximo
      print(
          '[NoteViewModel] _compressImage - Tamaño después de recortar: ${result.length} bytes');
      return result;
    }
    print(
        '[NoteViewModel] _compressImage - Imagen pequeña, sin compresión adicional');
    return bytes;
  }

  Future<List<String>> _extractImagePaths(Document document) async {
    print(
        '[NoteViewModel] _extractImagePaths - Extrayendo rutas de imágenes...');
    final paths = <String>[];
    final delta = document.toDelta();
    final operations = delta.toList();
    print(
        '[NoteViewModel] _extractImagePaths - Total operaciones: ${operations.length}');

    int imageCount = 0;
    for (final op in operations) {
      if (op.isInsert && op.value is Map) {
        final value = op.value as Map;
        if (value.containsKey('image')) {
          final imagePath = value['image'] as String;
          if (imagePath.isNotEmpty) {
            imageCount++;
            print(
                '[NoteViewModel] _extractImagePaths - Imagen $imageCount: $imagePath');
            paths.add(imagePath);
          }
        }
      }
    }

    print(
        '[NoteViewModel] _extractImagePaths - Total imágenes encontradas: $imageCount');
    return paths;
  }

  Future<Document> _processImagesInDocument(Document originalDocument) async {
    print(
        '[NoteViewModel] _processImagesInDocument - Procesando imágenes en documento...');

    try {
      final delta = originalDocument.toDelta();
      final originalOperations = delta.toList();

      print(
          '[NoteViewModel] _processImagesInDocument - Total operaciones a procesar: ${originalOperations.length}');

      // Si no hay operaciones, retornar el documento original
      if (originalOperations.isEmpty) {
        print(
            '[NoteViewModel] _processImagesInDocument - Documento vacío, retornando original');
        return originalDocument;
      }

      final processedOperations = <Operation>[];
      bool hasImages = false;

      for (final op in originalOperations) {
        if (op.isInsert && op.value is Map) {
          final value = op.value as Map;
          if (value.containsKey('image')) {
            final imagePath = value['image'] as String;

            try {
              print(
                  '[NoteViewModel] _processImagesInDocument - Procesando imagen: $imagePath');
              // Comprimir y mover la imagen
              final compressedPath = await _compressAndMoveImage(imagePath);

              // Reemplazar con la ruta comprimida
              processedOperations.add(
                Operation.insert(
                  {'image': compressedPath},
                ),
              );

              hasImages = true;
            } catch (e) {
              print(
                  '[NoteViewModel] _processImagesInDocument - Error procesando imagen $imagePath: $e');
              // Si falla, mantener la operación original
              processedOperations.add(op);
            }
          } else {
            processedOperations.add(op);
          }
        } else if (op.isDelete) {
          processedOperations.add(Operation.delete(op.length!));
        } else if (op.isRetain) {
          processedOperations.add(Operation.retain(
            op.length!,
            op.attributes,
          ));
        } else {
          // Para cualquier otra operación (insert de texto)
          processedOperations.add(op);
        }
      }

      print(
          '[NoteViewModel] _processImagesInDocument - Imágenes procesadas: ${hasImages ? "Sí" : "No"}');

      // Si no procesamos ninguna imagen y todas las operaciones son las mismas,
      // podemos retornar el documento original
      if (!hasImages &&
          processedOperations.length == originalOperations.length) {
        print(
            '[NoteViewModel] _processImagesInDocument - Sin cambios, retornando documento original');
        return originalDocument;
      }

      // Crear un nuevo Delta con las operaciones procesadas
      final processedDelta = Delta();
      for (final op in processedOperations) {
        processedDelta.push(op);
      }

      // Asegurarnos de que el Delta no esté vacío
      if (processedDelta.toList().isEmpty) {
        print(
            '[NoteViewModel] _processImagesInDocument - Delta vacío, retornando documento original');
        return originalDocument;
      }

      print(
          '[NoteViewModel] _processImagesInDocument - Documento procesado exitosamente');
      return Document.fromDelta(processedDelta);
    } catch (e) {
      print(
          '[NoteViewModel] _processImagesInDocument - Error procesando documento: $e');
      // Si hay algún error, retornar el documento original
      return originalDocument;
    }
  }

  Future<void> _insertImageFile(XFile imageFile) async {
    print(
        '[NoteViewModel] _insertImageFile - Insertando imagen desde archivo: ${imageFile.path}');
    final bytes = await imageFile.readAsBytes();
    print('[NoteViewModel] _insertImageFile - Bytes leídos: ${bytes.length}');
    await _insertImageBytes(bytes);
  }

  Future<void> _insertImageBytes(Uint8List bytes) async {
    print('[NoteViewModel] _insertImageBytes - Insertando bytes de imagen...');

    // Guardar temporalmente
    final tempDir = await getTemporaryDirectory();
    final tempPath = path.join(
      tempDir.path,
      'temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    print('[NoteViewModel] _insertImageBytes - Ruta temporal: $tempPath');
    await File(tempPath).writeAsBytes(bytes);
    print('[NoteViewModel] _insertImageBytes - Archivo temporal guardado');

    // Insertar en el editor
    final index = _quillController.selection.baseOffset.clamp(
      0,
      _quillController.document.length,
    );
    print('[NoteViewModel] _insertImageBytes - Offset de inserción: $index');
    final block = BlockEmbed.image(tempPath);

    _quillController.document.insert(index, block);
    _quillController.document.insert(index + 1, '\n');
    _quillController.updateSelection(
      TextSelection.collapsed(offset: index + 2),
      ChangeSource.local,
    );

    print('[NoteViewModel] _insertImageBytes - Imagen insertada en editor');
  }

  // Método para obtener entradas por mes
  Future<List<Map<String, dynamic>>> getEntriesByMonth(
      int year, int month) async {
    print(
        '[NoteViewModel] getEntriesByMonth - Obteniendo entradas para $month/$year');
    try {
      final result = await _databaseHelper.getDiaryEntriesByMonth(year, month);
      print(
          '[NoteViewModel] getEntriesByMonth - ${result.length} entradas obtenidas');
      return result;
    } catch (e) {
      print('[NoteViewModel] getEntriesByMonth - ERROR: $e');
      _showErrorMessage('Error al obtener entradas: $e');
      return [];
    }
  }

  // Método para obtener entrada por ID
  Future<Map<String, dynamic>?> getEntryById(int id) async {
    print('[NoteViewModel] getEntryById - Obteniendo entrada ID: $id');
    try {
      final result = await _databaseHelper.getDiaryEntryById(id);
      print(
          '[NoteViewModel] getEntryById - Resultado: ${result != null ? "Encontrada" : "No encontrada"}');
      return result;
    } catch (e) {
      print('[NoteViewModel] getEntryById - ERROR: $e');
      _showErrorMessage('Error al obtener entrada: $e');
      return null;
    }
  }

  // Método para eliminar entrada
  Future<bool> deleteEntry(int id) async {
    print('[NoteViewModel] deleteEntry - Eliminando entrada ID: $id');
    try {
      final result = await _databaseHelper.deleteDiaryEntry(id);
      print('[NoteViewModel] deleteEntry - Filas afectadas: $result');

      if (result > 0) {
        print(
            '[NoteViewModel] deleteEntry - Éxito, llamando _showSuccessMessage');
        _showSuccessMessage('Entrada eliminada exitosamente');
        return true;
      } else {
        print('[NoteViewModel] deleteEntry - No se eliminó ninguna fila');
        _showErrorMessage('No se pudo eliminar la entrada');
        return false;
      }
    } catch (e) {
      print('[NoteViewModel] deleteEntry - ERROR: $e');
      _showErrorMessage('Error al eliminar: $e');
      return false;
    }
  }

  // Método para obtener estadísticas
  Future<Map<String, dynamic>> getStatistics() async {
    print('[NoteViewModel] getStatistics - Obteniendo estadísticas...');
    try {
      final result = await _databaseHelper.getDiaryStatistics();
      print('[NoteViewModel] getStatistics - Estadísticas obtenidas: $result');
      return result;
    } catch (e) {
      print('[NoteViewModel] getStatistics - ERROR: $e');
      _showErrorMessage('Error al obtener estadísticas: $e');
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

  void dispose() {
    print('[NoteViewModel] dispose - Limpiando recursos...');
    _selectedDateController.close();
    print('[NoteViewModel] dispose - _selectedDateController cerrado');
    _selectedMoodController.close();
    print('[NoteViewModel] dispose - _selectedMoodController cerrado');
    _quillController.dispose();
    print('[NoteViewModel] dispose - _quillController disposed');
    _titleController.dispose();
    print('[NoteViewModel] dispose - _titleController disposed');
    print('[NoteViewModel] dispose - Recursos limpiados');
  }
}
