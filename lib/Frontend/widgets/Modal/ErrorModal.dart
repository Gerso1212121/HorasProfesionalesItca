// lib/Frontend/Modules/Auth/widgets/auth_error_dialog.dart
import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';

class ErrorModal extends StatelessWidget {
  final String errorTitle;
  final String errorMessage;
  final IconData errorIcon;

  const ErrorModal({
    super.key,
    required this.errorTitle,
    required this.errorMessage,
    this.errorIcon = Icons.error_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de error
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                errorIcon,
                size: 32,
                color: AppColors.error,
              ),
            ),

            const SizedBox(height: 20),

            // Título
            Text(
              errorTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Mensaje
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Botón para cerrar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  ),
                  elevation: 4,
                ),
                child: const Text(
                  'Entendido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
