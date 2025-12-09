// lib/Frontend/Modules/Auth/widgets/forms/LoginForm.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Utils/Auth/AuthValidators.dart';
import 'package:horas2/Frontend/widgets/Buttons/Buttons.dart';
import 'package:horas2/Frontend/widgets/Inputs/CustomTextField.dart';
import 'package:provider/provider.dart';
import 'package:horas2/Frontend/Modules/Auth/ViewModels/AuthLoginVM.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginForm extends StatefulWidget {
  final Function(String, String) onLogin;
  final Function() onForgotPassword;
  final Function() onNavigateToRegister;
  final Function(bool) onTogglePasswordVisibility;
  final String? errorMessage;
  final bool isLoading;
  final bool showPassword;
  
  // Agregar una función de callback para resetear
  final VoidCallback? onFormReset;

  const LoginForm({
    Key? key,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onNavigateToRegister,
    required this.onTogglePasswordVisibility,
    this.errorMessage,
    this.isLoading = false,
    this.showPassword = false,
    this.onFormReset,
  }) : super(key: key);

  @override
  LoginFormState createState() => LoginFormState();
}

class LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Método público para resetear el formulario
  void resetForm() {
    _emailController.clear();
    _passwordController.clear();
    _formKey.currentState?.reset();
    
    // Notificar al padre si es necesario
    widget.onFormReset?.call();
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    // Resetear al iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      resetForm();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

void _submitForm() {
  if (_formKey.currentState!.validate()) {
    // Guardar los valores antes de limpiar
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    // Limpiar los campos inmediatamente
    _emailController.clear();
    _passwordController.clear();
    _formKey.currentState?.reset();
    
    // Llamar al callback del login con los valores guardados
    widget.onLogin(email, password);
  }
}

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ERROR MESSAGE
          if (widget.errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                border: Border.all(color: AppColors.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.errorMessage!,
                      style: GoogleFonts.nunito(
                        fontSize: AppFontSizes.bodyMedium,
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // EMAIL FIELD
          CustomTextField(
            controller: _emailController,
            labelText: "Correo electrónico",
            fillColor: Colors.white,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            focusedColor: AppColors.primary,
            validator: AuthValidators.validateEmail,
            enabled: !widget.isLoading,
            textStyle: GoogleFonts.nunito(
              fontSize: AppFontSizes.bodyLarge,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppSpacing.lg),

          // PASSWORD FIELD
          CustomTextField(
            controller: _passwordController,
            labelText: "Contraseña",
            fillColor: Colors.white,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: !widget.showPassword,
            suffixIcon: widget.showPassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            onSuffixPressed: () {
              widget.onTogglePasswordVisibility(!widget.showPassword);
            },
            textInputAction: TextInputAction.done,
            focusedColor: AppColors.primary,
            validator: AuthValidators.validatePassword,
            enabled: !widget.isLoading,
            onSubmitted: (_) => _submitForm(),
            textStyle: GoogleFonts.nunito(
              fontSize: AppFontSizes.bodyLarge,
              color: AppColors.textPrimary,
            ),
          ),

          // FORGOT PASSWORD
          SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: widget.isLoading ? null : widget.onForgotPassword,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primaryLight,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
              ),
              child: Text(
                "¿Olvidaste tu contraseña?",
                style: GoogleFonts.nunito(
                  fontSize: AppFontSizes.bodyMedium,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // LOGIN BUTTON
          PrimaryGradientButton(
            text: "Iniciar sesión",
            onPressed: _submitForm,
            icon: Icons.login_rounded,
            gradientColors: widget.isLoading
                ? [Colors.grey.shade400, Colors.grey.shade600]
                : const [AppColors.primary, AppColors.primaryDark],
            borderRadius: AppBorderRadius.sm,
            padding: const EdgeInsets.symmetric(vertical: 16),
            elevation: widget.isLoading ? 2 : 6,
            textStyle: GoogleFonts.nunito(
              fontSize: AppFontSizes.bodyLarge,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          // REGISTER LINK
          SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "¿No tienes cuenta?",
                style: GoogleFonts.nunito(
                  fontSize: AppFontSizes.bodyLarge,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              TextButton(
                onPressed:
                    widget.isLoading ? null : widget.onNavigateToRegister,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                  ),
                ),
                child: Text(
                  "Crear cuenta",
                  style: GoogleFonts.nunito(
                    fontSize: AppFontSizes.bodyLarge,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}