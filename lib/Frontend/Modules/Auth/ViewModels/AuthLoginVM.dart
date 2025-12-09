// lib/Frontend/Modules/Auth/viewmodels/login_viewmodel.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthLoginVM extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  User? _currentUser;
  DateTime? lastPasswordResetRequest;
  Timer? _resetTimer;

  // Getters
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;

  // Verificar si puede solicitar otro reset (mínimo 2 minutos entre solicitudes)
  bool get canRequestPasswordReset {
    if (lastPasswordResetRequest == null) return true;
    final now = DateTime.now();
    final difference = now.difference(lastPasswordResetRequest!);
    return difference.inMinutes >= 2;
  }

  String get timeUntilNextReset {
    if (lastPasswordResetRequest == null) return '';
    final now = DateTime.now();
    final difference = now.difference(lastPasswordResetRequest!);
    final remainingSeconds = 120 - difference.inSeconds;

    if (remainingSeconds <= 0) return '';

    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;

    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    setLoading(true);

    try {
      print('🔐 Intentando login para: $email');

      // 1. Iniciar sesión en Firebase
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User user = userCredential.user!;
      print('✅ Usuario autenticado: ${user.uid}');

      // 2. Verificar si el email está verificado
      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null || !refreshedUser.emailVerified) {
        print('⚠️ Email no verificado para: ${user.email}');
        setLoading(false);
        return {
          'success': true,
          'user': user,
          'needsVerification': true,
          'needsData': false,
          'esItca': email.toLowerCase().endsWith('@itca.edu.sv'),
        };
      }

      print('✅ Email verificado correctamente');

      // 3. Verificar si el usuario existe en la colección "estudiantes"
      final studentDoc =
          await _firestore.collection('estudiantes').doc(user.uid).get();

      if (!studentDoc.exists) {
        print('❌ Usuario no encontrado en colección "estudiantes"');
        setLoading(false);
        return {
          'success': true,
          'user': user,
          'needsVerification': false,
          'needsData': true,
          'esItca': email.toLowerCase().endsWith('@itca.edu.sv'),
        };
      }

      final studentData = studentDoc.data() as Map<String, dynamic>?;
      print('📄 Datos encontrados en Firestore: ${studentData != null}');

      // DEBUG: Imprimir todos los datos
      if (studentData != null) {
        print('📋 Todos los campos del documento:');
        studentData.forEach((key, value) {
          print('   "$key": "$value" (tipo: ${value.runtimeType})');
        });
      }

      // Función auxiliar para verificar campos
      bool _campoValido(String campo, Map<String, dynamic>? data) {
        if (data == null || !data.containsKey(campo)) return false;

        final valor = data[campo];
        if (valor == null) return false;

        final valorStr = valor.toString().trim();
        return valorStr.isNotEmpty;
      }

      // 4. Verificar datos básicos obligatorios para TODOS los usuarios
      final tieneNombre = _campoValido('nombre', studentData);
      final tieneApellido = _campoValido('apellido', studentData);
      final tieneTelefono = _campoValido('telefono', studentData);

      print('🔍 Verificación datos básicos:');
      print('   Nombre: $tieneNombre');
      print('   Apellido: $tieneApellido');
      print('   Teléfono: $tieneTelefono');

      if (!tieneNombre || !tieneApellido || !tieneTelefono) {
        print('📝 Usuario necesita completar datos básicos');
        setLoading(false);
        return {
          'success': true,
          'user': user,
          'needsVerification': false,
          'needsData': true,
          'esItca': email.toLowerCase().endsWith('@itca.edu.sv'),
        };
      }

      // 5. Determinar si es ITCA
      final esItca = email.toLowerCase().endsWith('@itca.edu.sv');
      print('🎓 Es ITCA: $esItca');

      // 6. Si es ITCA, verificar datos adicionales específicos
      if (esItca) {
        print('🔍 Verificando datos ITCA específicos...');

        // Verificar carrera y sede
        final carreraValida = _campoValido('carrera', studentData);
        final sedeValida = _campoValido('sede', studentData);

        // Buscar campo de año - probar diferentes nombres
        bool anioValido = false;
        String anioCampoNombre = '';
        String? anioValor;

        // Lista de posibles nombres para el campo "año"
        final posiblesNombresAnio = [
          'anio_ingreso',
          'año',
          'anio',
          'ano',
          'year',
          'año_ingreso'
        ];

        for (final nombre in posiblesNombresAnio) {
          if (_campoValido(nombre, studentData)) {
            anioCampoNombre = nombre;
            anioValor = studentData![nombre].toString().trim();
            anioValido = anioValor.isNotEmpty;
            break;
          }
        }

        print('🔍 Campos ITCA encontrados:');
        print('   Carrera: $carreraValida');
        print('   Sede: $sedeValida');
        print('   Año ($anioCampoNombre): $anioValido');
        if (anioValor != null) print('   Valor de año: "$anioValor"');

        // Verificar que todos los campos estén presentes
        if (!carreraValida || !sedeValida || !anioValido) {
          print(
              '🎓 Estudiante ITCA necesita datos adicionales (faltan campos)');
          setLoading(false);
          return {
            'success': true,
            'user': user,
            'needsVerification': false,
            'needsData': true,
            'esItca': true,
          };
        }

        // Verificar que los valores no sean placeholders
        final valoresInvalidos = [
          'sin definir',
          'undefined',
          'null',
          'vacío',
          'pendiente',
          'seleccionar',
          'elige',
          'selecciona',
          '',
          '0',
          '0000'
        ];

        final carrera = studentData!['carrera'].toString().trim();
        final sede = studentData['sede'].toString().trim();

        final carreraInvalida =
            valoresInvalidos.contains(carrera.toLowerCase());
        final sedeInvalida = valoresInvalidos.contains(sede.toLowerCase());
        final anioInvalido = anioValor != null &&
            (valoresInvalidos.contains(anioValor.toLowerCase()) ||
                !RegExp(r'^\d{4}$').hasMatch(anioValor!));

        print('🔍 Validación valores ITCA:');
        print('   Carrera válida: ${!carreraInvalida} ("$carrera")');
        print('   Sede válida: ${!sedeInvalida} ("$sede")');
        print('   Año válido: ${!anioInvalido} ("$anioValor")');

        if (carreraInvalida || sedeInvalida || anioInvalido) {
          print('🎓 Estudiante ITCA tiene valores inválidos o placeholders');
          setLoading(false);
          return {
            'success': true,
            'user': user,
            'needsVerification': false,
            'needsData': true,
            'esItca': true,
          };
        }
      } else {
        // 7. Si NO es ITCA, limpiar datos ITCA si existen
        print('👤 Usuario NO ITCA - verificando datos ITCA para limpiar');

        final camposItca = [
          'carrera',
          'sede',
          'año',
          'anio',
          'ano',
          'year',
          'anio_ingreso'
        ];
        final updateData = <String, dynamic>{};

        bool tieneCamposItca = false;

        for (final campo in camposItca) {
          if (studentData?.containsKey(campo) == true) {
            final valor = studentData![campo];
            if (valor != null && valor.toString().trim().isNotEmpty) {
              print('   ⚠️ Campo ITCA encontrado: $campo = $valor');
              tieneCamposItca = true;
              updateData[campo] = null;
            }
          }
        }

        if (tieneCamposItca) {
          print('⚠️ Usuario no ITCA tiene datos ITCA. Limpiando...');
          try {
            await _firestore
                .collection('estudiantes')
                .doc(user.uid)
                .update(updateData);
            print('✅ Datos ITCA limpiados correctamente');
          } catch (e) {
            print('❌ Error al limpiar datos ITCA: $e');
            // No lanzamos excepción, solo logueamos el error
          }
        }
      }

      print('✅ Login exitoso - Todo verificado');
      setLoading(false);
      return {
        'success': true,
        'user': user,
        'needsVerification': false,
        'needsData': false,
        'esItca': esItca,
      };
    } on FirebaseAuthException catch (e) {
      setLoading(false);
      print('🔥 Error Firebase: ${e.code} - ${e.message}');

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido';
          break;
        case 'user-disabled':
          errorMessage = 'Cuenta deshabilitada';
          break;
        case 'too-many-requests':
          errorMessage = 'Demasiados intentos. Espera unos minutos.';
          break;
        case 'network-request-failed':
          errorMessage = 'Error de conexión a internet';
          break;
        default:
          errorMessage = 'Error de autenticación: ${e.message}';
      }

      throw Exception(errorMessage);
    } catch (e) {
      setLoading(false);
      print('❌ Error inesperado: $e');
      rethrow;
    }
  }

  // ✅ MÉTODO PARA ENVIAR CORREO DE VERIFICACIÓN (igual que en registro)
  Future<void> sendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('📧 Correo de verificación enviado a: ${user.email}');
      } else {
        print('ℹ️ Usuario ya verificado o no disponible');
      }
    } catch (e) {
      print('❌ Error al enviar correo de verificación: $e');
      throw Exception('Error al enviar correo de verificación');
    }
  }

  // ✅ MÉTODO PARA VERIFICAR SI EL CORREO YA SE VERIFICÓ
  Future<bool> checkEmailVerified() async {
    try {
      await _auth.currentUser?.reload();
      final user = _auth.currentUser;
      final isVerified = user?.emailVerified ?? false;
      print('🔍 Estado de verificación: $isVerified');
      return isVerified;
    } catch (e) {
      print('❌ Error al verificar estado: $e');
      return false;
    }
  }

  // ✅ MÉTODO PARA REENVIAR CORREO DE RECUPERACIÓN - VERSIÓN CORREGIDA
  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    print('🔐 Intentando reset de contraseña para: $email');

    if (!canRequestPasswordReset) {
      print('⏰ Espera requerida. Tiempo restante: $timeUntilNextReset');
      throw Exception(
          'Por favor espera $timeUntilNextReset antes de solicitar otro correo');
    }

    try {
      // 1. Primero enviar el correo
      print('📧 Enviando correo de recuperación...');
      await _auth.sendPasswordResetEmail(email: email.trim());
      print('✅ Correo de recuperación enviado exitosamente a: $email');

      // 2. Solo iniciar el timer si el envío fue exitoso
      _startResetTimer();
      print('⏰ Timer iniciado para nueva solicitud');
    } on FirebaseAuthException catch (e) {
      print('🔥 Error Firebase al resetear: ${e.code} - ${e.message}');

      // 3. Traducir errores de Firebase a mensajes amigables
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          // NO iniciamos el timer para usuario no encontrado
          errorMessage = 'No existe una cuenta con este correo electrónico.';
          break;
        case 'invalid-email':
          errorMessage = 'El correo electrónico no es válido.';
          break;
        case 'too-many-requests':
          errorMessage = 'Demasiados intentos. Por favor espera unos minutos.';
          break;
        case 'network-request-failed':
          errorMessage = 'Error de conexión. Verifica tu internet.';
          break;
        default:
          errorMessage = 'Error al enviar correo: ${e.message}';
      }

      print('❌ Error de reset: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Error inesperado al resetear: $e');
      throw Exception('Error inesperado al enviar correo de recuperación');
    }
  }

