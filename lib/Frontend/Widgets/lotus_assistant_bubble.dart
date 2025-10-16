import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LotusAssistantBubble extends StatelessWidget {
  const LotusAssistantBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 100, bottom: 80),
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '¡Hola! Soy Lotus\nPodemos iniciar una conversación!',
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontSize: 16, color: Colors.black),
            ),
          ),
        ),
        Positioned(
          right: 20,
          bottom: 20,
          child: Image.asset(
            'assets/images/lotus.png',
            width: 70,
            height: 70,
          ),
        ),
      ],
    );
  }
}
