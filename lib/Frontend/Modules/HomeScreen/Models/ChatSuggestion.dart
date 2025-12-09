import 'dart:ui';

import 'package:flutter/material.dart';

class ChatSuggestion {
  final String topic;
  final String summary;
  final String prompt;
  final Color backgroundColor;
  final String? emojiIcon;
  final IconData? customIcon;

  ChatSuggestion({
    required this.topic,
    required this.summary,
    required this.prompt,
    required this.backgroundColor,
    this.emojiIcon,
    this.customIcon,
  });

  // Método para crear sugerencia por defecto
  factory ChatSuggestion.defaultSuggestion(int index) {
    final styles = [
      {
        'backgroundColor': const Color(0xFFFFF2CC),
        'emojiIcon': '😊',
        'topic': 'Bienestar emocional',
        'summary': 'Hablar sobre cómo te has sentido últimamente y qué cosas te están preocupando.',
        'prompt': 'Quiero hablar sobre mi bienestar emocional y cómo me he estado sintiendo estos días.'
      },
      {
        'backgroundColor': const Color(0xFFD0E5F8),
        'emojiIcon': '📚',
        'topic': 'Ansiedad y estrés académico',
        'summary': 'Explorar cómo te afecta la carga de estudios y buscar estrategias para manejar la ansiedad.',
        'prompt': 'Me gustaría hablar sobre mi ansiedad y el estrés que siento por los estudios y exámenes.'
      },
      {
        'backgroundColor': const Color(0xFFE8D7FF),
        'emojiIcon': '🎯',
        'topic': 'Metas personales y motivación',
        'summary': 'Conversar sobre tus metas, lo que quieres lograr y cómo mantenerte motivado.',
        'prompt': 'Quiero hablar sobre mis metas personales y cómo mantenerme motivado sin sentirme tan presionado.'
      },
    ];
    
    final style = styles[index % styles.length];
    
    return ChatSuggestion(
      topic: style['topic'] as String,
      summary: style['summary'] as String,
      prompt: style['prompt'] as String,
      backgroundColor: style['backgroundColor'] as Color,
      emojiIcon: style['emojiIcon'] as String,
    );
  }

  // Lista de estilos disponibles
  static List<Map<String, dynamic>> get suggestionStyles => [
    {'backgroundColor': const Color(0xFFFFF2CC), 'emojiIcon': '😊'},
    {'backgroundColor': const Color(0xFFD0E5F8), 'emojiIcon': '📚'},
    {'backgroundColor': const Color(0xFFE8D7FF), 'emojiIcon': '🎯'},
    {'backgroundColor': const Color(0xFFCDEDEA), 'emojiIcon': '🤝'},
    {'backgroundColor': const Color(0xFFFAD4D4), 'emojiIcon': '💙'},
    {'backgroundColor': const Color(0xFFFFE5CC), 'emojiIcon': '🌟'},
    {'backgroundColor': const Color(0xFFE5CCFF), 'emojiIcon': '💪'},
    {'backgroundColor': const Color(0xFFCCE5FF), 'emojiIcon': '🧠'},
  ];
}