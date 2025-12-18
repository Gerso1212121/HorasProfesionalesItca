import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ChatBotScreen.dart';
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

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  final ChatService _chatService = ChatService();
  List<SesionChat> _sessions = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _diagnosticMode = false;

  @override
  void initState() {
    super.initState();
    _loadSessions();
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
      print('❌ Error cargando historial: $e');
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
        if (_diagnosticMode) {
          print(
              '🔍 Procesando sesión: ${sesion.fecha} con ${sesion.mensajes.length} mensajes');
        }

        List<Mensaje> mensajesDescifrados = [];

        for (var mensaje in sesion.mensajes) {
          String contenidoDescifrado = mensaje.contenido;

          try {
            contenidoDescifrado =
                await CifradoService.descifrarTexto(mensaje.contenido);
          } catch (e) {
            if (_diagnosticMode) {
              print('⚠️ Error procesando mensaje: $e');
            }
          }

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
        print('❌ Error procesando sesión: $e');
        descifradas.add(sesion);
      }
    }

    return descifradas;
  }

  Future<void> _repararChatsCifrados() async {
    try {
      final sessions = await _chatService.getSessions();
      int reparados = 0;

      for (var session in sessions) {
        for (var mensaje in session.mensajes) {
          if (mensaje.contenido.contains('cP43M') ||
              mensaje.contenido.contains('P43M')) {
            print(
                '🔧 ENCONTRADO CHAT CIFRADO MAL: ${mensaje.contenido.substring(0, min(30, mensaje.contenido.length))}...');

            try {
              String intento1 =
                  await CifradoService.descifrarTexto(mensaje.contenido);

              if (intento1 != mensaje.contenido) {
                print('   ✅ Reparado con CifradoService');
                reparados++;
              }
            } catch (e) {
              print('   ❌ Error reparando: $e');
            }
          }
        }
      }

      if (reparados > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Se repararon $reparados mensajes cifrados'),
            duration: Duration(seconds: 3),
          ),
        );
        _loadSessions();
      }
    } catch (e) {
      print('Error reparando chats: $e');
    }
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

    final firstMsg = userMessages.first;
    final content = firstMsg.contenido;

    return content.length > 60 ? '${content.substring(0, 60)}...' : content;
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
      if (content.length > 25) {
        return '${content.substring(0, 25)}...';
      }
      return content;
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
        title: Text(
          'Historial de Conversaciones',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black87,
          ),
        ),
        backgroundColor: const Color(0xFFF2FFFF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, 
              color: Color(0xFF86A8E7), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF86A8E7)),
            onPressed: _loadSessions,
            tooltip: 'Actualizar',
          ),
        ],
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

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _buildSkeletonCard();
      },
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 100,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 250,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.red[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline_rounded,
                size: 60, color: Color(0xFFEF5350)),
          ),
          const SizedBox(height: 24),
          Text(
            "Error al cargar el historial",
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _loadSessions,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF86A8E7),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.refresh_rounded, size: 20, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  "Reintentar",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
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
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.chat_bubble_outline_rounded,
                  size: 70, color: Color(0xFF86A8E7)),
            ),
            const SizedBox(height: 32),
            Text(
              "Aún no tienes conversaciones",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Comienza una nueva conversación con nuestro asistente",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.grey[600],
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF86A8E7),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, size: 22, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    "Nueva Conversación",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _sessions.length,
        itemBuilder: (context, index) {
          final session = _sessions[index];
          return _buildSessionCard(session);
        },
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF86A8E7).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            Navigator.pop(context, session);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF86A8E7), Color(0xFF91EAE4)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chat_bubble_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
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
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF86A8E7).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.schedule_rounded,
                                        size: 12, color: Color(0xFF86A8E7)),
                                    const SizedBox(width: 4),
                                    Text(
                                      lastMessageTime,
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF86A8E7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(session.fecha),
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.message_rounded,
                          size: 18, color: Color(0xFF86A8E7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getFirstMessageContent(session),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_rounded,
                              size: 14, color: Color(0xFF86A8E7)),
                          const SizedBox(width: 6),
                          Text(
                            '$messageCount',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF86A8E7),
                            ),
                          ),
                          Text(
                            ' mensajes',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF86A8E7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (hasTags)
                      Wrap(
                        spacing: 6,
                        children: session.etiquetas.take(2).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _getTagColor(tag).withOpacity(0.9),
                                  _getTagColor(tag).withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  tag,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
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

    if (lowerTag.contains('triste') || lowerTag.contains('tristeza')) {
      return const Color(0xFF2196F3);
    } else if (lowerTag.contains('ansied') || lowerTag.contains('ansiedad')) {
      return const Color(0xFFFF9800);
    } else if (lowerTag.contains('deprim') || lowerTag.contains('depresión')) {
      return const Color(0xFFF44336);
    } else if (lowerTag.contains('estrés') || lowerTag.contains('estres')) {
      return const Color(0xFF9C27B0);
    } else if (lowerTag.contains('feliz') ||
        lowerTag.contains('alegr') ||
        lowerTag.contains('felicidad')) {
      return const Color(0xFF4CAF50);
    } else if (lowerTag.contains('enoj') || lowerTag.contains('ira')) {
      return const Color(0xFFFF5722);
    } else if (lowerTag.contains('calm') || lowerTag.contains('paz')) {
      return const Color(0xFF00BCD4);
    } else if (lowerTag.contains('emocion') || lowerTag.contains('excit')) {
      return const Color(0xFFFFC107);
    }

    return const Color(0xFF607D8B);
  }
}