import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/Screens/ChatBotScreen.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/services/Chat_Service.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/servicechatcifrado.dart';
import 'package:intl/intl.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/sesionchat.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/mensajes.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen>
    with SingleTickerProviderStateMixin {
  final ChatService _chatService = ChatService();
  List<SesionChat> _sessions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _loadSessions();
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });

      final sessions = await _chatService.getSessions();
      final sessionsDescifradas = await _descifrarSesiones(sessions);

      setState(() {
        _sessions = List<SesionChat>.from(sessionsDescifradas);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  Future<List<SesionChat>> _descifrarSesiones(List<SesionChat> sesiones) async {
    List<SesionChat> descifradas = [];

    for (var sesion in sesiones) {
      try {
        List<Mensaje> mensajesDescifrados = [];

        for (var mensaje in sesion.mensajes) {
          String contenidoDescifrado = mensaje.contenido;
          try {
            contenidoDescifrado =
                await CifradoService.descifrarTexto(mensaje.contenido);
          } catch (e) {}

          mensajesDescifrados.add(Mensaje(
            emisor: mensaje.emisor,
            contenido: contenidoDescifrado,
            fecha: mensaje.fecha,
          ));
        }

        final sesionDescifrada = SesionChat(
          fecha: sesion.fecha,
          usuario: sesion.usuario,
          resumen: sesion.resumen,
          mensajes: mensajesDescifrados,
          etiquetas: sesion.etiquetas,
          tituloDinamico: sesion.tituloDinamico,
        );

        descifradas.add(sesionDescifrada);
      } catch (e) {
        descifradas.add(sesion);
      }
    }

    return descifradas;
  }

  String _formatDate(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      if (sessionDate == today) {
        return 'Hoy, ${DateFormat('HH:mm').format(dateTime)}';
      } else if (sessionDate == today.subtract(const Duration(days: 1))) {
        return 'Ayer, ${DateFormat('HH:mm').format(dateTime)}';
      } else {
        return DateFormat('dd/MM/yyyy').format(dateTime);
      }
    } catch (e) {
      return fecha;
    }
  }

  String _getFirstMessageContent(SesionChat session) {
    if (session.mensajes.isEmpty) return 'Sin mensajes';

    final userMessages = session.mensajes
        .where((msg) =>
            msg.emisor != "Sistema" &&
            msg.emisor != "Asistente" &&
            msg.contenido != "TYPING_INDICATOR")
        .toList();

    if (userMessages.isEmpty) return '...';
    final firstMsg = userMessages.first.contenido;
    return firstMsg.length > 60 ? '${firstMsg.substring(0, 60)}...' : firstMsg;
  }

  String _getSessionTitle(SesionChat session) {
    if (session.tituloDinamico != null && session.tituloDinamico!.isNotEmpty) {
      return session.tituloDinamico!;
    }

    if (session.mensajes.isNotEmpty) {
      final firstUserMsg = session.mensajes.firstWhere(
        (msg) => msg.emisor == "Usuario" || !msg.emisor.contains("Asistente"),
        orElse: () => session.mensajes.first,
      );

      final content = firstUserMsg.contenido;
      return content.length > 25 ? '${content.substring(0, 25)}...' : content;
    }

    try {
      final dateTime = DateTime.parse(session.fecha);
      return 'Chat ${DateFormat('dd/MM').format(dateTime)}';
    } catch (e) {
      return 'Conversación';
    }
  }

  String _getLastMessageTime(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Conversaciones'),
        backgroundColor: const Color(0xFFF2FFFF),
        elevation: 0,
        leading: _buildBackButton(),
        actions: [_buildRefreshButton()],
      ),
      backgroundColor: const Color(0xFFF2FFFF),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _hasError
              ? _buildErrorState()
              : _sessions.isEmpty
                  ? _buildEmptyState()
                  : _buildSessionsList(),
    );
  }

  Widget _buildBackButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF86A8E7), size: 20),
        onPressed: () => Navigator.pop(context),
        splashRadius: 20,
      ),
    );
  }

  Widget _buildRefreshButton() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.refresh_rounded,
            color: Color(0xFF86A8E7), size: 22),
        onPressed: _loadSessions,
        tooltip: 'Actualizar',
        splashRadius: 20,
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return _buildSkeletonItem(index);
      },
    );
  }

  Widget _buildSkeletonItem(int index) {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        final animationValue = _loadingController.value;
        final opacity = 0.3 +
            0.4 * (0.5 + 0.5 * sin(animationValue * 2 * pi + index * 0.5));

        return Opacity(
          opacity: opacity,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 16,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              width: 120,
                              height: 12,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 60,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 60, color: Color(0xFFEF5350)),
            ),
            const SizedBox(height: 24),
            const Text("Error al cargar el historial"),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(_errorMessage, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loadSessions,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF86A8E7)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Reintentar"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 70, color: Color(0xFF86A8E7)),
            ),
            const SizedBox(height: 32),
            const Text("Aún no tienes conversaciones",
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            const Text("Comienza una nueva conversación con nuestro asistente",
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF86A8E7)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 22, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Nueva Conversación"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList() {
    return RefreshIndicator(
      onRefresh: _loadSessions,
      color: const Color(0xFF86A8E7),
      backgroundColor: const Color(0xFFF2FFFF),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _sessions.length,
        itemBuilder: (context, index) => _buildSessionCard(_sessions[index]),
      ),
    );
  }

  Widget _buildSessionCard(SesionChat session) {
    final messageCount = session.mensajes.length;
    final hasTags = session.etiquetas.isNotEmpty;
    final lastMessageTime = _getLastMessageTime(session.fecha);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF86A8E7).withOpacity(0.08), blurRadius: 16)
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => Navigator.pop(context, session),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFF86A8E7), Color(0xFF91EAE4)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.chat_bubble_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _getSessionTitle(session),
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF86A8E7).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule_rounded,
                                        size: 12, color: Color(0xFF86A8E7)),
                                    const SizedBox(width: 6),
                                    Text(lastMessageTime,
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(_formatDate(session.fecha),
                              style: GoogleFonts.inter(
                                  color: const Color(0xFF888888))),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Contenido
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8F0FF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.message_rounded,
                          size: 18, color: Color(0xFF86A8E7)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _getFirstMessageContent(session),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Footer
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_rounded,
                              size: 14, color: Color(0xFF86A8E7)),
                          const SizedBox(width: 8),
                          Text('$messageCount mensajes'),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (hasTags)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: session.etiquetas.take(2).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getTagColor(tag).withOpacity(0.9),
                                  _getTagColor(tag).withOpacity(0.7)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(tag,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 11)),
                          );
                        }).toList(),
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

  Color _getTagColor(String tag) {
    final lowerTag = tag.toLowerCase();

    if (lowerTag.contains('triste')) return const Color(0xFF2196F3);
    if (lowerTag.contains('ansied')) return const Color(0xFFFF9800);
    if (lowerTag.contains('deprim')) return const Color(0xFFF44336);
    if (lowerTag.contains('estrés')) return const Color(0xFF9C27B0);
    if (lowerTag.contains('feliz')) return const Color(0xFF4CAF50);
    if (lowerTag.contains('enoj')) return const Color(0xFFFF5722);
    if (lowerTag.contains('calm')) return const Color(0xFF00BCD4);
    if (lowerTag.contains('emocion')) return const Color(0xFFFFC107);

    return const Color(0xFF607D8B);
  }
}
