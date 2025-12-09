import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horas2/Backend/Data/API/GPTService.dart';

class SedeAlertService {
  // Mapa de correos de administradores por sede
  static const Map<String, String> _adminEmailsPorSede = {
    'san miguel': 'sanmiguel@admin.com',
    'la unión': 'launion@admin.com',
    'zacatecoluca': 'zacatecoluca@admin.com',
    'sede central': 'sedecentral@admin.com',
    'santa tecla': 'sedecentral@admin.com', // Mismo que sede central
  };

  // Mapa de sedes que administra cada email real de Supabase
  // Este mapa relaciona el email REAL del administrador con la sede que administra
  static const Map<String, String> _sedesPorAdminReal = {
    'sanmiguel@admin.com': 'san miguel',
    'launion@admin.com': 'la unión',
    'zacatecoluca@admin.com': 'zacatecoluca',
    'sedecentral@admin.com': 'sede central',
    // Agregar aquí los emails reales de los administradores cuando se conozcan
    // Ejemplo: 'admin123@ejemplo.com': 'san miguel',
  };

  /// Normaliza el nombre de la sede
  static String normalizarSede(String sede) {
    String normalizada = sede.toLowerCase().trim();

    switch (normalizada) {
      case 'san miguel':
        return 'san miguel';
      case 'la unión':
      case 'la union':
        return 'la unión';
      case 'zacatecoluca':
      case 'zacate coluca':
        return 'zacatecoluca';
      case 'santa tecla':
        return 'santa tecla';
      case 'sede central':
        return 'sede central';
      default:
        return normalizada;
    }
  }

  /// Obtiene la sede que administra un email específico
  static String? getSedePorAdminEmail(String adminEmail) {
    // Primero intentar con el email tal cual está
    String? sede = _sedesPorAdminReal[adminEmail.toLowerCase()];
    if (sede != null) return sede;

    // Si no se encuentra, intentar buscar en el mapa inverso
    for (var entry in _adminEmailsPorSede.entries) {
      if (entry.value.toLowerCase() == adminEmail.toLowerCase()) {
        return entry.key;
      }
    }

    return null;
  }

  /// Obtiene el correo del administrador para una sede específica
  static String? getAdminEmailPorSede(String? sede) {
    if (sede == null || sede.isEmpty) {
      return null;
    }

    String sedeNormalizada = normalizarSede(sede);
    return _adminEmailsPorSede[sedeNormalizada];
  }

  /// Usa IA para evaluar si un mensaje contiene abuso sexual
  static Future<bool> _evaluarAbusoSexualConIA(String mensaje) async {
    try {
      final prompt = '''
Eres un experto en psicología y seguridad estudiantil. Evalúa si el siguiente mensaje de un estudiante contiene intenciones de abuso sexual o agresión sexual.

IMPORTANTE: 
- Masturbación o actividad sexual personal NO es abuso sexual
- Actividades normales (tocar objetos, instrumentos, etc.) NO es abuso sexual
- Bromas o expresiones coloquiales NO son abuso sexual
- PERO considera abuso sexual cuando hay intención de agredir sexualmente a OTRA persona
- Incluye violación, acoso sexual, tocamientos no consentidos, o expresiones de querer forzar actos sexuales
- Ejemplos que SÍ son abuso sexual: "quiero violar a [persona]", "voy a tocar a [alguien] sin permiso", "me dan ganas de forzar a [persona]", "quiero abusar de [alguien]", "voy a violar a mi amiga", "quiero tocar a [persona] sin consentimiento", "quiero violar a X", "voy a violar a [nombre]", "necesito violar a alguien"
- Cualquier expresión de querer tener relaciones sexuales forzadas con otra persona ES abuso sexual
- Cualquier mención de violación, abuso sexual, o agresión sexual hacia otra persona ES abuso sexual

Mensaje a evaluar: "$mensaje"

Responde ÚNICAMENTE con:
- "SI" si el mensaje contiene intenciones de abuso sexual o agresión sexual hacia otras personas
- "NO" si el mensaje NO contiene abuso sexual (incluye masturbación, actividades normales, bromas, etc.)

Respuesta:''';

      final response = await _llamarOpenAI(prompt);
      final respuesta = response.toLowerCase().trim();

      developer.log('🤖 IA evaluó abuso sexual: "$mensaje" → $respuesta');
      return respuesta == 'si';
    } catch (e) {
      developer.log('❌ Error evaluando abuso sexual con IA: $e');
      return false; // En caso de error, no generar alerta
    }
  }

