// lib/Frontend/Modules/Diary/model/diary_entry.dart
class DiaryEntry {
  final String id;
  final String title;
  final String content;
  final DateTime date;
  final String emoji;
  final List<String> images;
  final List<ContentBlock> contentBlocks;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
    this.emoji = "😊",
    this.images = const [],
    this.contentBlocks = const [],
  });

  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'] ?? '',
      title: map['titulo'] ?? '',
      content: map['contenido'] ?? '',
      date: map['fecha'] != null ? DateTime.parse(map['fecha']) : DateTime.now(),
      emoji: map['emoji'] ?? "😊",
      images: List<String>.from(map['images'] ?? []),
      contentBlocks: (map['contentBlocks'] as List<dynamic>? ?? [])
          .map((block) => ContentBlock.fromMap(block))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': title,
      'contenido': content,
      'fecha': date.toIso8601String(),
      'emoji': emoji,
      'images': images,
      'contentBlocks': contentBlocks.map((block) => block.toMap()).toList(),
    };
  }
}

class ContentBlock {
  final String type; // "text", "image", "drawing"
  final String value;

  ContentBlock({
    required this.type,
    required this.value,
  });

  factory ContentBlock.fromMap(Map<String, dynamic> map) {
    return ContentBlock(
      type: map['type'] ?? 'text',
      value: map['value'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'value': value,
    };
  }
}