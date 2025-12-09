import 'package:flutter/material.dart';
import 'dart:math';

class PieChartPainter extends CustomPainter {
  final double fillPercentage;
  final Color color;
  final bool isRunning;
  final bool isCompleted;

  PieChartPainter({
    required this.fillPercentage,
    required this.color,
    required this.isRunning,
    required this.isCompleted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double sweepAngle = 2 * pi * fillPercentage;

    final piePaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeWidth = 0;

    if (fillPercentage > 0 && fillPercentage <= 1.0) {
      canvas.drawArc(
        rect,
        -pi / 2,
        sweepAngle,
        true,
        piePaint,
      );
    }

    if (isRunning && fillPercentage > 0 && fillPercentage < 1.0) {
      final pulsePaint = Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawArc(
        rect,
        -pi / 2,
        sweepAngle,
        true,
        pulsePaint,
      );
    }

    if (isCompleted) {
      final completedPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(center, radius, completedPaint);
    }
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) {
    return oldDelegate.fillPercentage != fillPercentage ||
        oldDelegate.isRunning != isRunning ||
        oldDelegate.isCompleted != isCompleted;
  }
}