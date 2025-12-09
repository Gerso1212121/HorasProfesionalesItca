import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/widget/Skeleton/CalendarSkeleton.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CalendarWidget extends StatefulWidget {
  final DateTime selectedDay;
  final Function(DateTime selectedDay, DateTime focusedDay) onDaySelected;
  final VoidCallback onClose;

  const CalendarWidget({
    super.key,
    required this.selectedDay,
    required this.onDaySelected,
    required this.onClose,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedDay;
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = true;
  Set<DateTime> _eventDays = {};
  Set<DateTime> _metaRangeDays = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDay;
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final estudiante = await _dbHelper.getEstudiantePorUID(uid);
        final idEstudiante = estudiante?['id_estudiante'] as int?;

        // Cargar metas
        if (idEstudiante != null) {
          final metas = await _dbHelper.getMetasHistorial(idEstudiante);
          for (var meta in metas) {
            try {
              final fechaInicio = DateTime.parse(meta['fecha_inicio']);
              final fechaFin = DateTime.parse(meta['fecha_fin']);
              _metaRangeDays.addAll(_getDaysInRange(fechaInicio, fechaFin));
            } catch (e) {
              debugPrint('Error parseando meta: $e');
            }
          }
        }

        // Cargar citas
        final todasCitas = await _dbHelper.readAgendaCitasPorUid(estudianteUid: uid);
        for (var cita in todasCitas) {
          if (cita['confirmacion_cita'] == true || cita['confirmacion_cita'] == 1) {
            try {
              final fechaCita = DateTime.parse(cita['fecha_cita']);
              _eventDays.add(DateTime(fechaCita.year, fechaCita.month, fechaCita.day));
            } catch (e) {
              debugPrint('Error parseando cita: $e');
            }
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error cargando datos: $e');
      setState(() => _isLoading = false);
    }
  }

  Set<DateTime> _getDaysInRange(DateTime start, DateTime end) {
    final days = <DateTime>{};
    var current = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    
    while (current.isBefore(endDate) || current.isAtSameMomentAs(endDate)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    
    return days;
  }

Widget _buildDayCell(DateTime day, DateTime focusedDay) {
  final isSelected = isSameDay(day, widget.selectedDay);
  final isToday = isSameDay(day, DateTime.now());
  final hasEvent = _eventDays.contains(DateTime(day.year, day.month, day.day));
  final isInMetaRange = _metaRangeDays.contains(DateTime(day.year, day.month, day.day));

  return Container(
    margin: const EdgeInsets.all(4), // Aumentado de 2 a 4
    decoration: BoxDecoration(
      color: isSelected
          ? AppColors.primary
          : isToday
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
      shape: BoxShape.circle,
      border: isInMetaRange
          ? Border.all(color: AppColors.primaryLight.withOpacity(0.3), width: 1) // Aumentado de 10 a 12
          : null,
    ),
    child: Center(
      child: Container(
        width: 36, // Tamaño fijo para el área circular
        height: 36, // Tamaño fijo para el área circular
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${day.day}',
              style: GoogleFonts.inter(
                fontSize: 12, // Aumentado de 14 a 16
                fontWeight: isSelected || isToday ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? AppColors.primary
                        : Colors.grey[700],
              ),
            ),
            if (hasEvent)
              Positioned(
                bottom: 4, // Ajustado para la nueva proporción
                child: Container(
                  width: 6, // Aumentado de 4 a 6
                  height: 6, // Aumentado de 4 a 6
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: TableCalendar(
        firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
        lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(widget.selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() => _focusedDay = focusedDay);
          widget.onDaySelected(selectedDay, focusedDay);
        },
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: Colors.grey[700],
            size: 24,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: Colors.grey[700],
            size: 24,
          ),
          titleTextStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
          headerPadding: const EdgeInsets.only(bottom: 12),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          selectedDecoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          defaultTextStyle: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[700],
          ),
          weekendTextStyle: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[700],
          ),
          outsideTextStyle: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[400],
          ),
          cellPadding: EdgeInsets.zero,
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
          weekendStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        calendarBuilders: CalendarBuilders(
          defaultBuilder: (context, day, focusedDay) => _buildDayCell(day, focusedDay),
          todayBuilder: (context, day, focusedDay) => _buildDayCell(day, focusedDay),
          selectedBuilder: (context, day, focusedDay) => _buildDayCell(day, focusedDay),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildLegendItem(
            color: AppColors.primary,
            label: 'Seleccionado',
          ),
          _buildLegendItem(
            color: AppColors.success,
            label: 'Evento',
            isSmall: true,
          ),
          _buildLegendItem(
            color: AppColors.primaryLight,
            label: 'Meta activa',
            hasBorder: true,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    bool isSmall = false,
    bool hasBorder = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmall ? 16 : 20,
          height: isSmall ? 16 : 20,
          decoration: BoxDecoration(
            color: hasBorder ? Colors.transparent : color,
            shape: isSmall ? BoxShape.circle : BoxShape.circle,
            border: hasBorder
                ? Border.all(color: color.withOpacity(0.3), width: 1.5)
                : null,
          ),
          child: isSmall
              ? Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          if (_isLoading)
            const CalendarSkeleton()
          else ...[
            _buildCalendar(),
            const SizedBox(height: 16),
            _buildLegend(),
          ],
        ],
      ),
    );
  }
}