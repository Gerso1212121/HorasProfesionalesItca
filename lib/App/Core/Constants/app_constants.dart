import 'dart:ui';
import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // Durations
  static const durationShort = Duration(milliseconds: 300);
  static const durationMedium = Duration(seconds: 1);
  static const durationLong = Duration(seconds: 2);

  // Configuración IA para el diario
  static const int minEntriesForAnalysis = 3;
  static const int analysisUpdateInterval = 7; // días
}

class AppRoutes {
  AppRoutes._();

  static const String main = '/main';
  static const String register = '/register';
  static const String login = '/login';
  static const String diary = '/diary';
  static const String analysis = '/analysis';
}

class AppColors {
  AppColors._();

  // Colores principales existentes
  static const Color background = Color(0xFFF2FFFF);
  static const Color primary = Color(0xFFF66B7D);
  static const Color primaryLight = Color(0xFF86A8E7);
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Color(0xFF666666);

  // Colores específicos para psicología/diario
  static const Color diaryPrimary = Color(0xFF8B4513); // Marrón principal
  static const Color diarySecondary = Color(0xFFF9F5EB); // Beige claro
  static const Color diaryAccent = Color(0xFFFFB74D); // Ámbar
  static const Color diaryPaper = Color(0xFFFFFDE7); // Color papel
  static const Color diaryTextDark = Color(0xFF5D4037); // Marrón oscuro texto
  static const Color diaryTextLight = Color(0xFF8D6E63); // Marrón claro texto

  // Estados y feedback
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class AppFontSizes {
  AppFontSizes._();

  static const double bodySmall = 12.0;
  static const double bodyMedium = 14.0;
  static const double bodyLarge = 16.0;
  static const double headlineSmall = 20.0;
  static const double headlineMedium = 28.0;
  static const double headlineLarge = 32.0;
}

class AppBorderRadius {
  AppBorderRadius._();

  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 30.0;

  // Específicos para diario
  static const double diaryCard = 16.0;
  static const double diaryInput = 12.0;
}

class AppBreakpoints {
  AppBreakpoints._();

  static const double mobile = 400.0;
  static const double tablet = 768.0;
  static const double desktop = 1024.0;
}

class AppAssets {
  AppAssets._();

  static const String logo = 'assets/images/cerebron.png'; // Completé tu línea

  // Para el diario - si no tienes texturas, podemos usar colores sólidos
  static const String paperTexture = 'assets/images/paper_texture.jpg';

  // Si no tienes la imagen, podemos usar un placeholder o generar textura programáticamente
  static const String diaryPlaceholder = 'assets/images/diary_placeholder.png';
}

class AppFonts {
  AppFonts._();

  // Si quieres usar una fuente manuscrita, asegúrate de añadirla en pubspec.yaml
  static const String handwriting = 'Handwriting';
  static const String main = 'Roboto';
}

// Constantes específicas para el módulo de diario
class DiaryConstants {
  DiaryConstants._();

  // Emociones disponibles
  static const List<Map<String, dynamic>> emotions = [
    {
      'name': 'Muy feliz',
      'emoji': '😄',
      'value': 5,
      'color': Color(0xFF4CAF50)
    },
    {'name': 'Feliz', 'emoji': '😊', 'value': 4, 'color': Color(0xFF8BC34A)},
    {'name': 'Neutral', 'emoji': '😐', 'value': 3, 'color': Color(0xFF9E9E9E)},
    {'name': 'Cansado', 'emoji': '😴', 'value': 2, 'color': Color(0xFF607D8B)},
    {'name': 'Triste', 'emoji': '😢', 'value': 2, 'color': Color(0xFF2196F3)},
    {
      'name': 'Muy triste',
      'emoji': '😭',
      'value': 1,
      'color': Color(0xFF1976D2)
    },
    {'name': 'Ansioso', 'emoji': '😰', 'value': 2, 'color': Color(0xFFFF9800)},
    {'name': 'Relajado', 'emoji': '😌', 'value': 4, 'color': Color(0xFF4CAF50)},
    {'name': 'Enojado', 'emoji': '😠', 'value': 1, 'color': Color(0xFFF44336)},
    {
      'name': 'Emocionado',
      'emoji': '🤩',
      'value': 5,
      'color': Color(0xFFFFC107)
    },
  ];

  // Categorías temáticas
  static const List<Map<String, dynamic>> categories = [
    {'name': 'Ansiedad', 'emoji': '😰', 'color': Color(0xFFFF6B6B)},
    {'name': 'Estado de Ánimo', 'emoji': '😔', 'color': Color(0xFF5E72EB)},
    {'name': 'Sueño', 'emoji': '😴', 'color': Color(0xFF8E44AD)},
    {'name': 'Alimentación', 'emoji': '🍎', 'color': Color(0xFF27AE60)},
    {'name': 'Ejercicio', 'emoji': '💪', 'color': Color(0xFFE67E22)},
    {'name': 'Relaciones', 'emoji': '👥', 'color': Color(0xFF3498DB)},
    {'name': 'Trabajo/Estudio', 'emoji': '💼', 'color': Color(0xFFF39C12)},
    {'name': 'Autocuidado', 'emoji': '🧘', 'color': Color(0xFF1ABC9C)},
    {'name': 'Logros', 'emoji': '⭐', 'color': Color(0xFFF1C40F)},
    {'name': 'Desafíos', 'emoji': '🌧️', 'color': Color(0xFF7F8C8D)},
  ];

  // Pensamientos recurrentes comunes
  static const List<String> commonThoughts = [
    'pensamiento_catastrofico',
    'sobregeneralizacion',
    'filtro_mental',
    'descalificar_positivo',
    'lectura_mente',
    'prediccion_futuro',
    'razonamiento_emocional',
    'deberias',
    'etiquetado',
    'personalizacion'
  ];

  // Desencadenantes comunes
  static const List<String> commonTriggers = [
    'situaciones_sociales',
    'presion_academica',
    'conflictos_familiares',
    'incertidumbre',
    'cambios_rutina',
    'noticias_negativas',
    'falta_sueno',
    'hambre',
    'soledad',
    'exceso_estimulos'
  ];
}

// Añade esta clase al final de tu archivo app_constants.dart
class PaperTextureGenerator {
  static BoxDecoration getPaperTexture() {
    return BoxDecoration(
      color: AppColors.diaryPaper,
      // Simulamos textura con gradientes sutiles
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.diaryPaper,
          AppColors.diaryPaper,
          AppColors.diaryPaper.withOpacity(0.95),
        ],
        stops: const [0.0, 0.7, 1.0],
      ),
      // Añadimos un borde sutil
      border: Border.all(
        color: AppColors.diaryPrimary.withOpacity(0.1),
        width: 1,
      ),
      borderRadius: BorderRadius.circular(AppBorderRadius.diaryCard),
      // Efecto de sombra sutil para profundidad
      boxShadow: [
        BoxShadow(
          color: AppColors.diaryPrimary.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration getInputPaperTexture() {
    return BoxDecoration(
      color: AppColors.diaryPaper,
      borderRadius: BorderRadius.circular(AppBorderRadius.diaryInput),
      border: Border.all(
        color: AppColors.diaryPrimary.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.diaryPrimary.withOpacity(0.1),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }
}
