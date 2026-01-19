import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Admin/Admin_CitasContent.dart';
import 'package:horas2/Admin/login.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as SupabaseAuth;

import 'Admin/Admin_DashboardContent.dart';
import 'Admin/Admin_StatisticsContent.dart';
import 'Admin/Admin_SettingsContent.dart';
 import 'Admin/Admin_ContentsContent.dart';
import 'Admin/Admin_AlertasContent.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Variables
  int _selectedIndex = 0; // Índice de la pantalla seleccionada
  String? adminEmail; // Email del administrador
  bool isLoading = true; // Indicador de carga

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  // Método para cargar los datos del administrador
  Future<void> _loadAdminData() async {
    try {
      final user = SupabaseAuth.Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          adminEmail = user.email;
          isLoading = false;
        });
      }
    } catch (e) {
       print('Error cargando datos de admin: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Método para manejar el cierre de sesión del administrador
  Future<void> _handleLogout() async {
    try {
      await SupabaseAuth.Supabase.instance.client.auth.signOut();
       print('Admin logout exitoso');

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminLoginScreen()),
        );
      }
    } catch (e) {
       print('Error en logout admin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cerrar sesión: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: Text(
          'Panel de Administración',
          style: GoogleFonts.itim(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Administrador',
                      style: GoogleFonts.itim(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      adminEmail ?? 'N/A',
                      style: GoogleFonts.itim(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(
                      'Cerrar Sesión',
                      style: GoogleFonts.itim(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Logo/Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Administrador',
                  style: GoogleFonts.itim(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Text(
                  adminEmail ?? 'N/A',
                  style: GoogleFonts.itim(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 30),
                // Menu Items
                Expanded(
                  child: ListView(
                    children: [
                      _buildSidebarItem(
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                        index: 0,
                      ),
                      _buildSidebarItem(
                        icon: Icons.calendar_today,
                        title: 'Citas',
                        index: 1,
                      ),
                      _buildSidebarItem(
                        icon: Icons.analytics,
                        title: 'Estadísticas',
                        index: 2,
                      ),
                      _buildSidebarItem(
                        icon: Icons.security,
                        title: 'Seguridad',
                        index: 3,
                      ),
                      _buildSidebarItem(
                        icon: Icons.library_books,
                        title: 'Contenidos',
                        index: 4,
                      ),
 
                      _buildSidebarItem(
                        icon: Icons.warning_amber_rounded,
                        title: 'Mensajes de Alerta',
                        index: 5,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  // Método para construir los elementos del sidebar
  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.grey[400],
        ),
        title: Text(
          title,
          style: GoogleFonts.itim(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  // Método para construir el contenido principal según la pantalla seleccionada
  Widget _buildMainContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardContent(); // Pantalla de Dashboard
      case 1:
        return const CitasDashboardMejorado(); // Pantalla de Citas
      case 2:
        return const StatisticsContent(); // Pantalla de Estadísticas
      case 3:
        return const SecurityContent(); // Pantalla de Configuración
      case 4:
        return const ContentsContent(); // Pantalla de Contenidos
      case 5:
        return const AlertasContent(); // Pantalla de Logs del Sistema
       default:
        return const DashboardContent(); // Por defecto, mostrar el Dashboard
    }
  }

  Widget _buildStatsCard(
      String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.itim(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.itim(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
