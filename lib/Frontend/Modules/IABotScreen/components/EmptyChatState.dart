import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Empty Chat State
class EmptyChatState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.5,
        ),
        child: Center(
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogo(),
                const SizedBox(height: 24),
                Text(
                  'Inicia una conversación',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDescription(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
            'assets/images/brainquests.png',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
          );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Text(
        'Comparte lo que piensas, lo que sientes o simplemente empieza a conversar. \nEstoy aquí para escucharte.',
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: Colors.black54,
          height: 1.4,
        ),
      ),
    );
  }
}