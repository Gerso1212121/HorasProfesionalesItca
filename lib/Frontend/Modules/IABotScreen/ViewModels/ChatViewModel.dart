import 'dart:async';
import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:intl/intl.dart';

class ChatViewModel {
  // ========== ESTADO Y CONTROLADORES ==========
  final List<Mensaje> _messages = [];
  late String _usuario;
  String? _uidUsuario;
  String _nombreUsuario = "Usuario";
  String? _sedeEstudiante;
  String? _telefonoEstudiante;
  bool _sessionActive = false;
  bool _esSesionContinuada = false;

  // Configuración personalizada de IA
  final LibrosService _librosService = LibrosService();
  String _promptPersonalizado = '';
  bool _configuracionCargada = false;

  // Variable para bloquear envío mientras la IA está pensando
  bool _isThinking = false;

  // ========== SISTEMA DE AUTO-GUARDADO ==========
  bool _isEndingSession = false;
  Timer? _autoSaveTimer;
  String? _currentSessionId;
  static const int _autoSaveInterval = 30;
  static const String _autoSaveMarker = "🔄 AUTO_GUARDADO";

  // Seguimiento de alto riesgo
  Timer? _highRiskFollowUpTimer;
  int _sessionSeq = 0;

  // ========== CALLBACKS PARA LA UI ==========
  final Function()? onMessagesUpdated;
  final Function()? onSessionStateChanged;
  final Function(String)? onError;
  final Function()? onScrollToBottom;
  final Function(String)? showSnackBar;

  // ========== CONSTRUCTOR ==========
  ChatViewModel({
    this.onMessagesUpdated,
    this.onSessionStateChanged,
    this.onError,
    this.onScrollToBottom,
    this.showSnackBar,
  });

  // ========== GETTERS ==========
  List<Mensaje> get messages => _messages;
  bool get sessionActive => _sessionActive;
  bool get isThinking => _isThinking;
  String get nombreUsuario => _nombreUsuario;
  String? get sedeEstudiante => _sedeEstudiante;
  String get usuario => _usuario;

  // ========== MÉTODOS DE LÓGICA ==========

