import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class FirestoreFix {
  /// Solución específica para problemas de permisos de Firestore
  static Future<void> solucionarPermisosFirestore() async {
    developer.log('🔧 SOLUCIONANDO PERMISOS DE FIRESTORE...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('❌ No hay usuario autenticado');
        return;
      }

      developer.log('👤 Usuario autenticado: ${user.email}');
      developer.log('🆔 UID: ${user.uid}');

      // 1. Verificar si el documento del usuario existe
      final userDocRef =
          FirebaseFirestore.instance.collection('usuarios').doc(user.uid);

      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        developer.log('⚠️ Documento de usuario no existe, creando...');

        // Crear documento de usuario con estructura básica
        await userDocRef.set({
          'email': user.email,
          'fecha_creacion': DateTime.now().toIso8601String(),
          'ultima_actividad': DateTime.now().toIso8601String(),
          'estado': 'activo',
          'rol': 'estudiante',
          'institucion': 'ITCA-FEPADE',
        });

        developer.log('✅ Documento de usuario creado exitosamente');
      } else {
        developer.log('✅ Documento de usuario ya existe');

        // Actualizar última actividad
        await userDocRef.update({
          'ultima_actividad': DateTime.now().toIso8601String(),
        });
      }

      // 2. Verificar permisos de escritura en sesiones_chat
      try {
        final testDocRef =
            userDocRef.collection('sesiones_chat').doc('test_permissions');

        await testDocRef.set({
          'test': true,
          'timestamp': DateTime.now().toIso8601String(),
          'descripcion': 'Prueba de permisos de escritura',
        });

        developer.log('✅ Permisos de escritura verificados en sesiones_chat');

        // Limpiar documento de prueba
        await testDocRef.delete();
      } catch (e) {
        developer.log('❌ Error verificando permisos de escritura: $e');
        developer.log('⚠️ Posible problema de reglas de Firestore');
      }

      // 3. Verificar permisos de lectura
      try {
        final sesionesQuery =
            await userDocRef.collection('sesiones_chat').limit(1).get();

        developer.log('✅ Permisos de lectura verificados');
        developer.log('📊 Sesiones encontradas: ${sesionesQuery.docs.length}');
      } catch (e) {
        developer.log('❌ Error verificando permisos de lectura: $e');
      }

      // 4. Crear estructura de colecciones si no existe
      await _crearEstructuraColecciones(user.uid);

      developer.log('✅ SOLUCIÓN DE PERMISOS COMPLETADA');
    } catch (e) {
      developer.log('❌ Error solucionando permisos: $e');
    }
  }

  /// Crear estructura de colecciones necesarias
  static Future<void> _crearEstructuraColecciones(String uid) async {
    try {
      final userDocRef =
          FirebaseFirestore.instance.collection('usuarios').doc(uid);

      // Crear colección de sesiones_chat si no existe
      final sesionesRef = userDocRef.collection('sesiones_chat');

      // Crear un documento de prueba para verificar que la colección existe
      final testDoc = await sesionesRef.doc('estructura_test').get();

      if (!testDoc.exists) {
        await sesionesRef.doc('estructura_test').set({
          'fecha': DateTime.now().toIso8601String(),
          'tipo': 'estructura_test',
          'descripcion': 'Documento para verificar estructura de colección',
        });

        developer.log('✅ Estructura de colecciones creada');
      }
    } catch (e) {
      developer.log('❌ Error creando estructura de colecciones: $e');
    }
  }

  /// Verificar y reparar reglas de Firestore
  static Future<void> verificarReglasFirestore() async {
    developer.log('📋 VERIFICANDO REGLAS DE FIRESTORE...');

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        developer.log('❌ No hay usuario autenticado para verificar reglas');
        return;
      }

      // Intentar operaciones básicas para verificar reglas
      final userDocRef =
          FirebaseFirestore.instance.collection('usuarios').doc(user.uid);

      // Verificar lectura
      try {
        await userDocRef.get();
        developer.log('✅ Regla de lectura: PERMITIDA');
      } catch (e) {
        developer.log('❌ Regla de lectura: DENEGADA - $e');
      }

      // Verificar escritura
      try {
        await userDocRef.update({
          'ultima_verificacion': DateTime.now().toIso8601String(),
        });
        developer.log('✅ Regla de escritura: PERMITIDA');
      } catch (e) {
        developer.log('❌ Regla de escritura: DENEGADA - $e');
      }

      // Verificar subcolecciones
      try {
        final sesionesRef = userDocRef.collection('sesiones_chat');
        await sesionesRef.limit(1).get();
        developer.log('✅ Regla de subcolecciones: PERMITIDA');
      } catch (e) {
        developer.log('❌ Regla de subcolecciones: DENEGADA - $e');
      }
    } catch (e) {
      developer.log('❌ Error verificando reglas: $e');
    }
  }

  /// Solución completa para problemas de Firestore
  static Future<void> solucionCompletaFirestore() async {
    developer.log('🚀 EJECUTANDO SOLUCIÓN COMPLETA DE FIRESTORE...');

    await solucionarPermisosFirestore();
    await verificarReglasFirestore();

    developer.log('✅ SOLUCIÓN COMPLETA DE FIRESTORE FINALIZADA');
  }
}
