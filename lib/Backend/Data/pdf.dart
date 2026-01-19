import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:horas2/Backend/Data/openai.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:io' show File, Platform;
import 'dart:async' show TimeoutException;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;

class PDFProcessingService {
  static final PDFProcessingService _instance =
      PDFProcessingService._internal();
  factory PDFProcessingService() => _instance;
  PDFProcessingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  /// Procesa un archivo PDF y lo almacena en Firebase
  Future<Map<String, dynamic>> procesarPDF({
    required PlatformFile archivo,
    required String autor,
    required String categoria,
    required String descripcion,
  }) async {
    try {
      print('📚 Iniciando procesamiento de PDF: ${archivo.name}');
      print('📏 Tamaño: ${archivo.size} bytes');
      print('👤 Autor: $autor');
      print('🏷️ Categoría: $categoria');

      // Verificar configuración de OpenAI
      if (!OpenAIConfig.isConfigured) {
        print('❌ ERROR: OPENAI_API_KEY no está configurada');
        throw Exception(
            'OPENAI_API_KEY no está configurada. Verifica el archivo .env');
      }

      print('✅ Configuración de OpenAI verificada');

      // 1. Extraer texto del PDF
      print('📄 Iniciando extracción de texto del PDF...');
      final String textoExtraido = await _extraerTextoPDF(archivo);

      print('✅ Extracción de texto completada');
      print('📊 Caracteres extraídos: ${textoExtraido.length}');

      if (textoExtraido.isEmpty) {
        throw Exception('No se pudo extraer texto del PDF');
      }

      // 2. Procesar con IA para crear fragmentos
      final Map<String, dynamic> resultadoIA = await _procesarConIA(
        textoExtraido,
        archivo.name,
        autor,
        categoria,
        descripcion,
      );

      // 3. Crear estructura de datos
      final Map<String, dynamic> libroData = _crearEstructuraLibro(
        archivo: archivo,
        autor: autor,
        categoria: categoria,
        descripcion: descripcion,
        textoOriginal: textoExtraido,
        resultadoIA: resultadoIA,
      );

      // 4. Guardar en Firebase
      final String docId = await _guardarEnFirebase(libroData);

      print('✅ PDF procesado exitosamente: ${archivo.name}');
      print('📄 Document ID: $docId');
      print('🧩 Fragmentos: ${resultadoIA['fragmentos_originales']}');

      return {
        'success': true,
        'docId': docId,
        'fragmentos': resultadoIA['fragmentos_originales'],
        'mensaje': 'Libro procesado exitosamente',
      };
    } catch (e) {
      print('❌ ERROR PROCESANDO PDF: $e');
      print('📁 Archivo: ${archivo.name}');
      print('📏 Tamaño: ${archivo.size}');
      if (e is TimeoutException) {
        print('⏱️ TIMEOUT: La operación tardó demasiado');
      }

      return {
        'success': false,
        'error': e.toString(),
        'mensaje': 'Error al procesar el PDF',
      };
    }
  }

