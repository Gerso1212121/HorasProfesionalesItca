import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
/*----------|FIREBASE|----------*/
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
/*----------|SUPABASE|----------*/
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardContent extends StatelessWidget {
  const DashboardContent({Key? key}) : super(key: key);

  // Función para contar el número de estudiantes en Firestore
  Future<int> contarEstudiantes() async {
    print('Contando estudiantes en Firestore...');
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('estudiantes').get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  Future<int> sessionesHoy(DateTime fecha) async {
    print('Contando sesiones de hoy: $fecha');
    final supabase = Supabase.instance.client;

    final response = await supabase.rpc('contar_sesiones_hoy', params: {
      'fecha_input': fecha.toIso8601String().split('T')[0],
    });

    print('Response: $response');

    return response ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard General',
            style: GoogleFonts.itim(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: FutureBuilder<int>(
                  future: contarEstudiantes(),
                  builder: (context, snapshot) {
                    String value = snapshot.connectionState ==
                            ConnectionState.waiting
                        ? '...'
                        : (snapshot.hasData ? snapshot.data.toString() : '0');
                    return StatCard(
                      title: 'Usuarios Totales',
                      value: value,
                      icon: Icons.people,
                      color: const Color(0xFF3B82F6),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: StatCard(
                  title: 'Usuarios Activos',
                  value: '0',
                  icon: Icons.person_outline,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FutureBuilder<int>(
                  future: sessionesHoy(DateTime.now()),
                  builder: (context, snapshot) {
                    String value = snapshot.connectionState ==
                            ConnectionState.waiting
                        ? '...'
                        : (snapshot.hasData ? snapshot.data.toString() : '0');
                    return StatCard(
                      title: 'Sesiones Hoy',
                      value: value,
                      icon: Icons.login,
                      color: const Color(0xFFF59E0B),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actividad Reciente',
                  style: GoogleFonts.itim(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                const ActivityItem(
                  icon: Icons.login,
                  title: 'Inicio de sesión de administrador',
                  subtitle: 'Hace unos momentos',
                  color: Color(0xFF10B981),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                value,
                style: GoogleFonts.itim(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.itim(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// Este es el widget (clase) que encapsula tu lógica
class ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const ActivityItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.itim(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.itim(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
