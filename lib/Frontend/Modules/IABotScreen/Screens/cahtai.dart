/*----------|IMPORTACIONES BASICAS|----------*/
import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Backend/Data/API/GPTService.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/mensajes.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/sesionchat.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/degubhelper.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/firestorefix.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/funcionesDeia.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/libroservice.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/logicaZZZ.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/sede_alerta.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/service.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/servicechatcifrado.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/tituloIAservice.dart';
import 'dart:async'; // Importar para Timer

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

class ChatBotScreen extends StatefulWidget {
  final SesionChat? sesionAnterior;
  final String? mensajeInicial;

  const ChatBotScreen({super.key, this.sesionAnterior, this.mensajeInicial});

  @override
  State<ChatBotScreen> createState() => _ChatAiState();
}

class _ChatAiState extends State<ChatBotScreen> {
  final _messages = <Mensaje>[];
  late String _usuario;
  String? _uidUsuario;
  String _nombreUsuario = "Usuario";
  String? _sedeEstudiante;
  String? _telefonoEstudiante;
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

  // ========== SISTEMA DE AUTO-GUARDADO ==========
  bool _isEndingSession = false;
  Timer? _autoSaveTimer;
  String? _currentSessionId; // ID de la sesión actual para autoguardado
  static const int _autoSaveInterval = 30; // Segundos entre autoguardados
  static const String _autoSaveMarker =
      "🔄 AUTO_GUARDADO"; // Marcador para autoguardados

  // Seguimiento de alto riesgo (como en ProyectoAS)
  Timer? _highRiskFollowUpTimer;
  int _sessionSeq = 0;

  @override
  void initState() {
    super.initState();
    _inicializarChat();
    _startSession();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _detenerAutoSave(); // Detener autoguardado al destruir
    super.dispose();
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

    // Cargar sesión anterior si viene desde historial, o iniciar desde sugerencia
    if (widget.sesionAnterior != null) {
      await _cargarSesionAnterior();
    } else {
      developer.log(
          '🆕 SESIÓN INDEPENDIENTE: Sin memoria de conversaciones previas');

      // Si viene un mensaje inicial desde una sugerencia de chat, iniciar sesión automáticamente
      if (widget.mensajeInicial != null &&
          widget.mensajeInicial!.trim().isNotEmpty) {
        developer.log(
            '💡 MENSAJE INICIAL DESDE SUGERENCIA: "${widget.mensajeInicial}"');
        await _startSession();
        _addMessage(widget.mensajeInicial!.trim());
      }
    }

    developer.log('✅ INICIALIZACIÓN DEL CHAT COMPLETADA');
  }

  // ========== SISTEMA DE AUTO-GUARDADO ==========

  void _iniciarAutoSave() {
    if (!_sessionActive) return;

    _detenerAutoSave(); // Detener timer anterior si existe

    _autoSaveTimer = Timer.periodic(
      Duration(seconds: _autoSaveInterval),
      (timer) {
        if (_sessionActive && _messages.isNotEmpty && !_isThinking) {
          _autoGuardarSesion();
        }
      },
    );

    developer
        .log('🔄 AUTO-GUARDADO INICIADO: Cada $_autoSaveInterval segundos');
  }

  void _detenerAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  Future<void> _autoGuardarSesion() async {
    if (_messages.isEmpty || _isEndingSession || !_sessionActive || _isThinking)
      return;

    try {
      developer.log('💾 AUTO-GUARDANDO SESIÓN...');

      // Generar ID único para la sesión si no existe
      if (_currentSessionId == null) {
        _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      }

      // Guardado rápido sin generar título IA
      final mensajesCifrados = await CifradoService.cifrarMensajes(
        _messages.map((m) => m.toJson()).toList(),
      );

      final sesionAutoGuardada = SesionChat(
        fecha: _currentSessionId!,
        usuario: _usuario,
        resumen: _generarResumen(),
        mensajes: mensajesCifrados.map((m) => Mensaje.fromJson(m)).toList(),
        etiquetas: _generarEtiquetas(),
        tituloDinamico:
            _autoSaveMarker, // Usamos el marcador para identificar autoguardados
      );

      await FirebaseChatStorage.saveSesionChat(sesionAutoGuardada);
      developer.log('✅ AUTO-GUARDADO EXITOSO: ${_messages.length} mensajes');
    } catch (e) {
      developer.log('⚠️ ERROR EN AUTO-GUARDADO: $e');
      // No mostrar error al usuario en autoguardado
    }
  }