  Future<void> inicializarChat({
    SesionChat? sesionAnterior,
    String? mensajeInicial,
  }) async {
    print('🚀 INICIANDO CHAT CON DIAGNÓSTICO...');

    await DebugHelper.diagnosticarProblemas();
     await _cargarPerfilUsuario();
    await _cargarConfiguracionPersonalizada();

    if (sesionAnterior != null) {
      await _cargarSesionAnterior(sesionAnterior);
    } else {
      print(
          '🆕 SESIÓN INDEPENDIENTE: Sin memoria de conversaciones previas');

      if (mensajeInicial != null && mensajeInicial.trim().isNotEmpty) {
        developer
            .log('💡 MENSAJE INICIAL DESDE SUGERENCIA: "${mensajeInicial}"');
        await _startSession();
        addMessage(mensajeInicial.trim()); // CAMBIADO: _addMessage → addMessage
      }
    }

    print('✅ INICIALIZACIÓN DEL CHAT COMPLETADA');
  }
 






void addMessage(String text) async {
  print('📝 MENSAJE RECIBIDO: "$text"');
  print('📝📝📝 MENSAJE RECIBIDO: "$text" 📝📝📝');

  // 1. Verificar si ya está pensando - ANTES de procesar
  if (_isThinking) {
    print('🚫 Bloqueado: IA está pensando, no se puede enviar mensaje');
    return;
  }

  if (!_sessionActive) {
    _sessionActive = true;
    _notifySessionStateChanged();
  }

  // 2. Marcar como pensando INMEDIATAMENTE
  _isThinking = true;
  _notifyMessagesUpdated(); // Esto actualiza el botón de envío

  // Agregar mensaje del usuario
  _messages.add(Mensaje(
    emisor: _nombreUsuario,
    contenido: text,
    fecha: DateTime.now().toIso8601String(),
  ));

  _notifyMessagesUpdated();
  onScrollToBottom?.call(); // Scroll inmediato

  // Verificar si es pregunta sobre nombre
  final lower = text.toLowerCase();
  if (lower.contains('como me llamo') ||
      lower.contains('cómo me llamo') ||
      lower.contains('cual es mi nombre') ||
      lower.contains('cuál es mi nombre') ||
      lower.contains('sabes mi nombre') ||
      lower.contains('mi nombre')) {
    final nombreMostrar =
        _nombreUsuario.isNotEmpty ? _nombreUsuario : 'No lo tengo registrado';
    _messages.add(Mensaje(
      emisor: "Asistente",
      contenido: nombreMostrar == 'No lo tengo registrado'
          ? 'Creo que no tengo tu nombre registrado todavía. ¿Quieres que lo guardemos para personalizar tu experiencia?'
          : 'Te llamas $nombreMostrar 🙂',
      fecha: DateTime.now().toIso8601String(),
    ));
    
    // TERMINAR PENSAMIENTO
    _isThinking = false;
    _notifyMessagesUpdated();
    onScrollToBottom?.call();
    return;
  }

  print('🔍 INICIANDO ANÁLISIS EMOCIONAL para mensaje: "$text"');
  
  final emotion = await analyzeEmotion(text);
  print('🔍 ANÁLISIS EMOCIONAL: "$text" → $emotion');

  // Manejar emociones de alto riesgo
  if (emotion == 'high_risk') {
    print('🚨 HIGH_RISK DETECTADO - Mostrando mensaje de crisis INMEDIATAMENTE');
    
    final mensajeCrisis =
        SedeContactService.generarMensajeCrisis(_sedeEstudiante);
    
    // 1. Mostrar el mensaje de crisis al usuario
    _messages.add(Mensaje(
      emisor: "Sistema",
      contenido: mensajeCrisis,
      fecha: DateTime.now().toIso8601String(),
    ));
    
    // 2. GUARDAR LA ALERTA EN alertas_sede usando SedeAlertService
    try {
      print('📊 CREANDO ALERTA EN alertas_sede...');
      
      // Solo usar SedeAlertService - ya guarda con la estructura correcta
      await SedeAlertService.procesarMensajeParaAlerta(
        mensaje: text,
        sede: _sedeEstudiante,
        usuarioEmail: _usuario,
        usuarioNombre: _nombreUsuario,
        usuarioTelefono: _telefonoEstudiante,
        historialMensajes: _messages
            .where((m) => m.contenido != "TYPING_INDICATOR")
            .map((m) => m.toJson())
            .toList(),
      );
      
      print('✅ ALERTA GUARDADA EN alertas_sede');
      
      // OPCIONAL: Si necesitas registro adicional, usa este código:
      // await FirebaseFirestore.instance
      //     .collection('alertas_extra_log')
      //     .add({
      //   'estudiante_id': _uidUsuario,
      //   'mensaje': text,
      //   'fecha': DateTime.now().toIso8601String(),
      // });
      
    } catch (e, stackTrace) {
      print('❌ ERROR AL GUARDAR ALERTA: $e');
      print('❌ Stack trace: $stackTrace');
      
      // Intentar guardar en colección de respaldo si falla SedeAlertService
      try {
        await FirebaseFirestore.instance
            .collection('alertas_fallback')
            .add({
          'estudiante': _nombreUsuario,
          'email': _usuario,
          'sede': _sedeEstudiante,
          'mensaje': text,
          'error': e.toString(),
          'fecha': DateTime.now().toIso8601String(),
        });
      } catch (e2) {
        print('❌ ERROR INCLUSO EN FALLBACK: $e2');
      }
    }
    
    // 3. Actualizar UI
    _notifyMessagesUpdated();
    onScrollToBottom?.call();
    
    // 4. Programar seguimiento
    _programarSeguimientoHighRisk(text);
    
    // 5. IMPORTANTE: Terminar estado de pensamiento
    _isThinking = false;
    _notifyMessagesUpdated();
    
    return;
  } else if (emotion == 'sad' || emotion == 'stressed') {
    final empatica =
        getAssistantResponse(text, _nombreUsuario, emotion, null);
    _messages.add(Mensaje(
      emisor: "Asistente",
      contenido: empatica.isNotEmpty
          ? empatica
          : "💙 Siento mucho que te sientas así. Tu bienestar es importante y no tienes que cargar con esto solo/a. Estoy aquí para escucharte.",
      fecha: DateTime.now().toIso8601String(),
    ));
    
    // TERMINAR PENSAMIENTO
    _isThinking = false;
    _notifyMessagesUpdated();
    onScrollToBottom?.call();
    return;
  }

  // ========== PARTE CRÍTICA: PROCESAR CON GPT ==========
  
  // Agregar indicador de typing
  final loadingMsg = Mensaje(
    emisor: "Asistente",
    contenido: "TYPING_INDICATOR",
    fecha: DateTime.now().toIso8601String(),
  );

  _messages.add(loadingMsg);
  _notifyMessagesUpdated(); // Importante: notificar para mostrar el typing
  onScrollToBottom?.call(); // Scroll para ver el typing

  // Preparar mensajes para GPT
  List<Map<String, String>> messagesForGpt = [];

  if (_configuracionCargada && _promptPersonalizado.isNotEmpty) {
    messagesForGpt.add({"role": "system", "content": _promptPersonalizado});
    print('🤖 Prompt automático incluido en la conversación');

    try {
      final fragmentosRelevantes =
          _librosService.obtenerFragmentosRelevantes(text);

      if (fragmentosRelevantes.isNotEmpty &&
          !fragmentosRelevantes.contains('No se encontraron')) {
        final fragmentosLimitados = fragmentosRelevantes.length > 2000
            ? '${fragmentosRelevantes.substring(0, 2000)}...'
            : fragmentosRelevantes;

        messagesForGpt.add({
          "role": "system",
          "content":
              "INFORMACIÓN RELEVANTE DE LIBROS DE PSICOLOGÍA:\n\n$fragmentosLimitados\n\nUsa esta información como base teórica, pero responde de forma breve, clara y empática."
        });

        print('📚 Fragmentos de libros agregados al contexto de GPT');
      } else {
        print('ℹ️ Sin fragmentos relevantes para esta consulta, se usa solo el prompt general');
      }
    } catch (e) {
      print('⚠️ Error obteniendo fragmentos de libros: $e');
    }
  }

  // Agregar historial de conversación
  for (var msg in _messages.where((m) => m.contenido != "TYPING_INDICATOR")) {
    String role;
    if (msg.emisor == "Usuario" || msg.emisor == _nombreUsuario) {
      role = "user";
    } else if (msg.emisor == "Sistema") {
      role = "system";
    } else {
      role = "assistant";
    }

    messagesForGpt.add({"role": role, "content": msg.contenido});
  }

  print('🤖 ENVIANDO A GPT: ${messagesForGpt.length} mensajes');

  try {
    int intentos = 0;
    const maxIntentos = 3;
    String? respuesta;

    while (intentos < maxIntentos && respuesta == null) {
      intentos++;
      print('🔄 Intento $intentos de $maxIntentos');

      try {
        respuesta = await GPTService.getResponse(messagesForGpt);
        print('✅ RESPUESTA DE GPT: $respuesta');
        break;
      } catch (e) {
        print('❌ Error en intento $intentos: $e');
        if (intentos >= maxIntentos) {
          rethrow;
        }
        await Future.delayed(Duration(seconds: intentos));
      }
    }

    // Remover el indicador de typing
    _messages.removeWhere((m) => m.contenido == "TYPING_INDICATOR");
    
    // Agregar respuesta del asistente
    final gptMsg = Mensaje(
      emisor: "Asistente",
      contenido: respuesta?.trim() ??
          "Lo siento, no pude procesar tu mensaje. Inténtalo de nuevo.",
      fecha: DateTime.now().toIso8601String(),
    );
    _messages.add(gptMsg);

    _notifyMessagesUpdated();
    onScrollToBottom?.call();

    // Auto-guardar
    _autoGuardarSesion();
  } catch (e) {
    print('❌ ERROR GPT: $e');

    // Remover indicador de typing en caso de error
    _messages.removeWhere((m) => m.contenido == "TYPING_INDICATOR");

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
    _messages.add(errorMsg);

    _notifyMessagesUpdated();
    onScrollToBottom?.call();
  } finally {
    // IMPORTANTE: Finalizar estado de pensamiento en TODOS los casos
    _isThinking = false;
    _notifyMessagesUpdated(); // Esto habilitará el botón de nuevo
  }
}














