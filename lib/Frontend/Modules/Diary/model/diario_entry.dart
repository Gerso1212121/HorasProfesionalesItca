// lib/Frontend/Modules/Diary/Models/DiaryEntry.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:path/path.dart' as path;

class DiaryEntry {
  int? id;
  String title;
  DateTime date;
  String mood;
  String contentJson;
  List<String> compressedImagePaths;
  DateTime createdAt;
  DateTime updatedAt;

  DiaryEntry({
    this.id,
    required this.title,
    required this.date,
    required this.mood,
    required this.contentJson,
    this.compressedImagePaths = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  // Método para obtener el contenido como Document de Quill
  Document getDocument() {
    try {
      final delta = Delta.fromJson(jsonDecode(contentJson));
      return Document.fromDelta(delta);
    } catch (e) {
      return Document();
    }
  }

  // Método para convertir a mapa para SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'mood': mood,
      'content_json': contentJson,
      'compressed_image_paths': jsonEncode(compressedImagePaths),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Método para crear desde mapa de SQLite
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      mood: map['mood'],
      contentJson: map['content_json'],
      compressedImagePaths: List<String>.from(
          jsonDecode(map['compressed_image_paths'] ?? '[]')),
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Método para copiar con nuevos valores
  DiaryEntry copyWith({
    int? id,
    String? title,
    DateTime? date,
    String? mood,
    String? contentJson,
    List<String>? compressedImagePaths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      contentJson: contentJson ?? this.contentJson,
      compressedImagePaths: compressedImagePaths ?? this.compressedImagePaths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}