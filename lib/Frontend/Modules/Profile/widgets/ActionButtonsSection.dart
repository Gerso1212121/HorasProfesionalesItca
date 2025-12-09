import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:horas2/Frontend/Modules/Profile/ViewModels/ProfileVM.dart';

class ActionButtonsSection extends StatelessWidget {
  final ProfileVM vm;
  final bool esEstudianteItca;

  const ActionButtonsSection({
    super.key,
    required this.vm,
    required this.esEstudianteItca,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (esEstudianteItca)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: _ActionButton(
                text: 'Mis Citas',
                icon: LucideIcons.calendarClock,
                backgroundColor: const Color(0xFF86A8E7),
                textColor: Colors.white,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(LucideIcons.hammer,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text('Módulo en construcción'),
                        ],
                      ),
                      backgroundColor: Colors.grey[800],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ),
        Expanded(
          child: _ActionButton(
            text: 'Cerrar Sesión',
            icon: LucideIcons.logOut,
            backgroundColor: const Color(0xFFFFEEEE),
            textColor: const Color(0xFFFF6B6B),
            isDestructive: true,
            onTap: () => _showLogoutDialog(context, vm),
          ),
        ),
      ],
    );
  }

  Future<void> _showLogoutDialog(BuildContext context, ProfileVM vm) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Cerrar Sesión?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('¿Estás seguro de que deseas salir de tu cuenta?'),
        actionsPadding: const EdgeInsets.all(20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              vm.logout(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Cerrar Sesión',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.text,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: isDestructive
            ? []
            : [
                BoxShadow(
                  color: backgroundColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 10),
              Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontFamily: AppFonts.main,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}