  /// Usa IA para evaluar si un mensaje contiene intenciones de violencia
  static Future<bool> _evaluarViolenciaConIA(String mensaje) async {
    try {
      final prompt = '''
Eres un experto en psicología y seguridad estudiantil. Evalúa si el siguiente mensaje de un estudiante contiene intenciones de violencia hacia otras personas.

IMPORTANTE: 
- Expresar frustración o enojo NO es violencia
- Hablar de violencia en general (películas, noticias, etc.) NO es violencia
- Bromas o expresiones coloquiales NO son violencia
- Videojuegos, Minecraft, zombies, monstruos, enemigos virtuales NO son violencia real
- PERO considera violencia cuando hay intención clara de hacer daño a OTRA PERSONA REAL
- Ejemplos que SÍ son violencia: "quiero matar a [persona real]", "voy a golpear a [alguien real]", "me dan ganas de lastimar a [persona real]"
- Ejemplos que NO son violencia: "quiero matar zombies", "quiero matar monstruos", "quiero matar enemigos", "quiero matar en el juego", "quiero matar más" (en contexto de videojuegos)
- Cualquier expresión de querer matar, golpear, lastimar o hacer daño a OTRA PERSONA REAL ES violencia

Mensaje a evaluar: "$mensaje"

Responde ÚNICAMENTE con:
- "SI" si el mensaje contiene intenciones de violencia hacia otras personas REALES
- "NO" si el mensaje NO contiene violencia (incluye frustración, bromas, videojuegos, etc.)

Respuesta:''';

      final response = await _llamarOpenAI(prompt);
      final respuesta = response.toLowerCase().trim();

      developer.log('🤖 IA evaluó violencia: "$mensaje" → $respuesta');
      return respuesta == 'si';
    } catch (e) {
      developer.log('❌ Error evaluando violencia con IA: $e');
      return false; // En caso de error, no generar alerta
    }
  }

  /// Usa IA para evaluar si un mensaje contiene signos de depresión severa
  static Future<bool> _evaluarDepresionConIA(String mensaje) async {
    try {
      final prompt = '''
Eres un experto en psicología y seguridad estudiantil. Evalúa si el siguiente mensaje de un estudiante contiene signos de depresión SEVERA que requieren atención profesional inmediata.

IMPORTANTE: 
- Tristeza normal o mal humor NO es depresión severa
- Expresar cansancio o estrés NO es depresión severa
- Frustración por juegos, exámenes, o problemas menores NO es depresión severa
- Solo considera depresión severa cuando hay signos claros de desesperanza profunda, autodesprecio extremo, o ideación suicida real
- Frases como "me siento triste", "estoy cansado", "estoy mal por algo" NO son depresión severa
- Ejemplos de depresión severa: "no valgo nada", "mi vida no tiene sentido", "soy un fracaso total", "nadie me quiere", "quiero desaparecer"
- Ejemplos que NO son depresión severa: "estoy triste", "me siento mal", "estoy deprimido por [algo específico]", "me siento mal por perder mi juego"

Mensaje a evaluar: "$mensaje"

Responde ÚNICAMENTE con:
- "SI" si el mensaje contiene signos de depresión SEVERA que requieren atención profesional inmediata
- "NO" si el mensaje NO contiene depresión severa (incluye tristeza normal, estrés, frustración, etc.)

Respuesta:''';

      final response = await _llamarOpenAI(prompt);
      final respuesta = response.toLowerCase().trim();

      developer.log('🤖 IA evaluó depresión: "$mensaje" → $respuesta');
      return respuesta == 'si';
    } catch (e) {
      developer.log('❌ Error evaluando depresión con IA: $e');
      return false; // En caso de error, no generar alerta
    }
  }