// En el AuthLoginVM, corrige el método checkUserAfterVerification:
  Future<Map<String, dynamic>> checkUserAfterVerification() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || !user.emailVerified) {
        throw Exception('Usuario no verificado');
      }

      // ✅ CORREGIDO: Verificar en la colección 'estudiantes' (no 'users')
      final userDoc = await FirebaseFirestore.instance
          .collection('estudiantes') // ← CAMBIA de 'users' a 'estudiantes'
          .doc(user.uid)
          .get();

      // Verificar datos básicos obligatorios
      final hasCompleteData = userDoc.exists &&
          userDoc.data()?['nombre'] != null &&
          userDoc.data()?['apellido'] != null &&
          userDoc.data()?['telefono'] != null;

      final isItcaEmail = user.email?.endsWith('@itca.edu.sv') ?? false;

      // Si es ITCA, verificar campos adicionales
      if (isItcaEmail && userDoc.exists) {
        final data = userDoc.data()!;
        final tieneCarrera = data['carrera'] != null &&
            data['carrera'].toString().trim().isNotEmpty;
        final tieneSede =
            data['sede'] != null && data['sede'].toString().trim().isNotEmpty;
        final tieneAnio = data['anio_ingreso'] != null &&
            data['anio_ingreso'].toString().trim().isNotEmpty;

        if (!tieneCarrera || !tieneSede || !tieneAnio) {
          return {
            'success': true,
            'user': user,
            'needsData': true,
            'esItca': true,
          };
        }
      }

      return {
        'success': true,
        'user': user,
        'needsData': !hasCompleteData,
        'esItca': isItcaEmail,
      };
    } catch (e) {
      print('❌ Error en checkUserAfterVerification: $e');
      rethrow;
    }
  } // Método para iniciar el timer - VERSIÓN CORREGIDA

  void _startResetTimer() {
    print('⏰ Iniciando timer de 2 minutos...');
    lastPasswordResetRequest = DateTime.now();
    print('🕐 Última solicitud registrada: $lastPasswordResetRequest');

    // Cancelar timer anterior si existe
    _resetTimer?.cancel();

    // Iniciar nuevo timer
    _resetTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      print('⏰ Timer tick - Verificando si ya pasaron 2 minutos');
      if (canRequestPasswordReset) {
        print('✅ Ya pueden realizarse nuevas solicitudes');
        timer.cancel();
      }
      notifyListeners();
    });

    notifyListeners();
  }

  // ✅ CERRAR SESIÓN
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _currentUser = null;
      print('👋 Sesión cerrada');
      notifyListeners();
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      throw Exception('Error al cerrar sesión');
    }
  }

  // Helpers
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
