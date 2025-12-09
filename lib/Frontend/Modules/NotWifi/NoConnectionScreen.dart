// lib/Frontend/Modules/Connectivity/Screens/NoConnectionScreen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:horas2/Backend/Data/Services/Conecction/ConnectivityService.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';

class NoConnectionScreen extends StatefulWidget {
  final VoidCallback onRetry;
  final VoidCallback onExit;

  const NoConnectionScreen({
    super.key,
    required this.onRetry,
    required this.onExit,
  });

  @override
  State<NoConnectionScreen> createState() => _NoConnectionScreenState();
}

class _NoConnectionScreenState extends State<NoConnectionScreen> {
  bool _isChecking = false;
  bool _hasBasicConnectivity = false;

  @override
  void initState() {
    super.initState();
    _checkBasicConnectivity();
  }

  Future<void> _checkBasicConnectivity() async {
    try {
      final connectivity = Connectivity();
      final results = await connectivity.checkConnectivity();

      setState(() {
        _hasBasicConnectivity =
            results.any((result) => result != ConnectivityResult.none);
      });
    } catch (e) {
      print("Error al verificar conectividad: $e");
    }
  }

  Future<void> _handleRetry() async {
    setState(() => _isChecking = true);

    final hasRealInternet = await ConnectivityService.checkConnection();

    await _checkBasicConnectivity();

    setState(() => _isChecking = false);

    if (hasRealInternet) {
      widget.onRetry();
    } else {
      print('Sin conexión');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 70),

              // Ícono principal
              Icon(
                Icons.wifi_off_rounded,
                size: 90,
                color: Colors.redAccent,
              ),


              // Imagen
              Image.asset(
                'assets/images/brainsad.png',
                height: size.height * 0.35,
                fit: BoxFit.contain,
              ),


              // Título
              Text(
                _hasBasicConnectivity
                    ? "Sin conexión a internet"
                    : "Sin conexión",
                style: GoogleFonts.itim(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              // Subtítulo
              Text(
                _hasBasicConnectivity
                    ? "Tu dispositivo no tiene acceso a internet.\nIntenta nuevamente."
                    : "No encontramos redes disponibles.\nRevisa tus ajustes.",
                style: GoogleFonts.itim(
                  fontSize: 17,
                  color: Colors.grey[700],
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Botón reintentar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 4,
                  ),
                  child:Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasBasicConnectivity
                                  ? Icons.network_check
                                  : Icons.refresh_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _hasBasicConnectivity
                                  ? 'REINTENTAR'
                                  : 'REINTENTAR',
                              style: GoogleFonts.itim(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 15),

              // Botón salir
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: widget.onExit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(width: 2, color: Color(0xFFF66B7D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.exit_to_app_rounded,
                          color: Color(0xFFF66B7D)),
                      const SizedBox(width: 10),
                      Text(
                        'SALIR DE LA APP',
                        style: GoogleFonts.itim(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF66B7D),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
