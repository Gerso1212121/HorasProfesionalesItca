import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/DB/DatabaseHelper.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class StatisticsContent extends StatelessWidget {
  const StatisticsContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const StatisticsView();
}

class StatisticsView extends StatefulWidget {
  const StatisticsView({Key? key}) : super(key: key);

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  bool _isLoading = true;
  String? _selectedSede, _selectedCarrera, _selectedCiclo, _selectedEmocion;
  DateTime? _fechaInicio, _fechaFin;
  List<Map<String, dynamic>> _estadisticas = [];
  List<Map<String, dynamic>> _emocionesAgrupadas = [];
  Map<String, dynamic> _resumenGeneral = {};
  List<String> _sedes = [], _carreras = [], _ciclos = [], _emociones = [];

  final Color _primaryColor = Color(0xFFFF6B8B);
  final Color _secondaryColor = Color(0xFF4ECDC4);
  final Color _surfaceColor = Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Map<String, Color> _emocionColors = {
    'Feliz': Color(0xFFFFD166), 'Alegre': Color(0xFFFFB347),
    'Triste': Color(0xFF6A8EAE), 'Deprimido': Color(0xFF2D5D7B),
    'Enojado': Color(0xFFFF6B6B), 'Furioso': Color(0xFFC44536),
    'Ansioso': Color(0xFFFF9F68), 'Nervioso': Color(0xFFFF7B54),
    'Calmado': Color(0xFF4ECDC4), 'Relajado': Color(0xFF45B7AA),
  };

