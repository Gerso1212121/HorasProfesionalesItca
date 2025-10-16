import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../App/Data/DataBase/DatabaseHelper.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../Widgets/AgendarCitaWidget.dart';

class CitasScreen extends StatefulWidget {
  const CitasScreen({super.key});

  @override
  State<CitasScreen> createState() => _CitasScreenState();
}

class _CitasScreenState extends State<CitasScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  List<Map<String, dynamic>> _citas = [];
  bool _isLoading = true;
  String? _nombreEstudiante;
  String _filtroEstado = 'todas'; // todas, programada, completada, cancelada

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadCitas();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadCitas() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Obtener información del estudiante (nombre)
        final estudiante =
            await DatabaseHelper.instance.getEstudiantePorUID(user.uid);
        _nombreEstudiante = estudiante?['nombre'] ?? 'Usuario';

        print('Cargando citas para el usuario: ${user.uid}');

        // Traer citas directamente desde Supabase (RPC segura)
        final citasEstudiante =
            await DatabaseHelper.instance.readAgendaCitasPorUid(
          estudianteUid: user.uid,
        );

        print(
            'Se recargaron las citas para el usuario: ${user.uid} y se encontraron ${citasEstudiante.length} citas.');

        // Actualizar estado y lista de citas
        if (mounted) {
          setState(() {
            _citas = citasEstudiante;
            _isLoading = false;
          });

          _animationController.forward();
        }
      } else {
        print('Usuario no autenticado');
        setState(() => _isLoading = false);
      }
    } catch (e, stack) {
      print('Error cargando citas: $e');
      print(stack);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al cargar las citas',
              style: GoogleFonts.inter(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _citasFiltradas {
    if (_filtroEstado == 'todas') {
      return _citas;
    }
    return _citas
        .where((cita) => cita['estado_cita'] == _filtroEstado)
        .toList();
  }

  String _formatFecha(String fechaStr) {
    try {
      final fecha = DateTime.parse(fechaStr);
      return DateFormat('dd MMM yyyy, HH:mm', 'es').format(fecha);
    } catch (e) {
      return fechaStr;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'programada':
        return const Color(0xFF2196F3);
      case 'completada':
        return const Color(0xFF4CAF50);
      case 'cancelada':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'programada':
        return LucideIcons.clock;
      case 'completada':
        return LucideIcons.checkCircle;
      case 'cancelada':
        return LucideIcons.xCircle;
      default:
        return LucideIcons.calendar;
    }
  }

  Widget _buildFiltroChip(String valor, String etiqueta) {
    final isSelected = _filtroEstado == valor;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(
          etiqueta,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.black54,
          ),
        ),
        onSelected: (selected) {
          setState(() {
            _filtroEstado = valor;
          });
        },
        selectedColor: const Color(0xFF86A8E7),
        checkmarkColor: Colors.white,
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildCitaCard(Map<String, dynamic> cita, int index) {
    final estado = cita['estado_cita'] ?? 'programada';
    final fechaCita = cita['fecha_cita'] ?? '';
    final motivo = cita['motivo_cita'] ?? 'Sin motivo especificado';
    final notas = cita['notas_adicionales'] ?? '';
    final confirmacion = (cita['confirmacion_cita']) == 1;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animationValue = Curves.easeOut.transform(
          (_animationController.value - (index * 0.1)).clamp(0.0, 1.0),
        );

        return Transform.translate(
          offset: Offset(0, 50 * (1 - animationValue)),
          child: Opacity(
            opacity: animationValue,
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: _getEstadoColor(estado).withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con estado y fecha
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getEstadoColor(estado).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getEstadoIcon(estado),
                                size: 16,
                                color: _getEstadoColor(estado),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                estado.toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _getEstadoColor(estado),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (confirmacion)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.check,
                              size: 16,
                              color: Color(0xFF4CAF50),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Fecha y hora
                    Row(
                      children: [
                        Icon(
                          LucideIcons.calendar,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatFecha(fechaCita),
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Motivo
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.messageSquare,
                          size: 20,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            motivo,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Notas adicionales (si existen)
                    if (notas.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LucideIcons.fileText,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              notas,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: Column(
        children: [
          // Header con gradiente
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 20),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        LucideIcons.arrowLeft,
                        color: Colors.black87,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mis Citas',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loadCitas,
                      icon: const Icon(
                        LucideIcons.refreshCw,
                        color: Colors.black87,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                if (_nombreEstudiante != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Estudiante: $_nombreEstudiante',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Filtros
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtrar por estado:',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFiltroChip('todas', 'Todas'),
                      _buildFiltroChip('programada', 'Programadas'),
                      _buildFiltroChip('completada', 'Completadas'),
                      _buildFiltroChip('cancelada', 'Canceladas'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de citas
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFF86A8E7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Cargando citas...',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  )
                : _citasFiltradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _filtroEstado == 'todas'
                                  ? 'No tienes citas programadas'
                                  : 'No hay citas con el estado seleccionado',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Las citas aparecerán aquí cuando sean programadas por el personal de bienestar.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _citasFiltradas.length,
                        itemBuilder: (context, index) {
                          return _buildCitaCard(_citasFiltradas[index], index);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: AgendarCitaWidget(),
              );
            },
          );
        },
        child: const Icon(LucideIcons.plus),
        backgroundColor: const Color(0xFF86A8E7),
        tooltip: 'Agendar nueva cita',
      ),
    );
  }
}
