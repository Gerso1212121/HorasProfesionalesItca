import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:horas2/Frontend/Modules/Excercises/Data/Models/EjercicioModel.dart';
import 'package:horas2/Frontend/Modules/Excercises/ViewModel/ExerciseViewModel.dart';
// ✅ Importamos nuestro nuevo servicio de audio
import 'package:horas2/Frontend/Modules/Excercises/Services/AudioStreamService.dart';

class ExerciseRunnerScreen extends StatefulWidget {
  final EjercicioModel exercise;

  const ExerciseRunnerScreen({super.key, required this.exercise});

  @override
  State<ExerciseRunnerScreen> createState() => _ExerciseRunnerScreenState();
}

class _ExerciseRunnerScreenState extends State<ExerciseRunnerScreen>
    with TickerProviderStateMixin {
  // ✅ Usamos just_audio a través del servicio
  final AudioStreamService _audioService = AudioStreamService();

  late AnimationController _timerController;
  late AnimationController _breathingController;
  Timer? _tickTimer;

  int _timeLeftInSeconds = 0;
  bool _isPlaying = false;
  bool _isVoiceEnabled = true;
  int _currentStepIndex = 0;
  bool _isCompleted = false;

  List<String> _processedInstructions = [];

  @override
  void initState() {
    super.initState();
    _initSetup();
  }

  void _initSetup() {
    // 1. Procesar instrucciones (separar por |)
    _processedInstructions = [];
    for (var instruction in widget.exercise.instrucciones) {
      if (instruction.contains('|')) {
        final parts = instruction
            .split('|')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
        _processedInstructions.addAll(parts);
      } else {
        _processedInstructions.add(instruction);
      }
    }

    if (_processedInstructions.isEmpty) {
      _processedInstructions.add("Relájate y concéntrate en tu respiración.");
    }

    // 2. Configurar Timer
    _timeLeftInSeconds = widget.exercise.duracionMinutos * 60;

    _timerController = AnimationController(
      vsync: this,
      duration:
          Duration(seconds: _timeLeftInSeconds > 0 ? _timeLeftInSeconds : 60),
    );

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // NOTA: Con just_audio no necesitamos configuración inicial compleja como con TTS local.
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _timerController.forward();
      if (widget.exercise.tipo == TipoEjercicio.respiracion) {
        _breathingController.repeat(reverse: true);
      }
      _startTicker();

      if (_isVoiceEnabled) {
        _speakInstruction();
      }
    } else {
      _timerController.stop();
      _breathingController.stop();
      _tickTimer?.cancel();
      _audioService.pause(); // ✅ Pausar el stream de audio
    }
  }

  void _startTicker() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftInSeconds > 0) {
        setState(() => _timeLeftInSeconds--);
      } else {
        _finishExercise();
      }
    });
  }

  // ✅ Lógica de Voz actualizada para Stream
  Future<void> _speakInstruction() async {
    if (!_isVoiceEnabled) {
      await _audioService.stop();
      return;
    }

    String textToSpeak = "";
    if (_currentStepIndex < _processedInstructions.length) {
      textToSpeak = _processedInstructions[_currentStepIndex];
    } else {
      textToSpeak = "Ejercicio completado. ¡Buen trabajo!";
    }

    // just_audio se encarga de descargar y reproducir
    await _audioService.speak(textToSpeak);
  }

  void _toggleVoice() {
    setState(() {
      _isVoiceEnabled = !_isVoiceEnabled;
    });

    if (!_isVoiceEnabled) {
      _audioService.stop();
      _showSnack("Voz desactivada");
    } else {
      _showSnack("Voz activada");
      if (_isPlaying) {
        _speakInstruction();
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 12)),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _nextStep() {
    if (_currentStepIndex < _processedInstructions.length - 1) {
      setState(() => _currentStepIndex++);
      if (_isPlaying && _isVoiceEnabled) {
        _speakInstruction();
      }
    }
  }

  void _prevStep() {
    if (_currentStepIndex > 0) {
      setState(() => _currentStepIndex--);
      if (_isPlaying && _isVoiceEnabled) {
        _speakInstruction();
      }
    }
  }

  void _finishExercise() {
    if (_isCompleted) return;

    _isCompleted = true;
    _tickTimer?.cancel();
    _timerController.stop();
    _breathingController.stop();
    _audioService.stop(); // ✅ Detener audio

    // Guardar en Backend Local
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExerciseViewModel>(context, listen: false).completeExercise(
        widget.exercise.titulo,
        widget.exercise.categoria,
        widget.exercise.duracionMinutos,
      );
    });

    // Modal con el diseño Premium
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 10,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: widget.exercise.colorTema.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.trophy,
                  size: 48,
                  color: widget.exercise.colorTema,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "¡Excelente sesión!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Has dedicado este tiempo a tu bienestar. Tu progreso ha sido registrado correctamente.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blueGrey[400],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.exercise.colorTema,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    "Continuar",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _timerController.dispose();
    _breathingController.dispose();
    _audioService.dispose(); // ✅ Limpiar reproductor
    super.dispose();
  }

  String get _formattedTime {
    final m = (_timeLeftInSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_timeLeftInSeconds % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    // ... RESTO DEL DISEÑO IDÉNTICO ...
    // Se mantiene tu UI intacta, solo hemos cambiado la lógica interna del audio.

    final colorTema = widget.exercise.colorTema;
    final size = MediaQuery.of(context).size;
    final totalDuration = widget.exercise.duracionMinutos * 60;

    final progressValue =
        totalDuration > 0 ? 1.0 - (_timeLeftInSeconds / totalDuration) : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: size.height * 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorTema.withOpacity(0.2),
                  Colors.white,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          widget.exercise.titulo,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isVoiceEnabled
                              ? LucideIcons.volume2
                              : LucideIcons.volumeX,
                          color: _isVoiceEnabled ? Colors.black87 : Colors.grey,
                        ),
                        onPressed: _toggleVoice,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (widget.exercise.tipo ==
                                TipoEjercicio.respiracion)
                              AnimatedBuilder(
                                animation: _breathingController,
                                builder: (context, child) {
                                  return Container(
                                    width:
                                        180 + (_breathingController.value * 60),
                                    height:
                                        180 + (_breathingController.value * 60),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colorTema.withOpacity(0.2 -
                                          (_breathingController.value * 0.1)),
                                    ),
                                  );
                                },
                              ),
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: CircularProgressIndicator(
                                value: progressValue,
                                strokeWidth: 12,
                                backgroundColor: Colors.grey[200],
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(colorTema),
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formattedTime,
                                  style: GoogleFonts.poppins(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey[800],
                                  ),
                                ),
                                Text(
                                  _isPlaying ? "En progreso" : "Pausado",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                          child: Material(
                            color: Colors.white,
                            elevation: 0,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: _isVoiceEnabled
                                    ? _speakInstruction
                                    : () {
                                        _toggleVoice();
                                      },
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Paso ${_currentStepIndex + 1} de ${_processedInstructions.length}",
                                            style: GoogleFonts.poppins(
                                              color: colorTema,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (_isVoiceEnabled) ...[
                                            const SizedBox(width: 6),
                                            Icon(LucideIcons.ear,
                                                size: 14,
                                                color:
                                                    colorTema.withOpacity(0.5))
                                          ]
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: Text(
                                            _processedInstructions.isNotEmpty
                                                ? _processedInstructions[
                                                    _currentStepIndex]
                                                : "Preparando...",
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors.black87,
                                              height: 1.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _isVoiceEnabled
                                            ? "Toca para repetir"
                                            : "Toca para activar voz",
                                        style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: Colors.grey[400]),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: _currentStepIndex > 0
                                                ? _prevStep
                                                : null,
                                            icon: Icon(Icons.arrow_back_ios,
                                                size: 20,
                                                color: _currentStepIndex > 0
                                                    ? Colors.grey[800]
                                                    : Colors.grey[300]),
                                          ),
                                          Row(
                                            children: List.generate(
                                              (_processedInstructions.length >
                                                      5)
                                                  ? 5
                                                  : _processedInstructions
                                                      .length,
                                              (index) => Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 2),
                                                width: 6,
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color:
                                                      (_currentStepIndex % 5 ==
                                                              index)
                                                          ? colorTema
                                                          : Colors.grey[300],
                                                ),
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: _currentStepIndex <
                                                    _processedInstructions
                                                            .length -
                                                        1
                                                ? _nextStep
                                                : null,
                                            icon: Icon(Icons.arrow_forward_ios,
                                                size: 20,
                                                color: _currentStepIndex <
                                                        _processedInstructions
                                                                .length -
                                                            1
                                                    ? Colors.grey[800]
                                                    : Colors.grey[300]),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            bottom: 20, top: 30),
                                        child: Column(
                                          children: [
                                            GestureDetector(
                                              onTap: _togglePlayPause,
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                    milliseconds: 200),
                                                width: 70,
                                                height: 70,
                                                decoration: BoxDecoration(
                                                  color: _isPlaying
                                                      ? Colors.orangeAccent
                                                      : colorTema,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: (_isPlaying
                                                              ? Colors
                                                                  .orangeAccent
                                                              : colorTema)
                                                          .withOpacity(0.4),
                                                      blurRadius: 15,
                                                      offset:
                                                          const Offset(0, 5),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  _isPlaying
                                                      ? LucideIcons.pause
                                                      : LucideIcons.play,
                                                  color: Colors.white,
                                                  size: 32,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            TextButton(
                                              onPressed: _finishExercise,
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Colors.grey[500],
                                              ),
                                              child: Text(
                                                "Finalizar ahora",
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
