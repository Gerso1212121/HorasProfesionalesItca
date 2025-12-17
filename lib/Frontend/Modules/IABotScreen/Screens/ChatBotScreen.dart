import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/Screens/ChatHistoryScreen.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/ChatViewModel.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/components/ChatInputArea.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/components/Chat_header.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/components/EmptyChatState.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/components/MessageBubble.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/sesionchat.dart';
import 'dart:async';

// ========== CHAT SCREEN PRINCIPAL ==========
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

class _ChatAiState extends State<ChatBotScreen> {
  // ========== VIEWMODEL ==========
  late ChatViewModel _viewModel;

  // ========== CONTROLADORES ==========
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // ========== CLAVE DE SCAFFOLD ==========
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ========== ESTADO DE CARGA ==========
  bool _isLoadingPreviousChat = false;

  @override
  void initState() {
    super.initState();

    // Mostrar skeleton si hay sesión anterior
    if (widget.sesionAnterior != null) {
      _isLoadingPreviousChat = true;
    }

    // Inicializar ViewModel con callbacks
    _viewModel = ChatViewModel(
      onMessagesUpdated: _onMessagesUpdated,
      onSessionStateChanged: _onSessionStateChanged,
      onError: _onError,
      onScrollToBottom: _scrollToBottom,
      showSnackBar: _showSnackBar,
    );

    // Inicializar chat
    _viewModel.inicializarChat(
      sesionAnterior: widget.sesionAnterior,
      mensajeInicial: widget.mensajeInicial,
    ).then((_) {
      // Ocultar skeleton después de cargar
      if (mounted) {
        setState(() {
          _isLoadingPreviousChat = false;
        });
      }
    }).catchError((error) {
      // Ocultar skeleton incluso si hay error
      if (mounted) {
        setState(() {
          _isLoadingPreviousChat = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  // ========== CALLBACKS DEL VIEWMODEL ==========
  void _onMessagesUpdated() {
    if (mounted) {
      setState(() {});
      _scrollToBottom();
    }
  }

  void _onSessionStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ========== MÉTODOS DE UI ==========
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

  void _toggleMenu() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _handleMenuItemSelected(String item) {
    switch (item) {
      case 'go_to_chat':
        _scaffoldKey.currentState?.closeDrawer();
        break;
      case 'end_chat':
        _scaffoldKey.currentState?.closeDrawer();
        Future.delayed(const Duration(milliseconds: 300), () {
          _endSessionWithConfirmation();
        });
        break;
      case 'new_chat':
        _scaffoldKey.currentState?.closeDrawer();
        Future.delayed(const Duration(milliseconds: 300), () {
          _viewModel.startSession();
        });
        break;
      case 'history':
        _scaffoldKey.currentState?.closeDrawer();
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.push<SesionChat>(
            context,
            MaterialPageRoute(
              builder: (context) => const ChatHistoryScreen(),
            ),
          ).then((sesionSeleccionada) {
            if (sesionSeleccionada != null) {
              // Cargar la sesión seleccionada
              _cargarSesionDesdeHistorial(sesionSeleccionada);
            }
          });
        });
        break;
      case 'emergency':
        _scaffoldKey.currentState?.closeDrawer();
        Future.delayed(const Duration(milliseconds: 300), () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Contactos de Emergencia"),
              content: Text(_viewModel.getMensajeCrisis()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cerrar"),
                ),
              ],
            ),
          );
        });
        break;
      case 'settings':
        _scaffoldKey.currentState?.closeDrawer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Configuración - Próximamente")),
        );
        break;
      case 'help':
        _scaffoldKey.currentState?.closeDrawer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ayuda - Próximamente")),
        );
        break;
      case 'logout':
        _scaffoldKey.currentState?.closeDrawer();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Cerrar Sesión - Próximamente")),
        );
        break;
    }
  }

  // Método para cargar sesión desde el historial
  void _cargarSesionDesdeHistorial(SesionChat sesion) {
    if (mounted) {
      setState(() {
        _isLoadingPreviousChat = true;
      });
    }

    // Reiniciar el ViewModel con la nueva sesión
    _viewModel.dispose();
    
    _viewModel = ChatViewModel(
      onMessagesUpdated: _onMessagesUpdated,
      onSessionStateChanged: _onSessionStateChanged,
      onError: _onError,
      onScrollToBottom: _scrollToBottom,
      showSnackBar: _showSnackBar,
    );

    _viewModel.inicializarChat(
      sesionAnterior: sesion,
      mensajeInicial: null,
    ).then((_) {
      if (mounted) {
        setState(() {
          _isLoadingPreviousChat = false;
        });
        
        // Mostrar mensaje de confirmación
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chat cargado: ${_getTituloSesion(sesion)}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoadingPreviousChat = false;
        });
      }
      _onError('Error al cargar el chat: $error');
    });
  }

  String _getTituloSesion(SesionChat sesion) {
    if (sesion.tituloDinamico != null && sesion.tituloDinamico!.isNotEmpty) {
      return sesion.tituloDinamico!;
    }
    
    if (sesion.mensajes.isNotEmpty) {
      final firstMsg = sesion.mensajes.first;
      final content = firstMsg.contenido;
      if (content.length > 20) {
        return '${content.substring(0, 20)}...';
      }
      return content;
    }
    
    return 'Conversación';
  }

  Future<void> _endSessionWithConfirmation() async {
    // 1. Ejecutar diagnóstico (opcional, para depuración)
    _viewModel.diagnosticarGuardado();

    // 2. MOSTRAR DIÁLOGO DE CONFIRMACIÓN MEJORADO
    final bool confirmado = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("¿Finalizar chat?"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "¿Deseas guardar esta conversación antes de finalizar?",
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Text(
                  "📝 ${_viewModel.messages.length} mensajes",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF66B7D),
                ),
                child: const Text("Guardar y Finalizar"),
              ),
            ],
          ),
        ) ??
        false;

    // 3. Si el usuario confirma, llamar a endSession()
    if (confirmado) {
      await _viewModel.endSession();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chat no guardado'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ========== UI PRINCIPAL ==========
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF2FFFF),
      drawer: _buildDrawerMenu(),
      body: WillPopScope(
        onWillPop: () async {
          if (_viewModel.sessionActive && _viewModel.messages.isNotEmpty) {
            await _viewModel.guardadoRapidoAlSalir();
          }
          
          // Usar callback si está disponible, si no, permitir pop normal
          if (widget.onBackPressed != null) {
            widget.onBackPressed!();
            return false; // Evitar el pop automático
          }
          return true;
        },
        child: Column(
          children: [
            // Header con botón de menú
            ChatHeader(
              title: "Asistente AI",
              onMenuPressed: _toggleMenu,
             ),

            // Área de mensajes con skeleton de carga
            Expanded(
              child: _buildMessagesArea(),
            ),

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

  // ========== CONSTRUIR ÁREA DE MENSAJES ==========
  Widget _buildMessagesArea() {
    // Mostrar skeleton si está cargando chat anterior
    if (_isLoadingPreviousChat) {
      return _buildSkeletonLoading();
    }

    // Mostrar estado vacío o lista de mensajes
    if (_viewModel.messages.isEmpty) {
      return  Center(
        child: EmptyChatState(),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
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
        final isUser = msg.emisor != "Sistema" && msg.emisor != "Asistente";

        return MessageBubble(
          message: msg,
          isUser: isUser,
          showTypingIndicator: msg.contenido == "TYPING_INDICATOR",
        );
      },
    );
  }

  // ========== SKELETON DE CARGA ==========
Widget _buildSkeletonLoading() {
  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: 6, // Número de skeletons a mostrar
    itemBuilder: (context, index) {
      // Alternar entre skeleton de usuario y asistente
      final isUserSkeleton = index % 2 == 0;
      
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: isUserSkeleton 
              ? MainAxisAlignment.end 
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUserSkeleton) _buildAssistantAvatarSkeleton(),
            if (!isUserSkeleton) const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isUserSkeleton 
                      ? const Color(0xFF86A8E7).withOpacity(0.3)
                      : Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFFE0E0E0).withOpacity(0.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Skeleton para el nombre
                    Container(
                      width: 40,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isUserSkeleton
                            ? Colors.white.withOpacity(0.4)
                            : const Color(0xFF666666).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Skeleton para el contenido (líneas variables)
                    _buildContentSkeleton(isUserSkeleton, index),
                    
                    const SizedBox(height: 8),
                    
                    // Skeleton para la hora
                    Container(
                      width: 30,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isUserSkeleton
                            ? Colors.white.withOpacity(0.3)
                            : const Color(0xFF999999).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isUserSkeleton) const SizedBox(width: 8),
            if (isUserSkeleton) _buildUserAvatarSkeleton(),
          ],
        ),
      );
    },
  );
}

