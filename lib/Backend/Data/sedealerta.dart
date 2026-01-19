import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horas2/Backend/Data/API/GPTService.dart';

class SedeAlertService {
  // Mapa de correos de administradores por sede (versión completa con capitalización)
  static const Map<String, String> _adminEmailsPorSede = {
    'Sede San Miguel': 'sanmiguel@admin.com',
    'San Miguel': 'sanmiguel@admin.com',
    'Sede La Unión': 'launion@admin.com',
    'La Unión': 'launion@admin.com',
    'La Union': 'launion@admin.com', // Variante sin acento
    'Sede Zacatecoluca': 'zacatecoluca@admin.com',
    'Zacatecoluca': 'zacatecoluca@admin.com',
    'Sede Central': 'sedecentral@admin.com',
    'Sede central': 'sedecentral@admin.com',
    'Sede Santa Tecla': 'sedecentral@admin.com',
    'Santa Tecla': 'sedecentral@admin.com',
  };

  // Mapa de sedes que administra cada email real de Supabase
  static const Map<String, List<String>> _sedesPorAdminReal = {
    'sanmiguel@admin.com': ['Sede San Miguel', 'San Miguel'],
    'launion@admin.com': ['Sede La Unión', 'La Unión', 'Sede La Union'],
    'zacatecoluca@admin.com': ['Sede Zacatecoluca', 'Zacatecoluca'],
    'sedecentral@admin.com': [
      'Sede Central',
      'Sede Santa Tecla',
      'Santa Tecla',
      'Sede central'
    ],
    // Agregar aquí los emails reales de los administradores cuando se conozcan
    // Ejemplo: 'admin123@ejemplo.com': ['Sede San Miguel'],
  };

  /// Normaliza el nombre de la sede para coincidir con las variantes comunes
  static String normalizarSede(String sede) {
    String sedeLower = sede.toLowerCase().trim();

    if (sedeLower.contains('san miguel')) {
      return 'Sede San Miguel';
    } else if (sedeLower.contains('la unión') || sedeLower.contains('la union')) {
      return 'Sede La Unión';
    } else if (sedeLower.contains('zacatecoluca') || sedeLower.contains('zacate coluca')) {
      return 'Sede Zacatecoluca';
    } else if (sedeLower.contains('santa tecla')) {
      return 'Sede Santa Tecla';
    } else if (sedeLower.contains('sede central')) {
      return 'Sede Central';
    } else if (sedeLower.contains('sede')) {
      // Para cualquier otra sede, mantener el formato original pero con "Sede"
      return sede;
    } else {
      // Si no tiene "Sede" en el nombre, agregarlo
      return 'Sede $sede';
    }
  }

  /// Obtiene las sedes que administra un email específico
  static List<String>? getSedesPorAdminEmail(String adminEmail) {
    // Buscar en el mapa de admin a sedes
    final emailLower = adminEmail.toLowerCase();
    
    // Buscar coincidencia exacta
    final sedes = _sedesPorAdminReal[adminEmail];
    if (sedes != null) return sedes;
    
    // Buscar por coincidencia parcial
    for (var entry in _sedesPorAdminReal.entries) {
      if (entry.key.toLowerCase() == emailLower) {
        return entry.value;
      }
    }
    
    // Si no se encuentra, intentar deducir del email
    if (emailLower.contains('sanmiguel')) {
      return ['Sede San Miguel', 'San Miguel'];
    } else if (emailLower.contains('launion')) {
      return ['Sede La Unión', 'La Unión', 'Sede La Union'];
    } else if (emailLower.contains('zacatecoluca')) {
      return ['Sede Zacatecoluca', 'Zacatecoluca'];
    } else if (emailLower.contains('sedecentral') || emailLower.contains('central')) {
      return ['Sede Central', 'Sede Santa Tecla'];
    }
    
    return null;
  }

