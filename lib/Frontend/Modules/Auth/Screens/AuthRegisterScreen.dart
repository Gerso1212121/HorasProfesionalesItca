// lib/Frontend/Modules/Auth/Screens/AuthRegisterScreen.dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:horas2/Frontend/Modules/Auth/ViewModels/AuthRegisterVM.dart';
import 'package:horas2/Frontend/Modules/Auth/widgets/AuthHeader.dart';
import 'package:horas2/Frontend/Modules/Auth/widgets/dialogs/EmailVerificationDialog.dart';
import 'package:horas2/Frontend/Modules/Auth/widgets/forms/RegisterForm.dart';
import 'package:provider/provider.dart';

class AuthRegisterScreen extends StatefulWidget {
  const AuthRegisterScreen({super.key});

  @override
  State<AuthRegisterScreen> createState() => _AuthRegisterScreenState();
}

class _AuthRegisterScreenState extends State<AuthRegisterScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  void _showVerificationDialog(User user) {
    final esItca = user.email?.toLowerCase().endsWith('@itca.edu.sv') ?? false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmailVerificationDialog(
        user: user,
        esItca: esItca,
        onSuccess: () {
          // ✅ Email verificado exitosamente - Redirigir a UserDataScreen
          _navigateToUserDataScreen();
        },
        onClose: () {
          // El usuario cerró manualmente el diálogo
          setState(() => _isProcessing = false);
        },
      ),
    );
  }


  void _navigateToUserDataScreen() {
    setState(() => _isProcessing = false);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        context.go('/user-data');
      }
    });
  }

Future<void> _handleRegister(
  String email,
  String password,
  String confirmPassword,
  bool termsAccepted,
) async {
  print('🔄 _handleRegister llamado');
  print('📧 Email recibido: $email');
  print('🔐 Password recibido: ${password.length} caracteres');

  // Validar que no estén vacíos
  if (email.isEmpty || password.isEmpty) {
    setState(() {
      _isProcessing = false;
      _errorMessage = 'Email y contraseña son requeridos';
    });
    return;
  }

  setState(() {
    _errorMessage = null;
    _isProcessing = true;
  });

  try {
    final viewModel = Provider.of<AuthRegisterVM>(context, listen: false);
    print('🚀 Llamando a viewModel.register()...');
    
    // ✅ Pasar los valores directamente
    final user = await viewModel.register(
      email: email,
      password: password,
    );
    
    print('✅ viewModel.register() completado');
    
    _showVerificationDialog(user);
  
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = _getFirebaseErrorMessage(e);
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado. ¿Intentas iniciar sesión?';
      case 'invalid-email':
        return 'Correo electrónico no válido';
      case 'weak-password':
        return 'La contraseña es demasiado débil';
      case 'operation-not-allowed':
        return 'El registro con correo no está habilitado temporalmente';
      default:
        return 'Error en el registro: ${e.message ?? "Inténtalo nuevamente"}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthRegisterVM(),
      child: Builder(
        builder: (providerContext) {
          return GestureDetector(
            onTap: () => FocusScope.of(providerContext).unfocus(),
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botón de retroceso
                      IconButton(
                        onPressed: _isProcessing ? null : () => context.go('/login'),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 20,
                        ),
                        color: Colors.grey[700],
                      ),

                      // Header
                      AuthHeader(
                        title: '¡Comienza tu viaje!',
                        subtitle:
                            'Crea tu cuenta y descubre una nueva forma de cuidar tu bienestar',
                        imagePath: 'assets/images/brainidea.png',
                      ),
                      const SizedBox(height: 40),

                      // Formulario de registro
                      RegisterForm(
                        onRegister: _handleRegister,
                        onNavigateToLogin: () => context.go('/login'),
                        errorMessage: _errorMessage,
                        isLoading: _isProcessing,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}