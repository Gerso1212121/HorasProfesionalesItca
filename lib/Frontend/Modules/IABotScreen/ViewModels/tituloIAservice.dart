import 'dart:developer' as developer;
import 'package:horas2/Backend/Data/API/GPTService.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/mensajes.dart';

class TituloIAService {
  static Future<String> generarTituloConIA(List<Mensaje> mensajes) async {
    if (mensajes.isEmpty) {
      return "Conversación vacía";
    }

    try {
      // Obtener solo los mensajes del usuario para analizar el contexto
      final mensajesUsuario = mensajes
          .where((m) => m.emisor == "Usuario")
          .map((m) => m.contenido)
          .toList();

      if (mensajesUsuario.isEmpty) {
        return "Conversación sin mensajes del usuario";
      }

      // Crear un prompt para que la IA genere un título
      final contenidoCombinado = mensajesUsuario.take(5).join('\n');

      final prompt = '''
Analiza el siguiente contenido de una conversación y genera un título corto y descriptivo (máximo 30 caracteres) que capture la esencia del tema principal.

Conversación:
$contenidoCombinado

Genera solo el título, sin explicaciones adicionales. El título debe ser:
- Corto y directo
- Descriptivo del tema principal
- En español
- Máximo 30 caracteres

Título:''';

      final respuesta = await GPTService.getResponse([
        {"role": "user", "content": prompt}
      ]);

      // Limpiar la respuesta y asegurar que no exceda 30 caracteres
      String titulo = respuesta.trim();
      if (titulo.length > 30) {
        titulo = titulo.substring(0, 27) + "...";
      }

      developer.log('🤖 Título generado por IA: $titulo');
      return titulo;
    } catch (e) {
      developer.log('❌ Error generando título con IA: $e');
      // Fallback: usar el primer mensaje del usuario
      final primerMensaje =
          mensajes.where((m) => m.emisor == "Usuario").firstOrNull?.contenido ??
              "Conversación";

      if (primerMensaje.length > 30) {
        return "${primerMensaje.substring(0, 27)}...";
      }
      return primerMensaje;
    }
  }
}
