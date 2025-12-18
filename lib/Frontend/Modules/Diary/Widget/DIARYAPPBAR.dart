// lib/Frontend/Modules/Diary/Widgets/DiaryAppBar.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DiaryAppBar extends StatelessWidget {
  final VoidCallback? onCalendarTap;
  final VoidCallback? onProfileTap;
  final String? userName;
  final String? userAvatar;

  const DiaryAppBar({
    super.key,
    this.onCalendarTap,
    this.onProfileTap,
    this.userName,
    this.userAvatar,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      expandedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF4285F4).withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      title: Text(
        'Mi Diario',
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A237E),
          letterSpacing: -0.5,
        ),
      ),
      centerTitle: false,
      actions: [
        // Botón de calendario
        if (onCalendarTap != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                Icons.calendar_month_rounded,
                color: const Color(0xFF4285F4),
                size: 22,
              ),
              onPressed: onCalendarTap,
            ),
          ),

        // Avatar de usuario
        if (onProfileTap != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(22),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF4285F4),
                child: userAvatar != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(
                          userAvatar!,
                          fit: BoxFit.cover,
                          width: 44,
                          height: 44,
                        ),
                      )
                    : Text(
                        userName?.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}