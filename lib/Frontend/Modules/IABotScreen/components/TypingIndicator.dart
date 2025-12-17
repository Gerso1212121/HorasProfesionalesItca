import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/Screens/ChatBotScreen.dart';

class TypingIndicator extends StatefulWidget {
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    _startAnimation();
  }

  void _startAnimation() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedBuilder(
            animation: _animations[index],
            builder: (context, child) {
              return Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey
                      .withOpacity(0.5 + (_animations[index].value * 0.5)),
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
