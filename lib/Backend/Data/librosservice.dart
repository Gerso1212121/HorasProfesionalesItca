import 'dart:convert';
import 'dart:async' show TimeoutException;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:horas2/Backend/Data/pdf.dart';
import 'package:path/path.dart' as path;

class LibroPsicologia {
  final String archivo;
  final List<String> resumenesPorFragmento;
  final String resumenFinal;
  final String titulo;
  final String autor;
  final String categoria;
  final String descripcion;
  final bool activo;

  LibroPsicologia({
    required this.archivo,
    required this.resumenesPorFragmento,
    required this.resumenFinal,
    required this.titulo,
    required this.autor,
    required this.categoria,
    required this.descripcion,
    required this.activo,
  });

  factory LibroPsicologia.fromJson(Map<String, dynamic> json, {String? nombreArchivo}) {
    // Extraer título del nombre del archivo si no está en el JSON
    String titulo = json['titulo'] ?? '';
    if (titulo.isEmpty && nombreArchivo != null) {
      titulo = _extraerTituloDelArchivo(nombreArchivo);
    }
    
    return LibroPsicologia(
      archivo: json['archivo'] ?? nombreArchivo ?? '',
      resumenesPorFragmento:
          List<String>.from(json['resumenes_por_fragmento'] ?? []),
      resumenFinal: json['resumen_final'] ?? json['resumen_general'] ?? '',
      titulo: titulo,
      autor: json['autor'] ?? 'Autor Desconocido',
      categoria: json['categoria'] ?? 'Psicología',
      descripcion: json['descripcion'] ?? 'Libro de psicología e inteligencia emocional',
      activo: json['activo'] ?? true,
    );
  }
  
  static String _extraerTituloDelArchivo(String archivo) {
    String nombre = path.basenameWithoutExtension(archivo);
    nombre = nombre.replaceAll('-', ' ').replaceAll('_', ' ');
    List<String> palabras = nombre.split(' ');
    palabras = palabras.map((palabra) {
      if (palabra.isEmpty) return palabra;
      return palabra[0].toUpperCase() + palabra.substring(1).toLowerCase();
    }).toList();
    return palabras.join(' ');
  }

  factory LibroPsicologia.fromFirebase(Map<String, dynamic> data) {
    return LibroPsicologia(
      archivo: data['archivo'] ?? '',
      resumenesPorFragmento:
          List<String>.from(data['resumenes_por_fragmento'] ?? []),
      resumenFinal: data['descripcion'] ?? '',
      titulo: data['titulo'] ?? '',
      autor: data['autor'] ?? 'Autor Desconocido',
      categoria: data['categoria'] ?? 'General',
      descripcion: data['descripcion'] ?? '',
      activo: data['activo'] ?? true,
    );
  }
}

class LibrosService {
  static final LibrosService _instance = LibrosService._internal();
  factory LibrosService() => _instance;
  LibrosService._internal();

  final PDFProcessingService _pdfService = PDFProcessingService();
  final List<LibroPsicologia> _libros = [];
  bool _cargado = false;

  Future<void> cargarLibros() async {
    if (_cargado) {
      debugPrint('ℹ️ Libros ya cargados previamente: ${_libros.length}');
      return;
    }

    try {
      _libros.clear();
      int librosFirebase = 0;
      
      // Cargar libros desde Firebase
      try {
        final List<Map<String, dynamic>> librosFirebaseData = await _pdfService.obtenerLibros();
        for (Map<String, dynamic> libroData in librosFirebaseData) {
          if (libroData['activo'] == true) {
            _libros.add(LibroPsicologia.fromFirebase(libroData));
            librosFirebase++;
          }
        }
        debugPrint('✅ Libros de Firebase cargados: $librosFirebase');
      } catch (e) {
        debugPrint('⚠️ Error cargando libros de Firebase: $e');
      }

      // Siempre cargar también los libros locales
      final int librosAntesLocales = _libros.length;
      await _cargarLibrosLocales();
      final int librosLocales = _libros.length - librosAntesLocales;

      _cargado = true;
      debugPrint('📚 Total libros cargados: ${_libros.length} (Firebase: $librosFirebase, Locales: $librosLocales)');
    } catch (e) {
      debugPrint('❌ Error cargando libros: $e');
      // En caso de error, intentar cargar solo libros locales
      await _cargarLibrosLocales();
      debugPrint('📚 Libros locales cargados como respaldo: ${_libros.length}');
    }
  }

