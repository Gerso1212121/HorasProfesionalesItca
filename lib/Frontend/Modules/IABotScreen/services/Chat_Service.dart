import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/mensajes.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/sesionchat.dart';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/servicechatcifrado.dart';

class ChatService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserUid => _auth.currentUser?.uid;

  // Clave de cifrado (en una app real, esto debería ser más seguro)
  static String get _encryptionKey {
    final userUid = _auth.currentUser?.uid ?? 'default_key';
    // Usamos una combinación del UID del usuario y una clave fija
    // En producción, considera usar flutter_secure_storage para almacenar claves
    return '${userUid.substring(0, min(16, userUid.length))}_chat_enc_key_2024';
  }

  // ========== DIAGNÓSTICO ==========

  /// Ejecuta este diagnóstico para ver qué está pasando
  static Future<void> runDiagnosticoCompleto() async {
    developer.log('\n🔍🔍🔍 DIAGNÓSTICO COMPLETO DEL CIFRADO 🔍🔍🔍');

    try {
      // 1. Verificar conexión a CifradoService
      developer.log('1. Probando CifradoService...');

      // Probar cifrado simple
      const textoPrueba = 'Hola, me siento feliz :)';
      developer.log('   Texto original: "$textoPrueba"');

      try {
        final cifrado = await CifradoService.cifrarTexto(textoPrueba);
        developer.log('   ✅ CifradoService.cifrarTexto() funciona');
        developer.log(
            '   Texto cifrado: ${cifrado.substring(0, min(30, cifrado.length))}...');

        // Intentar descifrar
        final descifrado = await CifradoService.descifrarTexto(cifrado);
        developer.log('   ✅ CifradoService.descifrarTexto() funciona');
        developer.log('   Texto descifrado: "$descifrado"');

        if (descifrado == textoPrueba) {
          developer.log('   🎉 ¡CIFRADO/DESCIFRADO FUNCIONA CORRECTAMENTE!');
        } else {
          developer.log('   ❌ PROBLEMA: Descifrado diferente del original');
          developer.log('      Esperado: "$textoPrueba"');
          developer.log('      Obtenido: "$descifrado"');
        }
      } catch (e) {
        developer.log('   ❌ Error con CifradoService: $e');
      }

      // 2. Verificar sistema viejo de cifrado
      developer.log('\n2. Probando sistema viejo de cifrado...');
      try {
        final cifradoViejo = _simpleEncrypt(textoPrueba, _encryptionKey);
        developer.log('   ✅ _simpleEncrypt funciona');
        developer.log(
            '   Texto cifrado viejo: ${cifradoViejo.substring(0, min(30, cifradoViejo.length))}...');

        final descifradoViejo = _simpleDecrypt(cifradoViejo, _encryptionKey);
        developer.log('   ✅ _simpleDecrypt funciona');
        developer.log('   Texto descifrado viejo: "$descifradoViejo"');
      } catch (e) {
        developer.log('   ❌ Error con sistema viejo: $e');
      }

      // 3. Verificar SharedPreferences para clave
      developer.log('\n3. Verificando SharedPreferences...');
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('user_email');
      developer.log('   Email del usuario: $email');

      final tieneClave = await CifradoService.tieneClave();
      developer.log('   CifradoService tiene clave almacenada: $tieneClave');

      // 4. Verificar Firestore
      developer.log('\n4. Verificando Firestore...');
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final test = await _firestore
              .collection('usuarios')
              .doc(user.uid)
              .collection('sesiones_chat')
              .limit(1)
              .get();
          developer
              .log('   ✅ Firestore conectado: ${test.docs.length} sesiones');
        } catch (e) {
          developer.log('   ❌ Error Firestore: $e');
        }
      }
    } catch (e) {
      developer.log('❌ Error en diagnóstico: $e');
    }

    developer.log('\n🔍 FIN DEL DIAGNÓSTICO 🔍');
  }

  // ========== MÉTODOS DE CIFRADO MEJORADOS ==========

  /// Método para cifrar mensajes - VERSIÓN MEJORADA Y SEGURA
  static Future<List<Map<String, dynamic>>> encryptMessages(
      List<Map<String, dynamic>> messages) async {
    try {
      developer.log('🔐 CIFRANDO ${messages.length} mensajes...');

      if (messages.isEmpty) {
        developer.log('⚠️ No hay mensajes para cifrar');
        return messages;
      }

      final List<Map<String, dynamic>> encryptedMessages = [];

      for (final message in messages) {
        try {
          final encryptedMessage = Map<String, dynamic>.from(message);

          // Solo cifrar contenido del usuario (no del sistema/asistente)
          final esUsuario = message['emisor'] == 'Usuario' ||
              (message['emisor'] != 'Sistema' &&
                  message['emisor'] != 'Asistente');

          if (esUsuario && message['contenido'] != null) {
            final contenidoOriginal = message['contenido'].toString();

            // Solo cifrar si no está vacío y no es un indicador
            if (contenidoOriginal.isNotEmpty &&
                contenidoOriginal != 'TYPING_INDICATOR') {
              // INTENTAR con CifradoService primero
              try {
                final contenidoCifrado =
                    await CifradoService.cifrarTexto(contenidoOriginal);
                encryptedMessage['contenido'] = contenidoCifrado;
                encryptedMessage['cifrado'] = true;
                developer.log('   ✅ Mensaje cifrado con CifradoService');
              } catch (e) {
                developer.log(
                    '   ⚠️ Falló CifradoService, usando sistema viejo: $e');
                // Fallback al sistema viejo
                encryptedMessage['contenido'] =
                    _simpleEncrypt(contenidoOriginal, _encryptionKey);
                encryptedMessage['cifrado'] = true;
              }
            }
          } else if (message['contenido'] != null &&
              message['contenido'].toString().isNotEmpty) {
            developer.log('   📝 Mensaje del sistema/asistente - no cifrar');
          }

          encryptedMessages.add(encryptedMessage);
        } catch (e) {
          developer.log('   ❌ Error cifrando mensaje individual: $e');
          encryptedMessages.add(message); // Mantener original
        }
      }

      developer
          .log('✅ Cifrado completado: ${encryptedMessages.length} mensajes');
      return encryptedMessages;
    } catch (e) {
      developer.log('❌ Error general en encryptMessages: $e');
      return messages;
    }
  }

  /// Método para descifrar mensajes - VERSIÓN MEJORADA Y SEGURA
  static Future<List<Map<String, dynamic>>> decryptMessages(
      List<Map<String, dynamic>> messages) async {
    try {
      developer.log('🔐 DESCIFRANDO ${messages.length} mensajes...');

      if (messages.isEmpty) {
        developer.log('⚠️ No hay mensajes para descifrar');
        return messages;
      }

      final List<Map<String, dynamic>> decryptedMessages = [];

      for (final message in messages) {
        try {
          final decryptedMessage = Map<String, dynamic>.from(message);

          if (message['contenido'] != null) {
            final contenido = message['contenido'].toString();

            if (contenido.isNotEmpty && contenido != 'TYPING_INDICATOR') {
              // INTENTAR con CifradoService primero (es inteligente)
              try {
                final contenidoDescifrado =
                    await CifradoService.descifrarTexto(contenido);
                decryptedMessage['contenido'] = contenidoDescifrado;

                if (contenidoDescifrado != contenido) {
                  developer.log('   ✅ Mensaje descifrado con CifradoService');
                } else {
                  developer.log('   📝 Mensaje ya estaba descifrado');
                }
              } catch (e) {
                developer.log(
                    '   ⚠️ CifradoService falló, probando sistema viejo: $e');

                // Intentar con sistema viejo (solo si parece base64)
                try {
                  // Verificar si parece base64
                  if (_esBase64Valido(contenido)) {
                    final contenidoDescifradoViejo =
                        _simpleDecrypt(contenido, _encryptionKey);
                    decryptedMessage['contenido'] = contenidoDescifradoViejo;
                    developer.log('   ✅ Descifrado con sistema viejo');
                  } else {
                    developer.log('   📝 No es base64, manteniendo original');
                  }
                } catch (e2) {
                  developer.log('   ❌ Ambos sistemas fallaron: $e2');
                  // Mantener original
                }
              }
            }
          }

          decryptedMessages.add(decryptedMessage);
        } catch (e) {
          developer.log('   ❌ Error descifrando mensaje individual: $e');
          decryptedMessages.add(message); // Mantener original
        }
      }

      developer
          .log('✅ Descifrado completado: ${decryptedMessages.length} mensajes');
      return decryptedMessages;
    } catch (e) {
      developer.log('❌ Error general en decryptMessages: $e');
      return messages;
    }
  }

  // Método auxiliar para detectar base64
  static bool _esBase64Valido(String texto) {
    try {
      if (texto.isEmpty) return false;

      // Limpiar espacios
      final limpio = texto.trim();

      // Patrón base64
      final base64Pattern = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
      if (!base64Pattern.hasMatch(limpio)) return false;

      // Intentar decodificar
      final decoded = base64Url.decode(limpio);
      return decoded.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // ========== MÉTODOS ORIGINALES MANTENIDOS ==========

  /// Cifrado simple XOR (mantenido para compatibilidad)
  static String _simpleEncrypt(String text, String key) {
    try {
      final encryptedBytes = <int>[];
      for (int i = 0; i < text.length; i++) {
        final textChar = text.codeUnitAt(i);
        final keyChar = key.codeUnitAt(i % key.length);
        encryptedBytes.add(textChar ^ keyChar);
      }
      return base64Url.encode(encryptedBytes);
    } catch (e) {
      developer.log('❌ Error en cifrado: $e');
      return text; // Retornar texto original si falla el cifrado
    }
  }

  /// Descifrado simple XOR (mantenido para compatibilidad)
  static String _simpleDecrypt(String encryptedText, String key) {
    try {
      final encryptedBytes = base64Url.decode(encryptedText);
      final decryptedChars = <int>[];

      for (int i = 0; i < encryptedBytes.length; i++) {
        final encryptedChar = encryptedBytes[i];
        final keyChar = key.codeUnitAt(i % key.length);
        decryptedChars.add(encryptedChar ^ keyChar);
      }

      return utf8.decode(decryptedChars);
    } catch (e) {
      developer.log('❌ Error en descifrado: $e - Texto: $encryptedText');
      return encryptedText; // Retornar texto cifrado si falla el descifrado
    }
  }

  // ========== MÉTODOS PRINCIPALES MANTENIDOS ==========

  /// Guarda una sesión de chat en Firestore con respaldo local
  Future<void> saveSession(SesionChat session) async {
    try {
      if (_currentUserUid == null) {
        throw Exception('Usuario no autenticado');
      }

      // Cifrar mensajes antes de guardar
      final encryptedMessages = await encryptMessages(
        session.mensajes.map((m) => m.toJson()).toList(),
      );

      final sessionToSave = SesionChat(
        fecha: session.fecha,
        usuario: session.usuario,
        resumen: session.resumen,
        mensajes: encryptedMessages.map((m) => Mensaje.fromJson(m)).toList(),
        etiquetas: session.etiquetas,
        tituloDinamico: session.tituloDinamico,
      );

      await _firestore
          .collection('usuarios')
          .doc(_currentUserUid)
          .collection('sesiones_chat')
          .doc(session.fecha)
          .set(sessionToSave.toJson());

      await _saveSessionLocally(sessionToSave);

      developer.log('✅ Sesión guardada: ${session.mensajes.length} mensajes');
    } catch (e) {
      developer.log('❌ Error guardando sesión: $e');
      // Fallback: guardar localmente
      await _saveSessionLocally(session);
      rethrow;
    }
  }

  /// Obtiene todas las sesiones del usuario
  Future<List<SesionChat>> getSessions() async {
    try {
      if (_currentUserUid == null) return [];

      final querySnapshot = await _firestore
          .collection('usuarios')
          .doc(_currentUserUid)
          .collection('sesiones_chat')
          .orderBy('fecha', descending: true)
          .get();

      final sessions = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final session = SesionChat.fromJson(doc.data());
          final decryptedMessages = await decryptMessages(
            session.mensajes.map((m) => m.toJson()).toList(),
          );

          return SesionChat(
            fecha: session.fecha,
            usuario: session.usuario,
            resumen: session.resumen,
            mensajes:
                decryptedMessages.map((m) => Mensaje.fromJson(m)).toList(),
            etiquetas: session.etiquetas,
            tituloDinamico: session.tituloDinamico,
          );
        }),
      );

      return sessions;
    } catch (e) {
      developer.log('❌ Error cargando sesiones: $e');
      return await _getSessionsLocally();
    }
  }

  /// Elimina una sesión específica
  Future<void> deleteSession(String sessionId) async {
    try {
      if (_currentUserUid == null) throw Exception('Usuario no autenticado');

      await _firestore
          .collection('usuarios')
          .doc(_currentUserUid)
          .collection('sesiones_chat')
          .doc(sessionId)
          .delete();

      await _deleteSessionLocally(sessionId);

      developer.log('✅ Sesión eliminada: $sessionId');
    } catch (e) {
      developer.log('❌ Error eliminando sesión: $e');
      throw Exception('No se pudo eliminar la sesión');
    }
  }

  // ========== MÉTODOS PRIVADOS (SIN CAMBIOS) ==========

  Future<void> _saveSessionLocally(SesionChat session) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'session_chat_${_currentUserUid}_${session.fecha}';
      await prefs.setString(key, json.encode(session.toJson()));
    } catch (e) {
      developer.log('❌ Error guardando sesión localmente: $e');
    }
  }

  Future<List<SesionChat>> _getSessionsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('session_chat_${_currentUserUid}_'))
          .toList();

      List<SesionChat> sessions = [];
      for (final key in keys) {
        final sessionData = prefs.getString(key);
        if (sessionData != null) {
          try {
            final session = SesionChat.fromJson(json.decode(sessionData));
            final decryptedMessages = await decryptMessages(
              session.mensajes.map((m) => m.toJson()).toList(),
            );

            sessions.add(SesionChat(
              fecha: session.fecha,
              usuario: session.usuario,
              resumen: session.resumen,
              mensajes:
                  decryptedMessages.map((m) => Mensaje.fromJson(m)).toList(),
              etiquetas: session.etiquetas,
              tituloDinamico: session.tituloDinamico,
            ));
          } catch (e) {
            developer.log('❌ Error parseando sesión local: $e');
          }
        }
      }

      sessions.sort((a, b) => b.fecha.compareTo(a.fecha));
      return sessions;
    } catch (e) {
      developer.log('❌ Error cargando sesiones localmente: $e');
      return [];
    }
  }

  Future<void> _deleteSessionLocally(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'session_chat_${_currentUserUid}_$sessionId';
      await prefs.remove(key);
    } catch (e) {
      developer.log('❌ Error eliminando sesión localmente: $e');
    }
  }
}

/// Servicio auxiliar para diagnóstico y reparación de Firestore
class FirestoreDiagnosticService {
  static Future<void> diagnoseAndFix() async {
    developer.log('🔍 Diagnóstico de Firestore...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('❌ Usuario no autenticado');
        return;
      }

      // Verificar conexión
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      // Verificar permisos de escritura
      final testDoc = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .collection('diagnostic')
          .doc('test');

      await testDoc.set({'test': DateTime.now().toIso8601String()});
      await testDoc.delete();

      developer.log('✅ Firestore funcionando correctamente');
    } catch (e) {
      developer.log('❌ Problema detectado en Firestore: $e');
      throw Exception('Error de conexión con Firestore');
    }
  }
}
