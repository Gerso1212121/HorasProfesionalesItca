// lib/Frontend/Auth/widgets/terms_slider_sheet.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:horas2/Frontend/widgets/Buttons/Buttons.dart';

class AuthTermsSliderScreen extends StatefulWidget {
  final bool initialValue;
  final ValueChanged<bool> onTermsAccepted;
  final VoidCallback? onClose;

  const AuthTermsSliderScreen({
    super.key,
    required this.initialValue,
    required this.onTermsAccepted,
    this.onClose,
  });

  @override
  State<AuthTermsSliderScreen> createState() => _TermsSliderSheetState();
}

class _TermsSliderSheetState extends State<AuthTermsSliderScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAccepted = false;
  List<TermsSection> _termsSections = [];

  @override
  void initState() {
    super.initState();
    _isAccepted = widget.initialValue;
    _initializeTermsSections();
  }

  void _initializeTermsSections() {
    _termsSections = [
      TermsSection(
        title: 'Seguridad y Privacidad',
        content: '''
Tu privacidad es nuestra máxima prioridad. Esta aplicación está diseñada como un espacio seguro donde puedes explorar y expresar tus pensamientos libremente.

Protección de Datos:
• Todos tus datos están encriptados de extremo a extremo
• Tu información personal nunca se compartirá con terceros
• Tienes control total sobre lo que compartes

Confidencialidad:
• Tu diario es privado y solo tú puedes acceder a este
• Las conversaciones con la IA son confidenciales
        ''',
        color: AppColors.primary,
      ),
      TermsSection(
        title: 'Propósito Terapéutico',
        content: '''
Esta aplicación es una herramienta de apoyo diseñada para promover el bienestar emocional, NO sustituye la terapia profesional.

Objetivos:
• Brindar un espacio para la reflexión personal
• Ofrecer ejercicios prácticos de bienestar
• Facilitar el autoconocimiento emocional

Limitaciones:
• No somos un servicio de emergencia
• No proporcionamos diagnóstico médico
        ''',
        color: AppColors.diaryPrimary,
      ),
      TermsSection(
        title: 'IA como Asistente',
        content: '''
Nuestra Inteligencia Artificial está diseñada para escuchar y ofrecer perspectivas, siguiendo principios éticos.

Qué hace la IA:
• Escucha activamente tus inquietudes
• Sugiere ejercicios personalizados
• Ofrece diferentes perspectivas
• Nunca juzga tus sentimientos

Qué NO hace la IA:
• No toma decisiones por ti
• No da consejos médicos
• No reemplaza relaciones humanas
        ''',
        color: AppColors.info,
      ),
      TermsSection(
        title: 'Responsabilidad del Usuario',
        content: '''
Al usar esta aplicación, reconoces y aceptas ciertas responsabilidades:

Tus Compromisos:
• Usar la aplicación como herramienta de apoyo
• Ser honesto contigo mismo en el proceso
• Mantener la confidencialidad de tu acceso
• Compartir responsablemente

Autoreflexión:
• Los ejercicios requieren tu participación activa
• Los resultados dependen de tu compromiso
• Tú eres el protagonista de tu bienestar
        ''',
        color: AppColors.success,
      ),
      TermsSection(
        title: 'Diario Personal',
        content: '''
Tu diario es un espacio sagrado para tu crecimiento personal.

Características:
• Entradas privadas y encriptadas locales

Beneficios:
• Claridad mental a través de la escritura
• Espacio libre de juicios
        ''',
        color: AppColors.diaryAccent,
      ),
    ];
  }

  void _nextPage() {
    if (_currentPage < _termsSections.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _completeAcceptance();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

// lib/Frontend/Auth/widgets/terms_slider_sheet.dart
// Modifica SOLO la función _completeAcceptance:

  void _completeAcceptance() {
    // Primero, actualizar el estado local
    setState(() {
      _isAccepted = true;
    });

    // ✅ FORZAR una reconstrucción inmediata
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ Llamar al callback CON EL VALOR TRUE
      widget.onTermsAccepted(true);

      // ✅ Esperar un poco para que el estado se propague
      Future.delayed(const Duration(milliseconds: 200), () {
        if (widget.onClose != null) {
          widget.onClose!();
        } else {
          Navigator.of(context).pop();
        }
      });
    });
  }

