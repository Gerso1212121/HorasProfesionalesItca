// lib/Frontend/Auth/widgets/auth_buttons.dart
import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final Gradient? gradient;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool enableShadow;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.icon,
    this.gradient,
    this.width,
    this.height = 56,
    this.borderRadius = 12,
    this.enableShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final buttonGradient = gradient ??
        LinearGradient(
          colors: [
            backgroundColor,
            Color.lerp(backgroundColor, Colors.black, 0.1)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: buttonGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: enableShadow
              ? [
                  BoxShadow(
                    color: backgroundColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: textColor,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: EdgeInsets.zero, // Important for gradient to show
          ),
          child: isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: textColor,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(icon, size: 20, color: textColor),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color borderColor;
  final Color textColor;
  final Gradient? borderGradient;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool enableShadow;
  final Color? fillColor;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.borderColor = Colors.blue,
    this.textColor = Colors.blue,
    this.borderGradient,
    this.width,
    this.height = 56,
    this.borderRadius = 12,
    this.enableShadow = false,
    this.fillColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: borderGradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: borderGradient != null
              ? null
              : Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
          boxShadow: enableShadow
              ? [
                  BoxShadow(
                    color: borderColor.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: fillColor ?? Colors.transparent,
            side: borderGradient != null
                ? BorderSide.none
                : BorderSide(
                    color: borderColor,
                    width: 1.5,
                  ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Container(
            decoration: borderGradient != null
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius - 1),
                    border: Border.all(
                      color: Colors.white,
                      width: 1,
                    ),
                  )
                : null,
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient gradient;
  final Color textColor;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double? height;
  final double borderRadius;
  final double elevation;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.gradient,
    this.textColor = Colors.white,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.borderRadius = 12,
    this.elevation = 4,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: elevation * 2,
              offset: Offset(0, elevation),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: textColor,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        if (icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(icon, size: 20, color: textColor),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// En lib/Frontend/widgets/Buttons/Buttons.dart
class PrimaryGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;
  final List<Color> gradientColors;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final TextStyle? textStyle; // Nuevo parámetro

  const PrimaryGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    required this.gradientColors,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    this.elevation = 6,
    this.textStyle, // Nuevo parámetro
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: 0,
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: elevation > 0
              ? [
                  BoxShadow(
                    color: gradientColors.first.withOpacity(0.3),
                    blurRadius: elevation,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: textStyle ?? // Usa textStyle si se proporciona
                          const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class SuccessGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;

  const SuccessGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      gradient: const LinearGradient(
        colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Colors.white,
      icon: icon,
      isLoading: isLoading,
    );
  }
}

class WarningGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final IconData? icon;

  const WarningGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GradientButton(
      text: text,
      onPressed: onPressed,
      gradient: const LinearGradient(
        colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      textColor: Colors.white,
      icon: icon,
      isLoading: isLoading,
    );
  }
}

class GradientOutlineButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient borderGradient;
  final Color textColor;
  final bool isLoading;
  final double? width;
  final double? height;
  final double radius;

  const GradientOutlineButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.borderGradient,
    this.textColor = Colors.blue,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.radius = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: borderGradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Container(
        margin: const EdgeInsets.all(2), // grosor del borde
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: textColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
