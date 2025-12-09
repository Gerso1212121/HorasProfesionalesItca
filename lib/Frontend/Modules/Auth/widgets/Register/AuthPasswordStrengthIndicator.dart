// lib/Frontend/Auth/widgets/password_strength_indicator.dart
import 'package:flutter/material.dart';

class AuthPasswordStrengthIndicator extends StatelessWidget {
  final int strength; // 0-5
  final String? errorMessage;
  
  const AuthPasswordStrengthIndicator({
    super.key,
    required this.strength,
    this.errorMessage,
  });

  Color get _strengthColor {
    switch (strength) {
      case 0:
        return Colors.grey[300]!;
      case 1:
      case 2:
        return Colors.red;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.blue;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String get _strengthText {
    switch (strength) {
      case 0:
        return 'Muy débil';
      case 1:
      case 2:
        return 'Débil';
      case 3:
        return 'Regular';
      case 4:
        return 'Buena';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (strength == 0) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: strength / 5,
                backgroundColor: Colors.grey[200],
                color: _strengthColor,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _strengthText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _strengthColor,
              ),
            ),
          ],
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              errorMessage!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange[700],
              ),
            ),
          ),
      ],
    );
  }
}