  /// Obtiene el correo del administrador para una sede específica
  static String? getAdminEmailPorSede(String? sede) {
    if (sede == null || sede.isEmpty) {
      return null;
    }

    // Buscar coincidencia exacta
    if (_adminEmailsPorSede.containsKey(sede)) {
      return _adminEmailsPorSede[sede];
    }

    // Buscar por coincidencia parcial (sin importar mayúsculas/minúsculas)
    final sedeLower = sede.toLowerCase();
    
    for (var entry in _adminEmailsPorSede.entries) {
      if (entry.key.toLowerCase() == sedeLower ||
          entry.key.toLowerCase().contains(sedeLower) ||
          sedeLower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    return null;
  }

  // Los métodos de IA se mantienen igual...
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

      print('🤖 IA evaluó abuso sexual: "$mensaje" → $respuesta');
      return respuesta == 'si';
    } catch (e) {
      print('❌ Error evaluando abuso sexual con IA: $e');
      return false;
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

      print('🤖 IA evaluó violencia: "$mensaje" → $respuesta');
      return respuesta == 'si';
    } catch (e) {
      print('❌ Error evaluando violencia con IA: $e');
      return false;
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

      print('🤖 IA evaluó depresión: "$mensaje" → $respuesta');
      return respuesta == 'si';
    } catch (e) {
      print('❌ Error evaluando depresión con IA: $e');
      return false;
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

      print('🤖 IA evaluó suicidio: "$mensaje" → $respuesta');
      return respuesta == 'si';
    } catch (e) {
      print('❌ Error evaluando suicidio con IA: $e');
      return false;
    }
  }

  /// Llama a OpenAI para evaluación
  static Future<String> _llamarOpenAI(String prompt) async {
    try {
      final response = await GptApi.getResponse([
        {"role": "user", "content": prompt}
      ]);
      return response.trim();
    } catch (e) {
      print('❌ Error llamando a OpenAI: $e');
      return "NO";
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

      print('🎮 IA evaluó contexto videojuegos: "$mensaje" → $respuesta');
      return respuesta == 'si';
    } catch (e) {
      print('❌ Error evaluando contexto videojuegos con IA: $e');
      return false;
    }
  }

