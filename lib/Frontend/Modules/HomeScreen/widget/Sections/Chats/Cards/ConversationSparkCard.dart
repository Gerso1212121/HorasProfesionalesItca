import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ConversationSparkCard extends StatelessWidget {
  final String title;
  final String description;
  final Color cardColor;
  final IconData? iconAsset;
  final String? symbol;
  final String? conversationStarter;
  final VoidCallback? onSelect;

  const ConversationSparkCard({
    super.key,
    required this.title,
    required this.description,
    required this.cardColor,
    this.iconAsset,
    this.symbol,
    this.conversationStarter,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        width: 280,
        height: 320,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 0,
              offset: const Offset(0, 0),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header compacto
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: _renderSymbol(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Descripción
              Container(
                width: double.infinity,
                height: 80, // Reducido para dar más espacio a la pregunta
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.9),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.black87,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Pregunta - ESPACIO DESTACADO
              if (conversationStarter != null && conversationStarter!.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 90), // Altura mínima garantizada
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF66B7D).withOpacity(0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF66B7D).withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conversationStarter!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF66B7D).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'Pregunta definida',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF66B7D),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Botón de acción
              Container(
                width: double.infinity,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF66B7D),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF66B7D).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.chat_rounded,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Iniciar conversación',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _renderSymbol() {
    if (iconAsset != null) {
      return Icon(
        iconAsset,
        size: 20,
        color: const Color(0xFFF66B7D),
      );
    } else if (symbol != null) {
      return Text(
        symbol!,
        style: const TextStyle(fontSize: 18),
      );
    } else {
      return Icon(
        Icons.chat_rounded,
        size: 20,
        color: const Color(0xFFF66B7D),
      );
    }
  }
}