  Future<void> _cargarLibrosLocales() async {
    try {
      final List<String> archivos = [
        'lib/backEnd/LIBROS/La-Inteligencia-Emocional-Daniel-Goleman-1.json',
        'lib/backEnd/LIBROS/Cuaderno-ESEN-FES-8-web.json',
        'lib/backEnd/LIBROS/La inteligencia emocional en el desarrollo de la trayectoria académica 0257-4314-rces-39-02-e15.json',
        'lib/backEnd/LIBROS/inteligencia emocional y rendimiento académico v32n2a06.json',
        'lib/backEnd/LIBROS/creatividd ,inteligencia emocional  implicaciones educativas index.json',
        'lib/backEnd/LIBROS/autoregulacion emocional y rendimiento aroot,+49-60_MRM_No3-2021.json',
        'lib/backEnd/LIBROS/Manual_para_aprender.json',
        'lib/backEnd/LIBROS/Como autoregular a los estudidantes 16731188008.json',
      ];

      int librosCargados = 0;
      for (String archivo in archivos) {
        try {
          final String contenido = await rootBundle.loadString(archivo);
          final Map<String, dynamic> json = jsonDecode(contenido);
          final libro = LibroPsicologia.fromJson(json, nombreArchivo: archivo);
          _libros.add(libro);
          librosCargados++;
          debugPrint('✅ Libro local cargado: ${libro.titulo} (${libro.resumenesPorFragmento.length} fragmentos)');
        } catch (e) {
          debugPrint('❌ Error cargando libro local $archivo: $e');
        }
      }
      debugPrint('📚 Total libros locales cargados: $librosCargados de ${archivos.length}');
    } catch (e) {
      debugPrint('❌ Error cargando libros locales: $e');
    }
  }

  List<LibroPsicologia> get libros => _libros;

  /// Recarga los libros desde Firebase
  Future<void> recargarLibros() async {
    _cargado = false;
    await cargarLibros();
  }

  /// Obtiene todos los libros para la interfaz de administración (Firebase + Locales)
  Future<List<Map<String, dynamic>>> obtenerTodosLosLibros() async {
    List<Map<String, dynamic>> todosLosLibros = [];
    int librosFirebaseCount = 0;
    int librosLocalesCount = 0;

    try {
      // Obtener libros de Firebase
      try {
        debugPrint('📚 Intentando cargar libros de Firebase...');
        final List<Map<String, dynamic>> librosFirebase = await _pdfService
            .obtenerLibros()
            .timeout(
              const Duration(seconds: 15),
              onTimeout: () {
                debugPrint('⏱️ Timeout cargando libros de Firebase');
                return <Map<String, dynamic>>[];
              },
            );
        debugPrint('✅ Libros de Firebase obtenidos: ${librosFirebase.length}');
        
        for (Map<String, dynamic> libro in librosFirebase) {
          libro['fuente'] = 'firebase';
          libro['puedeEliminar'] = true;
          todosLosLibros.add(libro);
          librosFirebaseCount++;
        }
      } catch (e) {
        debugPrint('❌ Error cargando libros de Firebase: $e');
        // Continuar con libros locales aunque falle Firebase
      }

      // Obtener libros locales
      try {
        debugPrint('📚 Intentando cargar libros locales...');
        final List<Map<String, dynamic>> librosLocales = await _obtenerLibrosLocales();
        debugPrint('✅ Libros locales obtenidos: ${librosLocales.length}');
        
        for (Map<String, dynamic> libro in librosLocales) {
          libro['fuente'] = 'local';
          libro['puedeEliminar'] = false;
          todosLosLibros.add(libro);
          librosLocalesCount++;
        }
      } catch (e) {
        debugPrint('❌ Error cargando libros locales: $e');
        // Continuar aunque falle la carga de locales
      }

      debugPrint('📚 Total libros cargados: ${todosLosLibros.length} (Firebase: $librosFirebaseCount, Locales: $librosLocalesCount)');

      // Ordenar por fecha de creación (más recientes primero)
      todosLosLibros.sort((a, b) {
        final fechaA = DateTime.tryParse(a['fechaCreacion'] ?? '');
        final fechaB = DateTime.tryParse(b['fechaCreacion'] ?? '');
        
        if (fechaA == null && fechaB == null) return 0;
        if (fechaA == null) return 1;
        if (fechaB == null) return -1;
        
        return fechaB.compareTo(fechaA);
      });

    } catch (e) {
      debugPrint('❌ Error general obteniendo todos los libros: $e');
    }

    return todosLosLibros;
  }

