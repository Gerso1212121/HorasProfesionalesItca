/*----------|IMPORTACIONES BASICAS|----------*/
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

/*----------|MODULOS|----------*/
import '../../Data/Api/gptApi.dart';
import '../../Data/Models/mensaje.dart';
import '../../Data/Models/sesion_chat.dart';
import '../../Data/Model_ChatFirebaseRemote.dart';
import '../../Services/Service_Libros.dart';
import '../../Services/Services_Cifrado.dart';
import '../../Services/Service_TituloIA.dart';
import '../../Utils/Utils_DebugHelper.dart';
import '../../Utils/Utils_FirestorFix.dart';
import 'Module_HistorialSesionesUsuario.dart';

// Widget de animación de puntos como ChatGPT
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({Key? key}) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Iniciar animación secuencial
    _startAnimation();
  }

  void _startAnimation() {
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -_animations[index].value * 8),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF86A8E7),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class ChatAi extends StatefulWidget {
  final SesionChat? sesionAnterior;

  const ChatAi({super.key, this.sesionAnterior});

  @override
  State<ChatAi> createState() => _ChatAiState();
}

class _ChatAiState extends State<ChatAi> {
  final _messages = <Mensaje>[];
  late String _usuario;
  String? _uidUsuario;
  bool _sessionActive = false;
  final TextEditingController _controller = TextEditingController();
  bool _esSesionContinuada = false;

  // Configuración personalizada de IA
  final LibrosService _librosService = LibrosService();
  String _promptPersonalizado = '';
  bool _configuracionCargada = false;

  // ScrollController para auto-scroll
  final ScrollController _scrollController = ScrollController();

  // Variable para bloquear envío mientras la IA está pensando
  bool _isThinking = false;

  @override
  void initState() {
    super.initState();
    _inicializarChat();
  }

  // Método para hacer auto-scroll al final del chat
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

  Future<void> _inicializarChat() async {
    developer.log('🚀 INICIANDO CHAT CON DIAGNÓSTICO...');

    // Ejecutar diagnóstico automático
    await DebugHelper.diagnosticarProblemas();

    // Solucionar problemas de Firestore específicamente
    await FirestoreFix.solucionCompletaFirestore();

    // Cargar configuración y perfil
    await _cargarPerfilUsuario();
    await _cargarConfiguracionPersonalizada();

    // Cargar sesión anterior si viene desde historial
    if (widget.sesionAnterior != null) {
      _cargarSesionAnterior();
    } else {
      developer.log(
          '🆕 SESIÓN INDEPENDIENTE: Sin memoria de conversaciones previas');
    }

    developer.log('✅ INICIALIZACIÓN DEL CHAT COMPLETADA');
  }

  Future<void> _cargarConfiguracionPersonalizada() async {
    try {
      await _librosService.cargarLibros();

      _promptPersonalizado = _librosService.generarPromptPersonalizado(
          'Eres un asistente psicológico empático y profesional que:\n- Utiliza un tono cálido y comprensivo\n- Proporciona respuestas basadas en la psicología científica\n- Ofrece herramientas prácticas para el desarrollo emocional\n- Mantiene un enfoque ético y profesional\n- Adapta su comunicación según las necesidades del usuario\n- Utiliza la base de conocimiento de libros de psicología para fundamentar sus respuestas',
          '1. Siempre prioriza el bienestar emocional del usuario\n2. No proporcionar diagnósticos médicos o psicológicos\n3. Recomendar buscar ayuda profesional cuando sea necesario\n4. Mantener confidencialidad y respeto\n5. Usar lenguaje claro y accesible\n6. Basar respuestas en evidencia científica de los libros de psicología\n7. Fomentar la autoconciencia y el desarrollo personal\n8. Utilizar conceptos de inteligencia emocional de Daniel Goleman\n9. Referenciar técnicas psicológicas cuando sea apropiado');

      setState(() {
        _configuracionCargada = true;
      });

      developer
          .log('✅ Configuración automática cargada para todos los usuarios');
    } catch (e) {
      developer.log('⚠️ Error cargando configuración automática: $e');
    }
  }

