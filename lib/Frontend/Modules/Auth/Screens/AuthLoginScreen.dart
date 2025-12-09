// lib/Frontend/Modules/Auth/Screens/AuthLoginScreen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horas2/Frontend/Modules/Auth/ViewModels/AuthLoginVM.dart';
import 'package:horas2/Frontend/Modules/Auth/widgets/forms/LoginForm.dart';
import 'package:horas2/Frontend/Modules/Auth/widgets/AuthHeader.dart';
import 'package:horas2/Frontend/Modules/Auth/widgets/dialogs/EmailVerificationDialog.dart';
import 'package:horas2/Frontend/Modules/Auth/widgets/dialogs/ForgotPasswordDialog.dart';

class AuthLoginScreen extends StatefulWidget {
  const AuthLoginScreen({super.key});

  @override
  State<AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends State<AuthLoginScreen> {
  bool _showPassword = false;
  bool _isProcessing = false;
  String? _errorMessage;

  final GlobalKey<LoginFormState> _loginFormKey = GlobalKey<LoginFormState>();
  final UniqueKey _screenKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // No necesitamos WidgetsBindingObserver porque UniqueKey reconstruye todo
    _resetForm();
  }

  Future<void> _handleLogin(String email, String password) async {
    FocusScope.of(context).unfocus();

    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _isProcessing = true;
    });

    final viewModel = Provider.of<AuthLoginVM>(context, listen: false);

    try {
      final result =
          await viewModel.loginUser(email: email, password: password);

      if (!mounted) return;

      if (result['success'] == true) {
        if (result['needsVerification'] == true) {
          _showVerificationDialog(
            result['user'],
            result['esItca'] ?? false,
          );
        } else if (result['needsData'] == true) {
          _navigateToUserData(result['user'], result['esItca'] ?? false);
        } else {
          // Login exitoso
          context.go('/home');
        }
      } else {
        setState(() {
          _errorMessage = result['message'] ?? "Credenciales inválidas";
          _isProcessing = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _getFirebaseErrorMessage(e);
        _isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Error inesperado. Inténtalo nuevamente.";
        _isProcessing = false;
      });
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Usuario no encontrado. ¿Necesitas registrarte?';
      case 'wrong-password':
        return 'Contraseña incorrecta. Inténtalo nuevamente.';
      case 'invalid-email':
        return 'Correo electrónico no válido';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      default:
        return 'Error en el inicio de sesión: ${e.message ?? "Inténtalo nuevamente"}';
    }
  }

  void _showVerificationDialog(User? user, bool esItca) {
    setState(() => _isProcessing = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EmailVerificationDialog(
        user: user,
        esItca: esItca,
        onSuccess: () {
          _navigateToUserData(user, esItca);
        },
        onClose: () {
          // No necesitamos resetear porque UniqueKey ya maneja esto
        },
      ),
    );
  }

  void _navigateToUserData(User? user, bool esItca) {
    context.push('/user-data', extra: {'user': user, 'esItca': esItca});
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ForgotPasswordDialog(),
    );
  }

  void _resetForm() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _isProcessing = false;
        _showPassword = false;
      });
    }

    if (_loginFormKey.currentState != null) {
      _loginFormKey.currentState!.resetForm();
    }
  }

  void _navigateToRegister() {
    context.push('/register');
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _screenKey,
      child: Builder(
        builder: (providerContext) {
          return GestureDetector(
            onTap: () => FocusScope.of(providerContext).unfocus(),
            child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      const AuthHeader(
                        title: "¡Bienvenido de nuevo!",
                        subtitle:
                            "Accede a tu cuenta y continuemos con tu camino",
                        imagePath: "assets/images/brainhi.png",
                      ),
                      const SizedBox(height: 20),
                      LoginForm(
                        key: _loginFormKey,
                        onLogin: _handleLogin,
                        onForgotPassword: _showForgotPasswordDialog,
                        onNavigateToRegister: _navigateToRegister,
                        onTogglePasswordVisibility: (value) =>
                            setState(() => _showPassword = value),
                        errorMessage: _errorMessage,
                        isLoading: _isProcessing,
                        showPassword: _showPassword,
                      ),
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
