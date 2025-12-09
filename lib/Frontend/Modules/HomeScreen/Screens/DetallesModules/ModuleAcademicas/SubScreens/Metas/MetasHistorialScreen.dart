import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:intl/intl.dart';

class MetasHistorialScreen extends StatefulWidget {
  final int idEstudiante;

  const MetasHistorialScreen({super.key, required this.idEstudiante});

  @override
  State<MetasHistorialScreen> createState() => _MetasHistorialScreenState();
}

class _MetasHistorialScreenState extends State<MetasHistorialScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Map<String, dynamic>> _metas = [];
  Map<String, dynamic> _estadisticas = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final metas = await _dbHelper.getMetasHistorial(widget.idEstudiante);
    final stats = await _dbHelper.getEstadisticasMetas(widget.idEstudiante);

    setState(() {
      _metas = metas;
      _estadisticas = stats;
      _isLoading = false;
    });
  }

  String _formatDateRange(String fechaInicio, String fechaFin) {
    final inicio = DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaInicio));
    final fin = DateFormat('dd/MM/yyyy').format(DateTime.parse(fechaFin));
    return '$inicio - $fin';
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'completada':
        return const Color(0xFF4CAF50);
      case 'activa':
        return const Color(0xFF2196F3);
      case 'cancelada':
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado) {
      case 'completada':
        return Icons.check_circle;
      case 'activa':
        return Icons.pending;
      case 'cancelada':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Future<void> _deleteMeta(int idMeta) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar meta', style: GoogleFonts.inter()),
        content: Text(
          '¿Estás seguro de eliminar esta meta? Esta acción no se puede deshacer.',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('Eliminar', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _dbHelper.deleteMetaSemanal(idMeta);
      _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meta eliminada', style: GoogleFonts.inter()),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  void _showMetaDetails(Map<String, dynamic> meta) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MetaDetailsSheet(
        meta: meta,
        dbHelper: _dbHelper,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      appBar: AppBar(
        title: Text(
          'Historial de Metas',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Estadísticas generales
                  _buildEstadisticas(),
                  const SizedBox(height: 24),

                  // Lista de metas
                  Text(
                    'Historial',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_metas.isEmpty)
                    _buildEmptyState()
                  else
                    ..._metas.map((meta) => _buildMetaCard(meta)),
                ],
              ),
            ),
    );
  }

  Widget _buildEstadisticas() {
    final totalMetas = _estadisticas['total_metas'] ?? 0;
    final metasCompletadas = _estadisticas['metas_completadas'] ?? 0;
    final porcentajeMetas = _estadisticas['porcentaje_metas'] ?? 0.0;
    final tareasCompletadas = _estadisticas['tareas_completadas'] ?? 0;
    final totalTareas = _estadisticas['total_tareas'] ?? 0;
    final porcentajeTareas = _estadisticas['porcentaje_tareas'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
            'Estadísticas',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Metas',
                  '$metasCompletadas/$totalMetas',
                  '${porcentajeMetas.toStringAsFixed(1)}%',
                  Icons.flag,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Tareas',
                  '$tareasCompletadas/$totalTareas',
                  '${porcentajeTareas.toStringAsFixed(1)}%',
                  Icons.task_alt,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String label, String value, String percentage, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Text(
            percentage,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay metas registradas',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Crea tu primera meta semanal',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCard(Map<String, dynamic> meta) {
    final estado = meta['estado'] as String;
    final fechaInicio = meta['fecha_inicio'] as String;
    final fechaFin = meta['fecha_fin'] as String;
    final especifica = meta['especifica'] as String;
    final resultado = meta['resultado'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getEstadoColor(estado).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showMetaDetails(meta),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con estado
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getEstadoColor(estado).withOpacity(0.2),
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
                          const SizedBox(width: 4),
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
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteMeta(meta['id_meta'] as int),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Fechas
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateRange(fechaInicio, fechaFin),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Meta específica
                Text(
                  especifica,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                if (resultado != null && resultado.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.assessment,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Resultado: $resultado',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Botón ver detalles
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Ver detalles',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF4CAF50),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Color(0xFF4CAF50),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar detalles completos de una meta
class _MetaDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> meta;
  final DatabaseHelper dbHelper;

  const _MetaDetailsSheet({
    required this.meta,
    required this.dbHelper,
  });

  @override
  State<_MetaDetailsSheet> createState() => _MetaDetailsSheetState();
}

class _MetaDetailsSheetState extends State<_MetaDetailsSheet> {
  List<Map<String, dynamic>> _tareas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTareas();
  }

  Future<void> _loadTareas() async {
    final tareas =
        await widget.dbHelper.getTareasPorMeta(widget.meta['id_meta']);
    setState(() {
      _tareas = tareas;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Contenido
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título
                        Text(
                          'Detalles de la Meta',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Meta SMART
                        _buildDetailSection('Meta SMART', [
                          _buildDetailItem(
                              'Específica', widget.meta['especifica']),
                          _buildDetailItem('Medible', widget.meta['medible']),
                          _buildDetailItem(
                              'Alcanzable', widget.meta['alcanzable']),
                          _buildDetailItem(
                              'Relevante', widget.meta['relevante']),
                          _buildDetailItem('Temporal', widget.meta['temporal']),
                        ]),

                        const SizedBox(height: 24),

                        // Tareas
                        _buildDetailSection(
                          'Tareas Semanales',
                          _tareas.map((t) => _buildTareaItem(t)).toList(),
                        ),

                        const SizedBox(height: 24),

                        // Evaluación
                        if (widget.meta['resultado'] != null)
                          _buildDetailSection('Evaluación', [
                            _buildDetailItem(
                                'Resultado', widget.meta['resultado']),
                            if (widget.meta['factores_ayuda'] != null)
                              _buildDetailItem('Factores de ayuda',
                                  widget.meta['factores_ayuda']),
                            if (widget.meta['mejoras'] != null)
                              _buildDetailItem(
                                  'Mejoras', widget.meta['mejoras']),
                            if (widget.meta['reflexion'] != null)
                              _buildDetailItem(
                                  'Reflexión', widget.meta['reflexion']),
                            if (widget.meta['frase_motivacional'] != null)
                              _buildDetailItem('Frase motivacional',
                                  widget.meta['frase_motivacional']),
                          ]),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTareaItem(Map<String, dynamic> tarea) {
    final completada = (tarea['completada'] as int) == 1;
    final mood = tarea['estado_emocional'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completada
            ? const Color(0xFF4CAF50).withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: completada ? const Color(0xFF4CAF50) : Colors.grey[300]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            completada ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completada ? const Color(0xFF4CAF50) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tarea['dia_semana'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
                if (tarea['actividad'] != null &&
                    (tarea['actividad'] as String).isNotEmpty)
                  Text(
                    tarea['actividad'] as String,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                if (tarea['hora'] != null &&
                    (tarea['hora'] as String).isNotEmpty)
                  Text(
                    'Hora: ${tarea['hora']}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
          if (mood != null && mood.isNotEmpty)
            Text(mood, style: const TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}