  Future<void> _cargarSesionAnterior() async {
    developer.log('🔄 CARGANDO SESIÓN ANTERIOR DESDE HISTORIAL...');
    developer.log(
        '📝 Mensajes en sesión anterior: ${widget.sesionAnterior!.mensajes.length}');

    final mensajesParaDescifrar = widget.sesionAnterior!.mensajes.map((m) {
      final mensajeJson = m.toJson();
      return mensajeJson;
    }).toList();

    developer.log(
        '💥 DESCIFRADO FORZADO: Intentando descifrar ${mensajesParaDescifrar.length} mensajes...');

    final mensajesDescifrados =
        await CifradoService.descifrarMensajes(mensajesParaDescifrar);
    final mensajes =
        mensajesDescifrados.map((m) => Mensaje.fromJson(m)).toList();

    setState(() {
      _messages.clear();
      _messages.addAll(mensajes);
      _sessionActive = true;
      _esSesionContinuada = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    developer.log('✅ SESIÓN ANTERIOR CARGADA: ${_messages.length} mensajes');
  }

  Future<void> _cargarPerfilUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _uidUsuario = user.uid;
      _usuario = user.email ?? "Usuario";
      developer.log('👤 USUARIO CARGADO: $_usuario');
    }
  }

  Future<void> _startSession() async {
    setState(() {
      _sessionActive = true;
      _usuario = FirebaseAuth.instance.currentUser?.email ?? "Usuario";
    });

    developer.log('🚀 SESIÓN INICIADA PARA: $_usuario');
    developer
        .log('🆕 SESIÓN INDEPENDIENTE: Sin memoria de conversaciones previas');
  }

  void _addMessage(String text) async {
    if (_isThinking) {
      developer
          .log('🚫 Bloqueado: IA está pensando, no se puede enviar mensaje');
      return;
    }

    developer.log('💬 NUEVO MENSAJE DEL USUARIO: $text');

    setState(() {
      _isThinking = true;
    });

    final userMsg = Mensaje(
      emisor: "Usuario",
      contenido: text,
      fecha: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(userMsg);
    });

    _scrollToBottom();

