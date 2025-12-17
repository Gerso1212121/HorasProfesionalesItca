// lib/Frontend/Modules/Diary/Widgets/MoodSelectorWidget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MoodSelectorWidget extends StatelessWidget {
  final String selectedMood;
  final Function() onTap;

  const MoodSelectorWidget({
    Key? key,
    required this.selectedMood,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFD2E3FC), width: 2),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              selectedMood,
              key: ValueKey<String>(selectedMood),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
      ),
    );
  }
}