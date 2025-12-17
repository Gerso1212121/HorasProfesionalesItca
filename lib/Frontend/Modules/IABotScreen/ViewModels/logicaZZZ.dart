import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/mensajes.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/sesionchat.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/servicechatcifrado.dart';
import 'package:horas2/Frontend/Modules/IABotScreen/ViewModels/titulodinamicochats.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FirebaseChatStorage {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static String? get _currentUserUid => FirebaseAuth.instance.currentUser?.uid;

  static Future<void> saveSesionChat(SesionChat sesion) async {
    try {
      if (_currentUserUid == null) {
        developer.log('❌ Usuario no autenticado al guardar sesión');
        throw Exception('Usuario no autenticado');
      }

      // Generar título dinámico si no existe
      String tituloDinamico = sesion.tituloDinamico ??
          TituloDinamicoService.generarTituloDinamico(sesion.mensajes);

      // Crear nueva sesión con título dinámico
      final sesionConTitulo = SesionChat(
        fecha: sesion.fecha,
        usuario: sesion.usuario,
        resumen: sesion.resumen,
        mensajes: sesion.mensajes,
        etiquetas: sesion.etiquetas,
        tituloDinamico: tituloDinamico,
      );

      developer.log('🔄 Guardando sesión en Firebase...');
      developer.log('📝 Usuario: $_currentUserUid');
      developer.log('📝 Fecha: ${sesion.fecha}');
      developer.log('📝 Mensajes: ${sesion.mensajes.length}');
      developer.log('📝 Título dinámico: $tituloDinamico');

      // DEBUG: Verificar contenido de los mensajes
      developer.log('🔍 DEBUG - Contenido de mensajes a guardar:');
      for (int i = 0; i < min(sesion.mensajes.length, 3); i++) {
        final msg = sesion.mensajes[i];
        developer.log(
            '   [$i] ${msg.emisor}: ${msg.contenido.length > 50 ? "${msg.contenido.substring(0, 50)}..." : msg.contenido}');
      }

      // Intentar guardar en Firestore
      await _firestore
          .collection('usuarios')
          .doc(_currentUserUid)
          .collection('sesiones_chat')
          .doc(sesion.fecha)
          .set(sesionConTitulo.toJson());

      developer
          .log('✅ Sesión guardada exitosamente en Firebase: ${sesion.fecha}');

      // También guardar localmente como respaldo
      await _saveSesionLocally(sesionConTitulo);
    } catch (e) {
      developer.log('❌ Error guardando sesión en Firebase: $e');

      // Si es un error de permisos, guardar localmente como respaldo
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('permissions')) {
        developer.log('🔄 Error de permisos, guardando solo localmente...');
        await _saveSesionLocally(sesion);
      } else {
        developer
            .log('🔄 Error desconocido, guardando localmente como respaldo...');
        await _saveSesionLocally(sesion);
        rethrow;
      }
    }
  }

  static Future<void> _saveSesionLocally(SesionChat sesion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'sesion_chat_${_currentUserUid}_${sesion.fecha}';
      await prefs.setString(key, json.encode(sesion.toJson()));
      developer.log('✅ Sesión guardada localmente: $key');
    } catch (e) {
      developer.log('❌ Error guardando sesión localmente: $e');
      throw Exception(
          'No se pudo guardar la sesión ni en Firebase ni localmente');
    }
  }

  static Future<List<SesionChat>> getSesionesChat() async {
    try {
      if (_currentUserUid == null) {
        developer.log('❌ Usuario no autenticado al cargar sesiones');
        return [];
      }

      developer.log('🔄 Cargando sesiones desde Firebase...');
      developer.log('📝 Usuario: $_currentUserUid');

      final querySnapshot = await _firestore
          .collection('usuarios')
          .doc(_currentUserUid)
          .collection('sesiones_chat')
          .orderBy('fecha', descending: true)
          .get();

      final sesionesOriginales = querySnapshot.docs
          .map((doc) => SesionChat.fromJson(doc.data()))
          .toList();

      // FORZAR descifrado de mensajes de todas las sesiones
      final sesiones = <SesionChat>[];
      for (final sesionOriginal in sesionesOriginales) {
        try {
          // DESCIFRADO FORZADO: Usar método forzado que descifra TODO
          final mensajesParaDescifrar =
              sesionOriginal.mensajes.map((m) => m.toJson()).toList();

          developer.log(
              '💥 DESCIFRADO FORZADO: Descifrando ${mensajesParaDescifrar.length} mensajes para sesión: ${sesionOriginal.fecha}');

          final mensajesDescifrados =
              await CifradoService.descifrarMensajes(mensajesParaDescifrar);

          final sesionDescifrada = SesionChat(
            fecha: sesionOriginal.fecha,
            usuario: sesionOriginal.usuario,
            resumen: sesionOriginal.resumen,
            mensajes:
                mensajesDescifrados.map((m) => Mensaje.fromJson(m)).toList(),
            etiquetas: sesionOriginal.etiquetas,
            tituloDinamico: sesionOriginal.tituloDinamico,
          );
          sesiones.add(sesionDescifrada);
          developer.log(
              '🔓 FORZADO: Mensajes descifrados para sesión: ${sesionOriginal.fecha}');
        } catch (e) {
          developer.log(
              '❌ Error en descifrado forzado de sesión ${sesionOriginal.fecha}: $e');
          // Si falla el descifrado, usar la sesión original
          sesiones.add(sesionOriginal);
        }
      }

      developer.log('✅ Cargadas ${sesiones.length} sesiones desde Firebase');
      return sesiones;
    } catch (e) {
      developer.log('❌ Error cargando sesiones desde Firebase: $e');

      // Si es un error de permisos, cargar desde almacenamiento local
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('permissions')) {
        developer.log(
            '🔄 Error de permisos, cargando desde almacenamiento local...');
        return await _getSesionesLocally();
      }

      developer
          .log('🔄 Error desconocido, cargando desde almacenamiento local...');
      return await _getSesionesLocally();
    }
  }

  static Future<List<SesionChat>> _getSesionesLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('sesion_chat_${_currentUserUid}_'))
          .toList();

      developer.log(
          '🔍 Buscando sesiones locales con prefijo: sesion_chat_${_currentUserUid}_');
      developer.log('🔍 Claves encontradas: ${keys.length}');

      List<SesionChat> sesiones = [];
      for (final key in keys) {
        final sesionData = prefs.getString(key);
        if (sesionData != null) {
          try {
            final sesionOriginal = SesionChat.fromJson(json.decode(sesionData));

            // DESCIFRADO FORZADO: Descifrado de mensajes
            try {
              // DESCIFRADO FORZADO: Usar método forzado que descifra TODO
              final mensajesParaDescifrar =
                  sesionOriginal.mensajes.map((m) => m.toJson()).toList();

              developer.log(
                  '💥 DESCIFRADO FORZADO: Descifrando ${mensajesParaDescifrar.length} mensajes para sesión local: ${sesionOriginal.fecha}');

              final mensajesDescifrados =
                  await CifradoService.descifrarMensajes(mensajesParaDescifrar);

              final sesionDescifrada = SesionChat(
                fecha: sesionOriginal.fecha,
                usuario: sesionOriginal.usuario,
                resumen: sesionOriginal.resumen,
                mensajes: mensajesDescifrados
                    .map((m) => Mensaje.fromJson(m))
                    .toList(),
                etiquetas: sesionOriginal.etiquetas,
                tituloDinamico: sesionOriginal.tituloDinamico,
              );
              sesiones.add(sesionDescifrada);
              developer.log(
                  '🔓 FORZADO: Sesión local descifrada: ${sesionOriginal.fecha}');
            } catch (e) {
              developer.log(
                  '❌ Error en descifrado forzado de sesión local ${sesionOriginal.fecha}: $e');
              // Si falla el descifrado, usar la sesión original
              sesiones.add(sesionOriginal);
            }
          } catch (e) {
            developer.log('❌ Error parseando sesión local: $e');
          }
        }
      }

      // Ordenar por fecha descendente
      sesiones.sort((a, b) => b.fecha.compareTo(a.fecha));

      developer.log(
          '✅ Cargadas ${sesiones.length} sesiones desde almacenamiento local');
      return sesiones;
    } catch (e) {
      developer.log('❌ Error cargando sesiones localmente: $e');
      return [];
    }
  }

  static Future<void> deleteSesionChat(String fecha) async {
    try {
      if (_currentUserUid == null) throw Exception('Usuario no autenticado');

      // Eliminar de Firebase
      await _firestore
          .collection('usuarios')
          .doc(_currentUserUid)
          .collection('sesiones_chat')
          .doc(fecha)
          .delete();

      developer.log('✅ Sesión eliminada de Firebase: $fecha');

      // También eliminar localmente para asegurar consistencia
      await _deleteSesionLocally(fecha);
    } catch (e) {
      developer.log('❌ Error eliminando sesión de Firebase: $e');

      // Si es un error de permisos, eliminar localmente
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('permissions')) {
        developer.log('🔄 Eliminando sesión localmente...');
        await _deleteSesionLocally(fecha);
      } else {
        // Intentar eliminar localmente de todas formas
        try {
          await _deleteSesionLocally(fecha);
        } catch (localError) {
          developer.log('❌ Error eliminando sesión localmente: $localError');
        }
        rethrow;
      }
    }
  }

  static Future<void> _deleteSesionLocally(String fecha) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'sesion_chat_${_currentUserUid}_$fecha';
      await prefs.remove(key);
      developer.log('✅ Sesión eliminada localmente: $key');
    } catch (e) {
      developer.log('❌ Error eliminando sesión localmente: $e');
      throw Exception('No se pudo eliminar la sesión');
    }
  }

  static Future<void> deleteAllSesionesChat() async {
    try {
      if (_currentUserUid == null) throw Exception('Usuario no autenticado');

      // Eliminar de Firebase
      final querySnapshot = await _firestore
          .collection('usuarios')
          .doc(_currentUserUid)
          .collection('sesiones_chat')
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      developer.log('✅ Todas las sesiones eliminadas de Firebase');

      // También eliminar localmente para asegurar consistencia
      await _deleteAllSesionesLocally();
    } catch (e) {
      developer.log('❌ Error eliminando todas las sesiones: $e');

      // Si es un error de permisos, eliminar localmente
      if (e.toString().contains('permission-denied') ||
          e.toString().contains('permissions')) {
        developer.log('🔄 Eliminando todas las sesiones localmente...');
        await _deleteAllSesionesLocally();
      } else {
        // Intentar eliminar localmente de todas formas
        try {
          await _deleteAllSesionesLocally();
        } catch (localError) {
          developer.log('❌ Error eliminando sesiones localmente: $localError');
        }
        rethrow;
      }
    }
  }

  static Future<void> _deleteAllSesionesLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((key) => key.startsWith('sesion_chat_${_currentUserUid}_'))
          .toList();

      for (final key in keys) {
        await prefs.remove(key);
      }

      developer.log('✅ Todas las sesiones eliminadas localmente');
    } catch (e) {
      developer.log('❌ Error eliminando todas las sesiones localmente: $e');
      throw Exception('No se pudieron eliminar las sesiones');
    }
  }
}
