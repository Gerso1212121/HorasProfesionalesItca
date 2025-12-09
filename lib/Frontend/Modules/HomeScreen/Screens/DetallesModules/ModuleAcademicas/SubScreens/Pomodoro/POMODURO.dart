import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleAcademicas/SubScreens/Pomodoro/mode_selector.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleAcademicas/SubScreens/Pomodoro/music_settings_sheet.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleAcademicas/SubScreens/Pomodoro/pie_chart_painter.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleAcademicas/SubScreens/Pomodoro/time_display.dart';
import 'dart:async';

// Importaciones de modelos
import 'models/timer_mode.dart';
import 'models/music_settings.dart';
import 'models/timer_state.dart';

class PomodoroTimerScreen extends StatefulWidget {
  const PomodoroTimerScreen({Key? key}) : super(key: key);

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen>
    with SingleTickerProviderStateMixin {
  // Timer state
  late TimerState _timerState;
  TimerMode _currentMode = TimerMode.focus;
  Timer? _countdownTimer;
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Audio
  late AudioPlayer _audioPlayer;
  bool _isAudioInitialized = false;
  MusicSettings _musicSettings = MusicSettings();
  
  // Mapa de colores para modos
  final Map<String, Color> _modeColors = {
    'Focus': TimerMode.focus.color,
    'Short Break': TimerMode.shortBreak.color,
    'Long Break': TimerMode.longBreak.color,
  };

  @override
  void initState() {
    super.initState();
    _timerState = TimerState(remainingTime: _currentMode.duration);
    _initializeAnimation();
    _initializeAudio();
    _musicSettings.selectedSource = MusicSettings.onlineMusicOptions.first.source;
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.addListener(() {
      setState(() {
        _timerState = _timerState.copyWith(currentFill: _animation.value);
      });
    });
  }

  Future<void> _initializeAudio() async {
    _audioPlayer = AudioPlayer();
    
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_musicSettings.volume);
      _isAudioInitialized = true;
      
      _audioPlayer.onPlayerStateChanged.listen((state) {
        setState(() {
          _musicSettings.isPlaying = state == PlayerState.playing;
        });
      });
      
    } catch (e) {
      print('Error al inicializar audio: $e');
      _isAudioInitialized = false;
    }
  }
// En PomodoroTimerScreen, modifica los siguientes métodos:

