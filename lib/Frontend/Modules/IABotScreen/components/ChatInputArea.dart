import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInputArea extends StatefulWidget {
  final TextEditingController controller;
  final bool isThinking;
  final Function(String) onSendMessage;

  const ChatInputArea({
    Key? key,
    required this.controller,
    required this.isThinking,
    required this.onSendMessage,
  }) : super(key: key);

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  bool _localIsSending = false;
  
  @override
  void didUpdateWidget(covariant ChatInputArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Sincronizar con el estado del ViewModel
    // Cuando el ViewModel termina de pensar, liberar el bloqueo local
    if (oldWidget.isThinking && !widget.isThinking) {
      if (mounted) {
        setState(() {
          _localIsSending = false;
        });
      }
    }
    
    // Cuando el ViewModel empieza a pensar, activar bloqueo local
    if (!oldWidget.isThinking && widget.isThinking) {
      if (mounted) {
        setState(() {
          _localIsSending = true;
        });
      }
    }
  }

  void _handleSendMessage() {
    // Verificar si ya está enviando o el ViewModel está pensando
    if (_localIsSending || widget.isThinking) {
      return;
    }

    final text = widget.controller.text.trim();
    if (text.isEmpty) return;

    // Marcar como enviando inmediatamente
    setState(() {
      _localIsSending = true;
    });

    // Limpiar el campo de texto inmediatamente para feedback visual
    widget.controller.clear();

    // Enviar el mensaje
    widget.onSendMessage(text);
    
    // El bloqueo se liberará automáticamente cuando widget.isThinking cambie a false
    // a través de didUpdateWidget
  }

  bool get _isDisabled {
    return _localIsSending || widget.isThinking;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: widget.controller,
                enabled: !_isDisabled,
                decoration: InputDecoration(
                  hintText: "Escribe tu mensaje...",
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  suffixIcon: _isDisabled
                      ? Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF86A8E7),
                            ),
                          ),
                        )
                      : null,
                ),
                onSubmitted: (text) {
                  if (!_isDisabled) {
                    _handleSendMessage();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isDisabled
                    ? [Colors.grey, Colors.grey]
                    : [const Color(0xFF86A8E7), const Color(0xFFB2F5DB)],
              ),
            ),
            child: IconButton(
              onPressed: _isDisabled ? null : _handleSendMessage,
              icon: Icon(
                _isDisabled ? Icons.hourglass_empty : Icons.send,
                color: Colors.white,
              ),
              splashRadius: 24,
            ),
          ),
        ],
      ),
    );
  }
}