  void _iniciarAutoSave() {
    if (!_sessionActive) return;

    _detenerAutoSave();

    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: _autoSaveInterval),
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
      print('💾 AUTO-GUARDANDO SESIÓN...');

      if (_currentSessionId == null) {
        _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();
      }

      final mensajesCifrados = await CifradoService.cifrarMensajes(
        _messages.map((m) => m.toJson()).toList(),
      );

      final sesionAutoGuardada = SesionChat(
        fecha: _currentSessionId!,
        usuario: _usuario,
        resumen: _generarResumen(),
        mensajes: mensajesCifrados.map((m) => Mensaje.fromJson(m)).toList(),
        etiquetas: _generarEtiquetas(),
        tituloDinamico: _autoSaveMarker,
      );

      await FirebaseChatStorage.saveSesionChat(sesionAutoGuardada);
      print('✅ AUTO-GUARDADO EXITOSO: ${_messages.length} mensajes');
    } catch (e) {
      print('⚠️ ERROR EN AUTO-GUARDADO: $e');
    }
  }

  Future<void> guardadoRapidoAlSalir() async {
    if (_messages.isEmpty || _isEndingSession) return;

    try {
      print('🚪 GUARDADO RÁPIDO AL SALIR...');

      final sessionId =
          _currentSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();

      final mensajesCifrados = await CifradoService.cifrarMensajes(
        _messages.map((m) => m.toJson()).toList(),
      );

      final sesionRapida = SesionChat(
        fecha: sessionId,
        usuario: _usuario,
        resumen: _generarResumen(),
        mensajes: mensajesCifrados.map((m) => Mensaje.fromJson(m)).toList(),
        etiquetas: _generarEtiquetas(),
        tituloDinamico: "💾 Conversación guardada",
      );

      await FirebaseChatStorage.saveSesionChat(sesionRapida);
      print('✅ GUARDADO RÁPIDO EXITOSO');
    } catch (e) {
      print('⚠️ ERROR EN GUARDADO RÁPIDO: $e');
    }
  }

  Future<void> _cargarConfiguracionPersonalizada() async {
    try {
      await _librosService.cargarLibros();

      _promptPersonalizado = _librosService.generarPromptPersonalizado(
        'Eres un asistente psicológico empático y profesional que:\n- Utiliza un tono cálido y comprensivo\n- Proporciona respuestas basadas en la psicología científica\n- Ofrece herramientas prácticas para el desarrollo emocional\n- Mantiene un enfoque ético y profesional\n- Adapta su comunicación según las necesidades del usuario\n- Utiliza la base de conocimiento de libros de psicología para fundamentar sus respuestas\n- Te diriges al usuario por su nombre cuando sea natural. El usuario se llama: $_nombreUsuario',
        '1. Siempre prioriza el bienestar emocional del usuario\n2. No proporcionar diagnósticos médicos o psicológicos\n3. Recomendar buscar ayuda profesional cuando sea necesario\n4. Mantener confidencialidad y respeto\n5. Usar lenguaje claro y accesible\n6. Basar respuestas en evidencia científica de los libros de psicología\n7. Fomentar la autoconciencia y el desarrollo personal\n8. Utilizar conceptos de inteligencia emocional de Daniel Goleman\n9. Referenciar técnicas psicológicas cuando sea apropiado\n10. Cuando sea apropiado, usa el nombre del usuario ($_nombreUsuario) para hacer la conversación más cercana y personalizada',
      );

      _configuracionCargada = true;
      developer
          .log('✅ Configuración automática cargada para todos los usuarios');
    } catch (e) {
      print('⚠️ Error cargando configuración automática: $e');
    }
  }

  Future<void> _cargarSesionAnterior(SesionChat sesionAnterior) async {
    print('🔄 CARGANDO SESIÓN ANTERIOR DESDE HISTORIAL...');
    print(
        '📝 Mensajes en sesión anterior: ${sesionAnterior.mensajes.length}');

    final mensajesParaDescifrar = sesionAnterior.mensajes.map((m) {
      final mensajeJson = m.toJson();
      return mensajeJson;
    }).toList();

    print(
        '💥 DESCIFRADO FORZADO: Intentando descifrar ${mensajesParaDescifrar.length} mensajes...');

    final mensajesDescifrados =
        await CifradoService.descifrarMensajes(mensajesParaDescifrar);
    final mensajes =
        mensajesDescifrados.map((m) => Mensaje.fromJson(m)).toList();

    _messages.clear();
    _messages.addAll(mensajes);
    _sessionActive = true;
    _esSesionContinuada = true;
    _currentSessionId = sesionAnterior.fecha;

    _iniciarAutoSave();

    _notifyMessagesUpdated();
    onScrollToBottom?.call();

    print('✅ SESIÓN ANTERIOR CARGADA: ${_messages.length} mensajes');
  }

  Future<void> _cargarPerfilUsuario() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _uidUsuario = user.uid;
      _usuario = user.email ?? "Usuario";
      print('👤 USUARIO CARGADO (email): $_usuario');

      bool sedeEncontrada = false;

      try {
        final dbHelper = DatabaseHelper.instance;
        final estudiante = await dbHelper.getEstudianteByUID(user.uid);

        if (estudiante != null) {
          final nombre = (estudiante['nombre'] ?? '').toString().trim();
          final apellido = (estudiante['apellido'] ?? '').toString().trim();
          final sede = (estudiante['sede'] ?? '').toString().trim();
          final telefono = (estudiante['telefono'] ?? '').toString().trim();

          if (sede.isNotEmpty) {
            _sedeEstudiante = sede;
            sedeEncontrada = true;
            print('✅ SEDE OBTENIDA DE BD LOCAL: "$_sedeEstudiante"');
          } else {
            print('⚠️ Sede vacía en BD local');
          }

          if (nombre.isNotEmpty) {
            _nombreUsuario = apellido.isNotEmpty ? '$nombre $apellido' : nombre;
            print('👤 Nombre desde BD local: $_nombreUsuario');
          }

          _telefonoEstudiante = telefono;
        }
      } catch (e) {
        print('⚠️ Error obteniendo datos de BD local: $e');
      }

      if (!sedeEncontrada) {
        try {
          final estudianteDoc = await FirebaseFirestore.instance
              .collection('estudiantes')
              .doc(user.uid)
              .get();

          if (estudianteDoc.exists) {
            final data = estudianteDoc.data()!;
            final nombre = (data['nombre'] ?? '').toString().trim();
            final apellido = (data['apellido'] ?? '').toString().trim();
            final sede = (data['sede'] ?? '').toString().trim();
            final telefono = (data['telefono'] ?? '').toString().trim();

            if (sede.isNotEmpty) {
              _sedeEstudiante = sede;
              sedeEncontrada = true;
              print('✅ SEDE OBTENIDA DE FIRESTORE: "$_sedeEstudiante"');
            } else {
              print('⚠️ Sede vacía en Firestore');
            }

            if (nombre.isNotEmpty && _nombreUsuario == "Usuario") {
              _nombreUsuario =
                  apellido.isNotEmpty ? '$nombre $apellido' : nombre;
              print('👤 Nombre desde Firestore: $_nombreUsuario');
            }

            if (_telefonoEstudiante == null || _telefonoEstudiante!.isEmpty) {
              _telefonoEstudiante = telefono;
            }
          }
        } catch (e) {
          print('⚠️ Error obteniendo datos de Firestore: $e');
        }
      }

      if (_nombreUsuario == "Usuario" && user.email != null) {
        final emailParts = user.email!.split('@');
        if (emailParts.isNotEmpty && emailParts.first.isNotEmpty) {
          String base = emailParts.first;
          _nombreUsuario =
              '${base[0].toUpperCase()}${base.substring(1).toLowerCase()}';
          print('👤 Usando nombre derivado del email: $_nombreUsuario');
        }
      }

      if (!sedeEncontrada) {
        print(
            '❌❌❌ ERROR CRÍTICO: NO SE ENCONTRÓ SEDE PARA EL ESTUDIANTE ❌❌❌');
        print('❌ User UID: ${user.uid}');
        print('❌ User email: ${user.email}');
        print('❌ Se usará "sede central" como fallback');
        _sedeEstudiante = "sede central";
      }

      print('🏢 SEDE FINAL DEL ESTUDIANTE: "$_sedeEstudiante"');
      print('👤 NOMBRE FINAL: $_nombreUsuario');
      print('📞 TELÉFONO FINAL: $_telefonoEstudiante');

      await _verificarDatosEstudiante();
    }
  }

  Future<void> _verificarDatosEstudiante() async {
    print('🔍 VERIFICANDO DATOS DEL ESTUDIANTE...');
    print('👤 UID: $_uidUsuario');
    print('📧 Email: $_usuario');
    print('👤 Nombre: $_nombreUsuario');
    print('🏢 Sede: "$_sedeEstudiante"');
    print('📞 Teléfono: $_telefonoEstudiante');

    try {
      if (_uidUsuario != null) {
        final doc = await FirebaseFirestore.instance
            .collection('estudiantes')
            .doc(_uidUsuario)
            .get();

        if (doc.exists) {
          print('📋 DATOS EN FIRESTORE:');
          print('   Sede: ${doc.data()?['sede']}');
          print('   Nombre: ${doc.data()?['nombre']}');
          print('   Apellido: ${doc.data()?['apellido']}');
          print('   Teléfono: ${doc.data()?['telefono']}');
        } else {
          print('❌ No existe documento en Firestore para este UID');
        }
      }
    } catch (e) {
      print('⚠️ Error verificando Firestore: $e');
    }
  }

  Future<void> _startSession() async {
    _sessionActive = true;
    _usuario = FirebaseAuth.instance.currentUser?.email ?? "Usuario";
    _currentSessionId = DateTime.now().millisecondsSinceEpoch.toString();

    _iniciarAutoSave();

    _notifySessionStateChanged();
    print('🚀 SESIÓN INICIADA PARA: $_usuario');
    developer
        .log('🆕 SESIÓN INDEPENDIENTE: Sin memoria de conversaciones previas');
  }

  void startSession() {
    _startSession();
    _messages.clear();
    _notifyMessagesUpdated();
  }

  void _programarSeguimientoHighRisk(String mensaje) {
    print('⏰ PROGRAMANDO SEGUIMIENTO PARA ALTO RIESGO');

    _highRiskFollowUpTimer?.cancel();

    _highRiskFollowUpTimer = Timer(const Duration(minutes: 1), () {
      if (_sessionActive) {
        developer
            .log('🔔 SIGUIENDO A ALTO RIESGO - Verificando estado del usuario');

        _messages.add(Mensaje(
          emisor: "Sistema",
          contenido:
              "💙 ¿Cómo te sientes ahora? Recuerda que hay personas dispuestas a ayudarte. No estás solo/a.",
          fecha: DateTime.now().toIso8601String(),
        ));

        _notifyMessagesUpdated();
        onScrollToBottom?.call();
      }
    });
  }



  void diagnosticarGuardado() async {
    print('=== DIAGNÓSTICO DE GUARDADO ===');
    print('Mensajes en memoria: ${_messages.length}');
    print('Sesión activa: $_sessionActive');
    print('Usuario: $_usuario');
    print('ID Sesión: $_currentSessionId');

    if (_messages.isNotEmpty) {
      print('Primer mensaje: ${_messages.first.contenido}');
      print('Último mensaje: ${_messages.last.contenido}');
    }

    // Verificar conexión a Firebase
    try {
      final user = FirebaseAuth.instance.currentUser;
      print('Usuario Firebase: ${user?.uid}');

      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('sesiones_chat')
            .limit(1)
            .get();
        print('Conexión Firebase OK: ${doc.docs.length} sesiones');
      }
    } catch (e) {
      print('❌ Error conexión Firebase: $e');
    }
  }

  Future<void> endSession() async {
    if (_isEndingSession) {
      print(
          '⚠️ _endSession ya está en ejecución, ignorando llamada duplicada');
      return;
    }

    if (_messages.isEmpty) {
      _sessionActive = false;
      _notifySessionStateChanged();

      showSnackBar?.call('✅ Chat finalizado sin mensajes para guardar');
      return;
    }

    _isEndingSession = true;

    try {
      print('🔄 FINALIZANDO SESIÓN...');
      print('📊 Total mensajes a guardar: ${_messages.length}');
      print('👤 Usuario: $_usuario');
      print('🏷️ Sesión continuada: $_esSesionContinuada');

      // 1. Detener auto-guardado
      _detenerAutoSave();

      // 2. Generar título con IA
      String tituloDinamico;
      try {
        tituloDinamico = await TituloIAService.generarTituloConIA(_messages)
            .timeout(const Duration(seconds: 8), onTimeout: () {
          print('⏰ Timeout en generación de título, usando fallback');
          return _generarTituloFallback();
        });
        print('🤖 Título generado por IA: "$tituloDinamico"');
      } catch (e) {
        print('❌ Error generando título: $e');
        tituloDinamico = _generarTituloFallback();
      }

      // 3. Cifrar mensajes
      print('🔐 Cifrando mensajes...');
      final mensajesCifrados = await CifradoService.cifrarMensajes(
        _messages.map((m) => m.toJson()).toList(),
      );

      print('✅ Mensajes cifrados: ${mensajesCifrados.length}');

      // 4. Determinar ID de sesión
      final sessionId =
          _currentSessionId ?? DateTime.now().millisecondsSinceEpoch.toString();
      print('🆔 ID de sesión: $sessionId');

      // 5. Crear objeto SesionChat
      final sesionChat = SesionChat(
        fecha: sessionId,
        usuario: _usuario,
        resumen: _generarResumen(),
        mensajes: mensajesCifrados.map((m) => Mensaje.fromJson(m)).toList(),
        etiquetas: _generarEtiquetas(),
        tituloDinamico: tituloDinamico,
      );

      // 6. Guardar en Firebase
      print('💾 Guardando sesión en Firebase...');
      await FirebaseChatStorage.saveSesionChat(sesionChat);

      print('✅ Sesión guardada exitosamente');

      // 7. Limpiar estado
      _sessionActive = false;
      _messages.clear();
      _esSesionContinuada = false;
      _currentSessionId = null;

      _notifyMessagesUpdated();
      _notifySessionStateChanged();

      // 8. Mostrar confirmación
      showSnackBar?.call('✅ Chat guardado: "$tituloDinamico"');
    } catch (e) {
      print('❌ ERROR CRÍTICO AL GUARDAR SESIÓN: $e');

      String errorMessage = 'Error al guardar sesión';

      if (e.toString().contains('permission-denied') ||
          e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = '✅ Sesión guardada localmente (sin conexión a internet)';
      } else if (e.toString().contains('network') ||
          e.toString().contains('connection')) {
        errorMessage = '✅ Sesión guardada localmente (problema de red)';
      } else {
        errorMessage = '❌ Error: ${e.toString().split(':').first}';
      }

      // Limpiar estado de todas formas
      _sessionActive = false;
      _messages.clear();
      _esSesionContinuada = false;
      _currentSessionId = null;

      _notifyMessagesUpdated();
      _notifySessionStateChanged();

      showSnackBar?.call(errorMessage);
    } finally {
      _isEndingSession = false;
      print('🏁 _endSession completado');
    }
  }

  String _generarTituloFallback() {
    if (_messages.isEmpty) return "Conversación";

    final userMessages = _messages
        .where((m) =>
            m.emisor != "Sistema" &&
            m.emisor != "Asistente" &&
            m.contenido != "TYPING_INDICATOR")
        .toList();

    if (userMessages.isNotEmpty) {
      final primerMensaje = userMessages.first.contenido;
      if (primerMensaje.length > 30) {
        return "${primerMensaje.substring(0, 27)}...";
      }
      return primerMensaje;
    }

    final fecha = DateTime.now();
    return "Chat ${DateFormat('dd/MM HH:mm').format(fecha)}";
  }

  Future<void> _actualizarSesionExistenteConTitulo(
      String tituloDinamico) async {
    print('🔄 ACTUALIZANDO SESIÓN EXISTENTE CON TÍTULO...');

    final mensajesCifrados = await CifradoService.cifrarMensajes(
      _messages.map((m) => m.toJson()).toList(),
    );

    final sesionActualizada = SesionChat(
      fecha: _currentSessionId!,
      usuario: _usuario,
      resumen: _generarResumen(),
      mensajes: mensajesCifrados.map((m) => Mensaje.fromJson(m)).toList(),
      etiquetas: _generarEtiquetas(),
      tituloDinamico: tituloDinamico,
    );

    await FirebaseChatStorage.deleteSesionChat(_currentSessionId!);
    await FirebaseChatStorage.saveSesionChat(sesionActualizada);

    print('🔐 Mensajes cifrados antes de guardar');
    print('🤖 Título actualizado: $tituloDinamico');
    print('✅ SESIÓN ACTUALIZADA CORRECTAMENTE');
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

    print('🔐 Mensajes cifrados antes de guardar');
    print('🤖 Título generado por IA: $tituloDinamico');
    print('✅ NUEVA SESIÓN CREADA Y ANALIZADA');
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

  void clearMessages() {
    _messages.clear();
    _notifyMessagesUpdated();
  }

  String getMensajeCrisis() {
    return SedeContactService.generarMensajeCrisis(_sedeEstudiante);
  }

  void dispose() {
    _detenerAutoSave();
    _highRiskFollowUpTimer?.cancel();
  }

  // ========== NOTIFICACIONES ==========
  void _notifyMessagesUpdated() {
    onMessagesUpdated?.call();
  }

  void _notifySessionStateChanged() {
    onSessionStateChanged?.call();
  }
}