// También modifica el botón en _buildNavigationButtons():
  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1.5,
                  ),
                ),
                child: TextButton(
                  onPressed: _previousPage,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Anterior',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          if (_currentPage > 0) const SizedBox(width: 12),
          Expanded(
            flex: _currentPage > 0 ? 2 : 1,
            child: GradientButton(
              text: _currentPage < _termsSections.length - 1
                  ? 'Continuar'
                  : (_isAccepted ? '¡Aceptado!' : 'Aceptar Términos'),
              onPressed: () {
                if (_currentPage < _termsSections.length - 1) {
                  _nextPage();
                } else if (!_isAccepted) {
                  // Si no está aceptado y está en la última página
                  _completeAcceptance();
                }
              },
              gradient: _isAccepted && _currentPage == _termsSections.length - 1
                  ? const LinearGradient(
                      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              textColor: Colors.white,
              icon: _currentPage < _termsSections.length - 1
                  ? Icons.navigate_next
                  : (_isAccepted ? Icons.check : Icons.gpp_good),
              isLoading: false,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.lg),
          topRight: Radius.circular(AppBorderRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _termsSections.length,
                itemBuilder: (context, index) {
                  return _buildTermSection(_termsSections[index]);
                },
              ),
            ),

            // Progress indicator
            _buildProgressIndicator(),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight.withOpacity(0.3),
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppBorderRadius.lg),
          topRight: Radius.circular(AppBorderRadius.lg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gpp_good,
            color: AppColors.success,
            size: 32,
          ),
          SizedBox(
            height: 20,
          ),
          Column(
            children: [
              Text(
                'Términos y Condiciones',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Tu espacio seguro para crecer',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermSection(TermsSection section) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: section.color,
                    fontFamily: GoogleFonts.nunito()
                        .fontFamily, // Añade Nunito al título
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Text(
              section.content,
              style: GoogleFonts.nunito(
                // Aplica Nunito al contenido
                fontSize: AppFontSizes.bodyLarge, // Usa el tamaño definido
                color: AppColors.textPrimary, // Usa el color definido
                height: 1.6, // Mantén el interlineado
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildBenefitsSection(section),
        ],
      ),
    );
  }

  Widget _buildBenefitsSection(TermsSection section) {
    List<String> benefits = [];

    switch (section.title) {
      case 'Seguridad y Privacidad':
        benefits = [
          'Tu espacio, tus reglas',
          'Protección máxima de datos',
          'Borrado total cuando lo decidas',
        ];
        break;
      case 'Propósito Terapéutico':
        benefits = [
          'Herramientas para el autoconocimiento',
          'Crecimiento personal progresivo',
          'Espacio libre de prejuicios',
        ];
        break;
      case 'IA como Asistente':
        benefits = [
          'Compañía sin juicios',
          'Perspectivas diferentes',
          'Reflexiones que te hacen crecer',
        ];
        break;
      case 'Responsabilidad del Usuario':
        benefits = [
          'Tú eres el protagonista',
          'Empoderamiento personal',
          'Autonomía en tu proceso',
        ];
        break;
      case 'Diario Personal':
        benefits = [
          'Tu historia personal',
          'Registro de crecimiento',
          'Espacio para ser auténtico',
        ];
        break;
      default:
        benefits = ['Beneficio 1', 'Beneficio 2', 'Beneficio 3'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Beneficios para ti:',
          style: GoogleFonts.nunito(
            // Aplica Nunito aquí también
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: section.color,
          ),
        ),
        const SizedBox(height: 12),
        ...benefits
            .map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: section.color,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          benefit,
                          style: GoogleFonts.nunito(
                            // Aplica Nunito a los beneficios
                            fontSize: 15,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paso ${_currentPage + 1} de ${_termsSections.length}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${((_currentPage + 1) / _termsSections.length * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(3),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: (_currentPage + 1) / _termsSections.length,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class TermsSection {
  final String title;
  final String content;
  final Color color;

  TermsSection({
    required this.title,
    required this.content,
    required this.color,
  });
}