  // ========== GUARDADO RÁPIDO AL SALIR ==========

  Future<void> _guardadoRapidoAlSalir() async {
    if (_messages.isEmpty || _isEndingSession) return;

    try {
      developer.log('🚪 GUARDADO RÁPIDO AL SALIR...');

      // Usar ID existente o crear uno nuevo
      final sessionId =
          _currentSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

      // Guardado rápido sin IA
      final mensajesCifrados = await CifradoService.cifrarMensajes(
        _messages.map((m) => m.toJson()).toList(),
      );

      final sesionRapida = SesionChat(
        fecha: sessionId,
        usuario: _usuario,
        resumen: _generarResumen(),
        mensajes: mensajesCifrados.map((m) => Mensaje.fromJson(m)).toList(),
        etiquetas: _generarEtiquetas(),
        tituloDinamico: "💾 Conversación guardada", // Marcador diferente
      );

      await FirebaseChatStorage.saveSesionChat(sesionRapida);
      developer.log('✅ GUARDADO RÁPIDO EXITOSO');
    } catch (e) {
      developer.log('⚠️ ERROR EN GUARDADO RÁPIDO: $e');
    }
  }

  // ========== MÉTODOS OPTIMIZADOS ==========

  Future<void> _cargarConfiguracionPersonalizada() async {
    try {
      await _librosService.cargarLibros();

      _promptPersonalizado = _librosService.generarPromptPersonalizado(
          'Eres un asistente psicológico empático y profesional que:\n- Utiliza un tono cálido y comprensivo\n- Proporciona respuestas basadas en la psicología científica\n- Ofrece herramientas prácticas para el desarrollo emocional\n- Mantiene un enfoque ético y profesional\n- Adapta su comunicación según las necesidades del usuario\n- Utiliza la base de conocimiento de libros de psicología para fundamentar sus respuestas\n- Te diriges al usuario por su nombre cuando sea natural. El usuario se llama: $_nombreUsuario',
          '1. Siempre prioriza el bienestar emocional del usuario\n2. No proporcionar diagnósticos médicos o psicológicos\n3. Recomendar buscar ayuda profesional cuando sea necesario\n4. Mantener confidencialidad y respeto\n5. Usar lenguaje claro y accesible\n6. Basar respuestas en evidencia científica de los libros de psicología\n7. Fomentar la autoconciencia y el desarrollo personal\n8. Utilizar conceptos de inteligencia emocional de Daniel Goleman\n9. Referenciar técnicas psicológicas cuando sea apropiado\n10. Cuando sea apropiado, usa el nombre del usuario ($_nombreUsuario) para hacer la conversación más cercana y personalizada');

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
      // Usar el ID de la sesión anterior para autoguardado
      _currentSessionId = widget.sesionAnterior!.fecha;
    });

    // Iniciar autoguardado para sesiones continuadas
    _iniciarAutoSave();

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
      developer.log('👤 USUARIO CARGADO (email): $_usuario');