  /// Usa IA para evaluar si un mensaje contiene intenciones de suicidio
  static Future<bool> _evaluarSuicidioConIA(String mensaje) async {
    try {
      final prompt = '''
Eres un experto en psicología y seguridad estudiantil. Evalúa si el siguiente mensaje de un estudiante contiene intenciones REALES de suicidio o autolesión hacia SÍ MISMO.

IMPORTANTE: 
- Expresar tristeza o desánimo NO es intención de suicidio
- Hablar de muerte en general NO es intención de suicidio
- Bromas sobre muerte NO son intención de suicidio
- Expresiones coloquiales como "me voy a morir" por algo trivial (juegos, exámenes, etc.) NO son suicidio
- "Quiero matar" sin especificar a quién NO es suicidio (es violencia hacia otros)
- Solo considera suicidio cuando hay intención clara, específica y REAL de hacerse daño a SÍ MISMO
- Ejemplos de suicidio REAL: "me voy a matar", "quiero suicidarme", "me voy a quitar la vida", "quiero acabar conmigo", "tengo un plan para matarme"
- Ejemplos que NO son suicidio: "quiero matar", "voy a matar", "necesito matar a alguien", "me voy a morir" (por algo trivial), "me quiero morir" (por frustración)

Mensaje a evaluar: "$mensaje"

Responde ÚNICAMENTE con:
- "SI" si el mensaje contiene intenciones REALES y específicas de suicidio o autolesión hacia SÍ MISMO
- "NO" si el mensaje NO contiene intención real de suicidio (incluye tristeza, bromas, expresiones coloquiales, violencia hacia otros, etc.)

Respuesta:''';

      final response = await _llamarOpenAI(prompt);
      final respuesta = response.toLowerCase().trim();

      developer.log('🤖 IA evaluó suicidio: "$mensaje" → $respuesta');
      return respuesta == 'si';
    } catch (e) {
      developer.log('❌ Error evaluando suicidio con IA: $e');
      return false; // En caso de error, no generar alerta
    }
  }

  /// Llama a OpenAI para evaluación
  static Future<String> _llamarOpenAI(String prompt) async {
    try {
      // Importar el servicio de GPT existente
      final response = await GPTService.getResponse([
        {"role": "user", "content": prompt}
      ]);
      return response.trim();
    } catch (e) {
      developer.log('❌ Error llamando a OpenAI: $e');
      return "NO"; // En caso de error, no generar alerta
    }
  }

  /// Usa IA para detectar si el mensaje está en contexto de videojuegos
  static Future<bool> _esContextoVideojuegosConIA(String mensaje) async {
    try {
      final prompt = '''
Eres un experto en psicología y seguridad estudiantil. Evalúa si el siguiente mensaje está en contexto de videojuegos o entretenimiento virtual.

IMPORTANTE: 
- Si el mensaje menciona videojuegos, juegos, entretenimiento virtual, o actividades de ocio NO es una situación real de riesgo
- Expresiones como "matar zombies", "matar enemigos", "matar en el juego" NO son violencia real
- Frases como "me voy a morir" por perder en un juego NO son suicidio real
- Cualquier expresión relacionada con videojuegos, juegos, entretenimiento, o actividades virtuales NO requiere alerta
- IMPORTANTE: Si el mensaje es ambiguo (ej: "quiero matar") y NO menciona juegos explícitamente, asume que NO es videojuego (es mejor prevenir)

Mensaje a evaluar: "$mensaje"

Responde ÚNICAMENTE con:
- "SI" si el mensaje está en contexto de videojuegos o entretenimiento virtual
- "NO" si el mensaje NO está en contexto de videojuegos (es una situación real)

Respuesta:''';

      final response = await _llamarOpenAI(prompt);
      final respuesta = response.toLowerCase().trim();

      developer
          .log('🎮 IA evaluó contexto videojuegos: "$mensaje" → $respuesta');
      // Solo considerar videojuego si la respuesta es explícitamente "si"
      return respuesta == 'si';
    } catch (e) {
      developer.log('❌ Error evaluando contexto videojuegos con IA: $e');
      return false; // En caso de error, no bloquear alertas
    }
  }

