/*----------|IMPORTACIONES BASICAS|----------*/
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
/*----------|FIREBASE|----------*/
import 'package:firebase_auth/firebase_auth.dart';
/*----------|MODULOS|----------*/
import 'Auth_EmailSendVerification.dart';
import 'Auth_UserData.dart';
import '../../../../Frontend/Widgets/auth/custom_input_field.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // Variables para el formulario
  final _formKey = GlobalKey<FormState>(); // Clave para el formulario
  final TextEditingController correoController =
      TextEditingController(); // Controlador para el campo de correo
  final TextEditingController passwordController =
      TextEditingController(); // Controlador para el campo de contraseña
  final TextEditingController confirmPasswordController =
      TextEditingController(); // Controlador para el campo de confirmación de contraseña
  bool _isLoading = false; // Estado de carga para el botón de registro

  @override
  void dispose() {
    // Limpiar los controladores al destruir el widget
    correoController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Validadores para los campos de email y contraseña
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo';
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

  // Validador para la confirmación de contraseña
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }
    if (value != passwordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  // Registra un nuevo usuario en Firebase y maneja la verificación de email.
  void registroUsuario() async {
    // Validar el formulario antes de continuar
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Mostrar indicador de carga
    setState(() {
      _isLoading = true;
    });

    // Obtener los valores de los campos
    final correo = correoController.text.trim();
    final password = passwordController.text.trim();

    try {
      // Registrar el usuario en Firebase
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: correo,
        password: password,
      );

      // Enviar correo de verificación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Registro exitoso"),
          backgroundColor: Colors.green,
        ),
      );

      // Iniciar sesión inmediatamente después del registro
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
          _isLoading = false;
        });
      }
    }
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
                      'Crear Cuenta',
                      style: GoogleFonts.itim(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Únete a nuestra comunidad de bienestar',
                      style: GoogleFonts.itim(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    CustomInputField(
                      label: 'Correo Electrónico',
                      controller: correoController,
                      validator: _validateEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: 'Contraseña',
                      controller: passwordController,
                      validator: _validatePassword,
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    CustomInputField(
                      label: 'Confirmar Contraseña',
                      controller: confirmPasswordController,
                      validator: _validateConfirmPassword,
                      obscureText: true,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : registroUsuario,
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
                                'Crear Cuenta',
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
                          const TextSpan(text: '¿Ya tienes una cuenta? '),
                          TextSpan(
                            text: 'Inicia Sesión',
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
                                      builder: (context) =>
                                          const UserDataScreen()),
                                );
                              },
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
