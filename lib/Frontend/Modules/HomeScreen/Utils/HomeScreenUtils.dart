// HomeScreen/home_screen_utils.dart
import 'package:flutter/material.dart';

class HomeScreenUtils {
  static String getMonthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return months[month - 1];
  }

  static Map<String, dynamic> getCardColorsForModule(int index) {
    final List<Map<String, dynamic>> colorSchemes = [
      // Esquema azul (para módulo 1)
      {
        'background1': Colors.white,
        'background2': Colors.white,
        'borderColor': const Color(0xFF2196F3).withOpacity(0.25),
        'shadowColor': const Color(0xFF2196F3).withOpacity(0.15),
        'bubbleColor': const Color(0xFF2196F3).withOpacity(0.05),
        'badgeColor1': const Color(0xFF2196F3),
        'badgeColor2': const Color(0xFF42A5F5),
        'badgeShadow': const Color(0xFF2196F3).withOpacity(0.3),
        'iconColor': const Color(0xFF2196F3),
        'tagBackground': const Color(0xFF2196F3).withOpacity(0.1),
        'tagTextColor': const Color(0xFF2196F3),
        'buttonColor1': const Color(0xFF2196F3),
        'buttonColor2': const Color(0xFF42A5F5),
        'buttonShadow': const Color(0xFF2196F3).withOpacity(0.25),
      },
      // Esquema naranja (para módulo 2)
      {
        'background1': Colors.white,
        'background2': Colors.white,
        'borderColor': const Color(0xFFFF9800).withOpacity(0.25),
        'shadowColor': const Color(0xFFFF9800).withOpacity(0.15),
        'bubbleColor': const Color(0xFFFF9800).withOpacity(0.05),
        'badgeColor1': const Color(0xFFFF9800),
        'badgeColor2': const Color(0xFFFFB74D),
        'badgeShadow': const Color(0xFFFF9800).withOpacity(0.3),
        'iconColor': const Color(0xFFFF9800),
        'tagBackground': const Color(0xFFFF9800).withOpacity(0.1),
        'tagTextColor': const Color(0xFFFF9800),
        'buttonColor1': const Color(0xFFFF9800),
        'buttonColor2': const Color(0xFFFFB74D),
        'buttonShadow': const Color(0xFFFF9800).withOpacity(0.25),
      },
      // Esquema púrpura (para módulo 3)
      {
        'background1': Colors.white,
        'background2': Colors.white,
        'borderColor': const Color(0xFF9C27B0).withOpacity(0.25),
        'shadowColor': const Color(0xFF9C27B0).withOpacity(0.15),
        'bubbleColor': const Color(0xFF9C27B0).withOpacity(0.05),
        'badgeColor1': const Color(0xFF9C27B0),
        'badgeColor2': const Color(0xFFBA68C8),
        'badgeShadow': const Color(0xFF9C27B0).withOpacity(0.3),
        'iconColor': const Color(0xFF9C27B0),
        'tagBackground': const Color(0xFF9C27B0).withOpacity(0.1),
        'tagTextColor': const Color(0xFF9C27B0),
        'buttonColor1': const Color(0xFF9C27B0),
        'buttonColor2': const Color(0xFFBA68C8),
        'buttonShadow': const Color(0xFF9C27B0).withOpacity(0.25),
      },
    ];
    
    return colorSchemes[index % colorSchemes.length];
  }

  static String getBadgeTextForModule(int index) {
    final List<String> badges = ['ESENCIAL', 'RECOMENDADO', 'AVANZADO'];
    return badges[index % badges.length];
  }

  static IconData getIconForModule(int index) {
    final List<IconData> icons = [
      Icons.psychology_outlined,
      Icons.self_improvement,
      Icons.people_outline,
      Icons.emoji_objects_outlined,
      Icons.medical_services_outlined,
      Icons.insights_outlined,
    ];
    return icons[index % icons.length];
  }

  static String getDescriptionForModule(String title) {
    if (title.toLowerCase().contains('técnicas de regulación emocional') || 
        title.toLowerCase().contains('tecnicas de regulacion emocional')) {
      return 'Aprende estrategias prácticas para manejar tus emociones en momentos difíciles. Identifica, acepta y transforma emociones intensas con técnicas basadas en evidencia científica.';
    } else if (title.toLowerCase().contains('autoconocimiento')) {
      return 'Explora tu mundo interior para comprender mejor tus pensamientos, emociones y patrones de comportamiento. Descubre tus fortalezas, valores y áreas de crecimiento personal.';
    } else {
      return 'Explora herramientas prácticas para tu bienestar emocional y desarrollo personal. Encuentra estrategias efectivas para mejorar tu calidad de vida diaria.';
    }
  }
}