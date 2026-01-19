import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GptApi {
  static String get _apiKey {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OPENAI_API_KEY no está configurada en el archivo .env');
    }
    return apiKey;
  }

  static const _endpoint = 'https://api.openai.com/v1/chat/completions';

  static Future<String> getResponse(List<Map<String, String>> messages) async {
    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
        },
        body: utf8.encode(jsonEncode({
          "model": "gpt-3.5-turbo",
          "messages": messages,
          "temperature": 0.7,
        })),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else if (response.statusCode == 401) {
        print("Error 401: API key inválida - ${response.body}");
        return "⚠️ Error de autenticación. Verifica tu API key de OpenAI.";
      } else if (response.statusCode == 400) {
        print("Error 400: Solicitud incorrecta - ${response.body}");
        return "⚠️ Error en la solicitud. Verifica la configuración.";
      } else {
        print("Error GPT API: ${response.statusCode} - ${response.body}");
        return "⚠️ Lo siento, hubo un problema al responder. Inténtalo más tarde.";
      }
    } catch (e) {
      print("Excepción GPT API: $e");
      if (e.toString().contains('OPENAI_API_KEY no está configurada')) {
        return "⚠️ Error de configuración: API key no encontrada.";
      }
      return "⚠️ No pude conectar con el servidor. ¿Tienes conexión a internet?";
    }
  }
}
