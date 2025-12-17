import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/IABotScreen.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/mensajes.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/Screens/ChatBotScreen.dart'
    hide TypingIndicator;
import 'package:horas2/Frontend/Modules/IABotScreen/components/TypingIndicator.dart';



// Message Bubble
class MessageBubble extends StatelessWidget {
  final Mensaje message;
  final bool isUser;
  final bool showTypingIndicator;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isUser,
    this.showTypingIndicator = false,
  }) : super(key: key);

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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAssistantAvatar(),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF86A8E7) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border:
                    isUser ? null : Border.all(color: const Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? "Tú" : "Cerebrin",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isUser ? Colors.white70 : const Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 6),
                  showTypingIndicator
                      ?  TypingIndicator()
                      : Text(
                          message.contenido,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isUser ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(message.fecha),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isUser ? Colors.white70 : const Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }
Widget _buildAssistantAvatar() {
  return Container(
    width: 62,
    height: 62,
    decoration: BoxDecoration(
      color: const Color(0xFF86A8E7),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 6,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: ClipOval(
      child: Image.asset(
        'assets/images/brainprofile.png',
        width: 62,
        height: 62,
        fit: BoxFit.contain,  // Mantiene proporciones pero muestra toda la imagen
        alignment: Alignment.center,
      ),
    ),
  );
}



  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: Color(0xFFF66B7D),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}
