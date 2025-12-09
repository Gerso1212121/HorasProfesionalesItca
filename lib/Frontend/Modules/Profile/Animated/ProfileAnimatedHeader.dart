import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/Profile/ViewModels/AnimationStateVM.dart';
import 'package:provider/provider.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';

class ProfileAnimatedHeader extends StatefulWidget {
  final String nombre;
  final String inicial;

  const ProfileAnimatedHeader({
    super.key,
    required this.nombre,
    required this.inicial,
  });

  @override
  State<ProfileAnimatedHeader> createState() => _ProfileAnimatedHeaderState();
}

class _ProfileAnimatedHeaderState extends State<ProfileAnimatedHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _isInitialized = true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) {
      final animationState =
          Provider.of<AnimationStateVM>(context, listen: false);

      // Solo animar si no se ha animado antes en esta sesión
      if (!animationState.hasHeaderAnimated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _animationController.forward();
            animationState.setHeaderAnimated(true);
          }
        });
      } else {
        // Si ya se animó, ir directamente al estado final
        _animationController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.zoomBackground,
          StretchMode.blurBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo Parallax
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB2F5DB),
                    Color(0xFF86A8E7),
                  ],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
              ),
            ),

            // Formas decorativas
            Positioned(
              top: -50,
              right: -50,
              child: _DecorativeCircle(size: 200, opacity: 0.1),
            ),
            Positioned(
              bottom: 40,
              left: -30,
              child: _DecorativeCircle(size: 150, opacity: 0.15),
            ),
            Positioned(
              top: 80,
              left: 40,
              child: _DecorativeCircle(size: 50, opacity: 0.05),
            ),

            // Contenido animado
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 60),

                  // Avatar con animación
                  ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _animationController,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          widget.inicial,
                          style: const TextStyle(
                            fontSize: 45,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF86A8E7),
                            fontFamily: AppFonts.main,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nombre con animación secuencial
                  _SequentialFadeIn(
                    animationController: _animationController,
                    delay: 0.3,
                    child: Text(
                      '¡Hola, ${widget.nombre}!',
                      style: GoogleFonts.itim(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 2),
                            blurRadius: 4.0,
                            color: Color.fromARGB(40, 0, 0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),
                  _SequentialFadeIn(
                    animationController: _animationController,
                    delay: 0.4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        'Estudiante Activo',
                        style: GoogleFonts.itim(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final double opacity;

  const _DecorativeCircle({required this.size, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

// Widget para animaciones secuenciales
class _SequentialFadeIn extends StatelessWidget {
  final AnimationController animationController;
  final double delay;
  final Widget child;

  const _SequentialFadeIn({
    required this.animationController,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Interval(
            delay,
            1.0,
            curve: Curves.easeOut,
          ),
        ),
      ),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animationController,
            curve: Interval(
              delay,
              1.0,
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}
