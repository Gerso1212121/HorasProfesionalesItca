import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class PomodoroScreen extends StatefulWidget {
  const PomodoroScreen({Key? key}) : super(key: key);

  @override
  State<PomodoroScreen> createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen> {
  Timer? _timer;
  int _minutes = 25;
  int _seconds = 0;
  int _currentCycle = 1;
  bool _isRunning = false;
  bool _isBreak = false;
  String _currentTask = '';
  String _initialMood = '';
  String _sessionMood = '';
  int _completedCycles = 0;
  String _dailyReflection = '';

  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();

  // Frases motivacionales para durante la sesión
  final List<String> _focusPhrases = [
    "Concéntrate solo en este paso, lo demás vendrá después.",
    "Este tiempo es para ti, aprovéchalo al máximo.",
    "Cada minuto enfocado te acerca a tu meta.",
    "Evita distracciones. Tu futuro te lo agradecerá.",
  ];

  String get _currentFocusPhrase =>
      _focusPhrases[(_currentCycle - 1) % _focusPhrases.length];

  @override
  void dispose() {
    _timer?.cancel();
    _taskController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_seconds > 0) {
          _seconds--;
        } else if (_minutes > 0) {
          _minutes--;
          _seconds = 59;
        } else {
          _completeSession();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });
    _timer?.cancel();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      if (_isBreak) {
        _minutes = _currentCycle % 4 == 0 ? 15 : 5;
      } else {
        _minutes = 25;
      }
      _seconds = 0;
    });
    _timer?.cancel();
  }

  void _cancelCycle() {
    setState(() {
      _isRunning = false;
      _isBreak = false;
      _minutes = 25;
      _seconds = 0;
      _currentTask = '';
      _initialMood = '';
    });
    _timer?.cancel();
  }

  void _completeSession() {
    _timer?.cancel();

    if (!_isBreak) {
      // Completó una sesión de trabajo
      setState(() {
        _completedCycles++;
        _isBreak = true;
        _isRunning = false;

        if (_currentCycle % 4 == 0) {
          _minutes = 15; // Descanso largo
        } else {
          _minutes = 5; // Descanso corto
        }
        _seconds = 0;
      });

      _showSessionCompleteDialog();
    } else {
      // Completó un descanso
      if (_currentCycle >= 4) {
        _showDailySummary();
      } else {
        setState(() {
          _currentCycle++;
          _isBreak = false;
          _minutes = 25;
          _seconds = 0;
          _sessionMood = '';
        });
      }
    }
  }

  void _showSessionCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            '¡Buen trabajo!',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '¿Cómo te sentiste durante esta sesión?',
                style: GoogleFonts.inter(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildMoodButton('😃', 'Productivo'),
                  _buildMoodButton('😌', 'Tranquilo'),
                  _buildMoodButton('😕', 'Distraído'),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Sugerencia para el descanso:',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildBreakSuggestion(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startTimer();
              },
              child: Text(
                'Continuar al siguiente ciclo',
                style: GoogleFonts.inter(color: const Color(0xFF4CAF50)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoodButton(String emoji, String label) {
    final isSelected = _sessionMood == label;
    return GestureDetector(
      onTap: () => setState(() => _sessionMood = label),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected ? Border.all(color: const Color(0xFF4CAF50)) : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Text(label, style: GoogleFonts.inter(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakSuggestion() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            _currentCycle % 4 == 0
                ? 'Descanso largo (15 min)'
                : 'Descanso corto (5 min)',
            style: GoogleFonts.inter(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            '• Estiramiento de 2 minutos\n• Respiración 4-7-8 guiada\n• Frase motivadora',
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _showDailySummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Resumen Diario',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSummaryItem(
                    'Ciclos completados', '$_completedCycles de 4'),
                _buildSummaryItem(
                    'Tiempo efectivo', '${_completedCycles * 25} min'),
                _buildSummaryItem('Estado emocional promedio', '😌'),
                const SizedBox(height: 16),
                Text(
                  'Reflexión rápida:',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _reflectionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: '¿Qué lograste hoy?\n¿Qué puedes mejorar mañana?',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _dailyReflection = _reflectionController.text;
                  _currentCycle = 1;
                  _completedCycles = 0;
                  _isBreak = false;
                  _minutes = 25;
                  _seconds = 0;
                });
                Navigator.of(context).pop();
                Navigator.of(context).pop(); // Volver a la pantalla anterior
              },
              child: Text(
                'Finalizar',
                style: GoogleFonts.inter(color: const Color(0xFF4CAF50)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter()),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      appBar: AppBar(
        title: Text(
          'Concentra y Avanza',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFF66B7D),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!_isRunning && !_isBreak && _initialMood.isEmpty)
              _buildInitialSetup()
            else if (_isRunning || _isBreak)
              _buildActiveSession()
            else
              _buildPausedSession(),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialSetup() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Iniciar sesión Pomodoro',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 30),

          // Timer display
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF66B7D).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFF66B7D),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Cycle indicator
          Text(
            'Ciclo actual: $_currentCycle / 4',
            style: GoogleFonts.inter(fontSize: 18),
          ),

          const SizedBox(height: 20),

          // Task input
          TextField(
            controller: _taskController,
            decoration: InputDecoration(
              labelText: 'Tarea del momento',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) => _currentTask = value,
          ),

          const SizedBox(height: 20),

          // Initial mood
          Text(
            '¿Cómo te sientes antes de comenzar?',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInitialMoodButton('😊', 'Bien'),
              _buildInitialMoodButton('😐', 'Regular'),
              _buildInitialMoodButton('😟', 'Estresado/a'),
            ],
          ),

          const SizedBox(height: 30),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _initialMood.isNotEmpty && _currentTask.isNotEmpty
                  ? _startTimer
                  : null,
              icon: const Icon(Icons.play_arrow, color: Colors.white),
              label: Text(
                'Iniciar',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialMoodButton(String emoji, String label) {
    final isSelected = _initialMood == label;
    return GestureDetector(
      onTap: () => setState(() => _initialMood = label),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4CAF50).withOpacity(0.2)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border:
              isSelected ? Border.all(color: const Color(0xFF4CAF50)) : null,
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSession() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  _isBreak ? const Color(0xFF4CAF50) : const Color(0xFFF66B7D),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isBreak ? 'Descanso' : 'Enfoque',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Timer display
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color:
                  (_isBreak ? const Color(0xFF4CAF50) : const Color(0xFFF66B7D))
                      .withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              '${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: _isBreak
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF66B7D),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Text(
            'Ciclo $_currentCycle de 4',
            style: GoogleFonts.inter(fontSize: 18),
          ),

          if (!_isBreak) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Frase de enfoque:',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"$_currentFocusPhrase"',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.blue[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Evita distracciones. Este tiempo es para ti.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 30),

          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: _isRunning ? _pauseTimer : _startTimer,
                icon: Icon(
                  _isRunning ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                label: Text(
                  _isRunning ? 'Pausar' : 'Reanudar',
                  style: const TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isRunning ? Colors.orange : const Color(0xFF4CAF50),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _resetTimer,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Reiniciar',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _cancelCycle,
                icon: const Icon(Icons.close, color: Colors.white),
                label: const Text('Cancelar',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPausedSession() {
    return _buildActiveSession();
  }
}