  /// Extrae texto de un archivo PDF
  Future<String> _extraerTextoPDF(PlatformFile archivo) async {
    try {
      print('📄 Iniciando extracción real de texto del PDF');
      print('🌐 Plataforma: ${kIsWeb ? 'Web' : 'Desktop'}');

      // Obtener bytes del archivo según la plataforma
      Uint8List bytes;

      if (kIsWeb) {
        // En web, los bytes están disponibles directamente
        if (archivo.bytes == null) {
          throw Exception(
              'El archivo PDF no contiene datos. Por favor, selecciona un archivo válido.');
        }
        bytes = archivo.bytes!;
        print('🌐 Archivo cargado desde web (bytes directos)');
      } else {
        // En escritorio (Windows, Linux, macOS), leer desde el path
        if (archivo.path == null) {
          throw Exception(
              'No se pudo obtener la ruta del archivo. Por favor, selecciona un archivo válido.');
        }

        print('💾 Leyendo archivo desde ruta: ${archivo.path}');
        final File file = File(archivo.path!);
        
        if (!await file.exists()) {
          throw Exception(
              'El archivo no existe en la ruta especificada: ${archivo.path}');
        }

        bytes = await file.readAsBytes();
        print('✅ Archivo leído exitosamente desde ruta');
        print('📊 Bytes leídos: ${bytes.length}');
      }

      // Cargar el PDF usando syncfusion_flutter_pdf
      print('📖 Cargando PDF con Syncfusion...');
      final PdfDocument doc = PdfDocument(inputBytes: bytes);

      String textoCompleto = '';
      final int totalPaginas = doc.pages.count;

      print('📑 PDF cargado exitosamente');
      print('📄 Total páginas: $totalPaginas');

      // Extraer texto de cada página
      final PdfTextExtractor extractor = PdfTextExtractor(doc);
      for (int i = 0; i < totalPaginas; i++) {
        try {
          final String textoPagina =
              extractor.extractText(startPageIndex: i, endPageIndex: i);

          if (textoPagina.isNotEmpty) {
            textoCompleto += textoPagina;
            if (i < totalPaginas - 1) {
              textoCompleto += '\n\n'; // Separador entre páginas
            }
          }

          if ((i + 1) % 10 == 0 || i == totalPaginas - 1) {
            print('📄 Procesada página ${i + 1}/$totalPaginas');
          }
        } catch (e) {
          print('⚠️ Error extrayendo página ${i + 1}: $e');
          continue;
        }
      }

      // Cerrar el documento
      doc.dispose();

      // Verificar si se extrajo texto
      if (textoCompleto.trim().isEmpty || textoCompleto.trim().length < 50) {
        print('⚠️ ADVERTENCIA: Texto extraído insuficiente');
        print('📊 Caracteres: ${textoCompleto.length}');
        print('📄 Páginas: $totalPaginas');
        
        throw Exception(
            'ADVERTENCIA: No se pudo extraer texto significativo del archivo PDF. El archivo podría estar protegido por contraseña, contener solo imágenes escaneadas, o estar corrupto.');
      }

      print('✅ Texto extraído exitosamente del PDF');
      print('📊 Total caracteres: ${textoCompleto.length}');

      return textoCompleto;
    } catch (e) {
      print('❌ ERROR EXTRAYENDO TEXTO PDF: $e');
      print('📁 Archivo: ${archivo.name}');

      rethrow;
    }
  }

