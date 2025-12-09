class MusicOption {
  final String name;
  final String source;
  final String type; // 'local' o 'url'

  const MusicOption({
    required this.name,
    required this.source,
    required this.type,
  });
}

class MusicSettings {
  bool isEnabled = true;
  bool isPlaying = false;
  double volume = 0.5;
  String selectedType = 'url';
  String selectedSource = '';
  
  // Música local disponible
  static final localMusicOptions = [
    MusicOption(
      name: 'Meditación 1',
      source: 'meditacion.mp3',
      type: 'local',
    ),
    MusicOption(
      name: 'Meditación 2',
      source: 'meditation2.mp3',
      type: 'local',
    ),
    MusicOption(
      name: 'Sonidos de Lluvia',
      source: 'rain_sounds.mp3',
      type: 'local',
    ),
  ];

  // URLs de música online
  static final onlineMusicOptions = [
    MusicOption(
      name: 'Música Relajante 1',
      source: 'https://assets.mixkit.co/music/preview/mixkit-driving-ambition-32.mp3',
      type: 'url',
    ),
    MusicOption(
      name: 'Música Relajante 2',
      source: 'https://assets.mixkit.co/music/preview/mixkit-deep-relaxation-445.mp3',
      type: 'url',
    ),
    MusicOption(
      name: 'Sonidos de Naturaleza',
      source: 'https://assets.mixkit.co/music/preview/mixkit-forest-treasure-138.mp3',
      type: 'url',
    ),
    MusicOption(
      name: 'Música Calmante',
      source: 'https://assets.mixkit.co/music/preview/mixkit-deep-urban-623.mp3',
      type: 'url',
    ),
    MusicOption(
      name: 'Ambiente Relajante',
      source: 'https://assets.mixkit.co/music/preview/mixkit-sunny-happy-1322.mp3',
      type: 'url',
    ),
  ];
}