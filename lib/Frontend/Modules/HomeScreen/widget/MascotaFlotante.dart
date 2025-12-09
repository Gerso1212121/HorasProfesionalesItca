import 'package:flutter/material.dart';

class MascotaFlotante extends StatefulWidget {
  final VoidCallback onTap;
  final bool showInitialMessage;

  const MascotaFlotante({
    super.key,
    required this.onTap,
    this.showInitialMessage = true,
  });

  @override
  State<MascotaFlotante> createState() => _MascotaFlotanteState();
}

class _MascotaFlotanteState extends State<MascotaFlotante>
    with SingleTickerProviderStateMixin {
  bool _showMessage = false;
  bool _isPulsating = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animación para el pulso y rebote
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Usar animaciones separadas para evitar problemas con TweenSequence
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Mostrar mensaje inicial si está habilitado
    if (widget.showInitialMessage) {
      _showInitialMessage();
    }

    // Iniciar animación de pulso periódica
    _startPulseAnimation();
  }

  void _startPulseAnimation() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && !_isPulsating && !_showMessage) {
        setState(() => _isPulsating = true);
        
        // Usar un método diferente para la animación repetida
        _startPulseSequence();
      }
    });
  }

  void _startPulseSequence() {
    // Animación de 3 pulsos
    Future.doWhile(() async {
      if (!mounted || !_isPulsating) return false;
      
      // Pulso hacia adelante
      await _animationController.forward().then((_) {
        if (!mounted) return;
        // Pulso hacia atrás
        _animationController.reverse();
      });
      
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Repetir por 2 veces más (3 en total)
       int pulseCount = 0;
      pulseCount++;
      if (pulseCount >= 2) {
        pulseCount = 0;
        return false; // Detener el ciclo
      }
      return true; // Continuar
    }).then((_) {
      if (mounted) {
        setState(() => _isPulsating = false);
        // Programar siguiente pulso
        Future.delayed(const Duration(seconds: 7), () {
          if (mounted && !_showMessage) {
            _startPulseAnimation();
          }
        });
      }
    });
  }

  void _showInitialMessage() {
    Future.delayed(const Duration(seconds: 0), () {
      if (mounted && !_showMessage) {
        setState(() {
          _showMessage = true;
        });

        // Ocultar mensaje después de 5 segundos
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _showMessage = false;
            });
            // Iniciar pulsos después del mensaje inicial
            _startPulseAnimation();
          }
        });
      }
    });
  }

  void _handleTap() {
    // Detener cualquier animación en curso
    _animationController.stop();
    
    // Efecto visual inmediato
    setState(() {
      _showMessage = false;
      _isPulsating = false;
    });
    
    // Animación rápida de feedback
    _animationController.reset();
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // Pequeña pausa para feedback visual antes de la acción
    Future.delayed(const Duration(milliseconds: 150), () {
      widget.onTap();
    });
    
    // Mostrar mensaje después de la acción
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _showPostTapMessage();
      }
    });
  }

  void _showPostTapMessage() {
    setState(() {
      _showMessage = true;
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMessage = false;
        });
        // Reanudar animaciones periódicas
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            _startPulseAnimation();
          }
        });
      }
    });
  }

  void _toggleMessage() {
    _animationController.stop();
    setState(() {
      _showMessage = !_showMessage;
      _isPulsating = false;
    });

    if (_showMessage) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showMessage) {
          setState(() {
            _showMessage = false;
          });
          _startPulseAnimation();
        }
      });
    } else {
      _startPulseAnimation();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: const EdgeInsets.all(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Burbuja de chat con animación de entrada
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 150),
              switchInCurve: Curves.elasticOut,
              switchOutCurve: Curves.easeIn,
              child: _showMessage
                  ? _buildChatBubble()
                  : const SizedBox(width: 0),
            ),

            // Avatar de mascota con animaciones
            GestureDetector(
              onTap: _handleTap,
              onLongPress: _toggleMessage,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    // Animación de rebote (solo durante el pulso)
                    final bounceValue = _isPulsating ? _bounceAnimation.value : 0.0;
                    // Animación de escala (solo durante el pulso o interacción)
                    final scaleValue = _isPulsating ? _scaleAnimation.value : 1.0;
                    
                    return Transform.translate(
                      offset: Offset(0, bounceValue),
                      child: Transform.scale(
                        scale: scaleValue,
                        child: _buildMascotaAvatar(),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble() {
    return Container(
      key: const ValueKey('chatBubble'),
      margin: const EdgeInsets.only(right: 3, bottom: 0),
      constraints: const BoxConstraints(
        maxWidth: 60,
        minWidth: 60,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF86A8E7),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Indicador de escritura (animado)
          _buildTypingIndicator(),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return SizedBox(
      width: 24,
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMascotaAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF86A8E7).withOpacity(_isPulsating ? 0.6 : 0.3),
            blurRadius: _isPulsating ? 25 : 15,
            spreadRadius: _isPulsating ? 2 : 0,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        gradient: const LinearGradient(
          colors: [
            Color(0xFF86A8E7),
            Color(0xFF91EAE4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fondo de gradiente
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF86A8E7),
                    Color(0xFF91EAE4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Imagen de la mascota
            Padding(
              padding: const EdgeInsets.all(0),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/brainchat.png',
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            
            // Efecto de brillo
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.white.withOpacity(0.05),
                  ],
                ),
              ),
            ),
            
            // Badge de notificación
            if (_showMessage)
              Positioned(
                top: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF66B7D),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF66B7D).withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '!',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
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