import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UserDataHeader extends StatelessWidget {
  final bool esItca;
  final String? correo;
  final VoidCallback onBackPressed;

  const UserDataHeader({
    Key? key,
    required this.esItca,
    this.correo,
    required this.onBackPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String userTypeText = esItca 
      ? 'Estudiante ITCA' 
      : 'Usuario externo';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBackPressed,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 22,
              color: Color(0xFF3B82F6),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Completa tu perfil',
                  style: GoogleFonts.itim(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  userTypeText,
                  style: GoogleFonts.itim(
                    fontSize: 14,
                    color: esItca ? Colors.blue[700] : Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}