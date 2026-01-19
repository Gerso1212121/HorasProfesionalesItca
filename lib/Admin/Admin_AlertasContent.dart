import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Backend/Data/sedealerta.dart';
import 'package:horas2/logs/Utils_ServiceLog.dart' as LegacyLog;
import 'package:supabase_flutter/supabase_flutter.dart';

class AlertasContent extends StatefulWidget {
  const AlertasContent({Key? key}) : super(key: key);

  @override
  State<AlertasContent> createState() => _AlertasContentState();
}

class _AlertasContentState extends State<AlertasContent> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Estados
  bool _loading = true;
  List<Map<String, dynamic>> _alertas = [];
  List<Map<String, dynamic>> _alertasFiltradas = [];
  String? _adminEmail;
  Map<String, dynamic> _estadisticas = {};
  String _filtroActual = 'total';

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        print('👤 Admin autenticado:');
        print('   - Email: ${user.email}');
        print('   - ID: ${user.id}');

        setState(() {
          _adminEmail = user.email;
        });

        await _loadAlertas();
        await _loadEstadisticas();
      } else {
        print('❌ No hay usuario autenticado');
      }
    } catch (e) {
      await LegacyLog.LogService.log('Error cargando datos de admin: $e');
    }
  }

  Future<void> _loadAlertas() async {
    if (_adminEmail == null) return;
    setState(() => _loading = true);

    try {
      final alertas = await SedeAlertService.getAlertasPorAdmin(_adminEmail!);
      setState(() {
        _alertas = alertas;
        _aplicarFiltro();
        _loading = false;
      });

      await LegacyLog.LogService.log(
          'Alertas cargadas para admin $_adminEmail: ${alertas.length}');
    } catch (e) {
      await LegacyLog.LogService.log('Error cargando alertas: $e');
      setState(() => _loading = false);
      _showErrorSnackBar('Error al cargar las alertas');
    }
  }

  Future<void> _loadEstadisticas() async {
    try {
      if (_adminEmail != null) {
        final stats =
            await SedeAlertService.getEstadisticasAlertasPorAdmin(_adminEmail!);
        setState(() {
          _estadisticas = stats;
        });
      }
    } catch (e) {
      await LegacyLog.LogService.log('Error cargando estadísticas: $e');
    }
  }

  Future<void> _recargarTodo() async {
    await _loadAlertas();
    await _loadEstadisticas();
  }

  void _filtrarPorEstado(String estado) {
    setState(() {
      _filtroActual = estado;
      _aplicarFiltro();
    });
  }

  void _aplicarFiltro() {
    switch (_filtroActual) {
      case 'pendientes':
        _alertasFiltradas =
            _alertas.where((alerta) => alerta['leida'] != true).toList();
        break;
      case 'leidas':
        _alertasFiltradas =
            _alertas.where((alerta) => alerta['leida'] == true).toList();
        break;
      case 'total':
      default:
        _alertasFiltradas = List.from(_alertas);
        break;
    }
  }

  Color _getColorFiltroActual() {
    switch (_filtroActual) {
      case 'pendientes':
        return Colors.orange;
      case 'leidas':
        return Colors.green;
      case 'total':
      default:
        return Colors.blue;
    }
  }

  IconData _getIconoFiltroActual() {
    switch (_filtroActual) {
      case 'pendientes':
        return Icons.pending;
      case 'leidas':
        return Icons.check_circle;
      case 'total':
      default:
        return Icons.warning;
    }
  }

  String _getTextoFiltroActual() {
    switch (_filtroActual) {
      case 'pendientes':
        return 'Pendientes';
      case 'leidas':
        return 'Leídas';
      case 'total':
      default:
        return 'Todas';
    }
  }

  Future<void> _marcarComoLeida(String alertaId) async {
    try {
      await SedeAlertService.marcarAlertaComoLeida(alertaId);
      await _recargarTodo(); // Recargar todo
      _showSuccessSnackBar('Alerta marcada como leída');
    } catch (e) {
      await LegacyLog.LogService.log('Error marcando alerta como leída: $e');
      _showErrorSnackBar('Error al marcar la alerta');
    }
  }

  Future<void> _desmarcarComoLeida(String alertaId) async {
    try {
      await SedeAlertService.desmarcarAlertaComoLeida(alertaId);
      await _recargarTodo(); // Recargar todo
      _showSuccessSnackBar('Alerta desmarcada como leída');
    } catch (e) {
      await LegacyLog.LogService.log('Error desmarcando alerta como leída: $e');
      _showErrorSnackBar('Error al desmarcar la alerta');
    }
  }

  Future<void> _eliminarAlerta(String alertaId) async {
    try {
      await SedeAlertService.eliminarAlerta(alertaId);
      await _recargarTodo(); // Recargar todo
      _showSuccessSnackBar('Alerta eliminada');
    } catch (e) {
      await LegacyLog.LogService.log('Error eliminando alerta: $e');
      _showErrorSnackBar('Error al eliminar la alerta');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Color _getColorPorTipo(String tipo) {
    switch (tipo) {
      case 'suicidio':
        return Colors.red;
      case 'violencia':
        return Colors.orange;
      case 'abuso_sexual':
        return Colors.purple;
      case 'depresion':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconoPorTipo(String tipo) {
    switch (tipo) {
      case 'suicidio':
        return Icons.warning;
      case 'violencia':
        return Icons.security;
      case 'abuso_sexual':
        return Icons.report_problem;
      case 'depresion':
        return Icons.psychology;
      default:
        return Icons.info;
    }
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      final ahora = DateTime.now();
      final diferencia = ahora.difference(dateTime);

      if (diferencia.inMinutes < 1) {
        return 'Hace un momento';
      } else if (diferencia.inMinutes < 60) {
        return 'Hace ${diferencia.inMinutes} minutos';
      } else if (diferencia.inHours < 24) {
        return 'Hace ${diferencia.inHours} horas';
      } else {
        return 'Hace ${diferencia.inDays} días';
      }
    } catch (e) {
      return fecha;
    }
  }

  Widget _buildActionButton(
      IconData icon, String tooltip, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF475569), // Color Pastel Oscuro (Slate)
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 20),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      ),
    );
  }

  Widget _buildStatusAction(Map<String, dynamic> alerta, bool isLeida) {
    return IconButton(
      onPressed: () => isLeida
          ? _desmarcarComoLeida(alerta['id'])
          : _marcarComoLeida(alerta['id']),
      icon: Icon(
        isLeida ? Icons.history : Icons.check_circle_outline,
        color: isLeida ? Colors.blueAccent : Colors.green,
        size: 22,
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
    );
  }

  Widget _buildMiniBadge(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.only(top: 2), // Pequeño respiro entre badges
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(
            0xFFF1F5F9), // Un gris azulado muy suave (Verde Menta opcional)
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min, // Para que no ocupe todo el ancho
        children: [
          Icon(
            icon,
            size: 14,
            color: const Color(0xFF64748B), // Color pastel oscuro
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF475569),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertasGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: _alertasFiltradas.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 3 Columnas
        crossAxisSpacing: 20, // Espacio horizontal
        mainAxisSpacing: 25, // Espacio vertical
        mainAxisExtent: 230, // Altura fija de cada tarjeta
      ),
      itemBuilder: (context, index) {
        final alerta = _alertasFiltradas[index];
        final isLeida = alerta['leida'] == true;
        final colorTipo = _getColorPorTipo(alerta['tipo_alerta']);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border(
              left: BorderSide(
                  color: isLeida ? Colors.grey[300]! : colorTipo, width: 6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _showAlertaDetails(alerta),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabecera de la Tarjeta (Icono + Botón Acción)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isLeida
                              ? Colors.grey[100]
                              : colorTipo.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getIconoPorTipo(alerta['tipo_alerta']),
                          color: isLeida ? Colors.grey[400] : colorTipo,
                          size: 20,
                        ),
                      ),
                      _buildStatusAction(alerta, isLeida),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Título/Resumen
                  Text(
                    alerta['resumen'] ?? 'Alerta sin resumen',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color:
                          isLeida ? Colors.grey[500] : const Color(0xFF0F172A),
                      decoration: isLeida ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const Spacer(),

                  // Badges de Usuario y Sede
                  _buildMiniBadge(
                      Icons.person_outline, alerta['usuario_nombre'] ?? 'N/A'),
                  const SizedBox(height: 4),
                  _buildMiniBadge(
                      Icons.business_outlined, alerta['sede'] ?? 'Sin sede'),

                  const SizedBox(height: 8),

                  // Fecha
                  Row(
                    children: [
                      Icon(Icons.access_time,
                          size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        _formatearFecha(alerta['fecha'] ?? ''),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ],
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
      backgroundColor: const Color(0xFFF1F5F9), // Un gris azulado más moderno
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (Se mantiene igual, pero con estilo Inter)
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 32, color: Colors.orange[700]),
                const SizedBox(width: 12),
                Text(
                  'Mensajes de Alerta',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                _buildActionButton(Icons.refresh, 'Actualizar', _recargarTodo),
              ],
            ),
            const SizedBox(height: 24),

            if (_estadisticas.isNotEmpty) ...[
              _buildEstadisticasCard(),
              const SizedBox(height: 24),
            ],

            // Grid de alertas en 3 columnas
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _alertasFiltradas.isEmpty
                      ? _buildEmptyState()
                      : _buildAlertasGrid(), // Llamamos al nuevo método Grid
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadisticasCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Resumen de Alertas por Sede',
                style: GoogleFonts.itim(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getColorFiltroActual().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _getColorFiltroActual().withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getIconoFiltroActual(),
                      size: 16,
                      color: _getColorFiltroActual(),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getTextoFiltroActual(),
                      style: GoogleFonts.itim(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getColorFiltroActual(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Estadísticas generales como botones - EN UNA SOLA LÍNEA
          Row(
            children: [
              _buildStatButton(
                'Total',
                '${_estadisticas['total_alertas'] ?? 0}',
                Colors.blue,
                Icons.warning,
                'total',
              ),
              _buildStatButton(
                'Pendientes',
                '${_estadisticas['alertas_pendientes'] ?? 0}',
                Colors.orange,
                Icons.pending,
                'pendientes',
              ),
              _buildStatButton(
                'Leídas',
                '${_estadisticas['alertas_leidas'] ?? 0}',
                Colors.green,
                Icons.check_circle,
                'leidas',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatButton(String label, String value, Color color,
      IconData icon, String filtroTipo) {
    final isActive = _filtroActual == filtroTipo;

    return Expanded(
      child: GestureDetector(
        onTap: () => _filtrarPorEstado(filtroTipo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? color : color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? color : color.withOpacity(0.2),
              width: isActive ? 2 : 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono y cantidad en la misma línea
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: isActive ? Colors.white : color,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: GoogleFonts.itim(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : color,
                    ),
                  ),
                ],
              ),
              // Texto abajo
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.itim(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final (icono, titulo, subtitulo, color) = _getEmptyStateInfo();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              icono,
              size: 64,
              color: color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            titulo,
            style: GoogleFonts.itim(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitulo,
            style: GoogleFonts.itim(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getColorFiltroActual().withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getColorFiltroActual().withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconoFiltroActual(),
                  size: 16,
                  color: _getColorFiltroActual(),
                ),
                const SizedBox(width: 8),
                Text(
                  'Filtro activo: ${_getTextoFiltroActual()}',
                  style: GoogleFonts.itim(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getColorFiltroActual(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, String, Color) _getEmptyStateInfo() {
    switch (_filtroActual) {
      case 'pendientes':
        return (
          Icons.check_circle_outline,
          '¡Excelente trabajo!',
          'No hay alertas pendientes por revisar',
          Colors.green
        );
      case 'leidas':
        return (
          Icons.history,
          'No hay alertas leídas',
          'Las alertas leídas aparecerán aquí',
          Colors.blue
        );
      case 'total':
      default:
        return (
          Icons.inbox_outlined,
          'No hay alertas',
          'Las alertas de tu sede aparecerán aquí',
          Colors.grey
        );
    }
  }

  void _showAlertaDetails(Map<String, dynamic> alerta) {
    final bool isLeida = alerta['leida'] == true;
    final Color colorTipo = _getColorPorTipo(alerta['tipo_alerta']);
    final Color pastelOscuro = const Color(0xFF475569);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorTipo.withOpacity(0.2), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con Icono y Título
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorTipo.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getIconoPorTipo(alerta['tipo_alerta']),
                        color: colorTipo, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detalles de Alerta',
                          style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E293B)),
                        ),
                        Text(
                          _formatearFecha(alerta['fecha'] ?? ''),
                          style: GoogleFonts.inter(
                              fontSize: 13, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 32),

              // Información en Grid/Columnas
              Wrap(
                runSpacing: 12,
                spacing: 24,
                children: [
                  _buildModernDetail(
                      'Sede', alerta['sede'] ?? 'N/A', Icons.business),
                  _buildModernDetail('Usuario',
                      alerta['usuario_nombre'] ?? 'N/A', Icons.person),
                  _buildModernDetail('Email', alerta['usuario_email'] ?? 'N/A',
                      Icons.alternate_email),
                  _buildModernDetail('Estado', isLeida ? 'Leída' : 'Pendiente',
                      Icons.info_outline,
                      valueColor: isLeida ? Colors.green : Colors.orange),
                ],
              ),
              const SizedBox(height: 24),

              // Caja de Mensaje (Estilo Menta/Pastel)
              Text(
                'Contenido del Mensaje',
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: pastelOscuro,
                    fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4), // Verde Menta muy suave
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD1FAE5)),
                ),
                child: Text(
                  alerta['mensaje_original'] ?? 'Sin mensaje',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF065F46),
                      height: 1.5),
                ),
              ),

              const SizedBox(height: 24),

              // Acciones (Botones Estilo Pastel)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Botón Eliminar
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _eliminarAlerta(alerta['id']);
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Eliminar'),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.red[400]),
                  ),
                  const Spacer(),
                  // Botón Acción Principal (Cambiar Estado)
                  _buildActionPill(
                    isLeida ? 'Marcar Pendiente' : 'Marcar Leída',
                    isLeida ? Colors.blue : Colors.orange,
                    () {
                      Navigator.pop(context);
                      isLeida
                          ? _desmarcarComoLeida(alerta['id'])
                          : _marcarComoLeida(alerta['id']);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

// Widget auxiliar para las filas de detalle modernas
  Widget _buildModernDetail(String label, String value, IconData icon,
      {Color? valueColor}) {
    return SizedBox(
      width: 200,
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[400]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500])),
                Text(
                  value,
                  style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? const Color(0xFF334155)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// Widget para el botón principal tipo "Pill"
  Widget _buildActionPill(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.itim(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.itim(),
            ),
          ),
        ],
      ),
    );
  }
}
