/*----------|IMPORTACIONES BASICAS|----------*/
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Admin/Logic/Admin_AuditService.dart';
import 'package:horas2/Admin_Dashboard.dart';
import 'package:horas2/Widgets/input.dart';

/*----------|SUPABASE|----------*/
import 'package:supabase_flutter/supabase_flutter.dart' as SupabaseAuth;

/*----------|MODULOS|----------*/

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  // Variables para el formulario
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Validador para el campo de email de administrador
  String? _validateAdminEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo de administrador';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Por favor ingresa un correo válido';
    }
    if (!value.endsWith('@admin.com')) {
      return 'Solo se permiten correos de administrador (@admin.com)';
    }
    return null;
  }

  // Validador para la contraseña
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  /// Maneja el login de administrador
  Future<void> _handleAdminLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

       print(
          'Proceso de Login Administrador. Email: ${_emailController.text.trim()}');

      final supabase = SupabaseAuth.Supabase.instance.client;
      final SupabaseAuth.AuthResponse res =
          await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final SupabaseAuth.Session? session = res.session;
      final SupabaseAuth.User? user = res.user;

      if (session != null && user != null) {
        print(
            'Login de administrador exitoso. Usuario: ${user.email} | ID: ${user.id}');

        // Registrar acción de auditoría
        await AuditService.logAuthAction(
          action: 'LOGIN',
          adminId: user.id,
          username: user.email ?? 'admin@admin.com',
          details: 'Administrador inició sesión exitosamente',
        );

        // Limpiar campos
        _emailController.clear();
        _passwordController.clear();

        // Navegar al dashboard de administrador
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboard()),
          );
        }
      } else {
        throw Exception('No se pudo establecer la sesión de administrador');
      }
    } on SupabaseAuth.AuthException catch (e) {
      print('Error de autenticación admin: ${e.message}');

      String mensajeError = "Error al iniciar sesión";
      switch (e.message.toLowerCase()) {
        case 'invalid login credentials':
          mensajeError = "Credenciales de administrador inválidas";
          break;
        case 'email not confirmed':
          mensajeError = "Email de administrador no confirmado";
          break;
        case 'user not found':
          mensajeError = "Administrador no registrado";
          break;
        default:
          mensajeError = "Error de autenticación: ${e.message}";
      }

      if (mounted) {
        _showErrorSnackBar(mensajeError);
      }
    } catch (e) {
      print('Error inesperado en login admin: $e');
      if (mounted) {
        _showErrorSnackBar("Error inesperado: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.itim(),
        ),
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
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // Fondo oscuro elegante
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: size.width > 400 ? 400 : size.width * 0.9,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF162447),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFF1F4068),
                  width: 2,
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icono de administrador
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F4068),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: const Color(0xFF86A8E7),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Título
                    Text(
                      'Panel de Administración',
                      style: GoogleFonts.itim(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Acceso exclusivo para administradores',
                      style: GoogleFonts.itim(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Campo de email
                    CustomInputField(
                      label: 'Correo de Administrador',
                      controller: _emailController,
                      validator: _validateAdminEmail,
                      keyboardType: TextInputType.emailAddress,

                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Campo de contraseña
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
                    
                    const SizedBox(height: 30),
                    
                    // Botón de login
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleAdminLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF86A8E7),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: const Color.fromARGB(100, 134, 168, 231),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.login,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Acceder al Panel',
                                    style: GoogleFonts.itim(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Nota de seguridad
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F4068).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF86A8E7).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.security,
                            color: Color(0xFF86A8E7),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Acceso restringido solo a personal autorizado',
                              style: GoogleFonts.itim(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
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