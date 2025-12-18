import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// OPTIMIZACIÓN: Widget ahora es inmutable (const) donde sea posible
class ChatInputArea extends StatefulWidget {
  final TextEditingController controller;
  final bool isThinking;
  final Function(String) onSendMessage;

  const ChatInputArea({
    super.key,
    required this.controller,
    required this.isThinking,
    required this.onSendMessage,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  bool _localIsSending = false;

  @override
  void didUpdateWidget(covariant ChatInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);

    // OPTIMIZACIÓN: Verificación más eficiente de cambios de estado
    if (oldWidget.isThinking != widget.isThinking && mounted) {
      setState(() {
        _localIsSending = widget.isThinking;
      });
    }
  }

  void _handleSendMessage() {
    if (_localIsSending || widget.isThinking) return;

    final text = widget.controller.text.trim();
    if (text.isEmpty) return;

    // OPTIMIZACIÓN: Feedback visual inmediato
    setState(() => _localIsSending = true);
    widget.controller.clear();
    widget.onSendMessage(text);
  }

  bool get _isDisabled => _localIsSending || widget.isThinking;

// MODIFICAR _buildAutoSaveIndicator() en chat_input_area.dart:

  Widget _buildAutoSaveIndicator() {
    return Positioned(
      bottom: 4,
      right: 60,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4CAF50).withOpacity(0.9),
              const Color(0xFF2E7D32).withOpacity(0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4CAF50).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_upload_rounded,
                size: 12, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Auto-guardado activo',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

// MODIFICAR el build method para incluir el indicador:
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isDisabled
                          ? const Color(0xFFE0E0E0)
                          : const Color(0xFF86A8E7).withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: widget.controller,
                    enabled: !_isDisabled,
                    maxLines: 3,
                    minLines: 1,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: "Escribe tu mensaje...",
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF757575),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      suffixIcon: _isDisabled
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Color(0xFF86A8E7)),
                                ),
                              ),
                            )
                          : null,
                    ),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    onSubmitted: (text) {
                      if (!_isDisabled) _handleSendMessage();
                    },
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // OPTIMIZACIÓN: Botón con mejor feedback visual
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _isDisabled
                      ? const LinearGradient(
                          colors: [Color(0xFFCCCCCC), Color(0xFFAAAAAA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [Color(0xFF86A8E7), Color(0xFF91EAE4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  boxShadow: _isDisabled
                      ? []
                      : [
                          BoxShadow(
                            color: const Color(0xFF86A8E7).withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _isDisabled ? null : _handleSendMessage,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Icon(
                        _isDisabled ? Icons.hourglass_top : Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Indicador de autoguardado
          if (!_isDisabled && widget.controller.text.isNotEmpty)
            _buildAutoSaveIndicator(),
        ],
      ),
    );
  }
}
