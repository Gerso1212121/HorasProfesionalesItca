import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleAcademicas/SubScreens/Pomodoro/models/timer_mode.dart';

class ModeSelector extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeChanged;
  final Map<String, Color> modeColors;

  const ModeSelector({
    Key? key,
    required this.currentMode,
    required this.onModeChanged,
    required this.modeColors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: TimerMode.allModes.map((mode) {
            bool isSelected = currentMode == mode.name;
            return GestureDetector(
              onTap: () => onModeChanged(mode.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? modeColors[mode.name]! : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? modeColors[mode.name]! : Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  mode.name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}