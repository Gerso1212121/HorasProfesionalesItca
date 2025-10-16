import 'package:ai_app_tests/App/Backend/Auth/Admin/Admin_LibrosContent.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.library_books,
                size: 32,
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(width: 12),
              Text(
                'Gestión de Contenidos',
                style: GoogleFonts.itim(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Administra ejercicios, módulos educativos y biblioteca digital',
            style: GoogleFonts.itim(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF3B82F6),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF64748B),
              labelStyle: GoogleFonts.itim(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              unselectedLabelStyle: GoogleFonts.itim(
                fontWeight: FontWeight.normal,
                fontSize: 14,
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.fitness_center, size: 20),
                  text: 'Ejercicios',
                ),
                Tab(
                  icon: Icon(Icons.school, size: 20),
                  text: 'Módulos',
                ),
                Tab(
                  icon: Icon(Icons.menu_book, size: 20),
                  text: 'Libros',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Tab Content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBarView(
                controller: _tabController,
                children: const [
                  EjerciciosContent(),
                  ModulosContent(),
                  LibrosContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