  /// Procesa el texto con IA para crear fragmentos y resúmenes
  Future<Map<String, dynamic>> _procesarConIA(
    String texto,
    String nombreArchivo,
    String autor,
    String categoria,
    String descripcion,
  ) async {
    try {
      print('🤖 Iniciando procesamiento con IA');
      print('📊 Longitud del texto: ${texto.length} caracteres');
      
      // Dividir el texto en fragmentos de aproximadamente 2000 caracteres
      final List<String> fragmentos = _dividirEnFragmentos(texto, 2000);

      // Limitar a máximo 30 fragmentos para evitar timeouts en web
      final int maxFragmentos = 30;
      final List<String> fragmentosLimitados = fragmentos.length > maxFragmentos
          ? fragmentos.take(maxFragmentos).toList()
          : fragmentos;

      print('🧩 Fragmentos originales: ${fragmentos.length}');
      print('🧩 Fragmentos limitados: ${fragmentosLimitados.length}');

      // Usar los fragmentos originales directamente (NO generar resúmenes)
      final List<String> fragmentosParaChat = [];
      for (int i = 0; i < fragmentosLimitados.length; i++) {
        fragmentosParaChat.add(fragmentosLimitados[i]);
      }

      print('✅ Fragmentos preparados para chat');
      print('📝 Total fragmentos: ${fragmentosParaChat.length}');

      // Generar resumen general del libro
      final String resumenGeneral = await _generarResumenGeneral(
        nombreArchivo,
        autor,
        categoria,
        descripcion,
        fragmentosParaChat,
      );

      print('📋 Resumen general generado');
      print('📊 Longitud resumen: ${resumenGeneral.length} caracteres');

      return {
        'fragmentos_originales': fragmentosLimitados.length,
        'resumenes_generados': 0,
        'fragmentos': fragmentosLimitados,
        'resumenes_por_fragmento': fragmentosParaChat,
        'resumen_general': resumenGeneral,
        'procesado_con_ia': true,
        'fecha_procesamiento': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ ERROR PROCESANDO CON IA: $e');
      print('📄 Texto length: ${texto.length}');
      print('📁 Archivo: $nombreArchivo');

      throw Exception('Error procesando con IA: $e');
    }
  }

  /// Divide el texto en fragmentos de tamaño específico
  List<String> _dividirEnFragmentos(String texto, int tamanoMaximo) {
    print('✂️ Dividiendo texto en fragmentos de $tamanoMaximo caracteres...');
    
    final List<String> fragmentos = [];
    final List<String> oraciones = texto.split(RegExp(r'[.!?]+'));

    String fragmentoActual = '';

    for (String oracion in oraciones) {
      oracion = oracion.trim();
      if (oracion.isEmpty) continue;

      if (fragmentoActual.length + oracion.length > tamanoMaximo &&
          fragmentoActual.isNotEmpty) {
        fragmentos.add(fragmentoActual.trim());
        fragmentoActual = oracion;
      } else {
        fragmentoActual += (fragmentoActual.isEmpty ? '' : '. ') + oracion;
      }
    }

    if (fragmentoActual.isNotEmpty) {
      fragmentos.add(fragmentoActual.trim());
    }

    print('✅ Texto dividido en ${fragmentos.length} fragmentos');
    return fragmentos;
  }

  /// Genera un resumen para un fragmento específico
  Future<String> _generarResumenFragmento(
      String fragmento, int numeroFragmento) async {
    try {
      print('📝 Generando resumen para fragmento $numeroFragmento...');
      
      // Limitar el fragmento a 1500 caracteres para evitar tokens excesivos
      final String fragmentoLimitado = fragmento.length > 1500
          ? fragmento.substring(0, 1500) + '...'
          : fragmento;

      final String prompt = '''
Analiza este fragmento de un libro de psicología y crea un resumen conciso:

Fragmento $numeroFragmento:
$fragmentoLimitado

Resumen (máximo 150 palabras):
''';

      if (!OpenAIConfig.isConfigured) {
        throw Exception('OpenAI API key no configurada');
      }

      print('🌐 Enviando petición a OpenAI...');
      print('🤖 Modelo: ${OpenAIConfig.model}');

      final response = await http.post(
        Uri.parse('${OpenAIConfig.baseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_getOpenAIKey()}',
        },
        body: {
          'model': OpenAIConfig.model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 200,
          'temperature': OpenAIConfig.temperature,
        },
      ).timeout(const Duration(seconds: 30));

      print('✅ Respuesta recibida de OpenAI');
      print('📊 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return 'Fragmento $numeroFragmento: ${fragmento.substring(0, fragmento.length > 150 ? 150 : fragmento.length)}... Este fragmento aborda temas relacionados con psicología y proporciona información valiosa para el apoyo psicológico estudiantil.';
      } else {
        print('❌ Error en respuesta de OpenAI: ${response.statusCode}');
        throw Exception(
            'Error en API de OpenAI: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('⚠️ Error generando resumen con IA, usando resumen básico');
      return 'Fragmento $numeroFragmento: ${fragmento.substring(0, fragmento.length > 150 ? 150 : fragmento.length)}... Este fragmento aborda temas relacionados con psicología y proporciona información valiosa para el apoyo psicológico estudiantil.';
    }
  }

  /// Genera un resumen general del libro
  Future<String> _generarResumenGeneral(
    String nombreArchivo,
    String autor,
    String categoria,
    String descripcion,
    List<String> fragmentosOriginales,
  ) async {
    try {
      print('📋 Generando resumen general del libro...');
      print('📚 Título: $nombreArchivo');
      print('👤 Autor: $autor');
      
      // Limitar el contenido de fragmentos para evitar tokens excesivos
      final String contenidoFragmentos = fragmentosOriginales
          .take(3) // Solo tomar los primeros 3 fragmentos
          .join('\n\n');

      final String prompt = '''
Basándote en estos fragmentos de un libro de psicología, crea un resumen general:

Información del libro:
- Título: $nombreArchivo
- Autor: $autor
- Categoría: $categoria

Fragmentos del libro:
$contenidoFragmentos

Resumen general (máximo 200 palabras):
''';

      if (!OpenAIConfig.isConfigured) {
        throw Exception('OpenAI API key no configurada');
      }

      print('🌐 Enviando petición a OpenAI para resumen general...');

      final response = await http.post(
        Uri.parse('${OpenAIConfig.baseUrl}/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_getOpenAIKey()}',
        },
        body: {
          'model': OpenAIConfig.model,
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'max_tokens': 250,
          'temperature': OpenAIConfig.temperature,
        },
      ).timeout(const Duration(seconds: 30));

      print('✅ Respuesta recibida para resumen general');
      print('📊 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        return 'Este libro de $categoria aborda temas fundamentales de psicología, proporcionando información valiosa para el apoyo psicológico estudiantil. Los contenidos incluyen conceptos clave que pueden ser aplicados en el desarrollo académico y personal de los estudiantes.';
      } else {
        print('❌ Error en respuesta de OpenAI: ${response.statusCode}');
        throw Exception('Error en API de OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error generando resumen general, usando resumen básico');
      return 'Este libro de $categoria aborda temas fundamentales de psicología, proporcionando información valiosa para el apoyo psicológico estudiantil. Los contenidos incluyen conceptos clave que pueden ser aplicados en el desarrollo académico y personal de los estudiantes.';
    }
  }

  /// Crea la estructura de datos del libro según el formato especificado
  Map<String, dynamic> _crearEstructuraLibro({
    required PlatformFile archivo,
    required String autor,
    required String categoria,
    required String descripcion,
    required String textoOriginal,
    required Map<String, dynamic> resultadoIA,
  }) {
    print('🏗️ Creando estructura de datos del libro...');
    
    final String id = _uuid.v4();
    final String fechaActual = DateTime.now().toIso8601String();

    return {
      'activo': true,
      'archivo': archivo.name,
      'autor': autor,
      'categoria': categoria,
      'contenido': {
        'archivo': archivo.name,
        'resumenes_por_fragmento': resultadoIA['resumenes_por_fragmento'],
        'metadatos': {
          'fragmentos_originales': resultadoIA['fragmentos_originales'],
          'resumenes_generados': resultadoIA['resumenes_generados'],
          'procesado_con_ia': resultadoIA['procesado_con_ia'],
          'fecha_procesamiento': resultadoIA['fecha_procesamiento'],
        }
      },
      'creadoPor': 'sistema_pdf',
      'descripcion': descripcion,
      'fechaActualizacion': fechaActual,
      'fechaCreacion': fechaActual,
      'fragmentos_originales': resultadoIA['fragmentos_originales'],
      'id': id,
      'metadatos': {
        'archivo_original': path.basenameWithoutExtension(archivo.name),
        'contenido_estructurado': {
          'archivo': archivo.name,
          'metadatos': {
            'fecha_procesamiento': resultadoIA['fecha_procesamiento'],
            'fragmentos_originales': resultadoIA['fragmentos_originales'],
            'procesado_con_ia': resultadoIA['procesado_con_ia'],
            'resumenes_generados': resultadoIA['resumenes_generados'],
          },
          'resumenes_por_fragmento': resultadoIA['resumenes_por_fragmento'],
        },
        'estructura': 'json_like',
        'fuente': 'pdf_automatico',
        'ruta_pdf': kIsWeb
            ? 'archivo_subido_web'
            : (archivo.path ?? 'archivo_subido_desktop'),
        'version': '1.0',
        'procesado_con_ia': true,
      },
      'resumenes_por_fragmento': resultadoIA['resumenes_por_fragmento'],
      'tags': ['pdf', 'procesado'],
      'titulo': path.basenameWithoutExtension(archivo.name),
    };
  }

  /// Guarda el libro en Firebase
  Future<String> _guardarEnFirebase(Map<String, dynamic> libroData) async {
    try {
      print('💾 Intentando guardar libro en Firebase...');
      print('📚 Título: ${libroData['titulo']}');
      print('👤 Autor: ${libroData['autor']}');

      final DocumentReference docRef =
          await _firestore.collection('libros').add(libroData).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ Timeout guardando libro en Firebase');
          throw TimeoutException('La operación de guardado tardó demasiado');
        },
      );

      print('✅ Libro guardado exitosamente en Firebase: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ ERROR GUARDANDO EN FIREBASE: $e');
      print('📚 Título: ${libroData['titulo']}');
      print('👤 Autor: ${libroData['autor']}');

      // Si es un error de permisos, dar un mensaje más claro
      if (e.toString().contains('permission-denied')) {
        print('🔒 ERROR DE PERMISOS: Firestore no permite escribir');
        throw Exception(
            'Error de permisos: Las reglas de Firestore no permiten escribir.');
      }

      throw Exception('Error guardando en Firebase: $e');
    }
  }

  /// Obtiene la clave de OpenAI desde las variables de entorno
  String _getOpenAIKey() {
    final key = OpenAIConfig.apiKey;
    if (key.isEmpty) {
      print('❌ ERROR: OPENAI_API_KEY no está configurada');
      throw Exception(
          'OPENAI_API_KEY no está configurada. Verifica el archivo .env');
    }
    return key;
  }

  /// Obtiene todos los libros de Firebase
  Future<List<Map<String, dynamic>>> obtenerLibros() async {
    try {
      print('📚 Iniciando consulta a Firebase para obtener libros...');

      final QuerySnapshot snapshot = await _firestore
          .collection('libros')
          .orderBy('fechaCreacion', descending: true)
          .get()
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Timeout obteniendo libros de Firebase');
          throw TimeoutException('La consulta a Firebase tardó demasiado');
        },
      );

      print('✅ Consulta a Firebase completada');
      print('📄 Documentos encontrados: ${snapshot.docs.length}');

      final List<Map<String, dynamic>> libros = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      print('📚 Libros procesados: ${libros.length}');
      return libros;
    } catch (e) {
      print('❌ Error obteniendo libros de Firebase: $e');
      // Retornar lista vacía en lugar de lanzar excepción para no bloquear la UI
      return [];
    }
  }

