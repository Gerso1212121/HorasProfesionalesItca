import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeDisplay extends StatelessWidget {
  final int remainingTime;
  final int selectedDuration;
  final String currentMode;
  final bool hasStarted;
  final bool isCompleted;

  const TimeDisplay({
    Key? key,
    required this.remainingTime,
    required this.selectedDuration,
    required this.currentMode,
    required this.hasStarted,
    required this.isCompleted,
  }) : super(key: key);

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (!hasStarted && !isCompleted) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${selectedDuration ~/ 60}',
            style: GoogleFonts.poppins(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'minutos',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 1.2,
            ),
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _formatTime(remainingTime),
            style: GoogleFonts.poppins(
              fontSize: 56,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            currentMode.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
              letterSpacing: 1.2,
            ),
          ),
        ],
      );
    }
  }
}