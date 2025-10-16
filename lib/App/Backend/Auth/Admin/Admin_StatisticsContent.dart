import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../Data/DataBase/DatabaseHelper.dart';
import 'package:intl/intl.dart';

class StatisticsContent extends StatelessWidget {
  const StatisticsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const StatisticsView();
  }
}

class StatisticsView extends StatefulWidget {
  const StatisticsView({Key? key}) : super(key: key);

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // Filtros
  String? _selectedSede;
  String? _selectedCarrera;
  String? _selectedCiclo;
  String? _selectedEmocion;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;

  // Datos
  List<Map<String, dynamic>> _estadisticas = [];
  Map<String, dynamic> _resumenGeneral = {};
  bool _isLoading = true;

  // Opciones de filtros
  List<String> _sedes = [];
  List<String> _carreras = [];
  List<String> _ciclos = [];
  List<String> _emociones = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      await _loadFilterOptions();
      await _loadStatistics();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadFilterOptions() async {
    final data = await _dbHelper.getEmocionesFiltros();

    setState(() {
      _sedes = data['sedes'] ?? [];
      _carreras = data['carreras'] ?? [];
      _ciclos = data['ciclos'] ?? [];
      _emociones = data['emociones'] ?? [];
    });
  }

  Future<void> _loadStatistics() async {
    // Cargar estadísticas filtradas
    final estadisticas = await _dbHelper.getEmocionesEstadisticas(
      sede: _selectedSede,
      carrera: _selectedCarrera,
      ciclo: _selectedCiclo,
      emocion: _selectedEmocion,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
    );

    // Cargar resumen general
    final resumen = await _dbHelper.getResumenEmociones(
      sede: _selectedSede,
      carrera: _selectedCarrera,
      ciclo: _selectedCiclo,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
    );

    setState(() {
      _estadisticas = estadisticas;
      _resumenGeneral = resumen;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSede = null;
      _selectedCarrera = null;
      _selectedCiclo = null;
      _selectedEmocion = null;
      _fechaInicio = null;
      _fechaFin = null;
    });
    _loadStatistics();
  }