      // Intentar obtener nombre del estudiante desde la base de datos local
      try {
        final dbHelper = DatabaseHelper.instance;
        final estudiante = await dbHelper.getEstudianteByUID(user.uid);

        if (estudiante != null) {
          final nombre = (estudiante['nombre'] ?? '').toString().trim();
          final apellido = (estudiante['apellido'] ?? '').toString().trim();
          _sedeEstudiante = (estudiante['sede'] ?? '').toString().trim();
          _telefonoEstudiante =
              (estudiante['telefono'] ?? '').toString().trim();

          if (nombre.isNotEmpty) {
            _nombreUsuario = apellido.isNotEmpty ? '$nombre $apellido' : nombre;
          }

          developer.log('👤 NOMBRE DE USUARIO DESDE BD LOCAL: $_nombreUsuario');
          developer
              .log('🏢 SEDE DEL ESTUDIANTE (BD LOCAL): "$_sedeEstudiante"');
          developer.log('📞 TELÉFONO DEL ESTUDIANTE: $_telefonoEstudiante');
        } else {
          developer.log(
              '⚠️ Estudiante no encontrado en BD local, intentando desde Firestore...');
          // Fallback: intentar obtener desde Firestore
          try {
            final estudianteDoc = await FirebaseFirestore.instance
                .collection('estudiantes')
                .doc(user.uid)
                .get();

            if (estudianteDoc.exists) {
              final data = estudianteDoc.data()!;
              final nombre = (data['nombre'] ?? '').toString().trim();
              final apellido = (data['apellido'] ?? '').toString().trim();
              _sedeEstudiante = (data['sede'] ?? '').toString().trim();
              _telefonoEstudiante = (data['telefono'] ?? '').toString().trim();

              if (nombre.isNotEmpty) {
                _nombreUsuario =
                    apellido.isNotEmpty ? '$nombre $apellido' : nombre;
              }

              developer.log('👤 DATOS OBTENIDOS DESDE FIRESTORE:');
              developer.log('👤 NOMBRE: $_nombreUsuario');
              developer.log('🏢 SEDE: "$_sedeEstudiante"');
              developer.log('📞 TELÉFONO: $_telefonoEstudiante');
            } else {
              developer.log('⚠️ Estudiante no encontrado en Firestore tampoco');
            }
          } catch (e) {
            developer.log('⚠️ Error obteniendo estudiante desde Firestore: $e');
          }

          // Fallback final: usar parte del correo antes de la @
          if (_nombreUsuario == "Usuario" && user.email != null) {
            final emailParts = user.email!.split('@');
            if (emailParts.isNotEmpty && emailParts.first.isNotEmpty) {
              String base = emailParts.first;
              _nombreUsuario =
                  '${base[0].toUpperCase()}${base.substring(1).toLowerCase()}';
            }
          }
          developer.log('ℹ️ Usando nombre derivado del email: $_nombreUsuario');
        }
      } catch (e) {
        developer.log('⚠️ Error obteniendo nombre de usuario: $e');
      }

