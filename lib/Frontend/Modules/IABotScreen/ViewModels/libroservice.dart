import 'dart:convert';
import 'package:flutter/services.dart';

class LibroPsicologia {
  final String archivo;
  final List<String> resumenesPorFragmento;
  final String resumenFinal;

  LibroPsicologia({
    required this.archivo,
    required this.resumenesPorFragmento,
    required this.resumenFinal,
  });

  factory LibroPsicologia.fromJson(Map<String, dynamic> json) {
    return LibroPsicologia(
      archivo: json['archivo'] ?? '',
      resumenesPorFragmento:
          List<String>.from(json['resumenes_por_fragmento'] ?? []),
      resumenFinal: json['resumen_final'] ?? '',
    );
  }
}

class LibrosService {
  static final LibrosService _instance = LibrosService._internal();
  factory LibrosService() => _instance;
  LibrosService._internal();

  List<LibroPsicologia> _libros = [];
  bool _cargado = false;

  Future<void> cargarLibros() async {
    if (_cargado) return;

    try {
      const basePath = 'lib/App/Backend/Books/';
      final List<String> archivos = [
        '${basePath}La-Inteligencia-Emocional-Daniel-Goleman-1.json',
        '${basePath}Cuaderno-ESEN-FES-8-web.json',
        '${basePath}La inteligencia emocional en el desarrollo de la trayectoria académica 0257-4314-rces-39-02-e15.json',
        '${basePath}inteligencia emocional y rendimiento académico v32n2a06.json',
        '${basePath}creatividd ,inteligencia emocional  implicaciones educativas index.json',
        '${basePath}autoregulacion emocional y rendimiento aroot,+49-60_MRM_No3-2021.json',
      ];

      for (String archivo in archivos) {
        try {
          final String contenido = await rootBundle.loadString(archivo);
          final Map<String, dynamic> json = jsonDecode(contenido);
          _libros.add(LibroPsicologia.fromJson(json));
        } catch (e) {
          print('Error cargando libro $archivo: $e');
        }
      }

      _cargado = true;
      print('Libros cargados: ${_libros.length}');
    } catch (e) {
      print('Error cargando libros: $e');
    }
  }

  List<LibroPsicologia> get libros => _libros;

  String obtenerBaseConocimiento() {
    if (_libros.isEmpty) return '';

    String baseConocimiento = '''
# Base de Conocimiento en Psicología y Inteligencia Emocional

## Libros disponibles:
''';

    for (LibroPsicologia libro in _libros) {
      baseConocimiento += '''
### ${libro.archivo}
${libro.resumenFinal}

''';
    }

    return baseConocimiento;
  }

  String obtenerFragmentosRelevantes(String consulta) {
    if (_libros.isEmpty) return '';

    List<String> fragmentosRelevantes = [];

    for (LibroPsicologia libro in _libros) {
      for (String fragmento in libro.resumenesPorFragmento) {
        if (fragmento.toLowerCase().contains(consulta.toLowerCase())) {
          fragmentosRelevantes.add(fragmento);
          if (fragmentosRelevantes.length >= 3)
            break; // Máximo 3 fragmentos por libro
        }
      }
    }

    if (fragmentosRelevantes.isEmpty) {
      return 'No se encontraron fragmentos específicos para: $consulta';
    }

    return fragmentosRelevantes.join('\n\n---\n\n');
  }

  String generarPromptPersonalizado(String comportamiento, String reglas) {
    return '''
Eres un asistente psicológico especializado en inteligencia emocional y bienestar estudiantil para ITCA-FEPADE.

Tu objetivo es:
- Brindar respuestas breves, claras y en español.
- Ser empático y profesional, usando principios básicos de psicología emocional.
- Detectar cualquier lenguaje que indique conductas autodestructivas, depresivas severas, violencia extrema o ideación terrorista.

Si detectas señales de alerta graves, responde inmediatamente con el siguiente mensaje:
"Tu bienestar es lo más importante. Te recomiendo contactar de inmediato a la oficina de psicología de ITCA-FEPADE, donde profesionales pueden ayudarte de manera confidencial y segura."

$comportamiento

$reglas

Utiliza tu conocimiento en psicología para proporcionar respuestas fundamentadas, empáticas y profesionales. Prioriza el bienestar emocional del usuario y mantén un enfoque ético.
''';
  }
}
