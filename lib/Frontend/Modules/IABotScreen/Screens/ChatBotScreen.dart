import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/Screens/ChatHistoryScreen.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/ChatViewModel.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/components/chat_input_area.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/components/Chat_header.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/components/EmptyChatState.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/components/MessageBubble.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/components/chat_drawer_menu.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/sesionchat.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/modals/end_session_modal.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/modals/emergency_contacts_modal.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/modals/session_loaded_modal.dart';

// ========== CHAT SCREEN PRINCIPAL OPTIMIZADO ==========
class ChatBotScreen extends StatefulWidget {
  final SesionChat? sesionAnterior;
  final String? mensajeInicial;
  final VoidCallback? onBackPressed;
  final Function(SesionChat)? onSessionSelected;

  const ChatBotScreen({
    super.key,
    this.sesionAnterior,
    this.mensajeInicial,
    this.onBackPressed,
    this.onSessionSelected,
  });

  @override
  State<ChatBotScreen> createState() => _ChatAiState();
}

class _ChatAiState extends State<ChatBotScreen>
    with SingleTickerProviderStateMixin {
  late ChatViewModel _viewModel;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoadingPreviousChat = false;
  late AnimationController _skeletonController;
  bool _showAutoSaveIndicator = false;
  Timer? _autoSaveIndicatorTimer;

  @override
  void initState() {
    super.initState();

    // Animación de skeleton
    _skeletonController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();

    if (widget.sesionAnterior != null) {
      _isLoadingPreviousChat = true;
    }

    _viewModel = ChatViewModel(
      onMessagesUpdated: _onMessagesUpdated,
      onSessionStateChanged: _onSessionStateChanged,
      onError: _onError,
      onScrollToBottom: _scrollToBottom,
      showSnackBar: null,
      showEmergencyModal: _mostrarContactosEmergencia, // Callback para modal
    );

    _viewModel
        .inicializarChat(
      sesionAnterior: widget.sesionAnterior,
      mensajeInicial: widget.mensajeInicial,
    )
        .then((_) {
      if (mounted) {
        setState(() => _isLoadingPreviousChat = false);
      }
    }).catchError((error) {
      if (mounted) {
        setState(() => _isLoadingPreviousChat = false);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    _skeletonController.dispose();
    _autoSaveIndicatorTimer?.cancel();
    super.dispose();
  }

  // ========== CALLBACKS ==========
  void _onMessagesUpdated() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _onSessionStateChanged() {
    if (mounted) setState(() {});
  }

  void _onError(String error) {
    if (mounted) {
      _showErrorModal(error);
    }
  }

  void _showErrorModal(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Error"),
          ],
        ),
        content: Text(
          error,
          style:
              GoogleFonts.inter(fontSize: 14, color: const Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  // ========== MÉTODOS DE UI OPTIMIZADOS ==========
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void _toggleMenu() => _scaffoldKey.currentState?.openDrawer();

  void _closeDrawer() => _scaffoldKey.currentState?.closeDrawer();

  void _mostrarContactosEmergencia([String? mensajeCrisis]) {
    // Asegurarse de que el modal se muestre con un pequeño delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🎯 MOSTRANDO MODAL DE EMERGENCIA DESDE UI');
      showEmergencyContactsModal(
          context, mensajeCrisis ?? _viewModel.getMensajeCrisis());
    });
  }

  void _showTemporaryModal(String mensaje) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text(
          mensaje,
          style:
              GoogleFonts.inter(fontSize: 14, color: const Color(0xFF555555)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _cargarSesionDesdeHistorial(SesionChat sesion) {
    setState(() => _isLoadingPreviousChat = true);

    _viewModel.dispose();
    _viewModel = ChatViewModel(
      onMessagesUpdated: _onMessagesUpdated,
      onSessionStateChanged: _onSessionStateChanged,
      onError: _onError,
      onScrollToBottom: _scrollToBottom,
      showSnackBar: null,
      showEmergencyModal:
          _mostrarContactosEmergencia, // IMPORTANTE: pasar el callback
    );

    _viewModel
        .inicializarChat(sesionAnterior: sesion, mensajeInicial: null)
        .then((_) {
      if (mounted) {
        setState(() => _isLoadingPreviousChat = false);
        showSessionLoadedModal(context, _getTituloSesion(sesion));
      }
    }).catchError((error) {
      if (mounted) setState(() => _isLoadingPreviousChat = false);
      _onError('Error al cargar el chat: $error');
    });
  }

  String _getTituloSesion(SesionChat sesion) {
    if (sesion.tituloDinamico != null && sesion.tituloDinamico!.isNotEmpty) {
      return sesion.tituloDinamico!;
    }
    if (sesion.mensajes.isNotEmpty) {
      final content = sesion.mensajes.first.contenido;
      return content.length > 20 ? '${content.substring(0, 20)}...' : content;
    }
    return 'Conversación';
  }

  Future<void> _endSessionWithConfirmation() async {
    final bool? confirmado = await showEndSessionModal(context);

    if (confirmado == true) {
      await _viewModel.endSession();
    }
  }

  void _navigateToHistory() {
    Navigator.push<SesionChat>(
      context,
      MaterialPageRoute(
        builder: (context) => const ChatHistoryScreen(),
      ),
    ).then((sesionSeleccionada) {
      if (sesionSeleccionada != null) {
        _cargarSesionDesdeHistorial(sesionSeleccionada);
      }
    });
  }

  // ========== UI PRINCIPAL OPTIMIZADA ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2FFFF),
      drawer: _buildDrawerMenu(),
      body: PopScope(
        canPop: false,
        onPopInvoked: (didPop) async {
          if (didPop) return;

          if (_viewModel.sessionActive && _viewModel.messages.isNotEmpty) {
            await _viewModel.guardadoRapidoAlSalir();
          }
          if (widget.onBackPressed != null) {
            widget.onBackPressed!();
          } else {
            Navigator.of(context).pop();
          }
        },
        child: Column(
          children: [
            ChatHeader(title: "Asistente AI", onMenuPressed: _toggleMenu),
            Expanded(child: _buildMessagesArea()),
            ChatInputArea(
              controller: _controller,
              isThinking: _viewModel.isThinking,
              onSendMessage: (text) {
                if (text.trim().isNotEmpty && !_viewModel.isThinking) {
                  _viewModel.addMessage(text.trim());
                  _controller.clear();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========== ÁREA DE MENSAJES OPTIMIZADA ==========
  Widget _buildMessagesArea() {
    if (_isLoadingPreviousChat) return _buildSkeletonLoading();
    if (_viewModel.messages.isEmpty) return const EmptyChatState();

    return Column(
      children: [
        if (_showAutoSaveIndicator) _buildAutoSaveIndicator(),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            itemCount: _viewModel.messages
                .where((m) =>
                    m.emisor != "Sistema" ||
                    m.contenido.startsWith("🚨") ||
                    m.contenido.startsWith("⚠️"))
                .length,
            itemBuilder: (context, index) {
              final mensajesVisibles = _viewModel.messages
                  .where((m) =>
                      m.emisor != "Sistema" ||
                      m.contenido.startsWith("🚨") ||
                      m.contenido.startsWith("⚠️"))
                  .toList();
              final msg = mensajesVisibles[index];
              final isUser =
                  msg.emisor != "Sistema" && msg.emisor != "Asistente";

              return MessageBubble(
                message: msg,
                isUser: isUser,
                showTypingIndicator: msg.contenido == "TYPING_INDICATOR",
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAutoSaveIndicator() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_done, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            'Conversación guardada',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showAutoSaveIndicatorTemporarily() {
    setState(() {
      _showAutoSaveIndicator = true;
    });

    _autoSaveIndicatorTimer?.cancel();
    _autoSaveIndicatorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showAutoSaveIndicator = false;
        });
      }
    });
  }

  // ========== SKELETON OPTIMIZADO ==========
  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        final isUserSkeleton = index % 2 == 0;

        return AnimatedBuilder(
          animation: _skeletonController,
          builder: (context, child) {
            final animationValue = _skeletonController.value;
            final opacity = 0.3 +
                0.4 * (0.5 + 0.5 * sin(animationValue * 2 * pi + index * 0.5));

            return Opacity(
              opacity: opacity,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: isUserSkeleton
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isUserSkeleton) ...[
                      _buildAvatarSkeleton(isUser: false),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isUserSkeleton
                              ? const Color(0xFF86A8E7).withOpacity(0.1)
                              : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFE0E0E0).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isUserSkeleton
                                    ? Colors.white.withOpacity(0.5)
                                    : const Color(0xFF666666).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildContentSkeleton(isUserSkeleton, index),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                width: 40,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isUserSkeleton
                                      ? Colors.white.withOpacity(0.4)
                                      : const Color(0xFF999999)
                                          .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isUserSkeleton) ...[
                      const SizedBox(width: 12),
                      _buildAvatarSkeleton(isUser: true),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContentSkeleton(bool isUser, int index) {
    final lineCount = (index % 3) + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lineCount, (lineIndex) {
        final width = lineIndex == lineCount - 1
            ? 80.0 + (index % 5) * 20.0
            : 120.0 + (index % 7) * 30.0;

        return Padding(
          padding: EdgeInsets.only(bottom: lineIndex == lineCount - 1 ? 0 : 8),
          child: Container(
            width: width,
            height: 12,
            decoration: BoxDecoration(
              color: isUser
                  ? Colors.white.withOpacity(0.6)
                  : const Color(0xFF666666).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAvatarSkeleton({required bool isUser}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isUser
            ? const Color(0xFFF66B7D).withOpacity(0.2)
            : const Color(0xFF86A8E7).withOpacity(0.2),
        shape: BoxShape.circle,
      ),
    );
  }

  // ========== DRAWER OPTIMIZADO SEPARADO ==========
  Widget _buildDrawerMenu() {
    return ChatDrawerMenu(
      nombreUsuario: _viewModel.nombreUsuario,
      sedeEstudiante: _viewModel.sedeEstudiante,
      sessionActive: _viewModel.sessionActive,
      hasMessages: _viewModel.messages.isNotEmpty,
      onBackPressed: widget.onBackPressed,
      onCloseDrawer: _closeDrawer,
      onStartNewChat: () => _viewModel.startSession(),
      onEndChat: _endSessionWithConfirmation,
      onShowHistory: _navigateToHistory,
      onShowEmergencyContacts: _mostrarContactosEmergencia,
      onGoToChat: _closeDrawer,
    );
  }
}
