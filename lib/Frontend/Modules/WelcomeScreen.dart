import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Backend/Data/Services/Local/LocalStorageService.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  final LocalStorageService _storageService = LocalStorageService();
  bool _isSaving = false;

  Widget bubble(double size,
      {double? left, double? right, double? top, double? bottom}) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(242, 255, 255, 0.5),
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (_isSaving) return; // evita doble toque

    setState(() => _isSaving = true);

    // Cooldown de 1 segundo antes de permitir otro toque
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) setState(() => _isSaving = false);
    });

    try {
      await _storageService.setHasSeenWelcome(true);
      if (mounted) context.go('/login');
    } catch (e) {
      print('❌ Error guardando cache: $e');
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Transform.rotate(
                  angle: -4.9,
                  child: Container(
                    width: size.width * 1.9,
                    height: size.height * 0.80,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(800), //arriba Dercha SOLO ESTE 
                        bottomLeft: Radius.circular(200), //Arriba Izquierda
                        topRight: Radius.circular(200), //abajo Derecha
                        bottomRight: Radius.circular(900), //abajo Izquierda SOLO ESTE
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(242, 255, 255, 0.5),
                        borderRadius: BorderRadius.circular(35),
                      ),
                      child: Text(
                        '¡Hola! Soy Lotus\ny seré tu asistente personal\n¿Estás listo para comenzar?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 100),
                      child: SizedBox(
                        width: 130,
                        height: 40,
                        child: Stack(
                          children: [
                            bubble(14, left: 40, top: 0),
                            bubble(10, left: 55, top: 17),
                            bubble(8, left: 70, top: 28),
                          ],
                        ),
                      ),
                    ),
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 0, left: 90),
                          child: ClipRRect(
                            child: Image.asset(
                              'assets/images/brainwelcome.png',
                              height: size.height * 0.23,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            ElevatedButton(
              onPressed:
                  _isSaving ? null : _handleContinue, // Se desactiva 1 segundo
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF66B7D),
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 8,
                shadowColor: const Color.fromARGB(100, 246, 107, 125),
              ),
              child: Text(
                'Comenzar',
                style: GoogleFonts.itim(
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
