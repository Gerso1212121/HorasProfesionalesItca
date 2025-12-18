import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// OPTIMIZACIÓN: TypingIndicator con animaciones más eficientes
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    // OPTIMIZACIÓN: Animaciones más eficientes con delays calculados
    _animations = List.generate(3, (index) {
      return TweenSequence<double>([
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0.3, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: 1.0, end: 0.3)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40,
        ),
        TweenSequenceItem<double>(
          tween: ConstantTween<double>(0.3),
          weight: 20,
        ),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.2,
            1.0,
            curve: Curves.easeInOut,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF86A8E7)
                    .withOpacity(0.4 + (_animations[index].value * 0.6)),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}
