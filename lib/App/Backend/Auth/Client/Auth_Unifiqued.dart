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
import '../../../Utils/Utils_ServiceLog.dart';
import '../../../../Frontend/Widgets/auth/custom_input_field.dart';
import '../../../Data/DataBase/DatabaseHelper.dart';
import '../../../../Frontend/Widgets/log_Screen.dart';
import '../../Dashboard->FRONTEND.dart';
import 'Auth_UserData.dart';
import 'Auth_EmailSendVerification.dart';

/*----------|ADMIN|----------*/
import '../Admin/Admin_Dashboard.dart';
import '../Admin/Logic/Admin_AuditService.dart';

class AuthUnifiedScreen extends StatefulWidget {
  const AuthUnifiedScreen({super.key});

  @override
  State<AuthUnifiedScreen> createState() => _AuthUnifiedScreenState();
}

class _AuthUnifiedScreenState extends State<AuthUnifiedScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controladores para Login
  final _loginEmailController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  bool _loginIsLoading = false;
  bool _loginObscurePassword = true;

  // Controladores para Registro
  final _registerEmailController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  bool _registerIsLoading = false;
  bool _registerObscurePassword = true;
  bool _registerConfirmObscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  // Validadores comunes
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Por favor ingresa un correo válido';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (value != _registerPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // Métodos de Login
  Future<void> _handleAdminLogin() async {
    try {
      await LogService.log('Proceso de Login Administrador. Email: ${_loginEmailController.text.trim()}');

      final supabase = SupabaseAuth.Supabase.instance.client;
      final SupabaseAuth.AuthResponse res = await supabase.auth.signInWithPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );

      final SupabaseAuth.Session? session = res.session;
      final SupabaseAuth.User? user = res.user;

      if (session != null && user != null) {
        await LogService.log('Login de administrador exitoso. Usuario: ${user.email}');

        _loginEmailController.clear();
        _loginPasswordController.clear();

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
    if (!_loginFormKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _loginIsLoading = true;
      });

      if (_loginEmailController.text.trim().endsWith('@admin.com')) {
        await _handleAdminLogin();
        return;
      }

      final credencial = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );

      _loginEmailController.clear();
      _loginPasswordController.clear();

      User? user = credencial.user;

      if (user != null) {
        if (user.emailVerified) {
          final uid = user.uid;
          final estudianteDoc = await FirebaseFirestore.instance
              .collection('estudiantes')
              .doc(uid)
              .get();

          if (!estudianteDoc.exists) {
            await LogService.log('Proceso de Logeo. Resultados: Usuario autenticado con UID ${user.uid} pero no tiene datos en Firestore, mostrando formulario de datos del usuario');
            if (mounted) {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const UserDataScreen()));
            }
            return;
          }

          final userData = estudianteDoc.data();
          if (userData != null) {
            try {
              DatabaseHelper dbHelper = DatabaseHelper.instance;
              await dbHelper.deleteEstudianteActual();
              await dbHelper.insertEstudianteFromFirebase(userData);
              await LogService.log('Proceso de Logeo. Resultados: Usuario autenticado con UID ${user.uid} y datos: $userData, mostrando pantalla de dashboard');
            } catch (e) {
              await LogService.log('Proceso de Logeo. Resultados: Usuario autenticado con UID ${user.uid} pero error con BD: $e, continuando sin BD local');
            }
          }

          if (mounted) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const Dashboard()));
          }
          return;
        }

        await LogService.log('Proceso de Logeo. Resultados: Usuario autenticado con UID ${user.uid} pero su correo no está verificado, mostrando diálogo de verificación de correo');

        if (mounted) {
          showEmailVerificationDialog(context, user, onVerified: () {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const UserDataScreen()));
          });
        }
        return;
      }
    } on FirebaseAuthException catch (e) {
      await LogService.log('Proceso de Logeo. Resultados: Error al iniciar sesión: ${e.message}');
      if (!mounted) return;

      String mensajeError = "Error al iniciar sesión";
      switch (e.code) {
        case 'user-not-found':
          mensajeError = "Usuario no encontrado. Verifica tu correo electrónico.";
          break;
        case 'wrong-password':
          mensajeError = "Contraseña incorrecta";
          await LogService.log('XD - Usuario intentó con contraseña incorrecta: ${_loginEmailController.text.trim()}');
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
      await LogService.log('Proceso de Logeo. Resultados: Error inesperado: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error inesperado: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loginIsLoading = false;
        });
      }
    }
  }

  // Métodos de Registro
  void _registroUsuario() async {
    if (!_registerFormKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _registerIsLoading = true;
    });

    final correo = _registerEmailController.text.trim();
    final password = _registerPasswordController.text.trim();

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correo,
        password: password,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registro exitoso"),
          backgroundColor: Colors.green,
        ),
      );

      UserCredential result = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: correo, password: password);
      User user = result.user!;

      if (!user.emailVerified) {
        showEmailVerificationDialog(context, user, onVerified: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const UserDataScreen()),
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _registerIsLoading = false;
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Recuperar Contraseña',
            style: GoogleFonts.itim(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E5A87),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ingresa tu correo electrónico para recibir las instrucciones de recuperación.',
                style: GoogleFonts.itim(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  labelStyle: GoogleFonts.itim(color: Colors.grey[600]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF86A8E7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF86A8E7), width: 2),
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
                style: GoogleFonts.itim(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
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
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF86A8E7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Enviar',
                style: GoogleFonts.itim(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Claves para los formularios
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // TABS EN LA PARTE SUPERIOR
              _buildTopTabs(),
              
              // CONTENIDO PRINCIPAL
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // LOGO Y TEXTO
                      _buildHeader(),
                      const SizedBox(height: 40),
                      
                      // FORMULARIO CON TABBARVIEW CORRECTO
                      Expanded(
                        child: TabBarView(
                          children: [
                            // TAB DE LOGIN
                            SingleChildScrollView(
                              child: _buildLoginTab(),
                            ),
                            // TAB DE REGISTRO
                            SingleChildScrollView(
                              child: _buildRegisterTab(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        labelColor: const Color(0xFF86A8E7),
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: const Color(0xFF86A8E7),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.itim(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.itim(
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
        tabs: const [
          Tab(text: 'INICIO'),
          Tab(text: 'REGISTRO'),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/cerebron.png',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 20),
        
        // Título dinámico basado en el tab seleccionado
        Builder(
          builder: (context) {
            final currentIndex = DefaultTabController.of(context)?.index ?? 0;
            if (currentIndex == 0) {
              // Título para Login
              return Column(
                children: [
                  Text(
                    'CEREBRÓN',
                    style: GoogleFonts.itim(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E5A87),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Continúa tu aventura de bienestar',
                    style: GoogleFonts.itim(
                      fontSize: 16,
                      color: const Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            } else {
              // Título para Registro
              return Column(
                children: [
                  Text(
                    'CEREBRÓN',
                    style: GoogleFonts.itim(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2E5A87),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Regístrate para comenzar tu nuevo viaje',
                    style: GoogleFonts.itim(
                      fontSize: 16,
                      color: const Color(0xFF666666),
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildLoginTab() {
    return Form(
      key: _loginFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomInputField(
            label: 'Correo Electrónico',
            controller: _loginEmailController,
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          CustomInputField(
            label: 'Contraseña',
            controller: _loginPasswordController,
            validator: _validatePassword,
            obscureText: _loginObscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _loginObscurePassword ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF86A8E7),
              ),
              onPressed: () {
                setState(() {
                  _loginObscurePassword = !_loginObscurePassword;
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
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loginIsLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF66B7D),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: const Color.fromARGB(100, 246, 107, 125),
              ),
              child: _loginIsLoading
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
          const SizedBox(height: 20), // Espacio adicional para scroll
        ],
      ),
    );
  }

  Widget _buildRegisterTab() {
    return Form(
      key: _registerFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomInputField(
            label: 'Correo Electrónico',
            controller: _registerEmailController,
            validator: _validateEmail,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          CustomInputField(
            label: 'Contraseña',
            controller: _registerPasswordController,
            validator: _validatePassword,
            obscureText: _registerObscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _registerObscurePassword ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF86A8E7),
              ),
              onPressed: () {
                setState(() {
                  _registerObscurePassword = !_registerObscurePassword;
                });
              },
            ),
          ),
          const SizedBox(height: 20),
          CustomInputField(
            label: 'Confirmar Contraseña',
            controller: _registerConfirmPasswordController,
            validator: _validateConfirmPassword,
            obscureText: _registerConfirmObscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _registerConfirmObscurePassword ? Icons.visibility : Icons.visibility_off,
                color: const Color(0xFF86A8E7),
              ),
              onPressed: () {
                setState(() {
                  _registerConfirmObscurePassword = !_registerConfirmObscurePassword;
                });
              },
            ),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _registerIsLoading ? null : _registroUsuario,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF66B7D),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: const Color.fromARGB(100, 246, 107, 125),
              ),
              child: _registerIsLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Crear Cuenta',
                      style: GoogleFonts.itim(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20), // Espacio adicional para scroll
        ],
      ),
    );
  }
}