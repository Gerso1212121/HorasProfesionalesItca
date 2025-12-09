// lib/Frontend/Modules/Auth/widgets/dialogs/EmailVerificationDialog.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';

class EmailVerificationDialog extends StatefulWidget {
  final User? user;
  final bool esItca;
  final VoidCallback? onSuccess;
  final VoidCallback? onClose;

  const EmailVerificationDialog({
    super.key,
    required this.user,
    this.esItca = false,
    this.onSuccess,
    this.onClose,
  });

  @override
  State<EmailVerificationDialog> createState() =>
      _EmailVerificationDialogState();
}

class _EmailVerificationDialogState extends State<EmailVerificationDialog> {
  bool _isVerifying = false;
  bool _verificationFailed = false;
  String? _errorMessage;
  bool _showTimer = false;
  int _timerSeconds = 30;
  Timer? _timer;
  bool _canResend = true;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timerSeconds = 30;
    _showTimer = true;
    _canResend = false;
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        setState(() {
          _showTimer = false;
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  Future<void> _resendVerificationEmail() async {
    if (widget.user == null || !_canResend) return;

    try {
      await widget.user!.sendEmailVerification();
      _startResendTimer();
      
      // Mostrar confirmación
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.esItca 
                ? '📧 Correo de verificación ITCA reenviado'
                : '📧 Correo de verificación reenviado',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w500,
              ),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '❌ Error al reenviar: $e',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w500,
              ),
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

  Future<void> _verifyEmail() async {
    if (widget.user == null) return;

    setState(() {
      _isVerifying = true;
      _verificationFailed = false;
      _errorMessage = null;
    });

    try {
      await widget.user!.reload();
      await Future.delayed(const Duration(milliseconds: 500));
      
      final currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null && currentUser.emailVerified) {
        _onVerificationSuccess();
      } else {
        setState(() {
          _isVerifying = false;
          _verificationFailed = true;
          _errorMessage = 'Tu email aún no ha sido verificado.\n'
                         'Asegúrate de haber hecho clic en el enlace del correo.';
        });
      }
    } catch (e) {
      setState(() {
        _isVerifying = false;
        _verificationFailed = true;
        _errorMessage = 'Error al verificar: $e\n'
                       'Intenta nuevamente.';
      });
    }
  }

  void _onVerificationSuccess() {
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (widget.onSuccess != null) {
        widget.onSuccess!();
      }
    }
  }

  void _handleClose() {
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (widget.onClose != null) {
        widget.onClose!();
      }
    }
  }

  Widget _buildHeader() {
    final mainColor = widget.esItca ? const Color(0xFF0066CC) : AppColors.primary;
    
    return Column(
      children: [
        // Badge ITCA
        if (widget.esItca)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  mainColor,
                  mainColor.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: mainColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.school, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'ESTUDIANTE ITCA',
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        
        // Icono animado
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    mainColor.withOpacity(0.1),
                    mainColor.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
            ),
            
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    mainColor.withOpacity(0.15),
                    mainColor.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: mainColor.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                Icons.mail_outline_rounded,
                size: 40,
                color: mainColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTitle() {
    final mainColor = widget.esItca ? const Color(0xFF0066CC) : AppColors.primary;
    
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.nunito(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            children: [
              TextSpan(text: 'Verifica tu '),
              TextSpan(
                text: widget.esItca ? 'correo ITCA' : 'correo',
                style: TextStyle(
                  color: mainColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.esItca 
            ? 'Tu correo institucional (@itca.edu.sv)'
            : 'Confirma tu dirección de correo',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Instrucciones principales
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.send_rounded,
                  size: 18,
                  color: Colors.blue[600],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.esItca
                      ? "Hemos enviado un enlace de verificación a tu correo institucional @itca.edu.sv"
                      : "Hemos enviado un enlace de verificación a tu dirección de correo",
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Lista de pasos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[100]!),
            ),
            child: Column(
              children: [
                _buildStep(
                  number: '1',
                  title: 'Abre tu correo',
                  description: 'Busca nuestro mensaje de verificación',
                  icon: Icons.inbox_rounded,
                  color: Colors.blue,
                ),
                _buildStep(
                  number: '2',
                  title: 'Haz clic en el enlace',
                  description: 'Confirma tu dirección de correo',
                  icon: Icons.link_rounded,
                  color: Colors.green,
                ),
                _buildStep(
                  number: '3',
                  title: 'Regresa aquí',
                  description: 'Presiona "Ya verifiqué"',
                  icon: Icons.check_circle_rounded,
                  color: Colors.purple,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Advertencia SPAM
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[700],
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿No encuentras el correo?',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange[800],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Revisa tu carpeta de spam o correo no deseado. El correo podría haber llegado allí.',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.orange[700],
                          height: 1.4,
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
    );
  }

  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Número
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Icono
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          
          const SizedBox(width: 12),
          
          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResendSection() {
    final mainColor = widget.esItca ? const Color(0xFF0066CC) : AppColors.primary;
    
    return Column(
      children: [
        // Título de la sección
        Text(
          '¿No recibiste el correo?',
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        
        const SizedBox(height: 12),
        
        if (_showTimer)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, color: Colors.grey[700], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reenvío disponible en ',
                  style: GoogleFonts.nunito(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$_timerSeconds s',
                    style: GoogleFonts.nunito(
                      color: mainColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        if (!_showTimer && _canResend)
          ElevatedButton(
            onPressed: _resendVerificationEmail,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: mainColor,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: mainColor,
                  width: 1.5,
                ),
              ),
              shadowColor: Colors.transparent,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_rounded, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reenviar correo',
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final mainColor = widget.esItca ? const Color(0xFF0066CC) : AppColors.primary;
    
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
                // Header con icono
                _buildHeader(),
                
                const SizedBox(height: 24),
                
                // Título
                _buildTitle(),
                
                // Descripción y pasos
                _buildDescription(),
                
                // Sección de reenvío
                _buildResendSection(),
                
                // Mensaje de error
                if (_verificationFailed && _errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red[600],
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Verificación fallida',
                                style: GoogleFonts.nunito(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _errorMessage!,
                                style: GoogleFonts.nunito(
                                  fontSize: 14,
                                  color: Colors.red[600],
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Botón principal: YA VERIFIQUÉ
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _verifyEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      shadowColor: mainColor.withOpacity(0.3),
                    ),
                    child: _isVerifying
                        ? SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _verificationFailed
                                    ? Icons.refresh_rounded
                                    : Icons.check_circle_outline_rounded,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _verificationFailed
                                    ? 'Intentar nuevamente'
                                    : 'Ya verifiqué mi correo',
                                style: GoogleFonts.nunito(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Botón cerrar
                TextButton(
                  onPressed: _isVerifying ? null : _handleClose,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[600],
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(
                    "Volver al inicio de sesión",
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Información adicional
                Text(
                  'Te esperamos dentro de la app 👋',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
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