  /// Detecta el tipo de alerta con prioridad específica (evita duplicados) - PÚBLICO
  static Future<List<String>> detectarTiposAlerta(String mensaje) async {
    final tiposAlerta = <String>[];

    // PRIMERO: Verificar si es contexto de videojuegos usando IA
    final esVideojuegos = await _esContextoVideojuegosConIA(mensaje);
    if (esVideojuegos) {
      developer.log(
          '🎮 Contexto de videojuegos detectado por IA - NO evaluando alertas');
      return tiposAlerta; // No generar alertas en contexto de videojuegos
    }

    // Evaluar en orden de prioridad para evitar duplicados
    // 1. PRIMERO: Violencia hacia otros (más específico)
    final esViolencia = await _evaluarViolenciaConIA(mensaje);
    if (esViolencia) {
      tiposAlerta.add('violencia');
      return tiposAlerta; // Si es violencia, no evaluar otros tipos
    }

    // 2. SEGUNDO: Abuso sexual hacia otros (más específico)
    final esAbusoSexual = await _evaluarAbusoSexualConIA(mensaje);
    if (esAbusoSexual) {
      tiposAlerta.add('abuso_sexual');
      return tiposAlerta; // Si es abuso sexual, no evaluar otros tipos
    }

    // 3. TERCERO: Suicidio/autolesión (hacia sí mismo)
    final esSuicidio = await _evaluarSuicidioConIA(mensaje);
    if (esSuicidio) {
      tiposAlerta.add('suicidio');
      return tiposAlerta; // Si es suicidio, no evaluar depresión
    }

    // 4. CUARTO: Depresión severa (solo si no es ninguno de los anteriores)
    final esDepresion = await _evaluarDepresionConIA(mensaje);
    if (esDepresion) {
      tiposAlerta.add('depresion');
    }

    return tiposAlerta;
  }

  /// Crea una alerta en Firestore
  static Future<void> crearAlerta({
    required String mensaje,
    required String? sede,
    required String tipoAlerta,
    required String usuarioEmail,
    required String usuarioNombre,
    String? usuarioTelefono,
  }) async {
    try {
      developer.log('🔍 ========== CREAR ALERTA ==========');
      developer.log('🔍 Sede recibida: "$sede"');
      developer.log('🔍 Tipo de alerta: "$tipoAlerta"');
      developer.log('🔍 Usuario email: "$usuarioEmail"');
      developer.log('🔍 Usuario nombre: "$usuarioNombre"');

      // Normalizar la sede antes de buscar el admin
      final sedeNormalizada =
          sede != null && sede.isNotEmpty ? normalizarSede(sede) : null;
      developer.log('🔍 Sede normalizada: "$sedeNormalizada"');

      final adminEmail = getAdminEmailPorSede(sedeNormalizada);
      developer.log('🔍 Admin email encontrado: "$adminEmail"');

      if (adminEmail == null) {
        developer.log(
            '❌ ERROR: No se encontró administrador para la sede: "$sede" (normalizada: "$sedeNormalizada")');
        developer.log(
            '🔍 Sedes disponibles en mapa: ${_adminEmailsPorSede.keys.toList()}');
        throw Exception('No se encontró administrador para la sede: $sede');
      }

      final alerta = {
        'fecha': DateTime.now().toIso8601String(),
        'sede': sedeNormalizada ?? 'Sin sede',
        'tipo_alerta': tipoAlerta,
        'usuario_email': usuarioEmail,
        'usuario_nombre': usuarioNombre,
        'usuario_telefono': usuarioTelefono ?? 'No disponible',
        'admin_email': adminEmail,
        'estado': 'pendiente',
        'leida': false,
        'mensaje_original': mensaje,
        'resumen': _generarResumenAlerta(mensaje, tipoAlerta),
      };

      developer.log('📝 Intentando crear alerta en Firestore...');
      developer.log('📝 Datos completos de alerta:');
      alerta.forEach((key, value) {
        developer.log('   $key: $value');
      });

      final docRef = await FirebaseFirestore.instance
          .collection('alertas_sede')
          .add(alerta)
          .timeout(const Duration(seconds: 10));

      developer.log('🚨 ========== ALERTA CREADA EXITOSAMENTE ==========');
      developer.log('🚨 Tipo: $tipoAlerta');
      developer.log('🚨 Sede: "$sedeNormalizada"');
      developer.log('📧 Admin: $adminEmail');
      developer.log('🆔 ID del documento: ${docRef.id}');
      developer.log('✅ ============================================');
    } catch (e, stackTrace) {
      developer.log('❌ ========== ERROR CREANDO ALERTA ==========');
      developer.log('❌ Error: $e');
      developer.log('❌ Tipo: ${e.runtimeType}');
      developer.log('❌ Stack trace: $stackTrace');
      developer.log('❌ ============================================');
      // Re-lanzar el error para que se pueda manejar en el nivel superior
      rethrow;
    }
  }

