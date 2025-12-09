// lib/Frontend/Modules/Auth/widgets/AuthRegisterTermsCheckbox.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:horas2/Frontend/Modules/Auth/Screens/AuthTermsSliderScreen.dart';

class AuthRegisterTermsCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color primaryColor;

  const AuthRegisterTermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.primaryColor = AppColors.success,
  });

  @override
  State<AuthRegisterTermsCheckbox> createState() =>
      _AuthRegisterTermsCheckboxState();
}

class _AuthRegisterTermsCheckboxState extends State<AuthRegisterTermsCheckbox> {
  bool _localAccepted = false;

  @override
  void initState() {
    super.initState();
    _localAccepted = widget.value;
  }

  @override
  void didUpdateWidget(covariant AuthRegisterTermsCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _localAccepted = widget.value;
    }
  }

  void _showTermsSlider(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return AuthTermsSliderScreen(
              initialValue: _localAccepted,
              onTermsAccepted: (accepted) {
                setState(() {
                  _localAccepted = accepted;
                });
                // ✅ Notificar inmediatamente al ViewModel
                widget.onChanged(accepted);
              },
              onClose: () => Navigator.of(context).pop(),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final green = widget.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (!_localAccepted) {
              _showTermsSlider(context);
            } else {
              // Si ya está aceptado, al tocar se desmarca
              setState(() {
                _localAccepted = false;
              });
              widget.onChanged(false);
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _localAccepted ? green.withOpacity(0.12) : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _localAccepted ? green : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _localAccepted ? green : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _localAccepted ? green : Colors.grey[400]!,
                      width: 2,
                    ),
                    boxShadow: _localAccepted
                        ? [
                            BoxShadow(
                              color: green.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ]
                        : [],
                  ),
                  child: _localAccepted
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _localAccepted
                            ? 'Términos aceptados'
                            : 'Términos y Condiciones',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _localAccepted ? green : Colors.grey[800],
                        ),
                      ),
                      Text(
                        _localAccepted
                            ? 'Puedes proceder con el registro'
                            : 'Toca para leer los términos',
                        style: GoogleFonts.nunito(
                          color: Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _localAccepted ? Icons.verified : Icons.arrow_forward_ios,
                  size: 20,
                  color: _localAccepted ? green : Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            _localAccepted
                ? 'Términos aceptados. Puedes continuar con el registro.'
                : '',
            style: GoogleFonts.nunito(
              color: _localAccepted ? green : Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.bold,
              height: 1.4,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
