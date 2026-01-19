import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Admin/Admin_LibrosContent.dart';
import 'Admin_EjerciciosContent.dart';
import 'Admin_ModulosContent.dart';

class ContentsContent extends StatefulWidget {
  const ContentsContent({super.key});

  @override
  State<ContentsContent> createState() => _ContentsContentState();
}

class _ContentsContentState extends State<ContentsContent>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  // Colores definidos según tu solicitud
  final Color _azulPrincipal = const Color(0xFF2563EB); 
  final Color _verdeMentaFondo = const Color(0xFFF0FDF4); // Menta muy suave para el fondo
  final Color _pastelOscuro = const Color(0xFF475569); // Slate oscuro para botones/texto secundario

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _verdeMentaFondo, // Fondo sutil verde menta
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _azulPrincipal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.library_books, size: 36, color: _azulPrincipal),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Contenidos',
                      style: GoogleFonts.inter( // Cambio a Inter para mayor legibilidad
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Administra ejercicios, módulos educativos y biblioteca digital',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        color: _pastelOscuro,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // --- TAB BAR ESTILO PILL ---
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: _azulPrincipal,
                  boxShadow: [
                    BoxShadow(
                      color: _azulPrincipal.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: _pastelOscuro,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                unselectedLabelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(
                    height: 45,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fitness_center, size: 18),
                        SizedBox(width: 8),
                        Text('Ejercicios'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 45,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school, size: 18),
                        SizedBox(width: 8),
                        Text('Módulos'),
                      ],
                    ),
                  ),
                  Tab(
                    height: 45,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book, size: 18),
                        SizedBox(width: 8),
                        Text('Libros'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- TAB CONTENT (Tus interfaces integradas) ---
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: TabBarView(
                    controller: _tabController,
                    children: const [
                      EjerciciosContent(), // Se mantienen tus interfaces
                      ModulosContent(),
                      LibrosContent(),
                    ],
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