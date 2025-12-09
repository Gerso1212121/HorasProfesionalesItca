// lib/Frontend/Modules/Auth/widgets/dialogs/ForgotPasswordDialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:horas2/Frontend/Modules/Auth/ViewModels/AuthLoginVM.dart';
import 'package:horas2/Frontend/Utils/Auth/AuthValidators.dart';
import 'package:provider/provider.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Timer? _countdownTimer;
  double _progress = 0.0;
  bool _isLoading = false;
  bool _showSuccess = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _startTimerIfNeeded();
  }

void _startTimerIfNeeded() {
  final viewModel = Provider.of<AuthLoginVM>(context, listen: false);

  // Actualizamos progreso inicial
  setState(() {
    _progress = _calculateProgress(viewModel);
  });

  if (!viewModel.canRequestPasswordReset) {
    _countdownTimer?.cancel(); // Evitar timers duplicados
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final progress = _calculateProgress(viewModel);
      setState(() => _progress = progress);

      if (progress >= 1.0) timer.cancel();
    });
  }
}


  double _calculateProgress(AuthLoginVM viewModel) {
    if (viewModel.canRequestPasswordReset) return 1.0;
    if (viewModel.lastPasswordResetRequest == null) return 0.0;

    final now = DateTime.now();
    final difference = now.difference(viewModel.lastPasswordResetRequest!);
    final elapsedSeconds = difference.inSeconds.clamp(0, 120);

    return elapsedSeconds / 120;
  }

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final viewModel = Provider.of<AuthLoginVM>(context, listen: false);

    try {
      await viewModel.resetPassword(
        email: _emailController.text.trim(),
        context: context,
      );

      setState(() {
        _isLoading = false;
        _showSuccess = true;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Anillo decorativo
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF66B7D).withOpacity(0.1),
                    const Color(0xFF86A8E7).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
            ),
            
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF66B7D).withOpacity(0.15),
                    const Color(0xFF86A8E7).withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF66B7D).withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.lock_reset_rounded,
                size: 30,
                color: const Color(0xFFF66B7D),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        // Título
        Column(
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.nunito(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                children: const [
                  TextSpan(text: 'Recuperar '),
                  TextSpan(
                    text: 'Contraseña',
                    style: TextStyle(
                      color: Color(0xFFF66B7D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Restablece el acceso a tu cuenta',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        // Icono de éxito
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withOpacity(0.1),
                Colors.green.withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
          ),
          child: Icon(
            Icons.check_circle_rounded,
            size: 40,
            color: Colors.green,
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Mensaje de éxito
        Text(
          '¡Correo enviado exitosamente!',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        // Descripción
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.green[700],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hemos enviado las instrucciones para restablecer tu contraseña',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        color: Colors.green[800],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Correo destino
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[100]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.email_rounded,
                      size: 18,
                      color: Colors.green[600],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enviado a:',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: Colors.green[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _emailController.text.trim(),
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Botón de aceptar
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF66B7D),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
              shadowColor: const Color(0xFFF66B7D).withOpacity(0.3),
            ),
            child: Text(
              'Aceptar',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Consejo adicional
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: Colors.amber[600],
              ),
              const SizedBox(width: 8),
              Text(
                'Revisa tu carpeta de spam si no \nencuentras el correo',
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormState(AuthLoginVM viewModel) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Descripción
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF66B7D).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF66B7D).withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: const Color(0xFFF66B7D),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ingresa el correo electrónico asociado a tu cuenta. ',                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Campo de email
          TextFormField(
            controller: _emailController,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Correo electrónico',
              labelStyle: GoogleFonts.nunito(
                color: Colors.grey[600],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[400]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFFF66B7D),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              prefixIcon: Icon(
                Icons.email_rounded,
                color: Colors.grey[600],
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 56,
              ),
            ),
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
            keyboardType: TextInputType.emailAddress,
            validator: AuthValidators.validateEmail,
          ),
          
          const SizedBox(height: 24),
          
          // Botones
          Row(
            children: [
              // Botón cancelar
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[400]!),
                  ),
                  child: Text(
                    'Cancelar',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Botón enviar
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendPasswordResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF66B7D),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    shadowColor: const Color(0xFFF66B7D).withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send_rounded,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Enviar',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitState(AuthLoginVM viewModel) {
    return Column(
      children: [
        // Icono de espera
        Container(
          width: 70,
          height: 70,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF86A8E7).withOpacity(0.1),
                const Color(0xFF86A8E7).withOpacity(0.05),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF86A8E7).withOpacity(0.3), width: 2),
          ),
          child: Icon(
            Icons.timer_outlined,
            size: 40,
            color: const Color(0xFF86A8E7),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Mensaje
        Text(
          'Espera para solicitar otro correo',
          style: GoogleFonts.nunito(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF86A8E7).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF86A8E7).withOpacity(0.2)),
          ),
          child: Column(
            children: [
              // Barra de progreso
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF86A8E7),
                    ),
                    borderRadius: BorderRadius.circular(10),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 12),
                  
                  // Contador
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF86A8E7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86A8E7).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 18,
                          color: const Color(0xFF86A8E7),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tiempo restante: ${viewModel.timeUntilNextReset}',
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF86A8E7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Instrucción
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Para proteger tu cuenta, debes esperar 2 minutos entre solicitudes.',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Botón cerrar
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[700],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey[400]!),
            ),
            child: Text(
              'Cerrar',
              style: GoogleFonts.nunito(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AuthLoginVM>(context);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 40,
              spreadRadius: -10,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header
                _buildHeader(),
                
                const SizedBox(height: 24),
                
                // Contenido según estado
                if (_showSuccess)
                  _buildSuccessState()
                else if (viewModel.canRequestPasswordReset)
                  _buildFormState(viewModel)
                else
                  _buildWaitState(viewModel),
                
                const SizedBox(height: 8),
                
                // Footer informativo
                if (!_showSuccess && viewModel.canRequestPasswordReset)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      'Te enviaremos un correo con instrucciones para restablecer tu contraseña',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}