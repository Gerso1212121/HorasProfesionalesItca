import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleAcademicas/SubScreens/Pomodoro/models/music_settings.dart';

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

  // URLs de música online predefinidas (audio directo, no YouTube)
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
  ];

  MusicSettings copyWith({
    bool? isEnabled,
    bool? isPlaying,
    double? volume,
    String? selectedType,
    String? selectedSource,
  }) {
    return MusicSettings()
      ..isEnabled = isEnabled ?? this.isEnabled
      ..isPlaying = isPlaying ?? this.isPlaying
      ..volume = volume ?? this.volume
      ..selectedType = selectedType ?? this.selectedType
      ..selectedSource = selectedSource ?? this.selectedSource;
  }
}