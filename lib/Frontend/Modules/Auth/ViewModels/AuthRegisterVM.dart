import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class AuthRegisterVM extends ChangeNotifier {
  // StreamControllers para estado reactivo
  final _emailController = StreamController<String?>.broadcast();
  final _passwordController = StreamController<String?>.broadcast();
  final _confirmPasswordController = StreamController<String?>.broadcast();
  final _passwordStrengthController = StreamController<int>.broadcast();
  final _termsAcceptedController = StreamController<bool>.broadcast();
  final _loadingController = StreamController<bool>.broadcast();

  // Estado interno
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  bool _termsAccepted = false;
  bool _isDisposed = false;

  // GETTERS CORREGIDOS para la UI
  String? get emailError => _lastEmailError;
  String? get passwordError => _lastPasswordError;
  String? get confirmPasswordError => _lastConfirmPasswordError;
  int get passwordStrength => _lastPasswordStrength;
  bool get termsAccepted => _termsAccepted;

  // Variables para almacenar los últimos valores de error
  String? _lastEmailError;
  String? _lastPasswordError;
  String? _lastConfirmPasswordError;
  int _lastPasswordStrength = 0;

  // Getters para streams
  Stream<String?> get emailErrorStream => _emailController.stream;
  Stream<String?> get passwordErrorStream => _passwordController.stream;
  Stream<String?> get confirmPasswordErrorStream =>
      _confirmPasswordController.stream;
  Stream<int> get passwordStrengthStream => _passwordStrengthController.stream;
  Stream<bool> get termsAcceptedStream => _termsAcceptedController.stream;
  Stream<bool> get loadingStream => _loadingController.stream;

// En tu AuthRegisterVM, agrega estos getters al final:
  // ✅ GETTERS PARA VALIDACIONES EN TIEMPO REAL
  bool get isEmailValid {
    if (_email.isEmpty) return false;
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(_email);
  }

  bool get isPasswordValid {
    return _password.isNotEmpty && _password.length >= 6;
  }

  bool get isConfirmPasswordValid {
    return _confirmPassword.isNotEmpty && _password == _confirmPassword;
  }

  // Método seguro para agregar eventos a streams
  void _addToStream<T>(StreamController<T> controller, T value) {
    if (!_isDisposed && !controller.isClosed) {
      try {
        controller.add(value);
      } catch (e) {
        print('⚠️ Error agregando a stream: $e');
      }
    }
  }

  // Métodos para actualizar estado
  void updateTermsAccepted(bool accepted) {
    if (_isDisposed) return;
    _termsAccepted = accepted;
    _addToStream(_termsAcceptedController, accepted);
    notifyListeners();
  }

  void updateEmail(String email) {
    if (_isDisposed) return;
    _email = email.trim();
    _validateEmail();
    notifyListeners();
  }

void updatePassword(String password) {
  if (_isDisposed) return;
  _password = password;
  _validatePassword();
  _calculatePasswordStrength();
  
  // ✅ IMPORTANTE: Re-validar la confirmación cuando cambia la contraseña
  if (_confirmPassword.isNotEmpty) {
    _validateConfirmPassword();
  }
  
  notifyListeners();
}

// En _validateConfirmPassword, asegurarse de usar la contraseña actual
void _validateConfirmPassword() {
  if (_confirmPassword.isEmpty) {
    _lastConfirmPasswordError = null;
    _addToStream(_confirmPasswordController, null);
    return;
  }

  // ✅ Esto ya debería usar _password que se actualizó
  if (_password != _confirmPassword) {
    _lastConfirmPasswordError = 'Las contraseñas no coinciden';
    _addToStream(_confirmPasswordController, _lastConfirmPasswordError);
  } else {
    _lastConfirmPasswordError = null;
    _addToStream(_confirmPasswordController, null);
  }
}

  void updateConfirmPassword(String confirmPassword) {
    if (_isDisposed) return;
    _confirmPassword = confirmPassword;
    _validateConfirmPassword();
    notifyListeners();
  }

  // Validaciones
  void _validateEmail() {
    if (_email.isEmpty) {
      _lastEmailError = null;
      _addToStream(_emailController, null);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_email)) {
      _lastEmailError = 'Por favor ingresa un correo válido';
      _addToStream(_emailController, _lastEmailError);
    } else {
      _lastEmailError = null;
      _addToStream(_emailController, null);
    }
  }

  void _validatePassword() {
    if (_password.isEmpty) {
      _lastPasswordError = null;
      _addToStream(_passwordController, null);
      return;
    }

    if (_password.length < 6) {
      _lastPasswordError = 'La contraseña debe tener al menos 6 caracteres';
      _addToStream(_passwordController, _lastPasswordError);
    } else {
      _lastPasswordError = null;
      _addToStream(_passwordController, null);
    }
  }


  // Calcula la fuerza de la contraseña (0-4)
  void _calculatePasswordStrength() {
    if (_isDisposed) return;

    if (_password.isEmpty) {
      _lastPasswordStrength = 0;
      _addToStream(_passwordStrengthController, 0);
      return;
    }

    int strength = 0;

    // Longitud
    if (_password.length >= 8) strength += 1;
    // Contiene mayúsculas
    if (_password.contains(RegExp(r'[A-Z]'))) strength += 1;
    // Contiene minúsculas
    if (_password.contains(RegExp(r'[a-z]'))) strength += 1;
    // Contiene números
    if (_password.contains(RegExp(r'[0-9]'))) strength += 1;
    // Contiene caracteres especiales
    if (_password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 1;

    // Limitar a máximo 4
    _lastPasswordStrength = strength > 4 ? 4 : strength;
    _addToStream(_passwordStrengthController, _lastPasswordStrength);
  }

  // ✅ MÉTODO PARA VALIDAR TODO EL FORMULARIO
  bool isFormValid() {
    if (_isDisposed) return false;

    // 1. Validar formato de email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (_email.isEmpty || !emailRegex.hasMatch(_email)) {
      return false;
    }

    // 2. Validar longitud de contraseña
    if (_password.isEmpty || _password.length < 6) {
      return false;
    }

    // 3. Validar coincidencia de contraseñas
    if (_confirmPassword.isEmpty || _password != _confirmPassword) {
      return false;
    }

    // 4. Validar términos
    if (!_termsAccepted) {
      return false;
    }

    return true;
  }



