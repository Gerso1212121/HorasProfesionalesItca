import 'sesion_chat.dart';

class AnalisisEmocional {
  final String temaGeneral;
  final Map<String, double> emociones;
  final String nivelRiesgo;
  final double puntuacionRiesgo;
  final List<String> palabrasClave;
  final String resumenAnalisis;

  AnalisisEmocional({
    required this.temaGeneral,
    required this.emociones,
    required this.nivelRiesgo,
    required this.puntuacionRiesgo,
    required this.palabrasClave,
    required this.resumenAnalisis,
  });

  static Future<AnalisisEmocional> analizarSesion(SesionChat sesion) async {
    // Análisis básico de la sesión
    final contenido = sesion.mensajes
        .where((m) => m.emisor == "Usuario")
        .map((m) => m.contenido.toLowerCase())
        .join(" ");

    // Detectar emociones básicas
    Map<String, double> emociones = {
      'tristeza': _detectarEmocion(contenido, ['triste', 'deprimido', 'lloro']),
      'ansiedad': _detectarEmocion(contenido, ['ansioso', 'nervioso', 'preocupado']),
      'alegria': _detectarEmocion(contenido, ['feliz', 'alegre', 'contento']),
      'enojo': _detectarEmocion(contenido, ['enojado', 'molesto', 'frustrado']),
    };

    // Calcular nivel de riesgo
    double puntuacionRiesgo = (emociones['tristeza']! + emociones['ansiedad']!) * 50;
    String nivelRiesgo = _calcularNivelRiesgo(puntuacionRiesgo);

    return AnalisisEmocional(
      temaGeneral: _detectarTema(contenido),
      emociones: emociones,
      nivelRiesgo: nivelRiesgo,
      puntuacionRiesgo: puntuacionRiesgo,
      palabrasClave: _extraerPalabrasClave(contenido),
      resumenAnalisis: _generarResumen(emociones, nivelRiesgo),
    );
  }

  static double _detectarEmocion(String contenido, List<String> palabras) {
    int coincidencias = 0;
    for (String palabra in palabras) {
      if (contenido.contains(palabra)) coincidencias++;
    }
    return coincidencias / palabras.length;
  }

  static String _detectarTema(String contenido) {
    if (contenido.contains(RegExp(r'\b(estudio|examen|universidad|tarea)\b'))) {
      return 'académico';
    } else if (contenido.contains(RegExp(r'\b(familia|padres|hermanos)\b'))) {
      return 'familiar';
    } else if (contenido.contains(RegExp(r'\b(trabajo|empleo|jefe)\b'))) {
      return 'laboral';
    }
    return 'general';
  }

  static String _calcularNivelRiesgo(double puntuacion) {
    if (puntuacion >= 75) return 'crítico';
    if (puntuacion >= 50) return 'alto';
    if (puntuacion >= 25) return 'medio';
    return 'bajo';
  }

  static List<String> _extraerPalabrasClave(String contenido) {
    final palabras = contenido.split(' ');
    return palabras.where((p) => p.length > 4).take(5).toList();
  }

  static String _generarResumen(Map<String, double> emociones, String nivelRiesgo) {
    final emocionPrincipal = emociones.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    return 'Emoción predominante: $emocionPrincipal. Nivel de riesgo: $nivelRiesgo';
  }
}
