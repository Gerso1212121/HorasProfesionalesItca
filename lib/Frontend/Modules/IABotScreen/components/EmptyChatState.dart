import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// OPTIMIZACIÓN: EmptyChatState con animaciones sutiles
class EmptyChatState extends StatelessWidget {
  const EmptyChatState({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Center(
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 600),
            opacity: 1,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFF2FFFF).withOpacity(0.0),
                    const Color(0xFFE8F5E8).withOpacity(0.0),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildAnimatedLogo(),
                  const SizedBox(height: 32),
                  _buildTitle(),
                  const SizedBox(height: 16),
                  _buildDescription(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF86A8E7).withOpacity(0.15),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/brainquest.png',
          width: 160,
          height: 160,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Text(
        'Inicia una conversación',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildDescription() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            Text(
              'Comparte lo que piensas, lo que sientes o simplemente empieza a conversar.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF555555),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Estoy aquí para escucharte.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF86A8E7),
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