    // Mostrar indicador de carga con animación
    final loadingMsg = Mensaje(
      emisor: "Asistente",
      contenido: "TYPING_INDICATOR",
      fecha: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(loadingMsg);
    });

    _scrollToBottom();

    // Crear el historial de mensajes para enviar a GPT
    List<Map<String, String>> messagesForGpt = [];

    // Agregar prompt automático como primer mensaje del sistema
    if (_configuracionCargada && _promptPersonalizado.isNotEmpty) {
      messagesForGpt.add({"role": "system", "content": _promptPersonalizado});
      developer.log('🤖 Prompt automático incluido en la conversación');
    }

    // Agregar mensajes de la conversación
    for (var msg in _messages.where((m) => m.contenido != "TYPING_INDICATOR")) {
      String role;
      if (msg.emisor == "Usuario") {
        role = "user";
      } else if (msg.emisor == "Sistema") {
        role = "system";
      } else {
        role = "assistant";
      }

      messagesForGpt.add({"role": role, "content": msg.contenido});
    }

    developer.log('🤖 ENVIANDO A GPT: ${messagesForGpt.length} mensajes');

    try {
      int intentos = 0;
      const maxIntentos = 3;
      String? respuesta;

      while (intentos < maxIntentos && respuesta == null) {
        intentos++;
        developer.log('🔄 Intento $intentos de $maxIntentos');

        try {
          respuesta = await GptApi.getResponse(messagesForGpt);
          developer.log('✅ RESPUESTA DE GPT: $respuesta');
          break;
        } catch (e) {
          developer.log('❌ Error en intento $intentos: $e');
          if (intentos >= maxIntentos) {
            rethrow;
          }
          await Future.delayed(Duration(seconds: intentos));
        }
      }

      setState(() {
        _messages.removeLast();
        final gptMsg = Mensaje(
          emisor: "Asistente",
          contenido: respuesta?.trim() ??
              "Lo siento, no pude procesar tu mensaje. Inténtalo de nuevo.",
          fecha: DateTime.now().toIso8601String(),
        );
        _messages.add(gptMsg);
      });

      _scrollToBottom();
    } catch (e) {
      developer.log('❌ ERROR GPT: $e');

      setState(() {
        _messages.removeLast();
      });

      String errorMessage = "⚠️ Error al conectar con el asistente. ";
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('PERMISSION_DENIED')) {
        errorMessage += "Problema de permisos en Firestore.";
      } else if (e.toString().contains('network') ||
          e.toString().contains('timeout')) {
        errorMessage += "Problema de conexión. Verifica tu internet.";
      } else if (e.toString().contains('API')) {
        errorMessage += "Problema con la API de OpenAI.";
      } else {
        errorMessage += "Inténtalo de nuevo.";
      }

      final errorMsg = Mensaje(
        emisor: "Sistema",
        contenido: errorMessage,
        fecha: DateTime.now().toIso8601String(),
      );
      setState(() {
        _messages.add(errorMsg);
      });

      _scrollToBottom();
    } finally {
      setState(() {
        _isThinking = false;
      });
    }
  }

  bool _isEndingSession = false;

  Future<void> _endSession() async {
    if (_isEndingSession) {
      developer.log(
          '⚠️ _endSession ya está en ejecución, ignorando llamada duplicada');
      return;
    }

    if (_messages.isEmpty) {
      setState(() {
        _sessionActive = false;
      });
      return;
    }

    _isEndingSession = true;

    try {
      developer.log('🔄 FINALIZANDO SESIÓN...');

      final tituloDinamico =
          await TituloIAService.generarTituloConIA(_messages);
      developer.log('🤖 Título generado por IA al cerrar: $tituloDinamico');

      if (_esSesionContinuada && widget.sesionAnterior != null) {
        await _actualizarSesionExistenteConTitulo(tituloDinamico);
      } else {
        await _crearNuevaSesionConTitulo(tituloDinamico);
      }

      setState(() {
        _sessionActive = false;
        _messages.clear();
        _esSesionContinuada = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sesión guardada correctamente'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log('❌ ERROR AL PROCESAR SESIÓN: $e');

      String errorMessage = 'Error al guardar sesión';
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('permissions')) {
        errorMessage =
            'Error de permisos en Firestore. La sesión se guardó localmente como respaldo.';
      } else if (e.toString().contains('No se pudo guardar')) {
        errorMessage =
            'No se pudo guardar la sesión. Verifica tu conexión a internet.';
      }

      setState(() {
        _sessionActive = false;
        _messages.clear();
        _esSesionContinuada = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $errorMessage'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      _isEndingSession = false;
    }
  }

  Future<void> _actualizarSesionExistenteConTitulo(
      String tituloDinamico) async {
    developer.log('🔄 ACTUALIZANDO SESIÓN EXISTENTE CON TÍTULO...');

    final mensajesCifrados = await CifradoService.cifrarMensajes(
      _messages.map((m) => m.toJson()).toList(),
    );

    final sesionActualizada = SesionChat(
      fecha: widget.sesionAnterior!.fecha,
      usuario: _usuario,
      resumen: _generarResumen(),
      mensajes: mensajesCifrados.map((m) => Mensaje.fromJson(m)).toList(),
      etiquetas: _generarEtiquetas(),
      tituloDinamico: tituloDinamico,
    );

    await FirebaseChatStorage.deleteSesionChat(widget.sesionAnterior!.fecha);
    await FirebaseChatStorage.saveSesionChat(sesionActualizada);

    developer.log('🔐 Mensajes cifrados antes de guardar');
    developer.log('🤖 Título actualizado: $tituloDinamico');
    developer.log('✅ SESIÓN ACTUALIZADA CORRECTAMENTE');
  }

  Future<void> _crearNuevaSesionConTitulo(String tituloDinamico) async {
    final mensajesCifrados = await CifradoService.cifrarMensajes(
      _messages.map((m) => m.toJson()).toList(),
    );

    final sesionChat = SesionChat(
      fecha: DateTime.now().toIso8601String(),
      usuario: _usuario,
      resumen: _generarResumen(),
      mensajes: mensajesCifrados.map((m) => Mensaje.fromJson(m)).toList(),
      etiquetas: _generarEtiquetas(),
      tituloDinamico: tituloDinamico,
    );

    await FirebaseChatStorage.saveSesionChat(sesionChat);

    developer.log('🔐 Mensajes cifrados antes de guardar');
    developer.log('🤖 Título generado por IA: $tituloDinamico');
    developer.log('✅ NUEVA SESIÓN CREADA Y ANALIZADA');
  }

  String _generarResumen() {
    final mensajesUsuario = _messages
        .where((m) => m.emisor == "Usuario")
        .map((m) => m.contenido)
        .toList();

    if (mensajesUsuario.isEmpty) return "Sesión sin mensajes";

    String primerMensaje = mensajesUsuario.first;
    if (primerMensaje.length > 50) {
      return "${primerMensaje.substring(0, 50)}...";
    }

    return primerMensaje;
  }

  List<String> _generarEtiquetas() {
    final contenido = _messages
        .where((m) => m.emisor == "Usuario")
        .map((m) => m.contenido.toLowerCase())
        .join(" ");

    List<String> etiquetas = [];

    if (contenido.contains(RegExp(r'\b(triste|deprim|llor|melanc)\b'))) {
      etiquetas.add("😢 Tristeza");
    }
    if (contenido.contains(RegExp(r'\b(ansio|nervio|preocup|estres)\b'))) {
      etiquetas.add("😰 Ansiedad");
    }
    if (contenido.contains(RegExp(r'\b(enoj|ira|molest|frustrad)\b'))) {
      etiquetas.add("😠 Enojo");
    }
    if (contenido.contains(RegExp(r'\b(feliz|alegr|content|bien)\b'))) {
      etiquetas.add("😊 Alegría");
    }

    return etiquetas.take(3).toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // NUEVO DISEÑO APLICADO CON BOTÓN DE HISTORIAL EN SUPERIOR IZQUIERDA
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: Column(
        children: [
          // Header con gradiente (inspirado en HomeScreen)
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding:
                const EdgeInsets.only(top: 60, bottom: 20, left: 16, right: 16),
            child: Column(
              children: [
                // Fila superior con flecha y título
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🔙 Botón de retroceso
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black87,
                        size: 22,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),

                    // Título centrado
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            "Asistente AI",
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Tu compañero emocional",
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Espacio para balancear la flecha
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 12),

                // Botón de historial centrado
                Center(child: _buildHistorialSlideButton()),

                const SizedBox(height: 12),

                // Fila con indicador de sesión y botón terminar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: _sessionActive
                                ? const Color(0xFF4CAF50)
                                : const Color(0xFFF66B7D),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _sessionActive
                                    ? Icons.chat
                                    : Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _sessionActive ? "Activo" : "Inactivo",
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_sessionActive) ...[
                        const SizedBox(width: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFFF66B7D).withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _endSession,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.stop,
                                      color: Color(0xFFF66B7D),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Terminar",
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFFF66B7D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Área de mensajes
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return _messages.isEmpty
                    ? SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Center(
                            child: _buildEmptyState(),
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages
                            .where((m) =>
                                m.emisor != "Sistema" ||
                                m.contenido.startsWith("⚠️"))
                            .length,
                        itemBuilder: (context, index) {
                          final mensajesVisibles = _messages
                              .where((m) =>
                                  m.emisor != "Sistema" ||
                                  m.contenido.startsWith("⚠️"))
                              .toList();
                          final msg = mensajesVisibles[index];
                          final isUser = msg.emisor == "Usuario";

                          return _buildMessageBubble(msg, isUser);
                        },
                      );
              },
            ),
          ),

          // Área de entrada (footer)
          if (_sessionActive) _buildInputArea(),
          if (!_sessionActive) _buildStartSessionButton(),
        ],
      ),
    );
  }

  // Nuevo widget para el botón de historial con efecto slide
  Widget _buildHistorialSlideButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF66B7D).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HistorialSesionesUsuario(uidUsuario: _uidUsuario),
              ),
            );
          },
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.history,
                  color: Color(0xFFF66B7D),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  "Historial",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF66B7D),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF2FFFF).withOpacity(0.5),
            Color(0xFFE8F5E8).withOpacity(0.3),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono decorativo
            Container(
              width: 160,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.psychology_outlined,
                  size: 50,
                  color: Color(0xFF86A8E7),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Inicia una conversación',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Comparte tus pensamientos, preocupaciones o simplemente inicia una conversación. Estoy aquí para escucharte.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Mensaje msg, bool isUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFF86A8E7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.psychology_outlined,
                color: Colors.white,
                size: 18,
              ),
            ),
          if (!isUser) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF86A8E7) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: isUser ? null : Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del emisor
                  Text(
                    isUser ? "Tú" : "Asistente",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isUser ? Colors.white70 : Color(0xFF666666),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Contenido del mensaje
                  msg.contenido == "TYPING_INDICATOR"
                      ? const TypingIndicator()
                      : Text(
                          msg.contenido,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: isUser ? Colors.white : Colors.black87,
                            height: 1.4,
                          ),
                        ),
                  const SizedBox(height: 6),
                  // Hora
                  Text(
                    _formatTime(msg.fecha),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: isUser ? Colors.white70 : Color(0xFF999999),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Color(0xFFF66B7D),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Color(0xFFE0E0E0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_isThinking,
                      decoration: InputDecoration(
                        hintText: _isThinking
                            ? "El asistente está escribiendo..."
                            : "Escribe tu mensaje...",
                        hintStyle: GoogleFonts.inter(
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      style: GoogleFonts.inter(fontSize: 14),
                      onSubmitted: (text) {
                        if (text.trim().isNotEmpty && !_isThinking) {
                          _addMessage(text.trim());
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                  if (_isThinking)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF86A8E7)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isThinking
                    ? [Colors.grey, Colors.grey]
                    : [Color(0xFFF66B7D), Color(0xFF86A8E7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _isThinking
                  ? null
                  : () {
                      if (_controller.text.trim().isNotEmpty) {
                        _addMessage(_controller.text.trim());
                        _controller.clear();
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartSessionButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _startSession,
          icon: Icon(Icons.chat_bubble, color: Colors.white),
          label: Text(
            "Iniciar nueva sesión de chat",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFF66B7D),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            shadowColor: Color(0xFFF66B7D).withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  String _formatTime(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return fecha;
    }
  }
}
