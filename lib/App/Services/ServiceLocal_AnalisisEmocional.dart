import 'dart:developer' as developer;
import '../Data/Models/sesion_chat.dart';
import '../Data/Models/analisis_sesion.dart';

class AnalisisEmocional {
  // Diccionarios de palabras clave por emoción
  static const Map<String, List<String>> _palabrasEmociones = {
    'ansiedad': [
      'ansioso',
      'nervioso',
      'preocupado',
      'estresado',
      'agobiado',
      'inquieto',
      'tenso',
      'angustiado',
      'intranquilo',
      'agitado',
      'pánico',
      'miedo',
      'temor',
      'terror',
      'fobia'
    ],
    'depresión': [
      'triste',
      'deprimido',
      'melancólico',
      'desanimado',
      'abatido',
      'desesperanzado',
      'vacío',
      'solo',
      'aislado',
      'desesperado',
      'inútil',
      'culpable',
      'pesimista',
      'desalentado'
    ],
    'ira': [
      'enojado',
      'furioso',
      'molesto',
      'irritado',
      'frustrado',
      'rabioso',
      'indignado',
      'enfadado',
      'colérico',
      'hostil'
    ],
    'alegría': [
      'feliz',
      'contento',
      'alegre',
      'eufórico',
      'optimista',
      'esperanzado',
      'motivado',
      'entusiasmado',
      'satisfecho',
      'pleno'
    ],
    'miedo': [
      'asustado',
      'aterrorizado',
      'temeroso',
      'espantado',
      'horrorizado',
      'intimidado',
      'cobarde',
      'tímido',
      'inseguro'
    ],
    'confusión': [
      'confundido',
      'perdido',
      'desorientado',
      'dudoso',
      'incierto',
      'indeciso',
      'perplejo',
      'desconcertado'
    ]
  };

  // Palabras que indican riesgo
  static const List<String> _palabrasRiesgo = [
    'suicidio',
    'matarme',
    'acabar',
    'terminar',
    'morir',
    'lastimar',
    'dañar',
    'cortar',
    'herir',
    'dolor',
    'no puedo más',
    'sin salida',
    'sin esperanza',
    'inútil',
    'mejor muerto',
    'desaparecer',
    'no sirvo'
  ];

  // Temas generales
  static const Map<String, List<String>> _temas = {
    'académico': [
      'estudios',
      'universidad',
      'examen',
      'tarea',
      'calificación',
      'profesor',
      'clase',
      'carrera',
      'semestre',
      'graduación'
    ],
    'familiar': [
      'familia',
      'padres',
      'hermanos',
      'casa',
      'hogar',
      'mamá',
      'papá',
      'conflicto familiar',
      'divorcio'
    ],
    'relaciones': [
      'pareja',
      'novio',
      'novia',
      'amor',
      'relación',
      'amistad',
      'amigos',
      'social',
      'citas'
    ],
    'laboral': [
      'trabajo',
      'empleo',
      'jefe',
      'compañeros',
      'oficina',
      'sueldo',
      'carrera profesional',
      'entrevista'
    ],
    'salud': [
      'enfermedad',
      'dolor',
      'médico',
      'hospital',
      'síntomas',
      'medicamento',
      'tratamiento',
      'salud mental'
    ],
    'personal': [
      'autoestima',
      'identidad',
      'personalidad',
      'crecimiento',
      'metas',
      'sueños',
      'futuro',
      'propósito'
    ]
  };

  static Future<AnalisisSesion> analizarSesion(SesionChat sesion) async {
    developer.log('🔍 Iniciando análisis de sesión...');

    // Concatenar todo el contenido de los mensajes del usuario
    final contenidoCompleto = sesion.mensajes
        .where((m) => m.emisor == "Usuario")
        .map((m) => m.contenido.toLowerCase())
        .join(" ");

    developer.log(
        '📝 Contenido a analizar: ${contenidoCompleto.length > 100 ? contenidoCompleto.substring(0, 100) + "..." : contenidoCompleto}');

    // Validar que hay contenido para analizar
    if (contenidoCompleto.trim().isEmpty) {
      developer.log('⚠️ No hay contenido del usuario para analizar');
      return AnalisisSesion(
        fechaSesion: sesion.fecha,
        temaGeneral: 'general',
        emociones: {'neutral': 100.0},
        nivelRiesgo: 'bajo',
        puntuacionRiesgo: 0.0,
        palabrasClave: [],
        resumenAnalisis: 'Sesión sin contenido del usuario para analizar',
        idSesionChat: sesion.fecha.hashCode,
      );
    }

    // Analizar emociones
    final emociones = _analizarEmociones(contenidoCompleto);
    developer.log('😊 Emociones detectadas: $emociones');

    // Detectar tema general
    final tema = _detectarTema(contenidoCompleto);
    developer.log('🎯 Tema detectado: $tema');

    // Calcular riesgo
    final riesgo = _calcularRiesgo(contenidoCompleto);
    developer.log(
        '⚠️ Nivel de riesgo: ${riesgo['nivel']} (${riesgo['puntuacion']})');

    // Extraer palabras clave
    final palabrasClave = _extraerPalabrasClave(contenidoCompleto);
    developer.log('🔑 Palabras clave: $palabrasClave');

    // Generar resumen
    final resumen = _generarResumen(emociones, tema, riesgo['nivel']);

    return AnalisisSesion(
      fechaSesion: sesion.fecha,
      temaGeneral: tema,
      emociones: emociones,
      nivelRiesgo: riesgo['nivel'],
      puntuacionRiesgo: riesgo['puntuacion'],
      palabrasClave: palabrasClave,
      resumenAnalisis: resumen,
      idSesionChat: sesion.fecha.hashCode,
    );
  }

