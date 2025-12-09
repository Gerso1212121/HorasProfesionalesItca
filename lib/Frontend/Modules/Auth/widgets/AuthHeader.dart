// lib/Frontend/Auth/widgets/auth_header.dart
import 'package:flutter/material.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthHeader extends StatelessWidget {
  final Animation<double>? scaleAnimation;
  final Animation<double>? fadeAnimation;
  final String title;
  final String subtitle;
  final String imagePath;

  const AuthHeader({
    super.key,
    this.scaleAnimation,
    this.fadeAnimation,
    required this.title,
    required this.subtitle,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    Widget headerContent = Column(
      children: [
        // Logo con animación
        if (scaleAnimation != null)
          AnimatedBuilder(
            animation: scaleAnimation!,
            builder: (context, child) {
              return Transform.scale(
                scale: scaleAnimation!.value,
                child: _buildLogo(),
              );
            },
          )
        else
          _buildLogo(),
        
        SizedBox(height: AppSpacing.xl), // Usando constante
        
        // Textos con animación
        if (fadeAnimation != null)
          AnimatedBuilder(
            animation: fadeAnimation!,
            builder: (context, child) {
              return Opacity(
                opacity: fadeAnimation!.value,
                child: _buildTexts(context), // Pasamos context
              );
            },
          )
        else
          _buildTexts(context), // Pasamos context
      ],
    );

    return headerContent;
  }

  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Image.asset(
          imagePath,
          width: 200,
          height: 200,
        ),
      ],
    );
  }

  Widget _buildTexts(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          style: GoogleFonts.nunito( // Usando Nunito de Google Fonts
            fontSize: AppFontSizes.headlineMedium, // 28px
            fontWeight: FontWeight.w700, // Bold
            color: AppColors.textPrimary, // Colors.black87
            height: 1.2,
            letterSpacing: -0.3, // Mejor kerning para títulos
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.sm), // 8px
        Text(
          subtitle,
          style: GoogleFonts.nunito( // Usando Nunito de Google Fonts
            fontSize: AppFontSizes.bodyLarge, // 16px
            fontWeight: FontWeight.w400, // Regular
            color: AppColors.textSecondary, // Colors.grey[600]
            height: 1.4,
            letterSpacing: 0.1, // Ligero espaciado para mejor legibilidad
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}