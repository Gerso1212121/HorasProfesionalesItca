import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class DebugHelper {
  static Future<void> diagnosticarProblemas() async {
    developer.log('🔍 INICIANDO DIAGNÓSTICO COMPLETO...');

    // 1. Verificar autenticación de Firebase
    await _verificarAutenticacion();

    // 2. Verificar conexión a Firestore
    await _verificarFirestore();

    // 3. Verificar almacenamiento local
    await _verificarAlmacenamientoLocal();

    // 4. Verificar configuración de la aplicación
    await _verificarConfiguracion();

    developer.log('✅ DIAGNÓSTICO COMPLETADO');
  }

  static Future<void> _verificarAutenticacion() async {
    developer.log('🔐 Verificando autenticación...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        developer.log('✅ Usuario autenticado: ${user.email}');
        developer.log('🆔 UID: ${user.uid}');
        developer.log('📧 Email verificado: ${user.emailVerified}');
      } else {
        developer.log('❌ No hay usuario autenticado');
      }
    } catch (e) {
      developer.log('❌ Error verificando autenticación: $e');
    }
  }

  static Future<void> _verificarFirestore() async {
    developer.log('🔥 Verificando conexión a Firestore...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Intentar leer una colección de prueba
        final testDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();

        if (testDoc.exists) {
          developer.log('✅ Documento de usuario existe en Firestore');
        } else {
          developer.log('⚠️ Documento de usuario no existe, creando...');
          await FirebaseFirestore.instance
              .collection('usuarios')
              .doc(user.uid)
              .set({
            'email': user.email,
            'fecha_creacion': DateTime.now().toIso8601String(),
            'ultima_actividad': DateTime.now().toIso8601String(),
          });
          developer.log('✅ Documento de usuario creado');
        }

        // Verificar permisos de escritura
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('test')
            .doc('test')
            .set({'test': true});

        developer.log('✅ Permisos de escritura verificados');

        // Limpiar documento de prueba
        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .collection('test')
            .doc('test')
            .delete();
      } else {
        developer
            .log('❌ No se puede verificar Firestore sin usuario autenticado');
      }
    } catch (e) {
      developer.log('❌ Error verificando Firestore: $e');
      if (e.toString().contains('permission-denied')) {
        developer.log('⚠️ Problema de permisos en Firestore');
      }
    }
  }

  static Future<void> _verificarAlmacenamientoLocal() async {
    developer.log('📱 Verificando almacenamiento local...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      developer.log('📊 Total de claves en SharedPreferences: ${keys.length}');

      // Buscar sesiones locales
      final sesionKeys =
          keys.where((key) => key.contains('sesion_chat_')).toList();
      developer.log('💬 Sesiones locales encontradas: ${sesionKeys.length}');

      for (final key in sesionKeys.take(3)) {
        final data = prefs.getString(key);
        if (data != null) {
          try {
            final sesion = json.decode(data);
            developer.log(
                '📝 Sesión local: ${sesion['fecha']} - ${sesion['mensajes']?.length ?? 0} mensajes');
          } catch (e) {
            developer.log('❌ Error parseando sesión local: $e');
          }
        }
      }
    } catch (e) {
      developer.log('❌ Error verificando almacenamiento local: $e');
    }
  }

  static Future<void> _verificarConfiguracion() async {
    developer.log('⚙️ Verificando configuración...');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Verificar configuración de IA
      final comportamiento = prefs.getString('comportamiento_ia');
      final reglas = prefs.getString('reglas_ia');

      developer
          .log('🤖 Comportamiento IA configurado: ${comportamiento != null}');
      developer.log('📋 Reglas IA configuradas: ${reglas != null}');

      if (comportamiento == null || reglas == null) {
        developer.log(
            '⚠️ Configuración de IA incompleta, estableciendo valores por defecto...');

        await prefs.setString('comportamiento_ia',
            'Eres un asistente psicológico empático y profesional que:\n- Utiliza un tono cálido y comprensivo\n- Proporciona respuestas basadas en la psicología científica\n- Ofrece herramientas prácticas para el desarrollo emocional\n- Mantiene un enfoque ético y profesional\n- Adapta su comunicación según las necesidades del usuario\n- Utiliza la base de conocimiento de libros de psicología para fundamentar sus respuestas');

        await prefs.setString('reglas_ia',
            '1. Siempre prioriza el bienestar emocional del usuario\n2. No proporcionar diagnósticos médicos o psicológicos\n3. Recomendar buscar ayuda profesional cuando sea necesario\n4. Mantener confidencialidad y respeto\n5. Usar lenguaje claro y accesible\n6. Basar respuestas en evidencia científica de los libros de psicología\n7. Fomentar la autoconciencia y el desarrollo personal\n8. Utilizar conceptos de inteligencia emocional de Daniel Goleman\n9. Referenciar técnicas psicológicas cuando sea apropiado');

        developer.log('✅ Configuración de IA establecida por defecto');
      }
    } catch (e) {
      developer.log('❌ Error verificando configuración: $e');
    }
  }

  static Future<void> limpiarDatosCorruptos() async {
    developer.log('🧹 Limpiando datos corruptos...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      // Limpiar sesiones corruptas
      final sesionKeys =
          keys.where((key) => key.contains('sesion_chat_')).toList();

      for (final key in sesionKeys) {
        final data = prefs.getString(key);
        if (data != null) {
          try {
            json.decode(data); // Verificar si es JSON válido
          } catch (e) {
            developer.log('🗑️ Eliminando sesión corrupta: $key');
            await prefs.remove(key);
          }
        }
      }

      developer.log('✅ Limpieza de datos corruptos completada');
    } catch (e) {
      developer.log('❌ Error limpiando datos corruptos: $e');
    }
  }

  static Future<void> forzarReconexion() async {
    developer.log('🔄 Forzando reconexión...');

    try {
      // Cerrar sesión actual
      await FirebaseAuth.instance.signOut();
      developer.log('✅ Sesión cerrada');

      // Esperar un momento
      await Future.delayed(Duration(seconds: 2));

      // Verificar si hay usuario en SharedPreferences para reconectar
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('last_user_email');

      if (email != null) {
        developer.log('📧 Intentando reconectar con: $email');
        // Aquí podrías implementar la reconexión automática si es necesario
      }

      developer.log('✅ Reconexión forzada completada');
    } catch (e) {
      developer.log('❌ Error en reconexión forzada: $e');
    }
  }
}