  static Map<String, double> _analizarEmociones(String contenido) {
    Map<String, double> conteoEmociones = {};
    int totalPalabras = 0;

    _palabrasEmociones.forEach((emocion, palabras) {
      int conteo = 0;
      for (String palabra in palabras) {
        conteo += _contarOcurrencias(contenido, palabra);
      }
      conteoEmociones[emocion] = conteo.toDouble();
      totalPalabras += conteo;
    });

    // Convertir a porcentajes
    if (totalPalabras > 0) {
      conteoEmociones.forEach((emocion, conteo) {
        double porcentaje = (conteo / totalPalabras) * 100;
        conteoEmociones[emocion] = porcentaje.clamp(0.0, 100.0);
      });
    } else {
      // Si no se detectan emociones específicas, asignar neutral
      conteoEmociones.clear();
      conteoEmociones['neutral'] = 100.0;
    }

    return conteoEmociones;
  }

  static String _detectarTema(String contenido) {
    Map<String, int> puntuacionTemas = {};

    _temas.forEach((tema, palabras) {
      int puntuacion = 0;
      for (String palabra in palabras) {
        puntuacion += _contarOcurrencias(contenido, palabra);
      }
      puntuacionTemas[tema] = puntuacion;
    });

    // Encontrar el tema con mayor puntuación
    String temaPrincipal = 'general';
    int maxPuntuacion = 0;

    puntuacionTemas.forEach((tema, puntuacion) {
      if (puntuacion > maxPuntuacion) {
        maxPuntuacion = puntuacion;
        temaPrincipal = tema;
      }
    });

    return maxPuntuacion > 0 ? temaPrincipal : 'general';
  }

  static Map<String, dynamic> _calcularRiesgo(String contenido) {
    int puntuacionRiesgo = 0;

    // Buscar palabras de riesgo
    for (String palabra in _palabrasRiesgo) {
      puntuacionRiesgo += _contarOcurrencias(contenido, palabra) * 10;
    }

    // Buscar patrones de riesgo adicionales
    if (contenido.contains('no puedo') && contenido.contains('más')) {
      puntuacionRiesgo += 15;
    }
    if (contenido.contains('sin esperanza') ||
        contenido.contains('sin salida')) {
      puntuacionRiesgo += 20;
    }

    // Limitar la puntuación a un máximo de 100
    puntuacionRiesgo = puntuacionRiesgo.clamp(0, 100);

    // Determinar nivel de riesgo
    String nivel;
    if (puntuacionRiesgo >= 50) {
      nivel = 'crítico';
    } else if (puntuacionRiesgo >= 30) {
      nivel = 'alto';
    } else if (puntuacionRiesgo >= 15) {
      nivel = 'medio';
    } else {
      nivel = 'bajo';
    }

    return {
      'nivel': nivel,
      'puntuacion': puntuacionRiesgo.toDouble(),
    };
  }

  static List<String> _extraerPalabrasClave(String contenido) {
    List<String> palabrasClave = [];

    // Buscar todas las palabras emocionales encontradas
    _palabrasEmociones.forEach((emocion, palabras) {
      for (String palabra in palabras) {
        if (contenido.contains(palabra) && !palabrasClave.contains(palabra)) {
          palabrasClave.add(palabra);
        }
      }
    });

    // Buscar palabras de riesgo
    for (String palabra in _palabrasRiesgo) {
      if (contenido.contains(palabra) && !palabrasClave.contains(palabra)) {
        palabrasClave.add(palabra);
      }
    }

    return palabrasClave.take(10).toList(); // Limitar a 10 palabras clave
  }

  static String _generarResumen(
      Map<String, double> emociones, String tema, String nivelRiesgo) {
    String emocionPrincipal = 'neutral';
    double maxPorcentaje = 0;

    emociones.forEach((emocion, porcentaje) {
      if (porcentaje > maxPorcentaje) {
        maxPorcentaje = porcentaje;
        emocionPrincipal = emocion;
      }
    });

    String resumen = 'Sesión sobre $tema. ';

    if (maxPorcentaje > 0) {
      resumen +=
          'Emoción predominante: $emocionPrincipal (${maxPorcentaje.toStringAsFixed(1)}%). ';
    }

    if (nivelRiesgo != 'bajo') {
      resumen += 'Nivel de riesgo: $nivelRiesgo. ';
    }

    return resumen;
  }

  static int _contarOcurrencias(String texto, String palabra) {
    return palabra.allMatches(texto).length;
  }
}