Widget _buildContentSkeleton(bool isUser, int index) {
  // Número variable de líneas para hacerlo más realista
  final lineCount = (index % 3) + 1;
  
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: List.generate(lineCount, (lineIndex) {
      // Ancho variable para cada línea
      final width = lineIndex == lineCount - 1 
          ? 80.0 + (index % 5) * 20.0
          : 120.0 + (index % 7) * 30.0;
      
      return Padding(
        padding: EdgeInsets.only(bottom: lineIndex == lineCount - 1 ? 0 : 4),
        child: Container(
          width: width,
          height: 10,
          decoration: BoxDecoration(
            color: isUser
                ? Colors.white.withOpacity(0.5)
                : const Color(0xFF666666).withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }),
  );
}


  Widget _buildAssistantAvatarSkeleton() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF86A8E7).withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildUserAvatarSkeleton() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFFF66B7D).withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }

  // ========== DRAWER MEJORADO ==========
  Widget _buildDrawerMenu() {
    return Drawer(
      width: 225,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del menú
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.onBackPressed != null)
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        onPressed: () {
                          _scaffoldKey.currentState?.closeDrawer();
                          widget.onBackPressed?.call();
                        },
                      )
                    else
                      const SizedBox(width: 48),
                    Text(
                      'Menú',
                      style: GoogleFonts.itim(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 48), // Para balancear
                  ],
                ),
                Text(
                  _viewModel.nombreUsuario,
                  style: GoogleFonts.itim(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          // Opciones del menú
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _buildDrawerMenuItem(
                  icon: Icons.chat,
                  label: 'Ir al Chat',
                  onTap: () {
                    _scaffoldKey.currentState?.closeDrawer();
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.add_circle_outline,
                  label: 'Nuevo Chat',
                  onTap: () {
                    _scaffoldKey.currentState?.closeDrawer();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      _viewModel.startSession();
                    });
                  },
                ),
                _buildDrawerMenuItem(
                  icon: Icons.history,
                  label: 'Historial',
                  onTap: () {
                    _scaffoldKey.currentState?.closeDrawer();
                    Future.delayed(const Duration(milliseconds: 300), () {
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
                    });
                  },
                ),

                // Opción para finalizar chat
                if (_viewModel.sessionActive && _viewModel.messages.isNotEmpty)
                  _buildDrawerMenuItem(
                    icon: Icons.stop_circle_outlined,
                    label: 'Finalizar Chat',
                    color: const Color(0xFFF66B7D),
                    onTap: () async {
                      _scaffoldKey.currentState?.closeDrawer();
                      await Future.delayed(const Duration(milliseconds: 300));
                      await _endSessionWithConfirmation();
                    },
                  ),

                const Divider(height: 30, indent: 20, endIndent: 20),
                _buildDrawerMenuItem(
                  icon: Icons.emergency_outlined,
                  label: 'Contacto de Emergencia',
                  color: Colors.red,
                  onTap: () {
                    _scaffoldKey.currentState?.closeDrawer();
                    Future.delayed(const Duration(milliseconds: 300), () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text("Contactos de Emergencia"),
                          content: Text(_viewModel.getMensajeCrisis()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cerrar"),
                            ),
                          ],
                        ),
                      );
                    });
                  },
                ),
              ],
            ),
          ),

          // Footer del menú
          Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Asistente AI v1.0',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(
          icon,
          color: color ?? const Color(0xFF86A8E7),
        ),
        title: Text(
          label,
          style: GoogleFonts.itim(
            fontSize: 18,
            color: Colors.black87,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: Colors.black26,
        ),
        onTap: onTap,
      ),
    );
  }
}