      // Log final de la sede
      developer.log('🏢 SEDE FINAL DEL ESTUDIANTE: "$_sedeEstudiante"');
    }
  }

  Future<void> _startSession() async {
    setState(() {
      _sessionActive = true;
      _usuario = FirebaseAuth.instance.currentUser?.email ?? "Usuario";
      // Generar nuevo ID para sesión nueva
      _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
    });

    // Iniciar autoguardado para nueva sesión
    _iniciarAutoSave();

    developer.log('🚀 SESIÓN INICIADA PARA: $_usuario');
    developer
        .log('🆕 SESIÓN INDEPENDIENTE: Sin memoria de conversaciones previas');
  }

  void _addMessage(String text) async {
    developer.log('📝 MENSAJE RECIBIDO: "$text"');
    print('📝📝📝 MENSAJE RECIBIDO: "$text" 📝📝📝');

    // PRIMERO: Agregar mensaje del usuario SIEMPRE
    setState(() {
      if (!_sessionActive) {
        _sessionActive = true; // activar sesión si aún no estaba activa
      }
      _messages.add(Mensaje(
        emisor: _nombreUsuario,
        contenido: text,
        fecha: DateTime.now().toIso8601String(),
      ));
    });

    // Respuesta directa: "¿Cómo me llamo?" / "¿Cuál es mi nombre?"
    final lower = text.toLowerCase();
    if (lower.contains('como me llamo') ||
        lower.contains('cómo me llamo') ||
        lower.contains('cual es mi nombre') ||
        lower.contains('cuál es mi nombre') ||
        lower.contains('sabes mi nombre') ||
        lower.contains('mi nombre')) {
      final nombreMostrar =
          _nombreUsuario.isNotEmpty ? _nombreUsuario : 'No lo tengo registrado';
      setState(() {
        _messages.add(Mensaje(
          emisor: "Asistente",
          contenido: nombreMostrar == 'No lo tengo registrado'
              ? 'Creo que no tengo tu nombre registrado todavía. ¿Quieres que lo guardemos para personalizar tu experiencia?'
              : 'Te llamas $nombreMostrar 🙂',
          fecha: DateTime.now().toIso8601String(),
        ));
      });
      _scrollToBottom();
      return;
    }

    // Análisis emocional con IA
    developer.log('🔍 INICIANDO ANÁLISIS EMOCIONAL para mensaje: "$text"');
    print('🔍 INICIANDO ANÁLISIS EMOCIONAL para mensaje: "$text"');
    developer
        .log('🏢 SEDE DEL ESTUDIANTE ANTES DE ANALIZAR: "$_sedeEstudiante"');
    print('🏢 SEDE DEL ESTUDIANTE ANTES DE ANALIZAR: "$_sedeEstudiante"');
    developer.log('👤 USUARIO: $_usuario');
    print('👤 USUARIO: $_usuario');
    developer.log('👤 NOMBRE: $_nombreUsuario');
    print('👤 NOMBRE: $_nombreUsuario');

    final emotion =
        await analyzeEmotion(text); // neutral | sad | stressed | high_risk
    developer.log('🔍 ANÁLISIS EMOCIONAL: "$text" → $emotion');
    print('🔍 ANÁLISIS EMOCIONAL: "$text" → $emotion');

    // Respuestas adaptativas según emoción
    if (emotion == 'high_risk') {
      developer.log(
          '🚨 HIGH_RISK DETECTADO - Mostrando mensaje de crisis INMEDIATAMENTE');
      print(
          '🚨 HIGH_RISK DETECTADO - Mostrando mensaje de crisis INMEDIATAMENTE');

      // PRIMERO: Mostrar mensaje de crisis INMEDIATAMENTE (hardcoded)
      developer.log('🏢 SEDE PARA MENSAJE DE CRISIS: "$_sedeEstudiante"');
      print('🏢 SEDE PARA MENSAJE DE CRISIS: "$_sedeEstudiante"');

      final mensajeCrisis =
          SedeContactService.generarMensajeCrisis(_sedeEstudiante);
      developer.log('📱 Mensaje de crisis generado: $mensajeCrisis');
      print('📱 Mensaje de crisis generado: $mensajeCrisis');

      setState(() {
        _messages.add(Mensaje(
          emisor: "Sistema",
          contenido: mensajeCrisis,
          fecha: DateTime.now().toIso8601String(),
        ));
      });
      _scrollToBottom();

      // SEGUNDO: SIEMPRE crear la alerta en Firestore para el admin
      // Si ya detectamos high_risk, debemos guardar la alerta sin importar qué
      developer.log('🔍 CREANDO ALERTA EN FIRESTORE PARA ADMIN...');
      print('🔍 CREANDO ALERTA EN FIRESTORE PARA ADMIN...');

      // VALIDACIÓN: Verificar que tenemos los datos necesarios
      if (_sedeEstudiante == null || _sedeEstudiante!.isEmpty) {
        developer.log('❌❌❌ ERROR: SEDE DEL ESTUDIANTE ES NULL O VACÍA ❌❌❌');
        print('❌❌❌ ERROR: SEDE DEL ESTUDIANTE ES NULL O VACÍA ❌❌❌');
        print('❌ No se puede crear la alerta sin sede');
        return; // Salir si no hay sede
      }

      if (_usuario == null || _usuario!.isEmpty || _usuario == "Usuario") {
        developer.log('❌❌❌ ERROR: USUARIO ES NULL O INVÁLIDO ❌❌❌');
        print('❌❌❌ ERROR: USUARIO ES NULL O INVÁLIDO ❌❌❌');
        print('❌ Usuario actual: "$_usuario"');
        return; // Salir si no hay usuario válido
      }

      // SedeAlertService se encargará de detectar el tipo específico y crear la alerta
      try {
        developer.log('📞 LLAMANDO A procesarMensajeParaAlerta...');
        print('📞 LLAMANDO A procesarMensajeParaAlerta...');
        print('📞 Parámetros:');
        print('   - mensaje: "$text"');
        print('   - sede: "$_sedeEstudiante"');
        print('   - usuarioEmail: "$_usuario"');
        print('   - usuarioNombre: "$_nombreUsuario"');
        print('   - usuarioTelefono: "$_telefonoEstudiante"');

        await SedeAlertService.procesarMensajeParaAlerta(
          mensaje: text,
          sede: _sedeEstudiante,
          usuarioEmail: _usuario,
          usuarioNombre: _nombreUsuario,
          usuarioTelefono: _telefonoEstudiante,
          historialMensajes: _messages
              .map((msg) => {
                    'emisor': msg.emisor,
                    'contenido': msg.contenido,
                    'fecha': msg.fecha,
                  })
              .toList(),
        );
        developer
            .log('✅✅✅ ALERTA PROCESADA Y GUARDADA EN FIRESTORE PARA ADMIN ✅✅✅');
        print('✅✅✅ ALERTA PROCESADA Y GUARDADA EN FIRESTORE PARA ADMIN ✅✅✅');
      } catch (e, stackTrace) {
        developer.log('❌❌❌ ERROR CRÍTICO AL PROCESAR ALERTA: $e ❌❌❌');
        print('❌❌❌ ERROR CRÍTICO AL PROCESAR ALERTA: $e ❌❌❌');
        developer.log('❌ Stack trace: $stackTrace');
        print('❌ Stack trace: $stackTrace');
        // Aunque falle, el mensaje de crisis ya se mostró al estudiante
      }

      // Seguimiento 1 minuto después
      _highRiskFollowUpTimer?.cancel();
      final currentSeq = _sessionSeq;
      _highRiskFollowUpTimer = Timer(const Duration(minutes: 1), () {
        if (!mounted) return;
        if (currentSeq != _sessionSeq) return; // Evitar disparo en otra sesión
        setState(() {
          _messages.add(Mensaje(
            emisor: "Asistente",
            contenido:
                "Solo quiero recordarte que no estás solo 💙. Si lo deseas, puedo ayudarte a contactar al personal de Bienestar Estudiantil.",
            fecha: DateTime.now().toIso8601String(),
          ));
        });
        _scrollToBottom();
      });

      // IMPORTANTE: NO enviar a la IA cuando hay high_risk
      return;
    } else if (emotion == 'sad' || emotion == 'stressed') {
      // Respuesta empática más cálida y contextual
      final empatica =
          getAssistantResponse(text, _nombreUsuario, emotion, null);
      setState(() {
        _messages.add(Mensaje(
          emisor: "Asistente",
          contenido: empatica.isNotEmpty
              ? empatica
              : "💙 Siento mucho que te sientas así. Tu bienestar es importante y no tienes que cargar con esto solo/a. Estoy aquí para escucharte.",
          fecha: DateTime.now().toIso8601String(),
        ));
      });
      _scrollToBottom();
      return; // Evitar enviar también una respuesta adicional en el mismo turno
    }

    // El sistema de alertas inteligente ya maneja todo en SedeAlertService
    // No necesitamos lógica adicional aquí

    // TERCERO: Si no es crisis, continuar con la IA normal
    // Bloquear envío si la IA está pensando
    if (_isThinking) {
      developer
          .log('🚫 Bloqueado: IA está pensando, no se puede enviar mensaje');
      return;
    }

    developer.log('💬 NUEVO MENSAJE DEL USUARIO: $text');

    setState(() {
      _isThinking = true;
    });

    // Auto-guardar después de mensaje del usuario (sin esperar)
    _autoGuardarSesion();

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

      // ========= INYECCIÓN DE CONOCIMIENTO DESDE LIBROS (Firebase + Locales) =========
      try {
        final fragmentosRelevantes =
            _librosService.obtenerFragmentosRelevantes(text);

        if (fragmentosRelevantes.isNotEmpty &&
            !fragmentosRelevantes.contains('No se encontraron')) {
          // Limitar longitud para no saturar la API
          final fragmentosLimitados = fragmentosRelevantes.length > 2000
              ? '${fragmentosRelevantes.substring(0, 2000)}...'
              : fragmentosRelevantes;

          messagesForGpt.add({
            "role": "system",
            "content":
                "INFORMACIÓN RELEVANTE DE LIBROS DE PSICOLOGÍA:\n\n$fragmentosLimitados\n\nUsa esta información como base teórica, pero responde de forma breve, clara y empática."
          });

          developer.log('📚 Fragmentos de libros agregados al contexto de GPT');
        } else {
          developer.log(
              'ℹ️ Sin fragmentos relevantes para esta consulta, se usa solo el prompt general');
        }
      } catch (e) {
        developer.log('⚠️ Error obteniendo fragmentos de libros: $e');
      }
      // ========= FIN INYECCIÓN DE CONOCIMIENTO =========
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
          respuesta = await GPTService.getResponse(messagesForGpt);
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

      // Auto-guardar después de respuesta de IA (sin esperar)
      _autoGuardarSesion();
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

  // ========== GUARDADO FINAL OPTIMIZADO ==========

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

      // Detener autoguardado primero
      _detenerAutoSave();

      // Guardado inmediato mientras se genera el título
      await _guardadoRapidoAlSalir();

      // Generar título IA de forma asíncrona (no bloqueante)
      String tituloDinamico;
      try {
        tituloDinamico = await TituloIAService.generarTituloConIA(_messages)
            .timeout(Duration(seconds: 5));
        developer.log('🤖 Título generado por IA al cerrar: $tituloDinamico');
      } catch (e) {
        tituloDinamico =
            "Conversación ${DateTime.now().toString().substring(0, 16)}";
        developer.log('⏰ Timeout en generación de título, usando genérico');
      }

      // Actualizar con título IA si se generó
      if (_esSesionContinuada && widget.sesionAnterior != null) {
        await _actualizarSesionExistenteConTitulo(tituloDinamico);
      } else {
        await _crearNuevaSesionConTitulo(tituloDinamico);
      }

      setState(() {
        _sessionActive = false;
        _messages.clear();
        _esSesionContinuada = false;
        _currentSessionId = null;
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
        _currentSessionId = null;
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

  // ========== MÉTODOS DE GUARDADO RÁPIDO ==========

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
      fecha: _currentSessionId ?? DateTime.now().toIso8601String(),
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

  // ========== WIDGET PRINCIPAL ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: WillPopScope(
        onWillPop: () async {
          // Auto-guardar al salir con botón de retroceso
          if (_sessionActive && _messages.isNotEmpty) {
            await _guardadoRapidoAlSalir();
          }
          return true;
        },
        child: Column(
          children: [
            // Header con gradiente
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
              padding: const EdgeInsets.only(
                  top: 60, bottom: 20, left: 16, right: 16),
              child: Column(
                children: [
                  // Fila superior con flecha y título
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                                  m.contenido.startsWith("🚨") ||
                                  m.contenido.startsWith("⚠️"))
                              .length,
                          itemBuilder: (context, index) {
                            final mensajesVisibles = _messages
                                .where((m) =>
                                    m.emisor != "Sistema" ||
                                    m.contenido.startsWith("🚨") ||
                                    m.contenido.startsWith("⚠️"))
                                .toList();
                            final msg = mensajesVisibles[index];
                            // CORRECCIÓN: El usuario es cualquiera que NO sea Sistema ni Asistente
                            final isUser = msg.emisor != "Sistema" &&
                                msg.emisor != "Asistente";

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
      ),
    );
  }

  // Resto de los métodos de UI permanecen igual...
  // [_buildHistorialSlideButton, _buildEmptyState, _buildMessageBubble,
  //  _buildInputArea, _buildStartSessionButton, _formatTime]

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
          onTap: () {},
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
              height: 160, // Ajusté para que sea totalmente circular
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
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/cerebron.png',
                    width: 120, // Ajusta tamaño según prefieras
                    height: 120,
                    fit: BoxFit.contain,
                  ),
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
                        print('🔵 ENTER PRESIONADO - Texto: "$text"');
                        if (text.trim().isNotEmpty && !_isThinking) {
                          print('🔵 LLAMANDO A _addMessage desde onSubmitted');
                          _addMessage(text.trim());
                          _controller.clear();
                        } else {
                          print(
                              '🔵 NO SE LLAMA _addMessage - vacío: ${text.trim().isEmpty}, pensando: $_isThinking');
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
                      print(
                          '🔵 BOTÓN ENVIAR PRESIONADO - Texto: "${_controller.text}"');
                      if (_controller.text.trim().isNotEmpty) {
                        print('🔵 LLAMANDO A _addMessage desde botón');
                        _addMessage(_controller.text.trim());
                        _controller.clear();
                      } else {
                        print('🔵 NO SE LLAMA _addMessage - texto vacío');
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
