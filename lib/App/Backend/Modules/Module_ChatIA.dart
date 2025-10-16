/*----------|IMPORTACIONES BASICAS|----------*/
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';

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

/*----------|SIN USO|----------*/
//import '../../Services/titulo_dinamico_service.dart';
//import '../../UI/Screens/configuracion_ia_screen.dart';
//import '../../utils/solucion_rapida.dart';
//import 'package:shared_preferences/shared_preferences.dart';
//import 'dart:convert';
// import '../../Data/models/analisis_emocional.dart'; // ELIMINADO - Análisis de emociones oculto
//import '../../Data/database/DatabaseHelper.dart';

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
                    color: Colors.grey[600],
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
  final SesionChat?
      sesionAnterior; // Para retomar conversaciones desde historial

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
  // Map<String, dynamic>? _perfilUsuario; // No se usa actualmente
  // List<Map<String, dynamic>> _historialAnalisis = []; // ELIMINADO - Análisis de emociones oculto
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
      // SESIONES INDEPENDIENTES: Cada sesión es completamente nueva
      developer.log(
          '🆕 SESIÓN INDEPENDIENTE: Sin memoria de conversaciones previas');
    }

    developer.log('✅ INICIALIZACIÓN DEL CHAT COMPLETADA');
  }

  Future<void> _cargarConfiguracionPersonalizada() async {
    try {
      await _librosService.cargarLibros();

      // Siempre generar el prompt automáticamente para todos los usuarios
      _promptPersonalizado = _librosService.generarPromptPersonalizado(
          'Eres un asistente psicológico empático y profesional que:\n- Utiliza un tono cálido y comprensivo\n- Proporciona respuestas basadas en la psicología científica\n- Ofrece herramientas prácticas para el desarrollo emocional\n- Mantiene un enfoque ético y profesional\n- Adapta su comunicación según las necesidades del usuario\n- Utiliza la base de conocimiento de libros de psicología para fundamentar sus respuestas',
          '1. Siempre prioriza el bienestar emocional del usuario\n2. No proporcionar diagnósticos médicos o psicológicos\n3. Recomendar buscar ayuda profesional cuando sea necesario\n4. Mantener confidencialidad y respeto\n5. Usar lenguaje claro y accesible\n6. Basar respuestas en evidencia científica de los libros de psicología\n7. Fomentar la autoconciencia y el desarrollo personal\n8. Utilizar conceptos de inteligencia emocional de Daniel Goleman\n9. Referenciar técnicas psicológicas cuando sea apropiado');

      setState(() {
        _configuracionCargada = true;
      });

      developer
          .log('✅ Configuración automática cargada para todos los usuarios');
      developer.log('📚 Libros cargados: ${_librosService.libros.length}');
      developer.log('🤖 Prompt generado automáticamente');
    } catch (e) {
      developer.log('⚠️ Error cargando configuración automática: $e');
    }
  }

  Future<void> _cargarSesionAnterior() async {
    developer.log('🔄 CARGANDO SESIÓN ANTERIOR DESDE HISTORIAL...');
    developer.log(
      '📝 Mensajes en sesión anterior: ${widget.sesionAnterior!.mensajes.length}',
    );

    // DESCIFRADO FORZADO: Usar el método forzado que descifra TODO
    final mensajesParaDescifrar = widget.sesionAnterior!.mensajes.map((m) {
      final mensajeJson = m.toJson();
      // NO marcar como cifrado - usar el método forzado que descifra TODO
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

    // Auto-scroll al final después de cargar mensajes anteriores
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    developer.log('✅ SESIÓN ANTERIOR CARGADA: ${_messages.length} mensajes');
    developer.log('🔄 Estado de sesión continuada: $_esSesionContinuada');
    developer.log('🔐 Mensajes descifrados correctamente');
  }

  Future<void> _cargarPerfilUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _uidUsuario = user.uid;

      try {
        //final dbHelper = DatabaseHelper.instance;
        // _perfilUsuario = await dbHelper.getEstudiantePorUID(user.uid);
        // _historialAnalisis = await dbHelper.getAnalisisPorUsuario(user.uid); // ELIMINADO - Análisis oculto
      } catch (e) {
        // Si hay error con la base de datos (como en web), usar lista vacía
        developer.log('⚠️ Error cargando perfil: $e');
      }

      // ESTANDARIZAR: Usar siempre el email como identificador principal
      _usuario = user.email ?? "Usuario";

      developer.log('👤 USUARIO CARGADO: $_usuario');
      developer.log('📧 EMAIL: ${user.email}');
      developer.log('🆔 UID: ${user.uid}');
      developer.log('🔒 ANÁLISIS DE EMOCIONES: OCULTO');
    }
  }

  Future<void> _startSession() async {
    setState(() {
      _sessionActive = true;
      // ESTANDARIZAR: Usar siempre el email
      _usuario = FirebaseAuth.instance.currentUser?.email ?? "Usuario";
    });

    developer.log('🚀 SESIÓN INICIADA PARA: $_usuario');

    // SESIONES INDEPENDIENTES: No hay memoria de conversaciones anteriores
    developer
        .log('🆕 SESIÓN INDEPENDIENTE: Sin memoria de conversaciones previas');
  }

  // MÉTODOS DE ANÁLISIS DE EMOCIONES ELIMINADOS - SESIONES INDEPENDIENTES

  void _addMessage(String text) async {
    // Bloquear envío si la IA está pensando
    if (_isThinking) {
      developer
          .log('🚫 Bloqueado: IA está pensando, no se puede enviar mensaje');
      return;
    }

    developer.log('💬 NUEVO MENSAJE DEL USUARIO: $text');

    // Activar estado de pensamiento
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

    // Auto-scroll al final después de agregar mensaje del usuario
    _scrollToBottom();

    // Mostrar indicador de carga con animación
    final loadingMsg = Mensaje(
      emisor: "Asistente",
      contenido: "TYPING_INDICATOR", // Marcador especial para la animación
      fecha: DateTime.now().toIso8601String(),
    );

    setState(() {
      _messages.add(loadingMsg);
    });

    // Auto-scroll al final después de agregar indicador de carga
    _scrollToBottom();

    // Crear el historial de mensajes para enviar a GPT (incluyendo contexto)
    List<Map<String, String>> messagesForGpt = [];

    // Agregar prompt automático como primer mensaje del sistema (siempre activo)
    if (_configuracionCargada && _promptPersonalizado.isNotEmpty) {
      messagesForGpt.add({"role": "system", "content": _promptPersonalizado});
      developer.log('🤖 Prompt automático incluido en la conversación');
    } else {
      developer.log('⚠️ Prompt automático no disponible aún');
    }

    // Agregar mensajes de la conversación (excluyendo el mensaje de carga)
    for (var msg in _messages.where((m) => m.contenido != "TYPING_INDICATOR")) {
      String role;
      if (msg.emisor == "Usuario") {
        role = "user";
      } else if (msg.emisor == "Sistema") {
        role = "system"; // Contexto psicológico
      } else {
        role = "assistant";
      }

      messagesForGpt.add({"role": role, "content": msg.contenido});
    }

    developer.log(
      '🤖 ENVIANDO A GPT: ${messagesForGpt.length} mensajes (incluye prompt personalizado)',
    );

    try {
      // Reintentos para asegurar respuesta
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
            rethrow; // Re-lanzar el error si se agotaron los intentos
          }
          // Esperar antes del siguiente intento
          await Future.delayed(Duration(seconds: intentos));
        }
      }

      // Remover mensaje de carga y agregar respuesta real
      setState(() {
        _messages.removeLast(); // Remover "TYPING_INDICATOR"

        final gptMsg = Mensaje(
          emisor: "Asistente",
          contenido: respuesta?.trim() ??
              "Lo siento, no pude procesar tu mensaje. Inténtalo de nuevo.",
          fecha: DateTime.now().toIso8601String(),
        );

        _messages.add(gptMsg);
      });

      // Auto-scroll al final después de agregar respuesta de GPT
      _scrollToBottom();
    } catch (e) {
      developer.log('❌ ERROR GPT: $e');

      // Remover mensaje de carga
      setState(() {
        _messages.removeLast(); // Remover "TYPING_INDICATOR"
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

      // Auto-scroll al final después de agregar mensaje de error
      _scrollToBottom();
    } finally {
      // Resetear estado de pensamiento
      setState(() {
        _isThinking = false;
      });
    }
  }

  bool _isEndingSession = false;

  Future<void> _endSession() async {
    // Protección contra llamadas duplicadas
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

      // Generar título con IA solo al cerrar sesión
      final tituloDinamico =
          await TituloIAService.generarTituloConIA(_messages);
      developer.log('🤖 Título generado por IA al cerrar: $tituloDinamico');

      // Manejar sesiones continuadas vs nuevas
      if (_esSesionContinuada && widget.sesionAnterior != null) {
        // Actualizar la sesión existente con el nuevo título
        await _actualizarSesionExistenteConTitulo(tituloDinamico);
      } else {
        // Crear nueva sesión con el título generado
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

      // Manejar específicamente errores de permisos de Firestore
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
      // Reset del flag de protección
      _isEndingSession = false;
    }
  }

  // MÉTODO ELIMINADO - USAR _actualizarSesionExistenteConTitulo EN SU LUGAR

  Future<void> _actualizarSesionExistenteConTitulo(
      String tituloDinamico) async {
    developer.log('🔄 ACTUALIZANDO SESIÓN EXISTENTE CON TÍTULO...');

    // Cifrar mensajes antes de guardar
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

    // ANÁLISIS DE EMOCIONES ELIMINADO - SESIONES INDEPENDIENTES
    developer.log('🔒 ANÁLISIS DE EMOCIONES: OCULTO');
    developer.log('🔐 Mensajes cifrados antes de guardar');
    developer.log('🤖 Título actualizado: $tituloDinamico');

    developer.log('✅ SESIÓN ACTUALIZADA CORRECTAMENTE');
  }

  // MÉTODO ELIMINADO - USAR _crearNuevaSesionConTitulo EN SU LUGAR

  Future<void> _crearNuevaSesionConTitulo(String tituloDinamico) async {
    // Cifrar mensajes antes de guardar
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

    // ANÁLISIS DE EMOCIONES ELIMINADO - SESIONES INDEPENDIENTES
    developer.log('🔒 ANÁLISIS DE EMOCIONES: OCULTO');
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

    // Tomar el primer mensaje del usuario como base para el título
    String primerMensaje = mensajesUsuario.first;

    // Si es muy largo, cortarlo y agregar puntos suspensivos
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

    // Emociones
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

    // Temas
    if (contenido.contains(RegExp(r'\b(exam|estudi|univers|tarea|clase)\b'))) {
      etiquetas.add("📚 Académico");
    }
    if (contenido.contains(
      RegExp(r'\b(familia|padres|hermano|casa|hogar)\b'),
    )) {
      etiquetas.add("👨‍👩‍👧‍👦 Familia");
    }
    if (contenido.contains(RegExp(r'\b(pareja|novio|novia|amor|relación)\b'))) {
      etiquetas.add("💕 Relaciones");
    }
    if (contenido.contains(RegExp(r'\b(trabajo|empleo|jefe|oficina)\b'))) {
      etiquetas.add("💼 Laboral");
    }
    if (contenido.contains(RegExp(r'\b(enferm|dolor|médico|salud)\b'))) {
      etiquetas.add("🏥 Salud");
    }

    return etiquetas.take(3).toList(); // Máximo 3 etiquetas
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Asistente AI"),
        actions: [
          // Solo botones esenciales para el usuario
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HistorialSesionesUsuario(uidUsuario: _uidUsuario),
                ),
              );
            },
            tooltip: "Ver historial de chats",
          ),
          if (_sessionActive)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _endSession,
              tooltip: "Terminar sesión",
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text('Inicia una sesión para comenzar a chatear'),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages
                        .where(
                          (m) =>
                              m.emisor != "Sistema" ||
                              m.contenido.startsWith("⚠️"),
                        )
                        .length,
                    itemBuilder: (context, index) {
                      final mensajesVisibles = _messages
                          .where(
                            (m) =>
                                m.emisor != "Sistema" ||
                                m.contenido.startsWith("⚠️"),
                          )
                          .toList();
                      final msg = mensajesVisibles[index];
                      final isUser = msg.emisor == "Usuario";

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                          children: [
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Colors.blue[100]
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.emisor,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Mostrar animación de puntos si es el indicador de carga
                                    msg.contenido == "TYPING_INDICATOR"
                                        ? const TypingIndicator()
                                        : Text(msg.contenido),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(msg.fecha),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_sessionActive)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled:
                          true, // Siempre habilitado para mantener el teclado
                      decoration: InputDecoration(
                        hintText: _isThinking
                            ? "Esperando respuesta..."
                            : "Escribe tu mensaje...",
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        // Cambiar color cuando está bloqueado pero mantener funcional
                        filled: _isThinking,
                        fillColor: _isThinking ? Colors.grey[100] : null,
                      ),
                      maxLines: 3, // Limitar a 3 líneas máximo
                      minLines: 1, // Mínimo 1 línea
                      onSubmitted: (text) {
                        if (text.trim().isNotEmpty && !_isThinking) {
                          _addMessage(text.trim());
                          _controller.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: _isThinking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _isThinking
                        ? null
                        : () {
                            if (_controller.text.trim().isNotEmpty) {
                              _addMessage(_controller.text.trim());
                              _controller.clear();
                            }
                          },
                  ),
                ],
              ),
            ),
          if (!_sessionActive)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startSession,
                  icon: const Icon(Icons.chat),
                  label: const Text("Iniciar nueva sesión de chat"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
        ],
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

  void _debugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Usuario: $_usuario'),
              Text('UID: $_uidUsuario'),
              Text('Sesión activa: $_sessionActive'),
              Text('Mensajes: ${_messages.length}'),
              Text('🔒 Análisis de emociones: OCULTO'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final sesiones =
                        await FirebaseChatStorage.getSesionesChat();
                    developer.log(
                        '🔍 Debug: ${sesiones.length} sesiones encontradas');
                    for (int i = 0; i < sesiones.length; i++) {
                      developer.log(
                          '📝 Sesión $i: ${sesiones[i].fecha} - ${sesiones[i].resumen}');
                    }
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Debug: ${sesiones.length} sesiones encontradas')),
                      );
                    }
                  } catch (e) {
                    developer.log('❌ Error en debug: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error en debug: $e')),
                      );
                    }
                  }
                },
                child: const Text('🔍 Ver sesiones guardadas'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
