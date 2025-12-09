import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ProfileInfoCard extends StatelessWidget {
  final Map<String, dynamic> usuario;

  const ProfileInfoCard({super.key, required this.usuario});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      // Un poco más de padding vertical para que respire
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        // Sombra mucho más sutil, casi imperceptible, para un look limpio
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Se eliminó el título "Información Personal" interno para mayor sobriedad

          _buildInfoItem(
            icon: LucideIcons.user,
            label: 'Nombre Completo',
            value: '${usuario['nombre']} ${usuario['apellido'] ?? ''}',
            color: const Color(0xFF4CAF50), // Verde
          ),
          _buildInfoItem(
            icon: LucideIcons.mail,
            label: 'Correo Institucional',
            value: usuario['correo'] ?? 'Sin correo',
            color: const Color(0xFF2196F3), // Azul
          ),
          _buildInfoItem(
            icon: LucideIcons.phone,
            label: 'Teléfono',
            value: usuario['telefono'] ?? 'Sin teléfono',
            color: const Color(0xFF9C27B0), // Púrpura
          ),

          if (usuario.containsKey('sede') && usuario['sede'] != null)
            _buildInfoItem(
              icon: LucideIcons.building,
              label: 'Sede',
              value: usuario['sede'],
              color: const Color(0xFF607D8B), // Gris azulado
            ),

          if (usuario.containsKey('carrera') && usuario['carrera'] != null)
            _buildInfoItem(
              icon: LucideIcons.graduationCap,
              label: 'Carrera',
              value: usuario['carrera'],
              color: const Color(0xFFFF9800), // Naranja
              isLast: true,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isLast = false,
  }) {
    return Padding(
      // Separación vertical entre elementos
      padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono LIMPIO, sin contenedor de fondo
          Padding(
            padding: const EdgeInsets.only(top: 2), // Pequeño ajuste óptico
            child: Icon(
              icon,
              color: color.withOpacity(0.8), // Color un poco más suave
              size: 24,
            ),
          ),
          const SizedBox(width: 20), // Más espacio entre icono y texto

          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.itim(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500], // Etiqueta gris suave
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                      style: GoogleFonts.itim(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[900], // Valor oscuro y claro
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
