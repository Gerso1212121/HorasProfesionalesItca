import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/mensajes.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/components/TypingIndicator.dart';

// OPTIMIZACIÓN: MessageBubble con animaciones y mejor rendimiento visual
class MessageBubble extends StatelessWidget {
  final Mensaje message;
  final bool isUser;
  final bool showTypingIndicator;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isUser,
    this.showTypingIndicator = false,
  });

  String _formatTime(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return fecha;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAssistantAvatar(),
          if (!isUser) const SizedBox(width: 12),
          Flexible(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF86A8E7) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isUser ? 0.15 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
                border: isUser
                    ? null
                    : Border.all(
                        color: const Color(0xFFEEEEEE),
                        width: 1,
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Encabezado del mensaje
                  Text(
                    isUser ? "Tú" : "Cerebrin",
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isUser
                          ? Colors.white.withOpacity(0.9)
                          : const Color(0xFF666666),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Contenido del mensaje o indicador de typing
                  showTypingIndicator
                      ? TypingIndicator()
                      : Text(
                          message.contenido,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color:
                                isUser ? Colors.white : const Color(0xFF333333),
                            height: 1.5,
                          ),
                        ),

                  const SizedBox(height: 12),

                  // Timestamp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(message.fecha),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: isUser
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF888888),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 12),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAssistantAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF86A8E7), Color(0xFF91EAE4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF86A8E7).withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/brainprofile.png',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF66B7D), Color(0xFFF8939C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF66B7D).withOpacity(0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.person_rounded,
        color: Colors.white,
        size: 20,
      ),
    );
  }
}
