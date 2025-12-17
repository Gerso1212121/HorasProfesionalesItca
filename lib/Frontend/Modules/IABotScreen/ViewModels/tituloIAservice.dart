import 'dart:developer' as developer;
import 'package:horas2/Backend/Data/API/GPTService.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/mensajes.dart';

class TituloIAService {
  static Future<String> generarTituloConIA(List<Mensaje> mensajes) async {
    if (mensajes.isEmpty) {
      return "Conversación vacía";
    }

    try {
      // Obtener solo los mensajes del usuario (no sistema, no asistente)
      final mensajesUsuario = mensajes
          .where((m) => m.emisor != "Sistema" && 
                      m.emisor != "Asistente" &&
                      m.contenido != "TYPING_INDICATOR")
          .map((m) => m.contenido)
          .toList();

      if (mensajesUsuario.isEmpty) {
        return "Conversación sin mensajes del usuario";
      }

      // Tomar primeros 3 mensajes del usuario
      final contenidoCombinado = mensajesUsuario.take(3).join('\n');

      final prompt = '''
Analiza el siguiente contenido de una conversación y genera un título corto y descriptivo (máximo 30 caracteres) que capture la esencia del tema principal.

IMPORTANTE: 
- El título debe ser en español
- Máximo 30 caracteres
- Sé específico pero breve
- Usa un lenguaje natural

Conversación:
$contenidoCombinado

Título:''';

      final respuesta = await GPTService.getResponse([
        {"role": "user", "content": prompt}
      ]);

      // Limpiar la respuesta
      String titulo = respuesta.trim();
      
      // Remover comillas si las tiene
      titulo = titulo.replaceAll('"', '').replaceAll("'", '');
      
      // Limitar a 30 caracteres
      if (titulo.length > 30) {
        titulo = titulo.substring(0, 27) + "...";
      }
      
      // Si está vacío, usar fallback
      if (titulo.isEmpty) {
        titulo = _generarTituloFallback(mensajesUsuario.first);
      }

      developer.log('🤖 Título generado por IA: "$titulo"');
      return titulo;
    } catch (e) {
      developer.log('❌ Error generando título con IA: $e');
      
      // Fallback mejorado
      final mensajesUsuario = mensajes
          .where((m) => m.emisor != "Sistema" && 
                      m.emisor != "Asistente")
          .toList();
          
      if (mensajesUsuario.isNotEmpty) {
        return _generarTituloFallback(mensajesUsuario.first.contenido);
      }
      
      return "Conversación";
    }
  }
  
  static String _generarTituloFallback(String primerMensaje) {
    if (primerMensaje.length > 30) {
      return "${primerMensaje.substring(0, 27)}...";
    }
    return primerMensaje;
  }
}