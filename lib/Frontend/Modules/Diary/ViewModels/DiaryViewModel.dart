// lib/Frontend/Modules/Diary/ViewModels/NoteViewModel.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:horas2/Frontend/Modules/Diary/model/diario_entry.dart';
import 'package:horas2/Frontend/Modules/Diary/model/diarydb.dart';
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
  final DiaryDatabase _database = DiaryDatabase();

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
    _showSuccessMessage = onSuccess;
    _showErrorMessage = onError;
  }

  // Métodos públicos
  Future<void> initialize({DiaryEntry? existingEntry}) async {
    _isLoading = true;
    notifyListeners();

    if (existingEntry != null) {
      _currentEntry = existingEntry;
      _titleController = TextEditingController(text: existingEntry.title);
      _quillController = QuillController(
        document: existingEntry.getDocument(),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _selectedDateController.add(existingEntry.date);
      _selectedMoodController.add(existingEntry.mood);
    } else {
      _titleController = TextEditingController(text: 'Mi entrada del día');
      _quillController = QuillController(
        document: Document(),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _selectedDateController.add(DateTime.now());
      _selectedMoodController.add('😊');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateDate(DateTime newDate) async {
    _selectedDateController.add(newDate);
  }

  Future<void> updateMood(String newMood) async {
    _selectedMoodController.add(newMood);
  }

  Future<void> saveEntry() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Obtener valores actuales
      final currentDate = await _getCurrentDate();
      final currentMood = await _getCurrentMood();

      // Procesar imágenes antes de guardar
      final processedDocument = await _processImagesInDocument(
        _quillController.document,
      );

      final entry = DiaryEntry(
        id: _currentEntry?.id,
        title: _titleController.text.trim(),
        date: currentDate,
        mood: currentMood,
        contentJson: jsonEncode(processedDocument.toDelta().toJson()),
        compressedImagePaths: await _extractImagePaths(processedDocument),
        createdAt: _currentEntry?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (entry.id == null) {
        await _database.insertEntry(entry);
      } else {
        await _database.updateEntry(entry);
      }

      _showSuccessMessage('Nota guardada exitosamente');
    } catch (e) {
      _showErrorMessage('Error al guardar: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Métodos para imágenes
  Future<void> insertImageFromGallery() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _insertImageFile(image);
      }
    } catch (e) {
      _showErrorMessage('Error al seleccionar imagen: $e');
    }
  }

  Future<void> insertImageFromCamera() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      
      if (image != null) {
        await _insertImageFile(image);
      }
    } catch (e) {
      _showErrorMessage('Error al tomar foto: $e');
    }
  }

  Future<void> insertDrawing(Uint8List drawingBytes) async {
    try {
      final compressedBytes = await _compressImage(drawingBytes);
      await _insertImageBytes(compressedBytes);
    } catch (e) {
      _showErrorMessage('Error al insertar dibujo: $e');
    }
  }

  void insertEmoji(String emoji) {
    final offset = _quillController.selection.baseOffset;
    _quillController.document.insert(offset, emoji);
  }

  // Métodos privados
  Future<DateTime> _getCurrentDate() async {
    final completer = Completer<DateTime>();
    final subscription = selectedDateStream.listen((date) {
      if (!completer.isCompleted) {
        completer.complete(date);
      }
    });
    
    final date = await completer.future;
    subscription.cancel();
    return date;
  }

  Future<String> _getCurrentMood() async {
    final completer = Completer<String>();
    final subscription = selectedMoodStream.listen((mood) {
      if (!completer.isCompleted) {
        completer.complete(mood);
      }
    });
    
    final mood = await completer.future;
    subscription.cancel();
    return mood;
  }

  Future<String> _compressAndMoveImage(String originalPath) async {
    try {
      // Leer la imagen original
      final originalFile = File(originalPath);
      final originalBytes = await originalFile.readAsBytes();
      
      // Comprimir la imagen
      final compressedBytes = await _compressImage(originalBytes);
      
      // Guardar en directorio de documentos
      final appDir = await getApplicationDocumentsDirectory();
      final diaryImagesDir = Directory(path.join(appDir.path, 'diary_images'));
      
      if (!await diaryImagesDir.exists()) {
        await diaryImagesDir.create(recursive: true);
      }
      
      final fileName = 'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedPath = path.join(diaryImagesDir.path, fileName);
      
      await File(compressedPath).writeAsBytes(compressedBytes);
      
      // Eliminar archivo temporal si existe
      if (originalPath.contains('temp')) {
        await originalFile.delete();
      }
      
      return compressedPath;
    } catch (e) {
      throw Exception('Error al comprimir imagen: $e');
    }
  }

  Future<Uint8List> _compressImage(Uint8List bytes) async {
    // Aquí puedes implementar lógica de compresión más avanzada
    // Por ahora, solo reducimos la calidad si es muy grande
    if (bytes.length > 1024 * 1024) { // Si es mayor a 1MB
      // Podrías usar el paquete image para redimensionar
      // Por simplicidad, devolvemos los mismos bytes
      return bytes;
    }
    return bytes;
  }

  Future<List<String>> _extractImagePaths(Document document) async {
    final paths = <String>[];
    final delta = document.toDelta();
    
    // Usar el método toList() para obtener las operaciones
    final operations = delta.toList();
    
    for (final op in operations) {
      if (op.isInsert && op.value is Map) {
        final value = op.value as Map;
        if (value.containsKey('image')) {
          paths.add(value['image'] as String);
        }
      }
    }
    
    return paths;
  }

  Future<Document> _processImagesInDocument(Document document) async {
    final delta = document.toDelta();
    final processedOperations = <Operation>[];

    // Usar el método toList() para obtener las operaciones
    final operations = delta.toList();
    
    for (final op in operations) {
      if (op.isInsert && op.value is Map) {
        final value = op.value as Map;
        if (value.containsKey('image')) {
          final imagePath = value['image'] as String;
          
          // Comprimir y mover la imagen
          final compressedPath = await _compressAndMoveImage(imagePath);
          
          // Reemplazar con la ruta comprimida - Crear nueva operación
          processedOperations.add(
            Operation.insert(
              compressedPath,
              {'image': compressedPath},
            ),
          );
        } else {
          processedOperations.add(op);
        }
      } else if (op.isDelete) {
        // Mantener operaciones de eliminación
        processedOperations.add(Operation.delete(op.length!));
      } else if (op.isRetain) {
        // Mantener operaciones de retención
        processedOperations.add(Operation.retain(
          op.length!,
          op.attributes,
        ));
      }
    }

    // Crear un nuevo Delta con las operaciones procesadas
    final processedDelta = Delta();
    for (final op in processedOperations) {
      processedDelta.push(op);
    }
    
    return Document.fromDelta(processedDelta);
  }

  Future<void> _insertImageFile(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    await _insertImageBytes(bytes);
  }

  Future<void> _insertImageBytes(Uint8List bytes) async {
    // Guardar temporalmente
    final tempDir = await getTemporaryDirectory();
    final tempPath = path.join(
      tempDir.path,
      'temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    
    await File(tempPath).writeAsBytes(bytes);
    
    // Insertar en el editor
    final index = _quillController.selection.baseOffset;
    final block = BlockEmbed.image(tempPath);
    
    _quillController.document.insert(index, block);
    _quillController.document.insert(index + 1, '\n');
    _quillController.updateSelection(
      TextSelection.collapsed(offset: index + 2),
      ChangeSource.local,
    );
  }

  void dispose() {
    _selectedDateController.close();
    _selectedMoodController.close();
    _quillController.dispose();
    _titleController.dispose();
  }
}