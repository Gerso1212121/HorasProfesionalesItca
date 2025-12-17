import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


// Chat Header
class ChatHeader extends StatelessWidget {
  final String title;
   final VoidCallback? onMenuPressed;

  const ChatHeader({
    Key? key,
    this.title = "Asistente AI",
     this.onMenuPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.only(top: 40, bottom: 0, left: 16, right: 60),
      child: _buildTopRow(),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // MENÚ DE HAMBURGUESA - BOTÓN IZQUIERDO
        IconButton(
          icon: const Icon(
              Icons.menu,
              color: Color.fromARGB(255, 255, 255, 255),
              size: 28,
            ),
          onPressed: onMenuPressed,
        ),

        // Logo/Texto de la app (centrado)
        Expanded(
          child: Column(
            children: [
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
 
            ],
          ),
        ),
 
      ],
    );
  }
}