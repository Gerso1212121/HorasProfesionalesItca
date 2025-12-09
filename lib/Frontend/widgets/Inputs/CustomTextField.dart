import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final VoidCallback? onSuffixPressed;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool showCounter;
  final EdgeInsetsGeometry? contentPadding;
  final Color? fillColor;
  final Color? focusedColor;
  final Color? enabledBorderColor;
  final Color? errorBorderColor;
  final double borderRadius;
  final TextStyle? labelStyle;
  final TextStyle? hintStyle;
  final TextStyle? textStyle;
  final TextStyle? errorStyle;
  final bool isRequired;
  final String? errorText;
  final bool showClearButton;
  final bool showShadow;
  final double elevation;
  final List<String>? autofillHints;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.onChanged,
    this.onSubmitted,
    this.onSuffixPressed,
    this.validator,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.showCounter = false,
    this.contentPadding,
    this.fillColor = const Color.fromARGB(255, 247, 247, 247),
    this.focusedColor = const Color(0xFFF66B7D),
    this.enabledBorderColor,
    this.errorBorderColor,
    this.borderRadius = 12.0,
    this.labelStyle,
    this.hintStyle,
    this.textStyle,
    this.errorStyle,
    this.isRequired = false,
    this.errorText,
    this.showClearButton = false,
    this.showShadow = true,
    this.elevation = 2.0,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasError = errorText != null && errorText!.isNotEmpty;

    Widget textField = TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      autofillHints: autofillHints,
      style: textStyle ??
          TextStyle(
            fontSize: 16,
            color: enabled ? Colors.grey[900] : Colors.grey[600],
          ),
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        hintText: hintText,
        hintStyle: hintStyle ??
            TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
        labelStyle: labelStyle ??
            TextStyle(
              fontSize: 16,
              color: hasError
                  ? (errorBorderColor ?? Colors.red)
                  : Colors.grey[700],
            ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        prefixIcon: prefixIcon != null
            ? Icon(
                prefixIcon,
                color: hasError
                    ? (errorBorderColor ?? Colors.red)
                    : Colors.grey[700],
                size: 22,
              )
            : null,
        suffixIcon: showClearButton && controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  if (onChanged != null) onChanged!('');
                },
              )
            : (suffixIcon != null
                ? IconButton(
                    icon: Icon(
                      suffixIcon,
                      color: hasError
                          ? (errorBorderColor ?? Colors.red)
                          : Colors.grey[700],
                      size: 22,
                    ),
                    onPressed: onSuffixPressed,
                  )
                : null),
        filled: true,
        fillColor: fillColor,
        contentPadding: contentPadding ??
            const EdgeInsets.symmetric(vertical: 18.0, horizontal: 16.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: enabledBorderColor ?? Colors.grey,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: enabledBorderColor ?? const Color(0xFFE0E0E0),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: focusedColor ?? Colors.blue,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: errorBorderColor ?? Colors.red,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(
            color: errorBorderColor ?? Colors.red,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        errorText: errorText,
        errorStyle: errorStyle ??
            TextStyle(
              fontSize: 12,
              color: errorBorderColor ?? Colors.red,
            ),
        errorMaxLines: 2,
      ),
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
      validator: validator,
    );

    // Aplicar sombra si está habilitada
    if (showShadow) {
      return Material(
        elevation: elevation,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(borderRadius),
        child: textField,
      );
    }

    return textField;
  }
}

// Versión simplificada para uso rápido (manteniendo compatibilidad)
class SimpleCustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData? icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final Color focusedColor;
  final Color fillcolor;

  const SimpleCustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.focusedColor = const Color(0xFFF66B7D),
    this.fillcolor = const Color.fromARGB(255, 247, 247, 247),
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      controller: controller,
      labelText: labelText,
      prefixIcon: icon,
      obscureText: obscureText,
      keyboardType: keyboardType,
      focusedColor: focusedColor,
      fillColor: fillcolor,
    );
  }
}
