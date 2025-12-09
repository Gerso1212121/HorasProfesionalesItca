// lib/Frontend/Modules/Auth/widgets/forms/RegisterForm.dart
import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:horas2/Frontend/Modules/Auth/ViewModels/AuthRegisterVM.dart';
import 'package:horas2/Frontend/Modules/Auth/widgets/Register/AuthPasswordStrengthIndicator.dart';
import 'package:horas2/Frontend/Modules/Auth/widgets/Register/AuthRegisterTermsCheckbox.dart';
import 'package:horas2/Frontend/widgets/Buttons/Buttons.dart';
import 'package:horas2/Frontend/widgets/Inputs/CustomTextField.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterForm extends StatefulWidget {
  final Function(String, String, String, bool) onRegister;
  final Function() onNavigateToLogin;
  final String? errorMessage;
  final bool isLoading;

  const RegisterForm({
    super.key,
    required this.onRegister,
    required this.onNavigateToLogin,
    this.errorMessage,
    this.isLoading = false,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _termsAccepted = false;
  String? _termsError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<AuthRegisterVM>(context, listen: false);
      _setupTextControllers(viewModel);
    });
  }

  void _setupTextControllers(AuthRegisterVM viewModel) {
    _emailController.addListener(() {
      viewModel.updateEmail(_emailController.text);
      _forceConfirmPasswordValidation(viewModel);
    });

    _passwordController.addListener(() {
      viewModel.updatePassword(_passwordController.text);
      _forceConfirmPasswordValidation(viewModel);
    });

    _confirmPasswordController.addListener(() {
      viewModel.updateConfirmPassword(_confirmPasswordController.text);
    });
  }

  void _forceConfirmPasswordValidation(AuthRegisterVM viewModel) {
    if (_confirmPasswordController.text.isNotEmpty) {
      viewModel.updateConfirmPassword(_confirmPasswordController.text);
      if (_formKey.currentState != null) {
        _formKey.currentState!.validate();
      }
    }
  }

  // VALIDADORES INLINE SIMPLIFICADOS
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Por favor ingresa un correo válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Debes confirmar tu contraseña';
    }

    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (!_termsAccepted) {
        setState(() {
          _termsError = 'Debes aceptar los términos y condiciones';
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
        
        return;
      }
      
      setState(() => _termsError = null);

      widget.onRegister(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _confirmPasswordController.text.trim(),
        _termsAccepted,
      );
    }
  }

  void _togglePasswordVisibility() {
    setState(() => _showPassword = !_showPassword);
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() => _showConfirmPassword = !_showConfirmPassword);
  }

  void _updateTermsAccepted(bool? value) {
    if (value != null) {
      setState(() {
        _termsAccepted = value;
        _termsError = null;
      });

      final viewModel = Provider.of<AuthRegisterVM>(context, listen: false);
      viewModel.updateTermsAccepted(value);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthRegisterVM>(
      builder: (context, viewModel, child) {
        return StreamBuilder<String?>(
          stream: viewModel.emailErrorStream,
          builder: (context, emailSnapshot) {
            return StreamBuilder<String?>(
              stream: viewModel.passwordErrorStream,
              builder: (context, passwordSnapshot) {
                return StreamBuilder<String?>(
                  stream: viewModel.confirmPasswordErrorStream,
                  builder: (context, confirmPasswordSnapshot) {
                    return Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ERROR MESSAGE (para errores del servidor - Firebase)
                          if (widget.errorMessage != null)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(AppSpacing.md),
                              margin: EdgeInsets.only(bottom: AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                                border: Border.all(color: AppColors.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline,
                                      color: AppColors.error, size: 20),
                                  SizedBox(width: AppSpacing.sm),
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
                            validator: (value) {
                              if (emailSnapshot.hasData &&
                                  emailSnapshot.data != null) {
                                return emailSnapshot.data;
                              }
                              return _validateEmail(value);
                            },
                            errorText: emailSnapshot.data,
                            focusedColor: AppColors.primary,
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
                            obscureText: !_showPassword,
                            suffixIcon: _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            onSuffixPressed: _togglePasswordVisibility,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (passwordSnapshot.hasData &&
                                  passwordSnapshot.data != null) {
                                return passwordSnapshot.data;
                              }
                              return _validatePassword(value);
                            },
                            errorText: passwordSnapshot.data,
                            focusedColor: AppColors.primary,
                            enabled: !widget.isLoading,
                            textStyle: GoogleFonts.nunito(
                              fontSize: AppFontSizes.bodyLarge,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          // PASSWORD STRENGTH INDICATOR
                          if (_passwordController.text.isNotEmpty)
                            AuthPasswordStrengthIndicator(
                              strength: viewModel.passwordStrength,
                            ),
                          SizedBox(height: AppSpacing.lg),

                          // CONFIRM PASSWORD FIELD
                          CustomTextField(
                            controller: _confirmPasswordController,
                            labelText: "Confirmar contraseña",
                            fillColor: Colors.white,
                            prefixIcon: Icons.lock_reset_outlined,
                            obscureText: !_showConfirmPassword,
                            suffixIcon: _showConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            onSuffixPressed: _toggleConfirmPasswordVisibility,
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (confirmPasswordSnapshot.hasData &&
                                  confirmPasswordSnapshot.data != null) {
                                return confirmPasswordSnapshot.data;
                              }
                              return _validateConfirmPassword(value);
                            },
                            focusedColor: AppColors.primary,
                            enabled: !widget.isLoading,
                            onSubmitted: (_) => _submitForm(),
                            textStyle: GoogleFonts.nunito(
                              fontSize: AppFontSizes.bodyLarge,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: AppSpacing.lg),

                          // TERMS AND CONDITIONS CHECKBOX CON VALIDACIÓN
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AuthRegisterTermsCheckbox(
                                value: _termsAccepted,
                                onChanged: _updateTermsAccepted,
                                primaryColor: AppColors.success,
                              ),
                              
                              // Mostrar error de términos si existe
                              if (_termsError != null)
                                Padding(
                                  padding: EdgeInsets.only(
                                    left: AppSpacing.sm,
                                    top: AppSpacing.xs,
                                    bottom: AppSpacing.md,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: AppColors.error,
                                        size: 16,
                                      ),
                                      SizedBox(width: AppSpacing.xs),
                                      Expanded(
                                        child: Text(
                                          _termsError!,
                                          style: GoogleFonts.nunito(
                                            fontSize: AppFontSizes.bodySmall,
                                            color: AppColors.error,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.md),

                          // REGISTER BUTTON
                          PrimaryGradientButton(
                            text: "Crear cuenta",
                            onPressed: _submitForm,
                            isLoading: widget.isLoading,
                            icon: Icons.arrow_forward_rounded,
                            gradientColors: widget.isLoading
                                ? [Colors.grey.shade400, Colors.grey.shade600]
                                : [
                                    AppColors.primary,
                                    AppColors.primaryDark
                                  ],
                            borderRadius: AppBorderRadius.sm,
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            elevation: widget.isLoading ? 2 : 6,
                            textStyle: GoogleFonts.nunito(
                              fontSize: AppFontSizes.bodyLarge,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),

                          // LOGIN LINK
                          SizedBox(height: AppSpacing.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "¿Ya tienes cuenta?",
                                style: GoogleFonts.nunito(
                                  fontSize: AppFontSizes.bodyLarge,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              TextButton(
                                onPressed: widget.isLoading
                                    ? null
                                    : widget.onNavigateToLogin,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primaryLight,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm
                                  ),
                                ),
                                child: Text(
                                  "Inicia sesión",
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
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}