  Widget _buildStatsCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
            children: [
              Icon(icon, size: 32, color: color),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.itim(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.itim(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, VoidCallback onTap,
      {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: value != null
              ? (color ?? const Color(0xFF3B82F6))
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value ?? label,
              style: TextStyle(
                color: value != null ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.close,
                size: 16,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Filtros',
                  style: GoogleFonts.itim(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              children: [
                _buildFilterChip('Sede', _selectedSede, () async {
                  if (_selectedSede != null) {
                    setState(() => _selectedSede = null);
                    _loadStatistics();
                  } else {
                    _showSedeDialog();
                  }
                }),
                _buildFilterChip('Carrera', _selectedCarrera, () async {
                  if (_selectedCarrera != null) {
                    setState(() => _selectedCarrera = null);
                    _loadStatistics();
                  } else {
                    _showCarreraDialog();
                  }
                }),
                _buildFilterChip('Ciclo', _selectedCiclo, () async {
                  if (_selectedCiclo != null) {
                    setState(() => _selectedCiclo = null);
                    _loadStatistics();
                  } else {
                    _showCicloDialog();
                  }
                }),
                _buildFilterChip('Emoción', _selectedEmocion, () async {
                  if (_selectedEmocion != null) {
                    setState(() => _selectedEmocion = null);
                    _loadStatistics();
                  } else {
                    _showEmocionDialog();
                  }
                }, color: const Color(0xFF10B981)),
                _buildFilterChip(
                    'Fecha', _fechaInicio != null ? 'Personalizada' : null, () {
                  if (_fechaInicio != null || _fechaFin != null) {
                    setState(() {
                      _fechaInicio = null;
                      _fechaFin = null;
                    });
                    _loadStatistics();
                  } else {
                    _showDateRangeDialog();
                  }
                }, color: const Color(0xFFEF4444)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenCards() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.3,
      children: [
        _buildStatsCard(
          'Total Emociones',
          _resumenGeneral['total']?.toString() ?? '0',
          Icons.sentiment_satisfied_alt,
          const Color(0xFF3B82F6),
        ),
        _buildStatsCard(
          'Emociones Hoy',
          _resumenGeneral['hoy']?.toString() ?? '0',
          Icons.today,
          const Color(0xFF10B981),
        ),
        _buildStatsCard(
          'Esta Semana',
          _resumenGeneral['semana']?.toString() ?? '0',
          Icons.date_range,
          const Color(0xFFEF4444),
        ),
        _buildStatsCard(
          'Este Mes',
          _resumenGeneral['mes']?.toString() ?? '0',
          Icons.calendar_month,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildEmocionesChart() {
    if (_estadisticas.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No hay datos para mostrar',
              style: GoogleFonts.itim(fontSize: 16, color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalle de Emociones',
              style: GoogleFonts.itim(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _estadisticas.length,
              itemBuilder: (context, index) {
                final item = _estadisticas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getEmocionColor(item['emocion']),
                      child: Text(
                        _getEmocionEmoji(item['emocion']),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                    title: Text(
                      '${item['emocion']}',
                      style: GoogleFonts.itim(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Sede: ${item['sede']} • Carrera: ${item['carrera']}\n'
                      'Ciclo: ${item['ciclo']} • Fecha: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(item['fecha']))}',
                      style: GoogleFonts.itim(fontSize: 12),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item['cantidad']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getEmocionColor(String emocion) {
    switch (emocion.toLowerCase()) {
      case 'feliz':
      case 'alegre':
        return Colors.green;
      case 'triste':
      case 'deprimido':
        return Colors.blue;
      case 'enojado':
      case 'furioso':
        return Colors.red;
      case 'ansioso':
      case 'nervioso':
        return Colors.orange;
      case 'calmado':
      case 'relajado':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getEmocionEmoji(String emocion) {
    switch (emocion.toLowerCase()) {
      case 'feliz':
      case 'alegre':
        return '😊';
      case 'triste':
      case 'deprimido':
        return '😢';
      case 'enojado':
      case 'furioso':
        return '😠';
      case 'ansioso':
      case 'nervioso':
        return '😰';
      case 'calmado':
      case 'relajado':
        return '😌';
      default:
        return '😐';
    }
  }

  void _showSedeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Sede'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _sedes.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_sedes[index]),
                onTap: () {
                  setState(() => _selectedSede = _sedes[index]);
                  Navigator.pop(context);
                  _loadStatistics();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCarreraDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Carrera'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _carreras.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_carreras[index]),
                onTap: () {
                  setState(() => _selectedCarrera = _carreras[index]);
                  Navigator.pop(context);
                  _loadStatistics();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showCicloDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Ciclo'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _ciclos.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_ciclos[index]),
                onTap: () {
                  setState(() => _selectedCiclo = _ciclos[index]);
                  Navigator.pop(context);
                  _loadStatistics();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showEmocionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Emoción'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _emociones.length,
            itemBuilder: (context, index) {
              return ListTile(
                leading: Text(_getEmocionEmoji(_emociones[index]),
                    style: const TextStyle(fontSize: 24)),
                title: Text(_emociones[index]),
                onTap: () {
                  setState(() => _selectedEmocion = _emociones[index]);
                  Navigator.pop(context);
                  _loadStatistics();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showDateRangeDialog() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fechaInicio != null && _fechaFin != null
          ? DateTimeRange(start: _fechaInicio!, end: _fechaFin!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _fechaInicio = picked.start;
        _fechaFin = picked.end;
      });
      _loadStatistics();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Estadísticas y Reportes',
          style: GoogleFonts.itim(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildFiltersSection(),
                  _buildResumenCards(),
                  const SizedBox(height: 16),
                  _buildEmocionesChart(),
                ],
              ),
            ),
    );
  }
}
