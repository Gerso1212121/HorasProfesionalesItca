import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatDrawerMenu extends StatelessWidget {
  final String nombreUsuario;
  final String? sedeEstudiante;
  final bool sessionActive;
  final bool hasMessages;
  final VoidCallback? onBackPressed;
  final VoidCallback onCloseDrawer;
  final VoidCallback onStartNewChat;
  final VoidCallback onEndChat;
  final VoidCallback onShowHistory;
  final VoidCallback onShowEmergencyContacts;
  final VoidCallback onGoToChat;

  const ChatDrawerMenu({
    super.key,
    required this.nombreUsuario,
    this.sedeEstudiante,
    required this.sessionActive,
    required this.hasMessages,
    this.onBackPressed,
    required this.onCloseDrawer,
    required this.onStartNewChat,
    required this.onEndChat,
    required this.onShowHistory,
    required this.onShowEmergencyContacts,
    required this.onGoToChat,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 280,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),

          // Opciones del menú
          _buildMenuOptions(),

          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.only(top: 60, bottom: 24, left: 24, right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Botón de retroceso (si existe)
              if (onBackPressed != null)
                _buildIconButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () {
                    onCloseDrawer();
                    onBackPressed?.call();
                  },
                )
              else
                const SizedBox(width: 48),

              // Título del menú
              Text(
                'Menú',
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 48),
            ],
          ),

          const SizedBox(height: 16),

          // Nombre del usuario
          Text(
            nombreUsuario,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 4),

          // Sede del estudiante
          Text(
            'Sede: ${sedeEstudiante ?? "No especificada"}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOptions() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Ir al chat
          _buildDrawerMenuItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Ir al Chat',
            onTap: () {
              onCloseDrawer();
              onGoToChat();
            },
          ),

          // Nuevo chat
          _buildDrawerMenuItem(
            icon: Icons.add_rounded,
            label: 'Nuevo Chat',
            onTap: () {
              onCloseDrawer();
              onStartNewChat();
            },
          ),

          // Historial
          _buildDrawerMenuItem(
            icon: Icons.history_rounded,
            label: 'Historial',
            onTap: () {
              onCloseDrawer();
              onShowHistory();
            },
          ),

          // Finalizar chat (solo si hay sesión activa con mensajes)
          if (sessionActive && hasMessages)
            _buildDrawerMenuItem(
              icon: Icons.stop_circle_rounded,
              label: 'Finalizar Chat',
              color: const Color(0xFFF66B7D),
              onTap: () {
                onCloseDrawer();
                onEndChat();
              },
            ),

          const Divider(height: 20, indent: 20, endIndent: 20),

          // Contactos de emergencia
          _buildDrawerMenuItem(
            icon: Icons.emergency_rounded,
            label: 'Contacto de Emergencia',
            color: const Color(0xFFFF5252),
            onTap: () {
              onCloseDrawer();
              onShowEmergencyContacts();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Asistente AI v1.0',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF888888),
            ),
          ),
          const Icon(
            Icons.favorite_rounded,
            color: Color(0xFFF66B7D),
            size: 14,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
      ),
    );
  }

  Widget _buildDrawerMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (color ?? const Color(0xFF86A8E7)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color ?? const Color(0xFF86A8E7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCCCCCC),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