  /// Genera un resumen de la alerta sin mostrar el mensaje completo
  static String _generarResumenAlerta(String mensaje, String tipoAlerta) {
    switch (tipoAlerta) {
      case 'suicidio':
        return 'Usuario expresó pensamientos suicidas o de autolesión';
      case 'violencia':
        return 'Usuario expresó intenciones violentas o de agresión';
      case 'abuso_sexual':
        return 'Usuario expresó intenciones de abuso sexual o agresión sexual';
      case 'depresion':
        return 'Usuario mostró signos de depresión severa';
      default:
        return 'Usuario expresó preocupaciones que requieren atención';
    }
  }

  /// Procesa un mensaje y crea alerta si es necesario
  static Future<void> procesarMensajeParaAlerta({
    required String mensaje,
    required String? sede,
    required String usuarioEmail,
    required String usuarioNombre,
    String? usuarioTelefono,
    List<Map<String, dynamic>>? historialMensajes,
  }) async {
    developer.log('🔍 PROCESANDO MENSAJE PARA ALERTA: "$mensaje"');
    developer.log('🏢 Sede: $sede');
    developer.log('👤 Usuario: $usuarioEmail');

    // Crear mensaje con contexto si hay historial
    String mensajeConContexto = mensaje;
    if (historialMensajes != null && historialMensajes.isNotEmpty) {
      // Tomar los últimos 3 mensajes para contexto
      final mensajesRecientes = historialMensajes.take(3).toList();
      final contexto = mensajesRecientes
          .map((msg) => '${msg['emisor']}: ${msg['contenido']}')
          .join('\n');
      mensajeConContexto =
          'CONTEXTO DE CONVERSACIÓN:\n$contexto\n\nMENSAJE ACTUAL: $mensaje';
      developer.log('📝 Mensaje con contexto: $mensajeConContexto');
    }

    // Detectar el tipo de alerta con prioridad específica
    final tiposAlerta = await detectarTiposAlerta(mensajeConContexto);
    developer.log('🎯 Tipos de alerta detectados: $tiposAlerta');

    if (tiposAlerta.isNotEmpty) {
      // Crear una alerta por cada tipo detectado
      int alertasCreadas = 0;
      for (final tipoAlerta in tiposAlerta) {
        try {
          developer.log('✅ Creando alerta de tipo: $tipoAlerta');
          await crearAlerta(
            mensaje: mensaje,
            sede: sede,
            tipoAlerta: tipoAlerta,
            usuarioEmail: usuarioEmail,
            usuarioNombre: usuarioNombre,
            usuarioTelefono: usuarioTelefono,
          );
          alertasCreadas++;
          developer.log('✅ Alerta de tipo $tipoAlerta creada exitosamente');
        } catch (e) {
          developer.log('❌ Error al crear alerta de tipo $tipoAlerta: $e');
          // Continuar con las demás alertas aunque una falle
        }
      }
      developer.log(
          '📊 Total de alertas procesadas: ${tiposAlerta.length}, creadas exitosamente: $alertasCreadas');
    } else {
      developer.log('❌ No se crean alertas - no se detectaron tipos de riesgo');
      developer.log('🔍 Evaluando cada tipo individualmente para debug:');

      // Debug: evaluar cada tipo individualmente
      final esViolencia = await _evaluarViolenciaConIA(mensaje);
      final esAbusoSexual = await _evaluarAbusoSexualConIA(mensaje);
      final esSuicidio = await _evaluarSuicidioConIA(mensaje);
      final esDepresion = await _evaluarDepresionConIA(mensaje);

      developer.log('🔍 Debug - Violencia: $esViolencia');
      developer.log('🔍 Debug - Abuso Sexual: $esAbusoSexual');
      developer.log('🔍 Debug - Suicidio: $esSuicidio');
      developer.log('🔍 Debug - Depresión: $esDepresion');
    }
  }