  /// Elimina un libro de Firebase
  Future<void> eliminarLibro(String docId) async {
    try {
      print('🗑️ Intentando eliminar libro: $docId');
      await _firestore.collection('libros').doc(docId).delete();
      print('✅ Libro eliminado exitosamente: $docId');
    } catch (e) {
      print('❌ Error eliminando libro de Firebase: $e');
      throw Exception('Error eliminando libro: $e');
    }
  }

  /// Obtiene la base de conocimiento para el chat
  Future<String> obtenerBaseConocimiento() async {
    try {
      print('🧠 Generando base de conocimiento...');
      final List<Map<String, dynamic>> libros = await obtenerLibros();

      if (libros.isEmpty) {
        print('📭 No hay libros disponibles en la base de datos');
        return 'No hay libros de psicología disponibles.';
      }

      print('📚 Libros encontrados para base de conocimiento: ${libros.length}');

      String baseConocimiento = '''
# BASE DE CONOCIMIENTO EN PSICOLOGÍA

Esta es tu fuente de conocimiento científico para fundamentar todas las respuestas:

''';

      for (Map<String, dynamic> libro in libros) {
        if (libro['activo'] == true) {
          final String titulo = libro['titulo'] ?? 'Sin título';
          final String autor = libro['autor'] ?? 'Autor Desconocido';
          final String categoria = libro['categoria'] ?? 'General';

          baseConocimiento += '''
## 📚 $titulo
**Autor:** $autor  
**Categoría:** $categoria

''';

          // Agregar resúmenes de fragmentos
          final List<dynamic> resumenes =
              libro['resumenes_por_fragmento'] ?? [];
          for (int i = 0; i < resumenes.length && i < 5; i++) {
            baseConocimiento += '${resumenes[i]}\n\n';
          }

          baseConocimiento += '---\n\n';
        }
      }

      baseConocimiento += '''
## CONCEPTOS CLAVE A APLICAR:
- Inteligencia Emocional: Autoconciencia, autorregulación, motivación, empatía, habilidades sociales
- Regulación emocional: Técnicas de respiración, mindfulness, reestructuración cognitiva
- Desarrollo académico: Estrategias de estudio, manejo del estrés, motivación intrínseca
- Bienestar estudiantil: Equilibrio vida-académica, relaciones interpersonales, autoestima
- Técnicas psicológicas: Relajación progresiva, visualización, técnicas de afrontamiento

''';

      print('✅ Base de conocimiento generada exitosamente');
      print('📊 Longitud: ${baseConocimiento.length} caracteres');
      
      return baseConocimiento;
    } catch (e) {
      print('❌ Error generando base de conocimiento: $e');
      return 'Error generando base de conocimiento: $e';
    }
  }
}