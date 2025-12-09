import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Modules/Profile/ViewModels/AnimationStateVM.dart';
import 'package:provider/provider.dart';

class SequentialFadeIn extends StatefulWidget {
  final Widget child;
  final int delay;
  final String animationId;

  const SequentialFadeIn({
    super.key,
    required this.child,
    required this.delay,
    required this.animationId,
  });

  @override
  State<SequentialFadeIn> createState() => _SequentialFadeInState();
}

class _SequentialFadeInState extends State<SequentialFadeIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _translate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _opacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _translate = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    final animationState = Provider.of<AnimationStateVM>(context, listen: false);
    
    // Verificar si esta animación específica ya se ejecutó
    // En este ejemplo simplificado, usamos el estado global
    // Podrías extender AnimationStateVM para manejar múltiples animaciones
    
    if (!animationState.hasProfileScreenAnimated) {
      Future.delayed(Duration(milliseconds: widget.delay), () {
        if (mounted) {
          _controller.forward();
        }
      });
    } else {
      // Si ya se animó, ir directamente al estado final
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _translate,
        child: widget.child,
      ),
    );
  }
}