  /// Obtiene alertas para un administrador específico
  /// AHORA filtra por SEDE en lugar de por admin_email hardcoded
  static Future<List<Map<String, dynamic>>> getAlertasPorAdmin(
      String adminEmail) async {
    try {
      developer.log('🔍 ========== BUSCANDO ALERTAS PARA ADMIN ==========');
      developer.log('🔍 Admin email recibido: "$adminEmail"');

      // Determinar la sede que administra este email
      String? sedeAdministrada = getSedePorAdminEmail(adminEmail);
      developer.log('🏢 Sede administrada por este email: "$sedeAdministrada"');

      // Obtener todas las alertas
      final querySnapshot =
          await FirebaseFirestore.instance.collection('alertas_sede').get();

      developer.log(
          '📊 Total de alertas en Firestore: ${querySnapshot.docs.length}');

      // Log de todas las alertas para debug
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        developer.log('📋 Alerta ID: ${doc.id}');
        developer.log('   - admin_email: "${data['admin_email']}"');
        developer.log('   - sede: "${data['sede']}"');
        developer.log('   - tipo: "${data['tipo_alerta']}"');
        developer.log('   - usuario: "${data['usuario_nombre']}"');
      }

      // Si NO se encontró la sede administrada, mostrar TODAS las alertas como fallback
      if (sedeAdministrada == null) {
        developer.log(
            '⚠️ NO SE ENCONTRÓ SEDE PARA ESTE ADMIN - MOSTRANDO TODAS LAS ALERTAS');
        developer.log(
            '💡 Agrega el email "$adminEmail" al mapa _sedesPorAdminReal en sede_alert_service.dart');

        final todasLasAlertas = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Ordenar por fecha
        todasLasAlertas.sort((a, b) {
          final fechaA = DateTime.tryParse(a['fecha'] ?? '') ?? DateTime(1970);
          final fechaB = DateTime.tryParse(b['fecha'] ?? '') ?? DateTime(1970);
          return fechaB.compareTo(fechaA);
        });

        developer.log('📊 ========== RESULTADO (TODAS) ==========');
        developer.log('📊 Alertas mostradas: ${todasLasAlertas.length}');
        developer.log('✅ ====================================');
        return todasLasAlertas;
      }

      final alertas = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((alerta) {
        final alertaSede = alerta['sede']?.toString().toLowerCase() ?? '';
        final alertaAdminEmail =
            alerta['admin_email']?.toString().toLowerCase() ?? '';

        // Filtrar por sede O por email (para compatibilidad)
        bool coincidePorSede = false;
        bool coincidePorEmail = false;

        if (sedeAdministrada != null) {
          coincidePorSede = alertaSede == sedeAdministrada.toLowerCase();
        }

        coincidePorEmail = alertaAdminEmail == adminEmail.toLowerCase();

        final coincide = coincidePorSede || coincidePorEmail;

        developer.log('🔍 Evaluando alerta:');
        developer.log('   - Sede de la alerta: "$alertaSede"');
        developer.log('   - Sede administrada: "$sedeAdministrada"');
        developer.log('   - Email de la alerta: "$alertaAdminEmail"');
        developer.log('   - Email del admin: "$adminEmail"');
        developer.log('   - Coincide por sede: $coincidePorSede');
        developer.log('   - Coincide por email: $coincidePorEmail');
        developer
            .log('   - RESULTADO: ${coincide ? "✅ INCLUIDA" : "❌ EXCLUIDA"}');

        return coincide;
      }).toList();

      // Ordenar por fecha
      alertas.sort((a, b) {
        final fechaA = DateTime.tryParse(a['fecha'] ?? '') ?? DateTime(1970);
        final fechaB = DateTime.tryParse(b['fecha'] ?? '') ?? DateTime(1970);
        return fechaB.compareTo(fechaA);
      });

      developer.log('📊 ========== RESULTADO ==========');
      developer.log('📊 Alertas encontradas: ${alertas.length}');
      developer.log('✅ ====================================');
      return alertas;
    } catch (e, stackTrace) {
      developer.log('❌ Error obteniendo alertas: $e');
      developer.log('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Obtiene todas las alertas (para debugging)
  static Future<List<Map<String, dynamic>>> getAllAlertas() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('alertas_sede')
          .orderBy('fecha', descending: true)
          .limit(100)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      developer.log('❌ Error obteniendo todas las alertas: $e');
      return [];
    }
  }

  /// Marca una alerta como leída
  static Future<void> marcarAlertaComoLeida(String alertaId) async {
    try {
      await FirebaseFirestore.instance
          .collection('alertas_sede')
          .doc(alertaId)
          .update({
        'leida': true,
        'fecha_lectura': DateTime.now().toIso8601String(),
      });
      developer.log('✅ Alerta $alertaId marcada como leída');
    } catch (e) {
      developer.log('❌ Error marcando alerta como leída: $e');
    }
  }

