// lib/Frontend/Modules/Diary/model/diario_entry.dart
import 'dart:convert';
import 'package:flutter_quill/flutter_quill.dart';

class DiaryEntry {
  final int? id;
  final String title;
  final DateTime date;
  final String mood;
  final String contentJson;
  final List<String> compressedImagePaths;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry({
    this.id,
    required this.title,
    required this.date,
    required this.mood,
    required this.contentJson,
    required this.compressedImagePaths,
    required this.createdAt,
    required this.updatedAt,
  });

  // Método para obtener un Document de Flutter Quill
  Document getDocument() {
    try {
      final delta = Delta.fromJson(jsonDecode(contentJson));
      return Document.fromDelta(delta);
    } catch (e) {
      print('Error parsing document: $e');
      return Document();
    }
  }

  // Convertir a Map para la base de datos
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'mood': mood,
      'content_json': contentJson,
      'compressed_image_paths': compressedImagePaths.join('|'),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Crear desde un Map de la base de datos
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] as int?,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      mood: map['mood'] as String,
      contentJson: map['content_json'] is String
          ? map['content_json'] as String
          : jsonEncode(map['content_json']),
      compressedImagePaths: map['compressed_image_paths'] == null
          ? []
          : map['compressed_image_paths'] is String
              ? (map['compressed_image_paths'] as String)
                  .split('|')
                  .where((p) => p.isNotEmpty)
                  .toList()
              : List<String>.from(map['compressed_image_paths']),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  // Método para obtener un resumen del contenido (primeros 100 caracteres sin HTML)
  String getSummary() {
    try {
      final document = getDocument();
      final plainText = document.toPlainText();
      return plainText.length > 100
          ? '${plainText.substring(0, 100)}...'
          : plainText;
    } catch (e) {
      return 'Contenido no disponible';
    }
  }

  // Método para verificar si tiene imágenes
  bool hasImages() {
    return compressedImagePaths.isNotEmpty;
  }

  // Método para obtener la primera imagen (si existe)
  String? getFirstImage() {
    return compressedImagePaths.isNotEmpty ? compressedImagePaths.first : null;
  }
}