Future<void> _playMusic() async {
  if (!_isAudioInitialized || !_musicSettings.isEnabled) return;
  
  if (_musicSettings.isPlaying) return;
  
  try {
    print('Reproduciendo música: ${_musicSettings.selectedSource}');
    
    // Verificar si es un archivo local del usuario
    if (_musicSettings.selectedSource.isNotEmpty) {
      // Verificar si es un archivo del sistema (no de assets)
      if (_musicSettings.selectedSource.contains('/') && 
          !_musicSettings.selectedSource.startsWith('assets/')) {
        // Es un archivo del sistema
        await _audioPlayer.setSourceDeviceFile(_musicSettings.selectedSource);
      } else if (_musicSettings.selectedType == 'local') {
        // Es de assets (predeterminado)
        await _audioPlayer.play(AssetSource('assets/audio/${_musicSettings.selectedSource}'));
      } else {
        // Es online
        await _audioPlayer.play(UrlSource(_musicSettings.selectedSource));
      }
      
      await _audioPlayer.resume();
      setState(() {
        _musicSettings.isPlaying = true;
      });
    }
  } catch (e) {
    print('Error al reproducir música: $e');
    setState(() {
      _musicSettings.isPlaying = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al reproducir música: $e',
            style: const TextStyle(fontFamily: 'Inter'),
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

// También modifica _playTestMusic:
Future<void> _playTestMusic() async {
  if (!_isAudioInitialized || !_musicSettings.isEnabled) return;
  
  if (_musicSettings.selectedSource.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Selecciona un archivo de música primero',
          style: const TextStyle(fontFamily: 'Inter'),
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
    return;
  }
  
  try {
    // Detener cualquier reproducción actual
    await _audioPlayer.stop();
    
    // Verificar tipo de archivo
    if (_musicSettings.selectedSource.contains('/') && 
        !_musicSettings.selectedSource.startsWith('assets/')) {
      // Es un archivo del sistema
      await _audioPlayer.setSourceDeviceFile(_musicSettings.selectedSource);
    } else if (_musicSettings.selectedType == 'local') {
      // Es de assets
      await _audioPlayer.play(AssetSource('assets/audio/${_musicSettings.selectedSource}'));
    } else {
      // Es online
      await _audioPlayer.play(UrlSource(_musicSettings.selectedSource));
    }
    
    await _audioPlayer.resume();
    setState(() {
      _musicSettings.isPlaying = true;
    });
  } catch (e) {
    print('Error al reproducir música de prueba: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al reproducir música: $e',
            style: const TextStyle(fontFamily: 'Inter'),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}

 

  Future<void> _pauseMusic() async {
    if (_isAudioInitialized && _musicSettings.isPlaying) {
      try {
        await _audioPlayer.pause();
        setState(() {
          _musicSettings.isPlaying = false;
        });
      } catch (e) {
        print('Error al pausar música: $e');
      }
    }
  }

  Future<void> _stopMusic() async {
    if (_isAudioInitialized) {
      try {
        await _audioPlayer.stop();
        setState(() {
          _musicSettings.isPlaying = false;
        });
      } catch (e) {
        print('Error al detener música: $e');
      }
    }
  }

  Future<void> _setVolume(double volume) async {
    if (_isAudioInitialized) {
      try {
        await _audioPlayer.setVolume(volume);
        setState(() {
          _musicSettings.volume = volume;
        });
      } catch (e) {
        print('Error al ajustar volumen: $e');
      }
    }
  }

  void _updateAnimation() {
    double fillPercentage = 1.0 - (_timerState.remainingTime / _currentMode.duration);
    _animationController.animateTo(
      fillPercentage,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _startTimer() {
    setState(() {
      _timerState = _timerState.copyWith(
        isRunning: true,
        hasStarted: true,
      );
    });

    _updateAnimation();
    
    if (_musicSettings.isEnabled) {
      _playMusic();
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerState.remainingTime > 0) {
        setState(() {
          _timerState = _timerState.copyWith(
            remainingTime: _timerState.remainingTime - 1,
          );
          _updateAnimation();
        });
      } else {
        _completeSession();
      }
    });
  }

  void _pauseTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _timerState = _timerState.copyWith(isRunning: false);
    });
    
    _pauseMusic();
  }

  void _resumeTimer() {
    _startTimer();
  }

  void _completeSession() {
    _countdownTimer?.cancel();
    setState(() {
      _timerState = _timerState.copyWith(
        isRunning: false,
        isCompleted: true,
        remainingTime: 0,
      );
    });

    _animationController.animateTo(
      1.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    
    _stopMusic();
    _showCompletionDialog();
  }

  void _resetTimer() {
    _countdownTimer?.cancel();
    setState(() {
      _timerState = TimerState(remainingTime: _currentMode.duration);
    });

    _animationController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    
    _stopMusic();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            Text(
              '¡Sesión Completada!',
              style: GoogleFonts.itim(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        content: Text(
          'Excelente trabajo. Has completado tu sesión de ${_currentMode.name}.\n\n¿Te gustaría tomar un descanso o comenzar una nueva sesión?',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (_currentMode.name == 'Focus') {
                _setMode('Short Break');
              } else {
                _setMode('Focus');
              }
            },
            child: Text(
              _currentMode.name == 'Focus' ? 'Tomar Descanso' : 'Nueva Sesión',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _modeColors[_currentMode.name]!,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetTimer();
            },
            child: Text(
              'Reiniciar',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeColor = _modeColors[_currentMode.name]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FDFF),
      appBar: _buildAppBar(modeColor),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              _buildMainCard(modeColor),
              const SizedBox(height: 20),
              _buildInfoCard(modeColor),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(Color modeColor) {
    return AppBar(
      title: Text(
        'Timer Pomodoro',
        style: GoogleFonts.itim(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
      centerTitle: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.grey, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: Icon(
                _musicSettings.isPlaying ? Icons.music_note : Icons.music_off,
                color: _musicSettings.isEnabled ? modeColor : Colors.grey[400],
              ),
              onPressed: _showMusicSettings,
            ),
            if (_musicSettings.isPlaying)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainCard(Color modeColor) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: modeColor.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildCardHeader(modeColor),
            const SizedBox(height: 20),
            ModeSelector(
              currentMode: _currentMode.name,
              onModeChanged: _setMode,
              modeColors: _modeColors,
            ),
            const SizedBox(height: 30),
            _buildTimerCircle(modeColor),
            const SizedBox(height: 30),
            _buildTimerStatus(),
            const SizedBox(height: 30),
            _buildControlButton(modeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Color modeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: modeColor,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: modeColor.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_rounded, size: 12, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Técnica Pomodoro',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            GestureDetector(
              onTap: _showMusicSettings,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _musicSettings.isEnabled 
                    ? modeColor.withOpacity(0.1)
                    : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _musicSettings.isEnabled 
                      ? modeColor.withOpacity(0.3)
                      : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _musicSettings.isPlaying 
                        ? Icons.volume_up 
                        : Icons.volume_off,
                      size: 14,
                      color: _musicSettings.isEnabled 
                        ? modeColor 
                        : Colors.grey[400],
                    ),
                    if (_musicSettings.isPlaying) const SizedBox(width: 4),
                    if (_musicSettings.isPlaying) Text(
                      '${(_musicSettings.volume * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: modeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.timer_outlined, color: modeColor, size: 28),
          ],
        ),
      ],
    );
  }

  Widget _buildTimerCircle(Color modeColor) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: modeColor,
        boxShadow: [
          BoxShadow(
            color: modeColor.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: PieChartPainter(
              fillPercentage: _timerState.currentFill,
              color: Colors.white.withOpacity(0.3),
              isRunning: _timerState.isRunning,
              isCompleted: _timerState.isCompleted,
            ),
            size: const Size(220, 220),
          ),
          TimeDisplay(
            remainingTime: _timerState.remainingTime,
            selectedDuration: _currentMode.duration,
            currentMode: _currentMode.name,
            hasStarted: _timerState.hasStarted,
            isCompleted: _timerState.isCompleted,
          ),
        ],
      ),
    );
  }

  Widget _buildTimerStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _timerState.isRunning
                  ? Colors.green
                  : (_timerState.isCompleted ? Colors.green : Colors.grey),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _timerState.isCompleted
                ? 'COMPLETADO'
                : _timerState.isRunning
                    ? 'EN PROGRESO'
                    : 'LISTO PARA INICIAR',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _timerState.isCompleted
                  ? Colors.green
                  : _timerState.isRunning
                      ? Colors.green
                      : Colors.grey[600],
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(Color modeColor) {
    String buttonText = _getButtonText();

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _handleButtonPress,
        style: ElevatedButton.styleFrom(
          backgroundColor: modeColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: modeColor.withOpacity(0.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _timerState.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
              size: 24,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(
              buttonText,
              style: GoogleFonts.itim(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Color modeColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline_rounded, color: modeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Sobre la Técnica Pomodoro',
                style: GoogleFonts.itim(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'La técnica Pomodoro mejora la concentración y productividad dividiendo el trabajo en intervalos de 25 minutos (pomodoros) seguidos de breves descansos.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: modeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Enfócate 25 min',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: modeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: modeColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Descansa 5 min',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: modeColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showMusicSettings,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: modeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _musicSettings.isEnabled ? Icons.music_note : Icons.music_off,
                        size: 12,
                        color: modeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _musicSettings.isPlaying ? 'Música ON' : 'Música',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: modeColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getButtonText() {
    if (_timerState.isCompleted) return 'Comenzar Nueva';
    if (!_timerState.isRunning) return _timerState.hasStarted ? 'Reanudar' : 'Iniciar';
    return 'Pausar';
  }

  void _showMusicSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MusicSettingsSheet(
        settings: _musicSettings,
        onSettingsChanged: _updateMusicSettings,
        onPlayTest: _playTestMusic,
        onStopTest: _stopTestMusic,
        accentColor: _modeColors[_currentMode.name]!,
      ),
    );
  }

  void _updateMusicSettings(MusicSettings newSettings) {
    setState(() {
      _musicSettings = newSettings;
    });
    _audioPlayer.setVolume(newSettings.volume);
  }
 

  Future<void> _stopTestMusic() async {
    if (_isAudioInitialized) {
      try {
        await _audioPlayer.stop();
        setState(() {
          _musicSettings.isPlaying = false;
        });
      } catch (e) {
        print('Error al detener música de prueba: $e');
      }
    }
  }

  void _setMode(String modeName) {
    final newMode = TimerMode.allModes.firstWhere((m) => m.name == modeName);
    
    if (_timerState.isRunning) {
      _pauseTimer();
    }

    setState(() {
      _currentMode = newMode;
      _timerState = TimerState(remainingTime: newMode.duration);
    });

    _animationController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    
    _stopMusic();
  }

  void _handleButtonPress() {
    if (_timerState.isCompleted) {
      _resetTimer();
    } else if (!_timerState.isRunning) {
      if (!_timerState.hasStarted) {
        _startTimer();
      } else {
        _resumeTimer();
      }
    } else {
      _pauseTimer();
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
}