// En AuthRegisterVM.dart, modifica el método register():
// En AuthRegisterVM, cambia el método register para recibir parámetros:
Future<User> register({
  required String email,
  required String password,
}) async {
  if (_isDisposed) {
    throw Exception('El ViewModel ya fue desechado');
  }

  try {
    _addToStream(_loadingController, true);
    print('🔄 AuthRegisterVM.register() iniciando...');
    print('📧 Email recibido: $email');
    print('🔐 Password length: ${password.length}');

    // Validar que no estén vacíos
    if (email.isEmpty) {
      throw Exception('El email no puede estar vacío');
    }
    if (password.isEmpty) {
      throw Exception('La contraseña no puede estar vacía');
    }

    // 1. Crear usuario en Firebase
    print('🚀 Llamando a FirebaseAuth.instance.createUserWithEmailAndPassword...');
    final UserCredential userCredential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    print('✅ Usuario creado en Firebase: ${userCredential.user?.uid}');
    
    // Actualizar estado interno
    _email = email;
    _password = password;

    final User user = userCredential.user!;

    // 2. Enviar correo de verificación
    print('📧 Enviando email de verificación...');
    await user.sendEmailVerification();
    print('✅ Email de verificación enviado');

    _addToStream(_loadingController, false);
    print('✅ Registro completado exitosamente');

    return user;
  } on FirebaseAuthException catch (e) {
    print('🔥 ERROR FirebaseAuthException en register():');
    print('   Código: ${e.code}');
    print('   Mensaje: ${e.message}');
    print('   StackTrace: ${e.stackTrace}');
    
    _addToStream(_loadingController, false);
    
    // Mejora los mensajes de error
    String errorMessage;
    switch (e.code) {
      case 'email-already-in-use':
        errorMessage = 'Este correo ya está registrado. ¿Intentas iniciar sesión?';
        break;
      case 'invalid-email':
        errorMessage = 'Correo electrónico no válido';
        break;
      case 'operation-not-allowed':
        errorMessage = 'El registro con correo/contraseña no está habilitado en Firebase Console';
        break;
      case 'weak-password':
        errorMessage = 'La contraseña es demasiado débil. Usa al menos 6 caracteres';
        break;
      case 'too-many-requests':
        errorMessage = 'Demasiados intentos. Espera unos minutos';
        break;
      case 'network-request-failed':
        errorMessage = 'Error de conexión a internet';
        break;
      default:
        errorMessage = 'Error de registro: ${e.message ?? "Código: ${e.code}"}';
    }
    
    print('📤 Lanzando excepción: $errorMessage');
    throw Exception(errorMessage);
  } catch (e, stackTrace) {
    print('❌ ERROR GENERAL en register():');
    print('   Error: $e');
    print('   StackTrace: $stackTrace');
    
    _addToStream(_loadingController, false);
    throw Exception('Error inesperado al registrar: $e');
  }
}

  // ✅ MÉTODO PARA VERIFICAR SI EL EMAIL ESTÁ VERIFICADO
  Future<bool> checkEmailVerified() async {
    if (_isDisposed) return false;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Refrescar el usuario para obtener el estado actual
      await user.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      return refreshedUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  // ✅ MÉTODO PARA REENVIAR EMAIL DE VERIFICACIÓN
  Future<void> resendVerificationEmail() async {
    if (_isDisposed) {
      throw Exception('El ViewModel ya fue desechado');
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw Exception('Error al reenviar el correo: $e');
    }
  }

  // ✅ MÉTODO PARA RESETEAR EL FORMULARIO
  void reset() {
    if (_isDisposed) return;

    _email = '';
    _password = '';
    _confirmPassword = '';
    _termsAccepted = false;
    _lastEmailError = null;
    _lastPasswordError = null;
    _lastConfirmPasswordError = null;
    _lastPasswordStrength = 0;

    _addToStream(_emailController, null);
    _addToStream(_passwordController, null);
    _addToStream(_confirmPasswordController, null);
    _addToStream(_passwordStrengthController, 0);
    _addToStream(_termsAcceptedController, false);

    notifyListeners();
  }

  // ✅ Getters para el estado actual
  String get email => _email;
  String get password => _password;
  String get confirmPassword => _confirmPassword;

  // ✅ Limpiar recursos
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;

    _safeCloseController(_emailController, 'emailController');
    _safeCloseController(_passwordController, 'passwordController');
    _safeCloseController(
        _confirmPasswordController, 'confirmPasswordController');
    _safeCloseController(
        _passwordStrengthController, 'passwordStrengthController');
    _safeCloseController(_termsAcceptedController, 'termsAcceptedController');
    _safeCloseController(_loadingController, 'loadingController');

    super.dispose();
  }

  void _safeCloseController(StreamController controller, String name) {
    try {
      if (!controller.isClosed) {
        controller.close();
      }
    } catch (e) {
      print('⚠️ Error cerrando $name: $e');
    }
  }
}
