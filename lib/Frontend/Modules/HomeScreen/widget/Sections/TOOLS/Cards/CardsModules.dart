// HomeScreen/widgets/generic_help_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CardsModules extends StatelessWidget {
  final String title;
  final String description;
  final String badgeText;
  final IconData icon;
  final VoidCallback onTap;
  final Map<String, dynamic> cardColors;

  const CardsModules({
    super.key,
    required this.title,
    required this.description,
    required this.badgeText,
    required this.icon,
    required this.onTap,
    required this.cardColors,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 300,
          height: 200,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cardColors['borderColor'],
              width: 1.5,
            ),

          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge e ícono
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: cardColors['badgeColor1'],
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: cardColors['badgeShadow'],
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            badgeText,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      icon,
                      color: cardColors['iconColor'],
                      size: 28,
                    ),
                  ],
                ),
                
                const SizedBox(height: 14),
                
                // Título
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                const SizedBox(height: 8),
                
                // Descripción
                Expanded(
                  child: Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF5A5A5A),
                      height: 1.4,
                      letterSpacing: 0.1,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: cardColors['tagBackground'],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Módulo guía',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: cardColors['tagTextColor'],
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cardColors['buttonColor1'],
                        borderRadius: BorderRadius.circular(18),

                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Explorar',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}