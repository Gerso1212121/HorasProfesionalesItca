import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horas2/Backend/Data/API/GPTService.dart';

class SedeAlertService {
  // Mapa de correos de administradores por sede - ACTUALIZADO
  static const Map<String, String> _adminEmailsPorSede = {
    'san miguel': 'sanmiguel@admin.com',
    'la unión': 'launion@admin.com',
    'zacatecoluca': 'zacatecoluca@admin.com',
    'sede central': 'sedecentral@admin.com',
    'sede central san salvador': 'sedecentral@admin.com', // NUEVO: agregado
    'santa tecla': 'sedecentral@admin.com', // Mismo que sede central
  };

  // Mapa de sedes que administra cada email real de Supabase
  static const Map<String, String> _sedesPorAdminReal = {
    'sanmiguel@admin.com': 'san miguel',
    'launion@admin.com': 'la unión',
    'zacatecoluca@admin.com': 'zacatecoluca',
    'sedecentral@admin.com': 'sede central',
    // Agregar aquí los emails reales de los administradores cuando se conozcan
  };

  /// Normaliza el nombre de la sede - MEJORADO
  static String normalizarSede(String sede) {
    String normalizada = sede.toLowerCase().trim();

    // Mapear nombres alternativos - ACTUALIZADO
    final Map<String, String> mapeoSedes = {
      'sede san miguel': 'san miguel',
      'san miguel': 'san miguel',
      'sede la unión': 'la unión',
      'sede la union': 'la unión',
      'la unión': 'la unión',
      'la union': 'la unión',
      'sede zacatecoluca': 'zacatecoluca',
      'zacatecoluca': 'zacatecoluca',
      'zacate coluca': 'zacatecoluca',
      'sede santa tecla': 'santa tecla',
      'santa tecla': 'santa tecla',
      'sede central': 'sede central',
      'sede central san salvador': 'sede central san salvador', // NUEVO
      'central': 'sede central',
      'san salvador': 'sede central san salvador', // NUEVO
    };

    // Primero buscar coincidencia exacta
    String? sedeMapeada = mapeoSedes[normalizada];

    // Si no se encuentra exacto, buscar por contenido
    if (sedeMapeada == null) {
      if (normalizada.contains('san salvador')) {
        sedeMapeada = 'sede central san salvador';
      } else if (normalizada.contains('central')) {
        sedeMapeada = 'sede central';
      } else if (normalizada.contains('san miguel')) {
        sedeMapeada = 'san miguel';
      } else if (normalizada.contains('la unión') ||
          normalizada.contains('la union')) {
        sedeMapeada = 'la unión';
      } else if (normalizada.contains('zacatecoluca') ||
          normalizada.contains('zacate coluca')) {
        sedeMapeada = 'zacatecoluca';
      } else if (normalizada.contains('santa tecla')) {
        sedeMapeada = 'santa tecla';
      }
    }

    // Si aún no se encuentra, buscar en el mapa principal de admin emails
    if (sedeMapeada == null) {
      for (var key in _adminEmailsPorSede.keys) {
        if (normalizada.contains(key) || key.contains(normalizada)) {
          sedeMapeada = key;
          break;
        }
      }
    }

    return sedeMapeada ?? normalizada;
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

  /// Obtiene el correo del administrador para una sede específica - MEJORADO
  static String? getAdminEmailPorSede(String? sede) {
    if (sede == null || sede.isEmpty) {
      print('⚠️ Sede es null o vacía');
      return 'sedecentral@admin.com'; // Fallback a sede central
    }

    String sedeNormalizada = normalizarSede(sede);
    print('🔍 Sede normalizada para buscar admin: "$sedeNormalizada"');
    print('🔍 Mapa completo: $_adminEmailsPorSede');

    // Buscar primero coincidencia exacta
    String? adminEmail = _adminEmailsPorSede[sedeNormalizada];

    // Si no se encuentra, buscar por similitud
    if (adminEmail == null) {
      for (var key in _adminEmailsPorSede.keys) {
        if (sedeNormalizada.contains(key) || key.contains(sedeNormalizada)) {
          adminEmail = _adminEmailsPorSede[key];
          print('✅ Encontrado admin por similitud: $key -> $adminEmail');
          break;
        }
      }
    }

    // Fallback a sede central si no se encuentra
    adminEmail ??= 'sedecentral@admin.com';

    print('✅ Admin email para sede "$sede" ("$sedeNormalizada"): $adminEmail');
    return adminEmail;
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

Mensaje a evaluar: "$mensaje"

Responde ÚNICAMENTE con:
- "SI" si el mensaje contiene intenciones de abuso sexual o agresión sexual hacia otras personas
- "NO" si el mensaje NO contiene abuso sexual

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

Mensaje a evaluar: "$mensaje"

Responde ÚNICAMENTE con:
- "SI" si el mensaje contiene intenciones de violencia hacia otras personas REALES
- "NO" si el mensaje NO contiene violencia

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

Mensaje a evaluar: "$mensaje"

Responde ÚNICAMENTE con:
- "SI" si el mensaje contiene signos de depresión SEVERA que requieren atención profesional inmediata
- "NO" si el mensaje NO contiene depresión severa

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
- Solo considera suicidio cuando hay intención clara, específica y REAL de hacerse daño a SÍ MISMO

Mensaje a evaluar: "$mensaje"

Responde ÚNICAMENTE con:
- "SI" si el mensaje contiene intenciones REALES y específicas de suicidio o autolesión hacia SÍ MISMO
- "NO" si el mensaje NO contiene intención real de suicidio

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
      final response = await GPTService.getResponse([
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

Mensaje a evaluar: "$mensaje"

Responde ÚNICAMENTE con:
- "SI" si el mensaje está en contexto de videojuegos o entretenimiento virtual
- "NO" si el mensaje NO está en contexto de videojuegos (es una situación real)

Respuesta:''';

      final response = await _llamarOpenAI(prompt);
      final respuesta = response.toLowerCase().trim();

      developer
          .log('🎮 IA evaluó contexto videojuegos: "$mensaje" → $respuesta');
      return respuesta == 'si';
    } catch (e) {
      print('❌ Error evaluando contexto videojuegos con IA: $e');
      return false;
    }
  }

  /// Detecta el tipo de alerta con prioridad específica
  static Future<List<String>> detectarTiposAlerta(String mensaje) async {
    final tiposAlerta = <String>[];

    // Verificar si es contexto de videojuegos
    final esVideojuegos = await _esContextoVideojuegosConIA(mensaje);
    if (esVideojuegos) {
      print('🎮 Contexto de videojuegos detectado - NO generando alertas');
      return tiposAlerta;
    }

    // Evaluar en orden de prioridad
    final esViolencia = await _evaluarViolenciaConIA(mensaje);
    if (esViolencia) {
      tiposAlerta.add('violencia');
      return tiposAlerta;
    }

    final esAbusoSexual = await _evaluarAbusoSexualConIA(mensaje);
    if (esAbusoSexual) {
      tiposAlerta.add('abuso_sexual');
      return tiposAlerta;
    }

    final esSuicidio = await _evaluarSuicidioConIA(mensaje);
    if (esSuicidio) {
      tiposAlerta.add('suicidio');
      return tiposAlerta;
    }

    final esDepresion = await _evaluarDepresionConIA(mensaje);
    if (esDepresion) {
      tiposAlerta.add('depresion');
    }

    return tiposAlerta;
  }

  /// Crea una alerta en Firestore - MEJORADO CON MÁS LOGS
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

      // Normalizar la sede
      final sedeNormalizada = normalizarSede(sede ?? '');
      print('🔍 Sede normalizada: "$sedeNormalizada"');

      // Obtener admin email con fallback
      final adminEmail = getAdminEmailPorSede(sedeNormalizada);

      if (adminEmail == null) {
        print('⚠️ Usando fallback para admin email');
      }

      print('🔍 Admin email asignado: "$adminEmail"');

      final alerta = {
        'fecha': DateTime.now().toIso8601String(),
        'sede': sedeNormalizada,
        'tipo_alerta': tipoAlerta,
        'usuario_email': usuarioEmail,
        'usuario_nombre': usuarioNombre,
        'usuario_telefono': usuarioTelefono ?? 'No disponible',
        'admin_email': adminEmail ?? 'sedecentral@admin.com',
        'estado': 'pendiente',
        'leida': false,
        'mensaje_original': mensaje,
        'resumen': _generarResumenAlerta(mensaje, tipoAlerta),
      };

      print('📝 Creando alerta en Firestore...');

      final docRef = await FirebaseFirestore.instance
          .collection('alertas_sede')
          .add(alerta)
          .timeout(const Duration(seconds: 10));

      print('🚨 ========== ALERTA CREADA EXITOSAMENTE ==========');
      print('🚨 ID: ${docRef.id}');
      print('🚨 Tipo: $tipoAlerta');
      print('🚨 Sede: $sedeNormalizada');
      print('📧 Admin: $adminEmail');
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

  /// Verifica si el email es válido para alertas
  static bool _esEmailInstitucionalValido(String email) {
    return email.toLowerCase().endsWith('@itca.edu.sv');
  }

  /// Procesa mensaje para alerta - CON MEJORES LOGS
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

    // Validar email institucional
    if (!_esEmailInstitucionalValido(usuarioEmail)) {
      print('🔒 ALERTA BLOQUEADA: Email no institucional - $usuarioEmail');
      print('ℹ️ Solo se permiten alertas para emails @itca.edu.sv');
      return;
    }

    print('✅ Email institucional verificado: $usuarioEmail');

    // Crear mensaje con contexto si hay historial
    String mensajeConContexto = mensaje;
    if (historialMensajes != null && historialMensajes.isNotEmpty) {
      final mensajesRecientes = historialMensajes.take(3).toList();
      final contexto = mensajesRecientes
          .map((msg) => '${msg['emisor']}: ${msg['contenido']}')
          .join('\n');
      mensajeConContexto =
          'CONTEXTO DE CONVERSACIÓN:\n$contexto\n\nMENSAJE ACTUAL: $mensaje';
    }

    // Detectar tipos de alerta
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
      print(
          '📊 Alertas creadas exitosamente: $alertasCreadas de ${tiposAlerta.length}');
    } else {
      print('ℹ️ No se detectaron tipos de riesgo para alerta');
    }
  }

  /// Obtiene alertas para un administrador específico
  static Future<List<Map<String, dynamic>>> getAlertasPorAdmin(
      String adminEmail) async {
    try {
      print('🔍 Buscando alertas para admin: "$adminEmail"');

      // Determinar la sede que administra este email
      String? sedeAdministrada = getSedePorAdminEmail(adminEmail);
      print('🏢 Sede administrada: "$sedeAdministrada"');

      final querySnapshot =
          await FirebaseFirestore.instance.collection('alertas_sede').get();

      print('📊 Total de alertas en Firestore: ${querySnapshot.docs.length}');

      final alertas = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((alerta) {
        final alertaSede = alerta['sede']?.toString().toLowerCase() ?? '';
        final alertaAdminEmail =
            alerta['admin_email']?.toString().toLowerCase() ?? '';

        bool coincide = alertaAdminEmail == adminEmail.toLowerCase();

        if (sedeAdministrada != null) {
          coincide = coincide || (alertaSede == sedeAdministrada.toLowerCase());
        }

        return coincide;
      }).toList();

      // Ordenar por fecha
      alertas.sort((a, b) {
        final fechaA = DateTime.tryParse(a['fecha'] ?? '') ?? DateTime(1970);
        final fechaB = DateTime.tryParse(b['fecha'] ?? '') ?? DateTime(1970);
        return fechaB.compareTo(fechaA);
      });

      print('📊 Alertas encontradas para admin: ${alertas.length}');
      return alertas;
    } catch (e, stackTrace) {
      print('❌ Error obteniendo alertas: $e');
      print('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  /// Obtiene todas las alertas
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

  /// Obtiene estadísticas de alertas
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
        final sede = alerta['sede'] ?? 'Sin sede';
        alertasPorSede[sede] = (alertasPorSede[sede] ?? 0) + 1;

        final tipo = alerta['tipo_alerta'] ?? 'general';
        alertasPorTipo[tipo] = (alertasPorTipo[tipo] ?? 0) + 1;

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
      print('❌ Error obteniendo estadísticas: $e');
      return {
        'total_alertas': 0,
        'alertas_por_sede': <String, int>{},
        'alertas_por_tipo': <String, int>{},
        'alertas_pendientes': 0,
        'alertas_leidas': 0,
      };
    }
  }
}
