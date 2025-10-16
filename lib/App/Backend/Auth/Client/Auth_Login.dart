/*----------|IMPORTACIONES BASICAS|----------*/
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/*----------|FIREBASE|----------*/
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/*----------|SUPABASE|----------*/
import 'package:supabase_flutter/supabase_flutter.dart' as SupabaseAuth;

/*----------|MODULOS|----------*/
import '../../../utils/Utils_ServiceLog.dart';
import '../../../../Frontend/Widgets/auth/custom_input_field.dart';
import '../../../Data/DataBase/DatabaseHelper.dart';
import '../../../../Frontend/Widgets/log_Screen.dart';
import '../../Dashboard->FRONTEND.dart';
import 'Auth_Register.dart';
import 'Auth_UserData.dart';
import 'Auth_EmailSendVerification.dart';

/*----------|ADMIN|----------*/
import '../Admin/Admin_Dashboard.dart';
import '../Admin/Logic/Admin_AuditService.dart';

/*----------|TEMPORALEEES|----------*/
import '../../Modules/Debug/DebugScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Variables para el formulario
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario
  final _emailController =
      TextEditingController(); // Controlador para el campo de email
  final _passwordController =
      TextEditingController(); // Controlador para el campo de contraseña
  bool _isLoading = false; // Estado de carga para el botón de inicio de sesión
  bool _obscurePassword = true; // Para ocultar/mostrar la contraseña

  @override
  // Método para limpiar los controladores al salir de la pantalla
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validadores para los campos de email y contraseña
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Por favor ingresa un correo válido';
    }
    return null;
  }

  // Validador para la contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  /// Maneja el login de administrador.
  /// Si el email termina con @admin.com, se redirige al dashboard de administrador
  Future<void> _handleAdminLogin() async {
    try {
      await LogService.log(
          'Proceso de Login Administrador. Email: ${_emailController.text.trim()}');

      final supabase =
          SupabaseAuth.Supabase.instance.client; // Cliente de Supabase
      final SupabaseAuth.AuthResponse res =
          await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ); // Intentar iniciar sesión con Supabase

      final SupabaseAuth.Session? session = res.session; // Obtener la sesión
      final SupabaseAuth.User? user = res.user; // Obtener el usuario

      if (session != null && user != null) {
        await LogService.log(
            'Login de administrador exitoso. Usuario: ${user.email}');

        // Limpiar campos
        _emailController.clear();
        _passwordController.clear();

        // Navegar al dashboard de administrador
        if (mounted) {
          AuditService.logAuthAction(
            action: 'LOGIN',
            adminId: user.id,
            username: user.email,
            details: 'Administrador inició sesión exitosamente',
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        }
        return;
      } else {
        throw Exception('No se pudo establecer la sesión');
      }
    } on SupabaseAuth.AuthException catch (e) {
      await LogService.log('Error de autenticación admin: ${e.message}');

      String mensajeError = "Error al iniciar sesión como administrador";
      switch (e.message.toLowerCase()) {
        case 'invalid login credentials':
          mensajeError = "Credenciales de administrador inválidas";
          break;
        case 'email not confirmed':
          mensajeError = "Email de administrador no confirmado";
          break;
        default:
          mensajeError = "Error de autenticación: ${e.message}";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      throw e;
    } catch (e) {
      await LogService.log('Error inesperado en login admin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error inesperado: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      throw e;
    }
  }

  Future<void> _handleLogin() async {
    // Validar el formulario antes de proceder
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Mostrar estado de carga
      setState(() {
        _isLoading = true;
      });

      // Bypass para login de administrador
      // Evaluamos si termina con @admin.com
      if (_emailController.text.trim().endsWith('@admin.com')) {
        await _handleAdminLogin();
        return;
      }

      // Intentar iniciar sesión con Firebase Auth (usuarios normales)
      final credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Limpiar los campos de texto después de iniciar sesión
      _emailController.clear();
      _passwordController.clear();

      // Obtener el usuario actual
      User? user = credencial.user;

      // Si el usuario no es nulo, verificar si su correo está verificado
      if (user != null) {
        // Si el correo está verificado, proceder a cargar los datos del usuario
        if (user.emailVerified) {
          // Verificar si el usuario ya existe en Firestore
          final uid = user.uid;
          final estudianteDoc = await FirebaseFirestore.instance
              .collection('estudiantes')
              .doc(uid)
              .get();

          // Si el documento no existe, redirigir al formulario de datos del usuario
          if (!estudianteDoc.exists) {
            await LogService.log(
                'Proceso de Logeo. Resultados: Usuario autenticado con UID ${user.uid} pero no tiene datos en Firestore, mostrando formulario de datos del usuario');
            if (mounted) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const UserDataScreen()));
            }
            return;
          }

          // Si el documento existe, guardar los datos en la base de datos SQLite (si está disponible)
          final userData = estudianteDoc.data();
          if (userData != null) {
            try {
              DatabaseHelper dbHelper = DatabaseHelper.instance;
              await dbHelper.deleteEstudianteActual();
              await dbHelper.insertEstudianteFromFirebase(userData);
              await LogService.log(
                  'Proceso de Logeo. Resultados: Usuario autenticado con UID ${user.uid} y datos: $userData, mostrando pantalla de dashboard');
            } catch (e) {
              // Si hay error con la base de datos (como en web), continuar sin ella
              await LogService.log(
                  'Proceso de Logeo. Resultados: Usuario autenticado con UID ${user.uid} pero error con BD: $e, continuando sin BD local');
            }
          }

          // Navegar al dashboard
          if (mounted) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const Dashboard()));
          }
          return;
        }

        // Si el correo no está verificado
        await LogService.log(
            'Proceso de Logeo. Resultados: Usuario autenticado con UID ${user.uid} pero su correo no está verificado, mostrando diálogo de verificación de correo');

        if (mounted) {
          showEmailVerificationDialog(context, user, onVerified: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const UserDataScreen()));
          });
        }
        return;
      }
    } on FirebaseAuthException catch (e) {
      await LogService.log(
          'Proceso de Logeo. Resultados: Error al iniciar sesión: ${e.message}');
      if (!mounted) return;

      String mensajeError = "Error al iniciar sesión";

      // Manejo específico de errores de Firebase Auth
      switch (e.code) {
        case 'user-not-found':
          mensajeError =
              "Usuario no encontrado. Verifica tu correo electrónico.";
          break;
        case 'wrong-password':
          mensajeError = "Contraseña incorrecta";
          await LogService.log(
              'XD - Usuario intentó con contraseña incorrecta: ${_emailController.text.trim()}');
          break;
        case 'invalid-email':
          mensajeError = "Formato de correo electrónico inválido.";
          break;
        case 'user-disabled':
          mensajeError = "Esta cuenta ha sido deshabilitada.";
          break;
        case 'too-many-requests':
          mensajeError = "Demasiados intentos fallidos. Inténtalo más tarde.";
          break;
        case 'network-request-failed':
          mensajeError = "Error de conexión. Verifica tu internet.";
          break;
        default:
          mensajeError = "Error al iniciar sesión: ${e.message}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(mensajeError),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    } catch (e) {
      await LogService.log(
          'Proceso de Logeo. Resultados: Error inesperado: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error inesperado: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      // Ocultar estado de carga
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final emailController = TextEditingController();
        return AlertDialog(
          title: Text(
            'Recuperar Contraseña',
            style: GoogleFonts.itim(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa tu correo electrónico para recibir las instrucciones de recuperación.',
                style: GoogleFonts.itim(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancelar',
                style: GoogleFonts.itim(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.trim().isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(
                      email: emailController.text.trim(),
                    );
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Correo de recuperación enviado',
                          style: GoogleFonts.itim(),
                        ),
                        backgroundColor: const Color(0xFF86A8E7),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error al enviar correo: $e',
                          style: GoogleFonts.itim(),
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF86A8E7),
              ),
              child: Text(
                'Enviar',
                style: GoogleFonts.itim(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<String> get debugInfo async {
    final user = FirebaseAuth.instance.currentUser;
    String Alias = "Desconocido";
    String emocionActual = "Desconocida";
    String dbStatus = "Desconocido";
    int estudiantesCount = 0;
    String userInDb = "No disponible";

    try {
      DatabaseHelper dbHelper = DatabaseHelper.instance;

      // Para web, no intentar acceder a database directamente
      if (kIsWeb) {
        dbStatus = "Web - Usando SharedPreferences";
        estudiantesCount = await dbHelper.countEstudiantes();

        if (user != null) {
          try {
            final estudiante = await dbHelper.getEstudiantePorUID(user.uid);
            userInDb = estudiante != null
                ? estudiante.entries
                    .map((e) => "${e.key}: ${e.value}")
                    .join("\n")
                : "No disponible";
          } catch (e) {
            userInDb = "Error: $e";
          }
        }
      } else {
        try {
          await dbHelper.database;
          dbStatus = "OK";
        } catch (e) {
          dbStatus = "Error: $e";
        }

        estudiantesCount = await dbHelper.countEstudiantes();

        if (user != null) {
          try {
            final estudiante = await dbHelper.getEstudiantePorUID(user.uid);
            userInDb = estudiante != null
                ? estudiante.entries
                    .map((e) => "${e.key}: ${e.value}")
                    .join("\n")
                : "No disponible";
          } catch (e) {
            userInDb = "Error: $e";
          }
        }
      }
    } catch (e) {
      dbStatus = "Error: $e";
      estudiantesCount = -1;
    }

    return '''
Base de datos: $dbStatus
Estudiantes en BD: $estudiantesCount
Usuario: ${user != null ? user.email : "No autenticado"}
UID: ${user != null ? user.uid : "-"}
Alias: $Alias
Emoción Actual: $emocionActual
Usuario en Base de Datos:
$userInDb
''';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: size.width > 400 ? 380 : size.width * 0.9,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/cerebron.png',
                      height: 80,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Bienvenido de Vuelta',
                      style: GoogleFonts.itim(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Inicia sesión para continuar tu viaje de bienestar',
                      style: GoogleFonts.itim(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    CustomInputField(
                      label: 'Correo Electrónico',
                      controller: _emailController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: 'Contraseña',
                      controller: _passwordController,
                      validator: _validatePassword,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: const Color(0xFF86A8E7),
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: GoogleFonts.itim(
                            fontSize: 14,
                            color: const Color(0xFF86A8E7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF66B7D),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: const Color.fromARGB(100, 246, 107, 125),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Iniciar Sesión',
                                style: GoogleFonts.itim(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.itim(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                        children: [
                          const TextSpan(text: '¿No tienes una cuenta? '),
                          TextSpan(
                            text: 'Regístrate',
                            style: GoogleFonts.itim(
                              color: const Color(0xFF86A8E7),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegistroScreen()),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Sección de información de depuración (solo en modo debug)
                    if (true) ...[
                      ExpansionTile(
                        title: Text(
                          'Información de Depuración',
                          style: GoogleFonts.itim(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        children: [
                          FutureBuilder<String>(
                            future: debugInfo,
                            builder: (context, snapshot) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  snapshot.hasData
                                      ? snapshot.data!
                                      : "Cargando...",
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Colors.red,
                                  ),
                                ),
                              );
                            },
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (_) => const LogViewer(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF86A8E7),
                            ),
                            child: Text(
                              'Ver Logs',
                              style: GoogleFonts.itim(color: Colors.white),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const DebugScreen(),
                                ),
                              );
                            },
                            child: Text(
                              'Ir a Control de Base de Datos',
                              style: GoogleFonts.itim(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF66B7D),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
