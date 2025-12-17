import 'package:just_audio/just_audio.dart';

class AudioStreamService {
  final AudioPlayer _player = AudioPlayer();

  // Estado del reproductor
  bool get isPlaying => _player.playing;

  // URL del servicio TTS de Google (Gratuito y estable)
  // Usamos 'es-MX' para obtener el acento neutro latinoamericano similar a Dalia
  final String _baseUrl = "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=es-MX";

  AudioStreamService() {
    _initAudioSettings();
  }

  Future<void> _initAudioSettings() async {
    // 🎛️ AJUSTE DE "CALMA":
    // Dalia se caracteriza por ser pausada. 
    // Bajamos la velocidad a 0.85x o 0.9x para quitarle el efecto "robótico/acelerado" de Google.
    await _player.setSpeed(1.0); 
    
    // El pitch (tono) en 1.0 suele estar bien, pero puedes bajarlo a 0.95 para una voz más grave/relajada.
    await _player.setPitch(1.07); 
  }

  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    
    try {
      // 1. Detenemos cualquier audio previo suavemente
      if (_player.playing) {
        await _player.stop();
      }

      // 2. Construimos la URL
      final String url = "$_baseUrl&q=${Uri.encodeComponent(text)}";

      // 3. Cargamos la URL como un stream de audio
      await _player.setUrl(url);

      // 4. Reproducimos
      await _player.play();
    } catch (e) {
      print("❌ Error reproduciendo stream de audio: $e");
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> pause() async {
    await _player.pause();
  }
  
  void dispose() {
    _player.dispose();
  }
}