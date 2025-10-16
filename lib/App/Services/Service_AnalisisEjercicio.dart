import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../Data/Models/ejercicio_model.dart';
import '../Data/DataBase/DatabaseHelper.dart';
import 'Logs/Services_Log.dart';

class AnalisisEjercicioService {
  static String get _apiKey {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY no está configurada en el archivo .env');
    }
    return apiKey;
  }

  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  /// Analiza los resultados de un ejercicio y extrae una emoción específica
  /// Retorna una sola palabra que representa la emoción detectada
  static Future<String> analizarEmocionEjercicio({
    // Parámetros del ejercicio
    required EjercicioPsicologico ejercicio,
    // Puntuación del usuario (1-10)
    required int puntuacion,
    // Notas opcionales del usuario
    String? notas,
    // Duración del ejercicio en minutos (opcional)
    int? duracionMinutos,
    // UID del usuario
    String? uid,
  }) async {
    try {
      // Construir el prompt para el análisis
      final prompt = _construirPromptAnalisis(
        ejercicio: ejercicio, // Datos del ejercicio
        puntuacion: puntuacion, // Puntuación del usuario
        notas: notas, // Notas opcionales del usuario
        duracionMinutos: duracionMinutos, // Duración del ejercicio en minutos
      );

      // Imprimir el prompt para depuración
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
        },
        body: utf8.encode(jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": [
            {
              "role": "system",
              "content":
                  "Eres un psicólogo experto en análisis emocional. Tu tarea es analizar los resultados de ejercicios psicológicos y extraer UNA SOLA PALABRA que represente la emoción principal del usuario. Debes responder únicamente con una palabra en español, sin explicaciones adicionales."
            },
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.3,
          "max_tokens": 10,
        })),
      );

      // Verificar el estado de la respuesta
      // Si la respuesta es exitosa, procesar el contenido
      if (response.statusCode == 200) {
        // Decodificar la respuesta JSON
        // Usar utf8.decode para manejar correctamente los bytes
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // Extraer la emoción de la respuesta
        final emocion = data['choices'][0]['message']['content']
            .trim()
            .toLowerCase(); // Asegurarse de que la emoción esté en minúsculas

        // Limpiar la respuesta para asegurar que sea una sola palabra
        final emocionLimpia = _limpiarRespuestaEmocion(emocion);
        print('🔍 Emoción detectada: $emocionLimpia');
        LogService.log(
            'Emoción detectada: $emocionLimpia, iniciando actualizacion en base de datos',
            name: 'AnalisisEjercicioService');
        // Instanciar DatabaseHelper
        DatabaseHelper dbHelper = DatabaseHelper.instance;
        // Actuliza la emoción en Supabase
        final supabase = Supabase.instance.client;
        //Obtenesmos datos del estudiante desde la base de datos local
        final estudiante = await dbHelper.getEstudianteByUID(uid ?? '');

        final res =
            await supabase.rpc('registrar_emocion_generalizada', params: {
          'sede_input': '${estudiante?['sede'] ?? 'default'}',
          'carrera_input': '${estudiante?['carrera'] ?? 'default'}',
          'ciclo_input': '${estudiante?['ciclo'] ?? 'default'}',
          'emocion_anterior': '${estudiante?['emocion'] ?? 'neutral'}',
          'emocion_nueva': emocionLimpia,
        });
        // Actualizar la emoción del estudiante en la base de datos local
        dbHelper.actualizarEmocionEstudiante(uid ?? '',
            emocionLimpia); // Actualizar la emoción en la base de datos

        if (res == null) {
          LogService.error('❌ La respuesta de Supabase fue null');
        } else if (res.error != null) {
          LogService.error(
              'Error al registrar emoción en Supabase: ${res.error!.message}',
              error: res.error);
        } else {
          LogService.log(
              'Emoción registrada exitosamente en Supabase: $emocionLimpia');
        }

        return emocionLimpia;
      } else {
        print(
            "❌ Error en análisis emocional: ${response.statusCode} - ${response.body}");
        return "neutral"; // Emoción por defecto
      }
    } catch (e) {
      print("❌ Excepción en análisis emocional: $e");
      return "neutral"; // Emoción por defecto
    }
  }

  /// Construye el prompt para el análisis emocional
  static String _construirPromptAnalisis({
    required EjercicioPsicologico ejercicio,
    required int puntuacion,
    String? notas,
    int? duracionMinutos,
  }) {
    final buffer = StringBuffer();

    buffer.writeln(
        'Analiza los siguientes datos de un ejercicio psicológico y extrae UNA SOLA PALABRA que represente la emoción principal del usuario:');
    buffer.writeln('');
    buffer.writeln('Ejercicio: ${ejercicio.titulo}');
    buffer.writeln('Categoría: ${ejercicio.categoria}');
    buffer.writeln('Dificultad: ${ejercicio.dificultad}');
    buffer.writeln('Puntuación del usuario (1-10): $puntuacion');

    if (duracionMinutos != null) {
      buffer.writeln('Duración: ${duracionMinutos} minutos');
    }

    if (notas != null && notas.isNotEmpty) {
      buffer.writeln('Notas del usuario: "$notas"');
    }

    buffer.writeln('');
    buffer.writeln(
        'Basándote en estos datos, responde ÚNICAMENTE con una palabra en español que represente la emoción principal (ejemplos: feliz, tranquilo, ansioso, satisfecho, frustrado, relajado, estresado, contento, preocupado, etc.).');

    return buffer.toString();
  }

  /// Limpia la respuesta de la IA para asegurar que sea una sola palabra
  static String _limpiarRespuestaEmocion(String respuesta) {
    print('🔍 Respuesta original: $respuesta');
    // Remover puntuación y espacios extra
    String limpia = respuesta.replaceAll(RegExp(r'[^\w\s]'), '').trim();

    // Si hay múltiples palabras, tomar la primera
    if (limpia.contains(' ')) {
      limpia = limpia.split(' ').first;
    }

    // Si está vacía o es muy corta, usar valor por defecto
    if (limpia.isEmpty || limpia.length < 3) {
      return "neutral";
    }
    print('🔍 Respuesta limpia: $limpia');
    return limpia.toLowerCase();
  }

  /// Lista de emociones válidas para validación
  static const List<String> emocionesValidas = [
    'feliz',
    'contento',
    'satisfecho',
    'tranquilo',
    'relajado',
    'calmado',
    'ansioso',
    'estresado',
    'preocupado',
    'nervioso',
    'agitado',
    'frustrado',
    'molesto',
    'irritado',
    'enojado',
    'furioso',
    'triste',
    'deprimido',
    'melancólico',
    'desanimado',
    'confundido',
    'perplejo',
    'desorientado',
    'entusiasmado',
    'emocionado',
    'inspirado',
    'motivado',
    'agotado',
    'cansado',
    'fatigado',
    'neutral',
    'indiferente',
    'equilibrado'
  ];

  /// Valida si una emoción está en la lista de emociones válidas
  static bool esEmocionValida(String emocion) {
    return emocionesValidas.contains(emocion.toLowerCase());
  }
}
