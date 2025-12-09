import 'dart:developer' as developer;
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/mensajes.dart';

class TituloDinamicoService {
  static String generarTituloDinamico(List<Mensaje> mensajes) {
    if (mensajes.isEmpty) {
      return "Conversación vacía";
    }

    try {
      // Obtener los primeros mensajes para analizar el contexto
      final primerosMensajes = mensajes.take(3).toList();
      final contenidoCombinado =
          primerosMensajes.map((m) => m.contenido.toLowerCase()).join(' ');

      // Palabras clave para identificar temas
      final temas = {
        'salud mental': [
          'ansiedad',
          'depresión',
          'estrés',
          'triste',
          'feliz',
          'emociones',
          'sentimientos',
          'terapia',
          'psicólogo'
        ],
        'estudios': [
          'estudiar',
          'examen',
          'tarea',
          'universidad',
          'colegio',
          'aprendizaje',
          'profesor',
          'clase'
        ],
        'trabajo': [
          'trabajo',
          'empleo',
          'carrera',
          'profesión',
          'oficina',
          'jefe',
          'colaborador'
        ],
        'relaciones': [
          'amigo',
          'familia',
          'pareja',
          'novio',
          'novia',
          'amor',
          'romance',
          'matrimonio'
        ],
        'tecnología': [
          'computadora',
          'teléfono',
          'internet',
          'app',
          'software',
          'programación',
          'tecnología'
        ],
        'deportes': [
          'ejercicio',
          'gimnasio',
          'deporte',
          'fútbol',
          'basketball',
          'correr',
          'entrenamiento'
        ],
        'finanzas': [
          'dinero',
          'ahorro',
          'inversión',
          'gastos',
          'presupuesto',
          'trabajo',
          'salario'
        ],
        'viajes': [
          'viaje',
          'vacaciones',
          'turismo',
          'destino',
          'hotel',
          'avión',
          'turista'
        ],
        'cocina': [
          'cocinar',
          'receta',
          'comida',
          'restaurante',
          'chef',
          'gastronomía'
        ],
        'arte': [
          'música',
          'pintura',
          'arte',
          'dibujo',
          'creatividad',
          'diseño'
        ],
      };

      // Buscar el tema más relevante
      String temaEncontrado = "Conversación general";
      int maxCoincidencias = 0;

      for (final entry in temas.entries) {
        int coincidencias = 0;
        for (final palabra in entry.value) {
          if (contenidoCombinado.contains(palabra)) {
            coincidencias++;
          }
        }
        if (coincidencias > maxCoincidencias) {
          maxCoincidencias = coincidencias;
          temaEncontrado = entry.key;
        }
      }

      // Generar título específico basado en el primer mensaje del usuario
      final primerMensajeUsuario = mensajes.firstWhere(
        (m) => m.emisor == "Usuario",
        orElse: () => Mensaje(emisor: "Usuario", contenido: "", fecha: ""),
      );

      if (primerMensajeUsuario.contenido.isNotEmpty) {
        final contenido = primerMensajeUsuario.contenido.toLowerCase();

        // Títulos específicos basados en palabras clave
        if (contenido.contains('ayuda') || contenido.contains('ayúdame')) {
          return "🆘 Pidiendo ayuda";
        } else if (contenido.contains('cómo') || contenido.contains('como')) {
          return "❓ Pregunta: ${_extraerPregunta(primerMensajeUsuario.contenido)}";
        } else if (contenido.contains('qué') || contenido.contains('que')) {
          return "❓ Consulta: ${_extraerPregunta(primerMensajeUsuario.contenido)}";
        } else if (contenido.contains('gracias')) {
          return "🙏 Agradecimiento";
        } else if (contenido.contains('hola') ||
            contenido.contains('buenos días') ||
            contenido.contains('buenas')) {
          return "👋 Saludo inicial";
        } else if (contenido.length < 50) {
          // Si es un mensaje corto, usarlo como título
          return "💬 ${primerMensajeUsuario.contenido}";
        }
      }

      // Título basado en el tema encontrado
      switch (temaEncontrado) {
        case 'salud mental':
          return "🧠 Conversación sobre salud mental";
        case 'estudios':
          return "📚 Conversación sobre estudios";
        case 'trabajo':
          return "💼 Conversación sobre trabajo";
        case 'relaciones':
          return "❤️ Conversación sobre relaciones";
        case 'tecnología':
          return "💻 Conversación sobre tecnología";
        case 'deportes':
          return "⚽ Conversación sobre deportes";
        case 'finanzas':
          return "💰 Conversación sobre finanzas";
        case 'viajes':
          return "✈️ Conversación sobre viajes";
        case 'cocina':
          return "🍳 Conversación sobre cocina";
        case 'arte':
          return "🎨 Conversación sobre arte";
        default:
          return "💬 Conversación general";
      }
    } catch (e) {
      developer.log('❌ Error generando título dinámico: $e');
      return "💬 Conversación";
    }
  }

  static String _extraerPregunta(String contenido) {
    // Limpiar y acortar la pregunta para el título
    String pregunta = contenido.trim();
    if (pregunta.length > 30) {
      pregunta = pregunta.substring(0, 30) + "...";
    }
    return pregunta;
  }

  static String generarTituloPorFecha(String fecha) {
    try {
      final fechaObj = DateTime.parse(fecha);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(fechaObj);

      if (diferencia.inDays == 0) {
        return "📅 Hoy";
      } else if (diferencia.inDays == 1) {
        return "📅 Ayer";
      } else if (diferencia.inDays < 7) {
        return "📅 Hace ${diferencia.inDays} días";
      } else if (diferencia.inDays < 30) {
        final semanas = (diferencia.inDays / 7).floor();
        return "📅 Hace $semanas semana${semanas == 1 ? '' : 's'}";
      } else {
        final meses = (diferencia.inDays / 30).floor();
        return "📅 Hace $meses mes${meses == 1 ? '' : 'es'}";
      }
    } catch (e) {
      return "📅 Conversación";
    }
  }
}