  /// Obtiene los libros locales como Map para la interfaz
  Future<List<Map<String, dynamic>>> _obtenerLibrosLocales() async {
    List<Map<String, dynamic>> librosLocales = [];

    try {
      final List<String> archivos = [
        'lib/backEnd/LIBROS/La-Inteligencia-Emocional-Daniel-Goleman-1.json',
        'lib/backEnd/LIBROS/Cuaderno-ESEN-FES-8-web.json',
        'lib/backEnd/LIBROS/La inteligencia emocional en el desarrollo de la trayectoria académica 0257-4314-rces-39-02-e15.json',
        'lib/backEnd/LIBROS/inteligencia emocional y rendimiento académico v32n2a06.json',
        'lib/backEnd/LIBROS/creatividd ,inteligencia emocional  implicaciones educativas index.json',
        'lib/backEnd/LIBROS/autoregulacion emocional y rendimiento aroot,+49-60_MRM_No3-2021.json',
        'lib/backEnd/LIBROS/Manual_para_aprender.json',
        'lib/backEnd/LIBROS/Como autoregular a los estudidantes 16731188008.json',
      ];

      for (String archivo in archivos) {
        try {
          final String contenido = await rootBundle.loadString(archivo);
          final Map<String, dynamic> json = jsonDecode(contenido);
          
          // Convertir a formato compatible con la interfaz
          final Map<String, dynamic> libroLocal = {
            'id': 'local_${path.basenameWithoutExtension(archivo)}',
            'titulo': _extraerTituloDelArchivo(archivo),
            'autor': 'Autor Desconocido',
            'categoria': 'Psicología',
            'descripcion': 'Libro local de psicología e inteligencia emocional',
            'archivo': path.basename(archivo),
            'activo': true,
            'fechaCreacion': '2024-01-01T00:00:00.000Z',
            'fechaActualizacion': '2024-01-01T00:00:00.000Z',
            'fragmentos_originales': json['resumenes_por_fragmento']?.length ?? 0,
            'resumenes_por_fragmento': json['resumenes_por_fragmento'] ?? [],
            'creadoPor': 'sistema_local',
            'tags': ['local', 'json'],
          };
          
          librosLocales.add(libroLocal);
        } catch (e) {
          debugPrint('Error cargando libro local $archivo: $e');
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo libros locales: $e');
    }

    return librosLocales;
  }

  /// Extrae un título legible del nombre del archivo
  String _extraerTituloDelArchivo(String archivo) {
    return LibroPsicologia._extraerTituloDelArchivo(archivo);
  }

  String obtenerBaseConocimiento() {
    if (_libros.isEmpty) return 'No hay libros de psicología disponibles.';

    String baseConocimiento = '''
# BASE DE CONOCIMIENTO EN PSICOLOGÍA E INTELIGENCIA EMOCIONAL

Esta es tu fuente de conocimiento científico para fundamentar todas las respuestas:

''';

    for (LibroPsicologia libro in _libros) {
      if (!libro.activo) continue;
      
      baseConocimiento += '''
## 📚 ${libro.titulo}
**Autor:** ${libro.autor}  
**Categoría:** ${libro.categoria}

${libro.descripcion}

''';

      // Agregar fragmentos originales como prompts para el chat
      for (int i = 0; i < libro.resumenesPorFragmento.length && i < 5; i++) {
        baseConocimiento += '**Fragmento ${i + 1}:**\n${libro.resumenesPorFragmento[i]}\n\n';
      }
      
      baseConocimiento += '---\n\n';
    }

    baseConocimiento += '''

## CONCEPTOS CLAVE A APLICAR:
- Inteligencia Emocional (Daniel Goleman): Autoconciencia, autorregulación, motivación, empatía, habilidades sociales
- Regulación emocional: Técnicas de respiración, mindfulness, reestructuración cognitiva
- Desarrollo académico: Estrategias de estudio, manejo del estrés, motivación intrínseca
- Bienestar estudiantil: Equilibrio vida-académica, relaciones interpersonales, autoestima
- Técnicas psicológicas: Relajación progresiva, visualización, técnicas de afrontamiento

''';

    return baseConocimiento;
  }

  String obtenerFragmentosRelevantes(String consulta) {
    if (_libros.isEmpty) return '';

    List<String> fragmentosRelevantes = [];
    List<String> palabrasClave = consulta.toLowerCase().split(' ').where((palabra) => palabra.length > 3).toList();

    for (LibroPsicologia libro in _libros) {
      for (String fragmento in libro.resumenesPorFragmento) {
        String fragmentoLower = fragmento.toLowerCase();
        
        // Buscar coincidencias con palabras clave
        int coincidencias = 0;
        for (String palabra in palabrasClave) {
          if (fragmentoLower.contains(palabra)) {
            coincidencias++;
          }
        }
        
        // Si hay al menos una coincidencia o contiene la consulta completa
        if (coincidencias > 0 || fragmentoLower.contains(consulta.toLowerCase())) {
          fragmentosRelevantes.add(fragmento);
          if (fragmentosRelevantes.length >= 5) break; // Máximo 5 fragmentos
        }
      }
    }

    if (fragmentosRelevantes.isEmpty) {
      return 'No se encontraron fragmentos específicos para: $consulta';
    }

    return fragmentosRelevantes.join('\n\n---\n\n');
  }

  String generarPromptPersonalizado(String comportamiento, String reglas) {
    // Obtener solo un resumen corto de la base de conocimiento
    String baseConocimiento = _obtenerResumenConocimiento();
    
    return '''
Eres un psicólogo estudiantil de ITCA-FEPADE que habla como un amigo cercano y comprensivo.

TU ESTILO:
- Responde como si fueras un amigo que realmente se preocupa por mí
- Usa un lenguaje natural, cálido y cercano (no formal ni robótico)
- Máximo 3-4 oraciones por respuesta
- Sé directo pero cariñoso
- Usa emojis ocasionalmente para ser más humano
- Habla en primera persona ("te entiendo", "me preocupa que...")

$comportamiento

$reglas

## CONOCIMIENTO BÁSICO EN PSICOLOGÍA:

$baseConocimiento

IMPORTANTE:
- NO uses frases como "es importante que" o "debes considerar"
- NO seas preachy ni condescendiente
- SÍ sé genuino, empático y humano
- SÍ usa técnicas psicológicas pero de forma natural
- SÍ muestra preocupación real por el estudiante
- SÍ da consejos prácticos y aplicables
- Si detectas señales de crisis o pensamientos autodestructivos, responde inmediatamente con el contacto del psicólogo del ITCA

CONTACTO DE EMERGENCIA:
📞 Bienestar Estudiantil – ITCA Regional San Miguel
📧 Email: pcoreas@itca.edu.sv
📱 Móvil: 7854-6266 / 2669-2298

Responde como un amigo psicólogo que realmente se preocupa por el bienestar del estudiante.
''';
  }

  String _obtenerResumenConocimiento() {
    if (_libros.isEmpty) return 'No hay libros de psicología disponibles.';

    String resumen = '''
CONCEPTOS BÁSICOS QUE PUEDES USAR:
- Autoconciencia: Ayudar a reconocer emociones
- Autorregulación: Técnicas para calmarse
- Motivación: Mantener el impulso hacia metas
- Empatía: Entender cómo se sienten otros
- Habilidades sociales: Mejorar relaciones

TÉCNICAS PRÁCTICAS:
- Respiración profunda (4 segundos inhalar, 4 exhalar)
- Mindfulness básico (enfocarse en el presente)
- Cambiar pensamientos negativos por positivos
- Relajación muscular progresiva
- Visualización de situaciones exitosas

LIBROS DISPONIBLES EN LA BASE DE CONOCIMIENTO:
''';

    // Agregar información de los libros cargados (tanto Firebase como locales)
    for (LibroPsicologia libro in _libros) {
      if (!libro.activo) continue;
      resumen += '- ${libro.titulo} (${libro.autor}): ${libro.categoria}\n';
      // Agregar algunos fragmentos clave del libro
      if (libro.resumenesPorFragmento.isNotEmpty) {
        final fragmento = libro.resumenesPorFragmento[0];
        final preview = fragmento.length > 150 ? '${fragmento.substring(0, 150)}...' : fragmento;
        resumen += '  → $preview\n';
      }
    }

    resumen += '''
CONTACTO SI NECESITAS AYUDA PROFESIONAL:
Bienestar Estudiantil – ITCA Regional San Miguel
Email: pcoreas@itca.edu.sv
Móvil: 7854-6266 / 2669-2298
''';

    return resumen;
  }
}