  bool get _isDesktop => MediaQuery.of(context).size.width >= 1024;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final data = await _dbHelper.getEmocionesFiltros();
      final estadisticas = await _dbHelper.getEmocionesEstadisticas(
        sede: _selectedSede, carrera: _selectedCarrera,
        ciclo: _selectedCiclo, emocion: _selectedEmocion,
        fechaInicio: _fechaInicio, fechaFin: _fechaFin,
      );
      final resumen = await _dbHelper.getResumenEmociones(
        sede: _selectedSede, carrera: _selectedCarrera,
        ciclo: _selectedCiclo, fechaInicio: _fechaInicio, fechaFin: _fechaFin,
      );
      if (mounted) {
        setState(() {
          _sedes = data['sedes'] ?? []; _carreras = data['carreras'] ?? [];
          _ciclos = data['ciclos'] ?? []; _emociones = data['emociones'] ?? [];
          _estadisticas = estadisticas; _resumenGeneral = resumen;
          _emocionesAgrupadas = _agruparEmociones(estadisticas);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _agruparEmociones(List<Map<String, dynamic>> datos) {
    final Map<String, Map<String, dynamic>> agrupados = {};
    for (var item in datos) {
      final emocion = item['emocion'];
      final cantidad = int.tryParse(item['cantidad'].toString()) ?? 0;
      if (agrupados.containsKey(emocion)) {
        agrupados[emocion]!['cantidad'] += cantidad;
      } else {
        agrupados[emocion] = {'emocion': emocion, 'cantidad': cantidad, 'porcentaje': 0.0};
      }
    }
    final total = agrupados.values.fold<int>(0, (sum, item) => sum + (item['cantidad'] as int));
    agrupados.forEach((key, value) {
      value['porcentaje'] = total > 0 ? (value['cantidad'] / total * 100) : 0;
    });
    return agrupados.values.toList()..sort((a, b) => b['cantidad'].compareTo(a['cantidad']));
  }

  void _clearFilters() {
    setState(() {
      _selectedSede = null; _selectedCarrera = null;
      _selectedCiclo = null; _selectedEmocion = null;
      _fechaInicio = null; _fechaFin = null;
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: _isLoading ? _buildLoading() : _isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      floatingActionButton: !_isDesktop && (_selectedSede != null || _selectedCarrera != null || 
          _selectedCiclo != null || _selectedEmocion != null || _fechaInicio != null)
          ? FloatingActionButton.extended(
              onPressed: _clearFilters,
              backgroundColor: _primaryColor,
              icon: Icon(Icons.filter_alt_off_outlined),
              label: Text('Limpiar Filtros'),
            ) : null,
    );
  }

  Widget _buildLoading() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: _primaryColor, strokeWidth: 3),
        SizedBox(height: 24),
        Text('Cargando estadísticas...', style: GoogleFonts.inter(fontSize: 18, color: Colors.grey[600])),
      ],
    ),
  );

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummarySection(),
                SizedBox(height: 32),
                _buildFiltersSection(),
                SizedBox(height: 32),
                _buildEmotionsDetail(),
                SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: _surfaceColor,
          expandedHeight: 160,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(gradient: LinearGradient(colors: [
                _primaryColor.withOpacity(0.9), _secondaryColor.withOpacity(0.7)])),
              child: Padding(
                padding: EdgeInsets.only(bottom: 20, left: 24, right: 24),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard de Estadísticas', style: GoogleFonts.inter(
                        fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                      SizedBox(height: 8),
                      Text('Análisis detallado del estado emocional', style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.white.withOpacity(0.9))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [IconButton(onPressed: _loadData, icon: Icon(Icons.refresh, color: Colors.white))],
        ),
        SliverList(
          delegate: SliverChildListDelegate([
            SizedBox(height: 32),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildSummarySection(),
                  SizedBox(height: 32),
                  _buildFiltersSection(),
                  SizedBox(height: 32),
                  _buildEmotionsDetail(),
                  SizedBox(height: 48),
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 180,
      decoration: BoxDecoration(gradient: LinearGradient(colors: [
        _primaryColor.withOpacity(0.9), _secondaryColor.withOpacity(0.7)])),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('Dashboard de Estadísticas', style: GoogleFonts.inter(
                    fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                  SizedBox(height: 8),
                  Text('Análisis detallado del estado emocional', style: GoogleFonts.inter(
                    fontSize: 18, color: Colors.white.withOpacity(0.9))),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(onPressed: _loadData, icon: Icon(Icons.refresh, color: Colors.white, size: 28)),
                SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: Icon(Icons.filter_alt_off, size: 20),
                  label: Text('Limpiar Filtros'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, foregroundColor: _primaryColor,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: _primaryColor, size: 28),
              SizedBox(width: 16),
              Text('Resumen General', style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF212529))),
              Spacer(),
              if (_isDesktop) Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: _surfaceColor, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE9ECEF))),
                child: Row(children: [
                  Icon(Icons.info_outline, size: 18, color: Colors.grey[600]),
                  SizedBox(width: 8),
                  Text('${_estadisticas.length} registros', style: GoogleFonts.inter(
                    fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                ]),
              ),
            ],
          ),
          SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
            crossAxisCount: _isDesktop ? 4 : 2, crossAxisSpacing: 20, mainAxisSpacing: 20,
            children: [
              _buildMetricCard('Total', _resumenGeneral['total']?.toString() ?? '0', 'Emociones totales', 
                Icons.assessment_outlined, _primaryColor),
              _buildMetricCard('Hoy', _resumenGeneral['hoy']?.toString() ?? '0', 'Registros de hoy', 
                Icons.today_outlined, _secondaryColor),
              _buildMetricCard('Semana', _resumenGeneral['semana']?.toString() ?? '0', 'Últimos 7 días', 
                Icons.date_range_outlined, Color(0xFF87CEEB)),
              _buildMetricCard('Mes', _resumenGeneral['mes']?.toString() ?? '0', 'Registros del mes', 
                Icons.calendar_month_outlined, Color(0xFF2E8B57)),
            ],
          ),
          SizedBox(height: 32),
          if (_emocionesAgrupadas.isNotEmpty) ...[
            Divider(color: Color(0xFFE9ECEF), height: 1),
            SizedBox(height: 24),
            _isDesktop ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 2, child: _buildChartSection()),
                SizedBox(width: 32),
                Expanded(flex: 3, child: _buildDistributionSection()),
              ],
            ) : Column(children: [
              _buildChartSection(),
              SizedBox(height: 24),
              _buildDistributionSection(),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24)),
            Spacer(),
            Text(value, style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, color: color, height: 1)),
          ]),
          SizedBox(height: 16),
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF212529))),
          SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF212529).withOpacity(0.6))),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE9ECEF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribución por Emoción', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF212529))),
          SizedBox(height: 16),
          Container(
            height: _isDesktop ? 300 : 250,
            child: SfCircularChart(
              tooltipBehavior: TooltipBehavior(enable: true),
              series: <PieSeries<Map<String, dynamic>, String>>[
                PieSeries(
                  dataSource: _emocionesAgrupadas,
                  xValueMapper: (data, _) => data['emocion'],
                  yValueMapper: (data, _) => data['cantidad'],
                  pointColorMapper: (data, _) => _emocionColors[data['emocion']] ?? _primaryColor,
                  dataLabelSettings: DataLabelSettings(isVisible: true, labelPosition: ChartDataLabelPosition.outside),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSection() {
    final total = _emocionesAgrupadas.fold<int>(0, (sum, item) => sum + item['cantidad'] as int);
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceColor, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE9ECEF))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Detalle de Distribución', style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF212529))),
            Spacer(),
            Text('Total: $total', style: GoogleFonts.inter(
              fontSize: 14, fontWeight: FontWeight.w600, color: _primaryColor)),
          ]),
          SizedBox(height: 16),
          ..._emocionesAgrupadas.map((item) {
            final percentage = item['porcentaje'];
            final color = _emocionColors[item['emocion']] ?? _primaryColor;
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(_getEmocionEmoji(item['emocion']), style: TextStyle(fontSize: 20)))),
                SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(item['emocion'], style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212529))),
                    Text('${item['cantidad']} (${percentage.toStringAsFixed(1)}%)', style: GoogleFonts.inter(
                      fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                  ]),
                  SizedBox(height: 8),
                  Container(height: 8, width: double.infinity, decoration: BoxDecoration(
                    color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                    child: FractionallySizedBox(widthFactor: percentage / 100,
                      child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))))),
                ])),
              ]),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardColor, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: Offset(0, 8))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.filter_alt_outlined, color: _primaryColor, size: 28),
            SizedBox(width: 16),
            Text('Filtros Avanzados', style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF212529))),
            Spacer(),
            if (_isDesktop) ElevatedButton.icon(
              onPressed: _clearFilters, icon: Icon(Icons.clear_all, size: 20), label: Text('Limpiar Todo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _surfaceColor, foregroundColor: Color(0xFF212529),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Color(0xFFE9ECEF))),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
            ),
          ]),
          SizedBox(height: 24),
          _isDesktop ? GridView.count(
            shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 3, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 4,
            children: [
              _buildFilterBox('Sede', _selectedSede, Icons.location_city_outlined, _primaryColor, _sedes),
              _buildFilterBox('Carrera', _selectedCarrera, Icons.school_outlined, _secondaryColor, _carreras),
              _buildFilterBox('Ciclo', _selectedCiclo, Icons.loop_outlined, Color(0xFF87CEEB), _ciclos),
            ],
          ) : Wrap(spacing: 12, runSpacing: 12, children: [
            _buildFilterChip('Sede', _selectedSede, Icons.location_city_outlined, _primaryColor, _sedes),
            _buildFilterChip('Carrera', _selectedCarrera, Icons.school_outlined, _secondaryColor, _carreras),
            _buildFilterChip('Ciclo', _selectedCiclo, Icons.loop_outlined, Color(0xFF87CEEB), _ciclos),
          ]),
          SizedBox(height: 20),
          Row(children: [
            Expanded(child: _isDesktop ? _buildFilterBox('Emoción', _selectedEmocion, 
              Icons.emoji_emotions_outlined, Color(0xFFFFB347), _emociones, showEmojis: true) 
              : _buildFilterChip('Emoción', _selectedEmocion, Icons.emoji_emotions_outlined, 
                Color(0xFFFFB347), _emociones, showEmojis: true)),
            SizedBox(width: 20),
            Expanded(child: _buildDateFilter()),
          ]),
        ],
      ),
    );
  }

  Widget _buildFilterBox(String label, String? value, IconData icon, Color color, List<String> options, 
      {bool showEmojis = false}) {
    return GestureDetector(
      onTap: () => _showFilterDialog(label, options, showEmojis: showEmojis),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value != null ? color : _surfaceColor, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value != null ? color : Color(0xFFE9ECEF), width: 2)),
        child: Row(children: [
          Icon(icon, size: 24, color: value != null ? Colors.white : color),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
              color: value != null ? Colors.white : Colors.grey[600])),
            SizedBox(height: 4),
            Text(value ?? 'Seleccionar', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600,
              color: value != null ? Colors.white : Color(0xFF212529)), overflow: TextOverflow.ellipsis),
          ])),
          if (value != null) Icon(Icons.check_circle, size: 20, color: Colors.white),
        ]),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, IconData icon, Color color, List<String> options,
      {bool showEmojis = false}) {
    return GestureDetector(
      onTap: () => _showFilterDialog(label, options, showEmojis: showEmojis),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: value != null ? color : Colors.transparent, borderRadius: BorderRadius.circular(25),
          border: Border.all(color: value != null ? color : Colors.grey[300]!, width: 1.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: value != null ? Colors.white : color),
          SizedBox(width: 10),
          Text(value ?? label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600,
            color: value != null ? Colors.white : Color(0xFF212529))),
        ]),
      ),
    );
  }

  Widget _buildDateFilter() {
    return GestureDetector(
      onTap: _showDateRangePicker,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _fechaInicio != null ? Color(0xFF6A8EAE) : _surfaceColor, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _fechaInicio != null ? Color(0xFF6A8EAE) : Color(0xFFE9ECEF), width: 2)),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined, size: 24,
            color: _fechaInicio != null ? Colors.white : Color(0xFF6A8EAE)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Fecha', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500,
              color: _fechaInicio != null ? Colors.white : Colors.grey[600])),
            SizedBox(height: 4),
            Text(_fechaInicio != null ? 'Rango personalizado' : 'Seleccionar rango',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600,
                color: _fechaInicio != null ? Colors.white : Color(0xFF212529))),
          ])),
        ]),
      ),
    );
  }

  Widget _buildEmotionsDetail() {
    if (_estadisticas.isEmpty) {
      return Container(
        padding: EdgeInsets.all(48),
        decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.insights_outlined, size: 80, color: Colors.grey[300]),
          SizedBox(height: 24),
          Text('No hay datos disponibles', style: GoogleFonts.inter(
            fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey[400])),
          SizedBox(height: 12),
          Text('Intenta con diferentes filtros para ver los resultados',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey[400])),
        ]),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: _cardColor, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: Offset(0, 8))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.all(24), child: Row(children: [
          Icon(Icons.table_chart_outlined, color: _primaryColor, size: 28),
          SizedBox(width: 16),
          Text('Registros Detallados', style: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF212529))),
          Spacer(),
          Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: _surfaceColor, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE9ECEF))),
            child: Row(children: [
              Icon(Icons.filter_list, size: 18, color: Colors.grey[600]),
              SizedBox(width: 8),
              Text('${_estadisticas.length} registros', style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
            ])),
        ])),
        _isDesktop ? _buildDataTable() : _buildMobileList(),
      ]),
    );
  }

  Widget _buildDataTable() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 60, dataRowHeight: 60, columnSpacing: 40, horizontalMargin: 20,
        columns: ['Emoción', 'Sede', 'Carrera', 'Ciclo', 'Fecha', 'Cantidad'].map((text) => 
          DataColumn(label: Container(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Text(text, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, 
              color: Colors.grey[800]))))).toList(),
        rows: _estadisticas.map((item) {
          final color = _emocionColors[item['emocion']] ?? _primaryColor;
          return DataRow(cells: [
            DataCell(Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(
                color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(_getEmocionEmoji(item['emocion']), style: TextStyle(fontSize: 18)))),
              SizedBox(width: 12),
              Text(item['emocion'], style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.grey[900])),
            ])),
            DataCell(Text(item['sede'] ?? '-')),
            DataCell(Text(item['carrera'] ?? '-')),
            DataCell(Text(item['ciclo'] ?? '-')),
            DataCell(Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(item['fecha'])))),
            DataCell(Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text('${item['cantidad']}', style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)))),
          ]);
        }).toList(),
      ),
    );
  }

  Widget _buildMobileList() {
    return ListView.separated(
      shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _estadisticas.length,
      separatorBuilder: (_, __) => Divider(color: Color(0xFFE9ECEF), height: 1),
      itemBuilder: (context, index) {
        final item = _estadisticas[index];
        final color = _emocionColors[item['emocion']] ?? _primaryColor;
        return Container(padding: EdgeInsets.symmetric(vertical: 16), child: Row(children: [
          Expanded(flex: 2, child: Row(children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(
              color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(_getEmocionEmoji(item['emocion']), style: TextStyle(fontSize: 20)))),
            SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item['emocion'], style: GoogleFonts.inter(
                fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF212529))),
              SizedBox(height: 4),
              Text('${item['sede']} • ${item['carrera']}', style: GoogleFonts.inter(
                fontSize: 12, color: Colors.grey[600])),
            ])),
          ])),
          Expanded(flex: 2, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Ciclo ${item['ciclo']}', style: GoogleFonts.inter(
              fontSize: 14, color: Colors.grey[700], fontWeight: FontWeight.w500)),
            SizedBox(height: 4),
            Text(DateFormat('dd/MM/yyyy').format(DateTime.parse(item['fecha'])), 
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
          ])),
          Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text('${item['cantidad']}', style: GoogleFonts.inter(
              fontSize: 16, fontWeight: FontWeight.w700, color: color))),
        ]));
      },
    );
  }

  void _showFilterDialog(String title, List<String> options, {bool showEmojis = false}) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24), topRight: Radius.circular(24))),
        child: Column(children: [
          Container(padding: EdgeInsets.all(24), decoration: BoxDecoration(
            color: _primaryColor, borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24))),
            child: Row(children: [
              Icon(Icons.search, color: Colors.white, size: 28),
              SizedBox(width: 16),
              Expanded(child: Text('Seleccionar $title', style: GoogleFonts.inter(
                fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white))),
            ])),
          Expanded(child: ListView.builder(itemCount: options.length, itemBuilder: (context, index) {
            final option = options[index];
            return ListTile(
              leading: showEmojis ? Container(width: 40, height: 40, decoration: BoxDecoration(
                color: _emocionColors[option]?.withOpacity(0.1) ?? _primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12)), child: Center(
                  child: Text(_getEmocionEmoji(option), style: TextStyle(fontSize: 20)))) : null,
              title: Text(option, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  if (title == 'Sede') _selectedSede = option;
                  else if (title == 'Carrera') _selectedCarrera = option;
                  else if (title == 'Ciclo') _selectedCiclo = option;
                  else if (title == 'Emoción') _selectedEmocion = option;
                });
                _loadData();
              },
            );
          })),
          Padding(padding: EdgeInsets.all(24), child: SizedBox(width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            ))),
        ]),
      ),
    );
  }

  Future<void> _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context, firstDate: DateTime(2020), lastDate: DateTime.now().add(Duration(days: 365)),
      initialDateRange: _fechaInicio != null && _fechaFin != null ? 
        DateTimeRange(start: _fechaInicio!, end: _fechaFin!) : 
        DateTimeRange(start: DateTime.now().subtract(Duration(days: 30)), end: DateTime.now()),
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: _primaryColor, onPrimary: Colors.white, 
            surface: Colors.white, onSurface: Color(0xFF212529)),
          dialogBackgroundColor: Colors.white),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _fechaInicio = picked.start;
        _fechaFin = picked.end;
      });
      _loadData();
    }
  }

  String _getEmocionEmoji(String emocion) {
    final emojis = {
      'Feliz': '😊', 'Alegre': '😄', 'Triste': '😢', 'Deprimido': '😞',
      'Enojado': '😠', 'Furioso': '🤬', 'Ansioso': '😰', 'Nervioso': '😬',
      'Calmado': '😌', 'Relajado': '😎',
    };
    return emojis[emocion] ?? '😐';
  }
}