  /// Detecta el tipo de alerta con prioridad específica
  static Future<List<String>> detectarTiposAlerta(String mensaje) async {
    final tiposAlerta = <String>[];

    // PRIMERO: Verificar si es contexto de videojuegos usando IA
    final esVideojuegos = await _esContextoVideojuegosConIA(mensaje);
    if (esVideojuegos) {
      print('🎮 Contexto de videojuegos detectado por IA - NO evaluando alertas');
      return tiposAlerta;
    }

    // Evaluar en orden de prioridad para evitar duplicados
    // 1. PRIMERO: Violencia hacia otros
    final esViolencia = await _evaluarViolenciaConIA(mensaje);
    if (esViolencia) {
      tiposAlerta.add('violencia');
      return tiposAlerta;
    }

    // 2. SEGUNDO: Abuso sexual hacia otros
    final esAbusoSexual = await _evaluarAbusoSexualConIA(mensaje);
    if (esAbusoSexual) {
      tiposAlerta.add('abuso_sexual');
      return tiposAlerta;
    }

    // 3. TERCERO: Suicidio/autolesión
    final esSuicidio = await _evaluarSuicidioConIA(mensaje);
    if (esSuicidio) {
      tiposAlerta.add('suicidio');
      return tiposAlerta;
    }

    // 4. CUARTO: Depresión severa
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
      print('🔍 ========== CREAR ALERTA ==========');
      print('🔍 Sede recibida: "$sede"');
      print('🔍 Tipo de alerta: "$tipoAlerta"');
      print('🔍 Usuario email: "$usuarioEmail"');
      print('🔍 Usuario nombre: "$usuarioNombre"');

      // Normalizar la sede antes de buscar el admin
      final sedeNormalizada = sede != null && sede.isNotEmpty ? normalizarSede(sede) : 'Sede Desconocida';
      print('🔍 Sede normalizada: "$sedeNormalizada"');

      final adminEmail = getAdminEmailPorSede(sedeNormalizada);
      print('🔍 Admin email encontrado: "$adminEmail"');

      if (adminEmail == null) {
        print('⚠️ No se encontró admin específico, usando admin por defecto');
        // Podrías usar un admin por defecto aquí si lo prefieres
        // throw Exception('No se encontró administrador para la sede: $sede');
      }

      final alerta = {
        'fecha': DateTime.now().toIso8601String(),
        'sede': sedeNormalizada,
        'tipo_alerta': tipoAlerta,
        'usuario_email': usuarioEmail,
        'usuario_nombre': usuarioNombre,
        'usuario_telefono': usuarioTelefono ?? 'No disponible',
        'admin_email': adminEmail ?? 'admin@default.com',
        'estado': 'pendiente',
        'leida': false,
        'mensaje_original': mensaje,
        'resumen': _generarResumenAlerta(mensaje, tipoAlerta),
      };

      print('📝 Intentando crear alerta en Firestore...');

      final docRef = await FirebaseFirestore.instance
          .collection('alertas_sede')
          .add(alerta)
          .timeout(const Duration(seconds: 10));

      print('🚨 ========== ALERTA CREADA EXITOSAMENTE ==========');
      print('🚨 Tipo: $tipoAlerta');
      print('🚨 Sede: "$sedeNormalizada"');
      print('📧 Admin: ${adminEmail ?? "admin por defecto"}');
      print('🆔 ID del documento: ${docRef.id}');
      print('✅ ============================================');
    } catch (e, stackTrace) {
      print('❌ ========== ERROR CREANDO ALERTA ==========');
      print('❌ Error: $e');
      print('❌ Stack trace: $stackTrace');
      print('❌ ============================================');
      rethrow;
    }
  }

  /// Genera un resumen de la alerta
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
    print('🔍 PROCESANDO MENSAJE PARA ALERTA: "$mensaje"');
    print('🏢 Sede: $sede');
    print('👤 Usuario: $usuarioEmail');

    String mensajeConContexto = mensaje;
    if (historialMensajes != null && historialMensajes.isNotEmpty) {
      final mensajesRecientes = historialMensajes.take(3).toList();
      final contexto = mensajesRecientes
          .map((msg) => '${msg['emisor']}: ${msg['contenido']}')
          .join('\n');
      mensajeConContexto = 'CONTEXTO DE CONVERSACIÓN:\n$contexto\n\nMENSAJE ACTUAL: $mensaje';
    }

    final tiposAlerta = await detectarTiposAlerta(mensajeConContexto);
    print('🎯 Tipos de alerta detectados: $tiposAlerta');

    if (tiposAlerta.isNotEmpty) {
      int alertasCreadas = 0;
      for (final tipoAlerta in tiposAlerta) {
        try {
          print('✅ Creando alerta de tipo: $tipoAlerta');
          await crearAlerta(
            mensaje: mensaje,
            sede: sede,
            tipoAlerta: tipoAlerta,
            usuarioEmail: usuarioEmail,
            usuarioNombre: usuarioNombre,
            usuarioTelefono: usuarioTelefono,
          );
          alertasCreadas++;
        } catch (e) {
          print('❌ Error al crear alerta de tipo $tipoAlerta: $e');
        }
      }
      print('📊 Total de alertas creadas exitosamente: $alertasCreadas');
    } else {
      print('❌ No se crean alertas - no se detectaron tipos de riesgo');
    }
  }

  /// Obtiene alertas para un administrador específico
  static Future<List<Map<String, dynamic>>> getAlertasPorAdmin(String adminEmail) async {
    try {
      print('🔍 ========== BUSCANDO ALERTAS PARA ADMIN ==========');
      print('🔍 Admin email recibido: "$adminEmail"');

      // Obtener las sedes que administra este email
      final sedesAdministradas = getSedesPorAdminEmail(adminEmail);
      print('🏢 Sedes administradas por este email: $sedesAdministradas');

      // Obtener todas las alertas
      final querySnapshot = await FirebaseFirestore.instance
          .collection('alertas_sede')
          .orderBy('fecha', descending: true)
          .get();

      print('📊 Total de alertas en Firestore: ${querySnapshot.docs.length}');

      // Si no hay sedes definidas, mostrar todas (para debugging)
      if (sedesAdministradas == null || sedesAdministradas.isEmpty) {
        print('⚠️ NO SE ENCONTRARON SEDES PARA ESTE ADMIN - MOSTRANDO TODAS LAS ALERTAS');
        final todasLasAlertas = querySnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        print('📊 Alertas mostradas: ${todasLasAlertas.length}');
        return todasLasAlertas;
      }

      // Filtrar alertas por sede
      final alertas = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((alerta) {
        final alertaSede = alerta['sede']?.toString() ?? '';
        
        // Verificar si la sede de la alerta coincide con alguna de las sedes administradas
        bool coincide = sedesAdministradas.any((sedeAdmin) {
          final sedeLower = alertaSede.toLowerCase();
          final sedeAdminLower = sedeAdmin.toLowerCase();
          
          // Coincidencia exacta o parcial
          return sedeLower == sedeAdminLower || 
                 sedeLower.contains(sedeAdminLower) ||
                 sedeAdminLower.contains(sedeLower);
        });

        if (coincide) {
          print('✅ Alerta INCLUIDA - Sede: "$alertaSede" coincide con sedes administradas');
        }

        return coincide;
      }).toList();

      print('📊 ========== RESULTADO ==========');
      print('📊 Alertas encontradas para admin $adminEmail: ${alertas.length}');
      print('✅ ====================================');
      return alertas;
    } catch (e, stackTrace) {
      print('❌ Error obteniendo alertas: $e');
      print('❌ Stack trace: $stackTrace');
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
      print('❌ Error obteniendo todas las alertas: $e');
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
      print('✅ Alerta $alertaId marcada como leída');
    } catch (e) {
      print('❌ Error marcando alerta como leída: $e');
    }
  }

  /// Desmarca una alerta como leída
  static Future<void> desmarcarAlertaComoLeida(String alertaId) async {
    try {
      await FirebaseFirestore.instance
          .collection('alertas_sede')
          .doc(alertaId)
          .update({
        'leida': false,
        'fecha_lectura': null,
      });
      print('🔄 Alerta $alertaId desmarcada como leída');
    } catch (e) {
      print('❌ Error desmarcando alerta como leída: $e');
    }
  }

  /// Elimina una alerta
  static Future<void> eliminarAlerta(String alertaId) async {
    try {
      await FirebaseFirestore.instance
          .collection('alertas_sede')
          .doc(alertaId)
          .delete();
      print('🗑️ Alerta $alertaId eliminada');
    } catch (e) {
      print('❌ Error eliminando alerta: $e');
    }
  }

  /// Obtiene estadísticas de alertas para un administrador específico
  static Future<Map<String, dynamic>> getEstadisticasAlertasPorAdmin(String adminEmail) async {
    try {
      // Obtener las sedes que administra este email
      final sedesAdministradas = getSedesPorAdminEmail(adminEmail);
      print('📊 Estadísticas - Sedes administradas por $adminEmail: $sedesAdministradas');

      // Obtener todas las alertas
      final querySnapshot = await FirebaseFirestore.instance
          .collection('alertas_sede')
          .orderBy('fecha', descending: true)
          .get();

      // Filtrar por sede
      final alertas = querySnapshot.docs.map((doc) => doc.data()).where((alerta) {
        final alertaSede = alerta['sede']?.toString() ?? '';
        
        if (sedesAdministradas == null || sedesAdministradas.isEmpty) {
          return true; // Si no hay sedes definidas, incluir todas
        }

        // Verificar si la sede de la alerta coincide con alguna de las sedes administradas
        return sedesAdministradas.any((sedeAdmin) {
          final sedeLower = alertaSede.toLowerCase();
          final sedeAdminLower = sedeAdmin.toLowerCase();
          
          return sedeLower == sedeAdminLower || 
                 sedeLower.contains(sedeAdminLower) ||
                 sedeAdminLower.contains(sedeLower);
        });
      }).toList();

      print('📊 Total alertas filtradas para estadísticas: ${alertas.length}');

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

        alertasPorSede[sede]!['total'] = (alertasPorSede[sede]!['total'] ?? 0) + 1;

        if (alerta['leida'] == true) {
          alertasPorSede[sede]!['leidas'] = (alertasPorSede[sede]!['leidas'] ?? 0) + 1;
          alertasLeidas++;
        } else {
          alertasPorSede[sede]!['pendientes'] = (alertasPorSede[sede]!['pendientes'] ?? 0) + 1;
          alertasPendientes++;
        }

        // Por tipo
        final tipo = alerta['tipo_alerta'] ?? 'general';
        alertasPorTipo[tipo] = (alertasPorTipo[tipo] ?? 0) + 1;
      }

      final resultado = {
        'total_alertas': alertas.length,
        'alertas_por_sede': alertasPorSede,
        'alertas_por_tipo': alertasPorTipo,
        'alertas_pendientes': alertasPendientes,
        'alertas_leidas': alertasLeidas,
        'sedes_administradas': sedesAdministradas ?? [],
      };

      print('📊 Resultado estadísticas:');
      print('   - Total alertas: ${resultado['total_alertas']}');
      print('   - Pendientes: ${resultado['alertas_pendientes']}');
      print('   - Leídas: ${resultado['alertas_leidas']}');
      print('   - Sedes encontradas: ${alertasPorSede.keys.toList()}');
      return resultado;
    } catch (e) {
      print('❌ Error obteniendo estadísticas por admin: $e');
      return {
        'total_alertas': 0,
        'alertas_por_sede': <String, Map<String, int>>{},
        'alertas_por_tipo': <String, int>{},
        'alertas_pendientes': 0,
        'alertas_leidas': 0,
        'sedes_administradas': [],
      };
    }
  }
}