  /// Desmarca una alerta como leída (la marca como no leída)
  static Future<void> desmarcarAlertaComoLeida(String alertaId) async {
    try {
      await FirebaseFirestore.instance
          .collection('alertas_sede')
          .doc(alertaId)
          .update({
        'leida': false,
        'fecha_lectura': null,
      });
      developer.log('🔄 Alerta $alertaId desmarcada como leída');
    } catch (e) {
      developer.log('❌ Error desmarcando alerta como leída: $e');
    }
  }

  /// Elimina una alerta
  static Future<void> eliminarAlerta(String alertaId) async {
    try {
      await FirebaseFirestore.instance
          .collection('alertas_sede')
          .doc(alertaId)
          .delete();
      developer.log('🗑️ Alerta $alertaId eliminada');
    } catch (e) {
      developer.log('❌ Error eliminando alerta: $e');
    }
  }

  /// Obtiene estadísticas de alertas por sede
  static Future<Map<String, dynamic>> getEstadisticasAlertas() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('alertas_sede').get();

      final alertas = querySnapshot.docs.map((doc) => doc.data()).toList();

      final alertasPorSede = <String, int>{};
      final alertasPorTipo = <String, int>{};
      int alertasPendientes = 0;
      int alertasLeidas = 0;

      for (final alerta in alertas) {
        // Por sede
        final sede = alerta['sede'] ?? 'Sin sede';
        alertasPorSede[sede] = (alertasPorSede[sede] ?? 0) + 1;

        // Por tipo
        final tipo = alerta['tipo_alerta'] ?? 'general';
        alertasPorTipo[tipo] = (alertasPorTipo[tipo] ?? 0) + 1;

        // Estado
        if (alerta['leida'] == true) {
          alertasLeidas++;
        } else {
          alertasPendientes++;
        }
      }

      return {
        'total_alertas': alertas.length,
        'alertas_por_sede': alertasPorSede,
        'alertas_por_tipo': alertasPorTipo,
        'alertas_pendientes': alertasPendientes,
        'alertas_leidas': alertasLeidas,
      };
    } catch (e) {
      developer.log('❌ Error obteniendo estadísticas: $e');
      return {
        'total_alertas': 0,
        'alertas_por_sede': <String, int>{},
        'alertas_por_tipo': <String, int>{},
        'alertas_pendientes': 0,
        'alertas_leidas': 0,
      };
    }
  }

  /// Obtiene estadísticas de alertas para un administrador específico por sede
  static Future<Map<String, dynamic>> getEstadisticasAlertasPorAdmin(
      String adminEmail) async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('alertas_sede').get();

      final alertas = querySnapshot.docs
          .map((doc) => doc.data())
          .where((alerta) => alerta['admin_email'] == adminEmail)
          .toList();

      final alertasPorSede = <String, Map<String, int>>{};
      final alertasPorTipo = <String, int>{};
      int alertasPendientes = 0;
      int alertasLeidas = 0;

      for (final alerta in alertas) {
        // Por sede con desglose
        final sede = alerta['sede'] ?? 'Sin sede';
        if (!alertasPorSede.containsKey(sede)) {
          alertasPorSede[sede] = {
            'total': 0,
            'pendientes': 0,
            'leidas': 0,
          };
        }

        alertasPorSede[sede]!['total'] =
            (alertasPorSede[sede]!['total'] ?? 0) + 1;

        if (alerta['leida'] == true) {
          alertasPorSede[sede]!['leidas'] =
              (alertasPorSede[sede]!['leidas'] ?? 0) + 1;
          alertasLeidas++;
        } else {
          alertasPorSede[sede]!['pendientes'] =
              (alertasPorSede[sede]!['pendientes'] ?? 0) + 1;
          alertasPendientes++;
        }

        // Por tipo
        final tipo = alerta['tipo_alerta'] ?? 'general';
        alertasPorTipo[tipo] = (alertasPorTipo[tipo] ?? 0) + 1;
      }

      return {
        'total_alertas': alertas.length,
        'alertas_por_sede': alertasPorSede,
        'alertas_por_tipo': alertasPorTipo,
        'alertas_pendientes': alertasPendientes,
        'alertas_leidas': alertasLeidas,
      };
    } catch (e) {
      developer.log('❌ Error obteniendo estadísticas por admin: $e');
      return {
        'total_alertas': 0,
        'alertas_por_sede': <String, Map<String, int>>{},
        'alertas_por_tipo': <String, int>{},
        'alertas_pendientes': 0,
        'alertas_leidas': 0,
      };
    }
  }
}
