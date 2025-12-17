import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import '../ViewModel/ExerciseViewModel.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  void initState() {
    super.initState();
    // Cargar datos apenas se abre la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ExerciseViewModel>(context, listen: false).loadProgressData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mi Progreso',
          style: GoogleFonts.itim(
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Consumer<ExerciseViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoadingProgress) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Título Sección
                Text(
                  'Resumen Global',
                  style: GoogleFonts.itim(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const SizedBox(height: 16),
                
                // 2. TARJETAS DE ESTADÍSTICAS (Con Datos Reales)
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        title: 'Minutos',
                        value: '${vm.stats['minutes']}',
                        icon: LucideIcons.clock,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Sesiones',
                        value: '${vm.stats['sessions']}',
                        icon: LucideIcons.checkCircle,
                        color: const Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _StatCard(
                        title: 'Racha',
                        value: '${vm.stats['streak']} días',
                        icon: LucideIcons.flame,
                        color: const Color(0xFFFB923C),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // 3. GRÁFICO DE BARRAS DINÁMICO
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actividad Semanal',
                        style: GoogleFonts.itim(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _Bar(label: 'L', heightPct: vm.weeklyData[1] ?? 0.0, isToday: DateTime.now().weekday == 1),
                          _Bar(label: 'M', heightPct: vm.weeklyData[2] ?? 0.0, isToday: DateTime.now().weekday == 2),
                          _Bar(label: 'X', heightPct: vm.weeklyData[3] ?? 0.0, isToday: DateTime.now().weekday == 3),
                          _Bar(label: 'J', heightPct: vm.weeklyData[4] ?? 0.0, isToday: DateTime.now().weekday == 4),
                          _Bar(label: 'V', heightPct: vm.weeklyData[5] ?? 0.0, isToday: DateTime.now().weekday == 5),
                          _Bar(label: 'S', heightPct: vm.weeklyData[6] ?? 0.0, isToday: DateTime.now().weekday == 6),
                          _Bar(label: 'D', heightPct: vm.weeklyData[7] ?? 0.0, isToday: DateTime.now().weekday == 7),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // 4. LISTA DE HISTORIAL (Con Datos Reales)
                Text(
                  'Historial Reciente',
                  style: GoogleFonts.itim(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey[800],
                  ),
                ),
                const SizedBox(height: 16),
                
                if (vm.recentHistory.isEmpty)
                   Center(
                     child: Padding(
                       padding: const EdgeInsets.all(20.0),
                       child: Text("Aún no tienes actividad registrada", style: GoogleFonts.itim(color: Colors.grey)),
                     ),
                   )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: vm.recentHistory.length > 10 ? 10 : vm.recentHistory.length, // Mostrar solo los últimos 10
                    itemBuilder: (context, index) {
                      final session = vm.recentHistory[index];
                      return _HistoryTile(
                        title: session.title,
                        category: session.category,
                        date: DateFormat('dd/MM - HH:mm').format(session.date),
                        duration: '${session.durationMinutes} min',
                      );
                    },
                  ),
                 const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---------------- WIDGETS AUXILIARES ----------------

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            textAlign: TextAlign.center,
            style: GoogleFonts.itim(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF1E293B)),
          ),
          Text(title, style: GoogleFonts.itim(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double heightPct; // 0.0 a 1.0
  final bool isToday;

  const _Bar({required this.label, required this.heightPct, required this.isToday});

  @override
  Widget build(BuildContext context) {
    // Altura mínima visual para que no desaparezca si es 0
    final double displayHeightPct = heightPct < 0.05 && heightPct > 0 ? 0.05 : heightPct;

    return Column(
      children: [
        Container(
          width: 12,
          height: 100, 
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500), // Animación suave
            curve: Curves.easeOut,
            height: 100 * displayHeightPct,
            width: 12,
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFFFF9800) : (heightPct > 0 ? const Color(0xFF38BDF8) : const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.itim(
            fontSize: 12,
            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            color: isToday ? Colors.orange : Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final String title;
  final String category;
  final String date;
  final String duration;

  const _HistoryTile({required this.title, required this.category, required this.date, required this.duration});

  @override
  Widget build(BuildContext context) {
    // Determinar color según categoría simple
    Color iconColor = Colors.orange;
    IconData iconData = LucideIcons.sparkles;
    
    if (category.toLowerCase().contains('ansiedad')) { iconColor = Colors.green; iconData = LucideIcons.leaf; }
    else if (category.toLowerCase().contains('respiración')) { iconColor = Colors.blue; iconData = LucideIcons.wind; }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(iconData, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.itim(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF1E293B))),
                Text('$category • $date', style: GoogleFonts.itim(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Text(duration, style: GoogleFonts.itim(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400])),
        ],
      ),
    );
  }
}