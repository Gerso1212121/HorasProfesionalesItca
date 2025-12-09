import 'dart:core';
import 'package:horas2/Backend/Data/API/GPTService.dart';

import 'dart:developer' as developer;

// Analiza el mensaje del usuario y clasifica la emoción/estado usando IA
// Retorna: neutral | sad | stressed | high_risk
Future<String> analyzeEmotion(String message) async {
  if (message.isEmpty) return 'neutral';

  try {
    // Usar IA para evaluar el estado emocional
    final prompt = '''
Eres un experto en psicología estudiantil. Analiza el siguiente mensaje de un estudiante y clasifica su estado emocional.

IMPORTANTE: 
- Solo considera 'high_risk' si hay intenciones claras de autolesión o violencia hacia otros
- 'sad' es para tristeza normal, duelo, o depresión leve
- 'stressed' es para ansiedad, preocupación, o estrés académico
- 'neutral' es para conversaciones normales

Mensaje a analizar: "$message"

Responde ÚNICAMENTE con una de estas opciones:
- "high_risk" si hay intenciones de autolesión o violencia
- "sad" si hay tristeza, duelo, o depresión leve
- "stressed" si hay ansiedad, preocupación, o estrés
- "neutral" si es una conversación normal

Respuesta:''';

    final response = await GPTService.getResponse([
      {"role": "user", "content": prompt}
    ]);

    final emotion = response.toLowerCase().trim();

    // Validar que la respuesta sea válida
    if (['high_risk', 'sad', 'stressed', 'neutral'].contains(emotion)) {
      return emotion;
    } else {
      // Fallback a neutral si la respuesta no es válida
      return 'neutral';
    }
  } catch (e) {
    developer.log('❌ Error analizando emoción: $e');
    // En caso de error, retornar neutral
    return 'neutral';
  }
}

// Genera una respuesta base del asistente según la emoción detectada
String getAssistantResponse(String userMessage, String userName, String emotion,
    String? highRiskFollowUpMessage) {
  switch (emotion) {
    case 'high_risk':
      return '🚨 ALERTA: Tu vida es muy valiosa y mereces ayuda profesional INMEDIATA.\n\n'
          '📞 Bienestar Estudiantil – ITCA San Miguel\n'
          '☎️ 7854-6266 / 2669-2298\n'
          '📧 pcoreas@itca.edu.sv\n\n'
          '💙 Por favor, contacta ahora. No estás solo.';
    case 'sad':
      return '💙 Siento mucho que te sientas así, $userName. Tu bienestar es importante y '
          'no tienes que cargar con esto solo/a. Si quieres, podemos explorar juntos '
          'maneras de sentirte un poquito mejor ahora.';
    case 'stressed':
      return '💙 Entiendo que te sientes abrumado/a, $userName. Es normal sentirse así a veces. '
          'Tu bienestar es importante. Si quieres, podemos hablar sobre lo que te está '
          'preocupando y buscar maneras de manejar esta situación juntos.';
    case 'neutral':
    default:
      return '';
  }
}
