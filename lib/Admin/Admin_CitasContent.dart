import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CitaServiceIntegrado {
  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String TABLE_NAME = 'agenda_cita';

  Future<List<Map<String, dynamic>>> getCitas() async {
    try {
      final response = await _supabase
          .from(TABLE_NAME)
          .select()
          .order('fecha_cita', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error obteniendo citas: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getInfoEstudiante(String estudianteUid) async {
    try {
      // Buscar en la colección de alertas (que tiene la sede)
      final querySnapshot = await _firestore
          .collection('alertas_suicidio')
          .where('usuario_email', isNotEqualTo: null)
          .get();

      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        // Aquí necesitarías una manera de relacionar estudianteUid con el usuario
        // Normalmente usarías el email o un campo común
        // Por ahora usaremos el UID de Firebase
        if (doc.id == estudianteUid) {
          return {
            'sede': data['sede'] ?? 'Sin sede',
            'email': data['usuario_email'] ?? '',
            'nombre': data['usuario_nombre'] ?? '',
            'telefono': data['usuario_telefono'] ?? '',
            'tipo_alerta': data['tipo_alerta'] ?? ''
          };
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo info estudiante: $e');
      return null;
    }
  }

  String getAdminSede() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email?.toLowerCase() ?? '';
    
    print('📧 Email admin: $email');
    
    if (email.contains('sanmiguel') || email.contains('san miguel')) {
      return 'san miguel';
    } else if (email.contains('lima')) {
      return 'lima';
    } else if (email.contains('arequipa')) {
      return 'arequipa';
    }
    return 'general';
  }

  Future<List<Map<String, dynamic>>> getAlertasSede(String sede) async {
    try {
      final querySnapshot = await _firestore
          .collection('alertas_suicidio')
          .where('sede', isEqualTo: sede)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('❌ Error obteniendo alertas: $e');
      return [];
    }
  }
}

class CitasDashboardMejorado extends StatefulWidget {
  const CitasDashboardMejorado({Key? key}) : super(key: key);

  @override
  State<CitasDashboardMejorado> createState() => _CitasDashboardMejoradoState();
}

class _CitasDashboardMejoradoState extends State<CitasDashboardMejorado> {
  final CitaServiceIntegrado _service = CitaServiceIntegrado();
  final TextEditingController _searchController = TextEditingController();
  
  bool _loading = true;
  List<Map<String, dynamic>> _citas = [];
  List<Map<String, dynamic>> _citasFiltradas = [];
  String _sedeAdmin = '';
  String _filtroEstado = 'todas';
  String _filtroSede = 'todas';
  List<String> _sedesDisponibles = ['todas'];
  List<String> _estadosDisponibles = ['todas'];
  
  // Estadísticas
  int _totalCitas = 0;
  int _totalAlertas = 0;

  @override
  void initState() {
    super.initState();
    _sedeAdmin = _service.getAdminSede();
    _initData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() => _loading = true);
    
    try {
      // Obtener citas y filtrar por sede
      final citas = await _service.getCitas();
      final citasConSede = await _enriquecerCitasConSede(citas);
      
      // Obtener alertas de la sede del admin
      final alertas = await _service.getAlertasSede(_sedeAdmin);
      
      // Extraer sedes únicas
      final sedesSet = <String>{};
      final estadosSet = <String>{};
      
      for (final cita in citasConSede) {
        final sede = cita['sede_estudiante']?.toString().toLowerCase() ?? '';
        final estado = cita['estado_cita']?.toString().toLowerCase() ?? '';
        
        if (sede.isNotEmpty && sede != 'sin sede') sedesSet.add(sede);
        if (estado.isNotEmpty) estadosSet.add(estado);
      }
      
      final sedesList = sedesSet.toList()..sort();
      final estadosList = estadosSet.toList()..sort();
      
      setState(() {
        _citas = citasConSede;
        _citasFiltradas = citasConSede;
        _sedesDisponibles = ['todas', ...sedesList];
        _estadosDisponibles = ['todas', ...estadosList];
        _totalCitas = citasConSede.length;
        _totalAlertas = alertas.length;
        _loading = false;
      });
      
      print('✅ Datos cargados: ${_citas.length} citas, ${alertas.length} alertas');
    } catch (e) {
      print('❌ Error inicializando datos: $e');
      setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _enriquecerCitasConSede(
      List<Map<String, dynamic>> citas) async {
    final citasEnriquecidas = <Map<String, dynamic>>[];
    
    for (final cita in citas) {
      final estudianteUid = cita['estudiante_uid']?.toString();
      Map<String, dynamic> citaModificada = Map.from(cita);
      
      if (estudianteUid != null && estudianteUid.isNotEmpty) {
        final estudianteInfo = await _service.getInfoEstudiante(estudianteUid);
        if (estudianteInfo != null) {
          citaModificada['sede'] = estudianteInfo['sede'];
          citaModificada['info_estudiante'] = estudianteInfo;
        } else {
          citaModificada['sede'] = 'Sin sede';
          citaModificada['info_estudiante'] = null;
        }


      } else {
        citaModificada['sede'] = 'Sin sede';
        citaModificada['info_estudiante'] = null;
      }
      
      citasEnriquecidas.add(citaModificada);
    }
    
    return citasEnriquecidas;
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase().trim();
    
    if (query.isEmpty) {
      _aplicarFiltros();
      return;
    }
    
    final resultados = _citas.where((cita) {
      final nombre = cita['nombre_estudiante']?.toString().toLowerCase() ?? '';
      final motivo = cita['motivo_cita']?.toString().toLowerCase() ?? '';
      final diagnostico = cita['diagnostico']?.toString().toLowerCase() ?? '';
      final sede = cita['sede_estudiante']?.toString().toLowerCase() ?? '';
      final estado = cita['estado_cita']?.toString().toLowerCase() ?? '';
      
      return nombre.contains(query) ||
             motivo.contains(query) ||
             diagnostico.contains(query) ||
             sede.contains(query) ||
             estado.contains(query);
    }).toList();
    
    setState(() => _citasFiltradas = resultados);
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> resultados = _citas;
    
    // Filtrar por sede
    if (_filtroSede != 'todas') {
      resultados = resultados.where((cita) {
        final sede = cita['sede_estudiante']?.toString().toLowerCase() ?? '';
        return sede == _filtroSede.toLowerCase();
      }).toList();
    }
    
    // Filtrar por estado
    if (_filtroEstado != 'todas') {
      resultados = resultados.where((cita) {
        final estado = cita['estado_cita']?.toString().toLowerCase() ?? '';
        return estado == _filtroEstado.toLowerCase();
      }).toList();
    }
    
    setState(() => _citasFiltradas = resultados);
  }

  Color _getColorEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return Colors.green.shade600;
      case 'pendiente':
        return Colors.orange.shade600;
      case 'cancelada':
        return Colors.red.shade600;
      case 'completada':
        return Colors.blue.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha == null) return 'Sin fecha';
    
    try {
      final fechaStr = fecha.toString();
      final dateTime = DateTime.parse(fechaStr);
      return '${dateTime.day.toString().padLeft(2, '0')}/'
            '${dateTime.month.toString().padLeft(2, '0')}/'
            '${dateTime.year} '
            '${dateTime.hour.toString().padLeft(2, '0')}:'
            '${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return fecha.toString();
    }
  }

  Widget _buildCitaCard(Map<String, dynamic> cita, int index) {
    final nombre = cita['nombre_estudiante']?.toString() ?? 'Sin nombre';
    final motivo = cita['motivo_cita']?.toString() ?? 'Sin motivo';
    final fecha = cita['fecha_cita'];
    final estado = cita['estado_cita']?.toString() ?? 'pendiente';
    final diagnostico = cita['diagnostico']?.toString() ?? 'Sin diagnóstico';
    final notas = cita['notas_adicionales']?.toString();
    final sede = cita['sede']?.toString() ?? 'Sin sede';
    final estudianteInfo = cita['info_estudiante'] as Map<String, dynamic>?;
    final confirmada = cita['confirmacion_cita'] == true;

    return Container(
      margin: const EdgeInsets.all(6),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _mostrarDetalles(cita),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getColorEstado(estado).withOpacity(0.3),
                width: 1,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  _getColorEstado(estado).withOpacity(0.05),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header con avatar y estado
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getColorEstado(estado).withOpacity(0.1),
                          border: Border.all(
                            color: _getColorEstado(estado),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.person,
                          color: _getColorEstado(estado),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nombre,
                              style: GoogleFonts.itim(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _getColorEstado(estado).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                estado.toUpperCase(),
                                style: GoogleFonts.itim(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: _getColorEstado(estado),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Sede con bandera
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.blue.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          sede.toUpperCase(),
                          style: GoogleFonts.itim(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Fecha
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formatearFecha(fecha),
                          style: GoogleFonts.itim(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Motivo
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.medical_services,
                        size: 14,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          motivo,
                          style: GoogleFonts.itim(
                            fontSize: 12,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Badges
                  if (diagnostico != 'Sin diagnóstico' ||
                      notas != null ||
                      estudianteInfo != null ||
                      confirmada)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (diagnostico != 'Sin diagnóstico')
                          _buildMiniBadge('💊', Colors.purple),
                        if (notas != null && notas.isNotEmpty)
                          _buildMiniBadge('📝', Colors.orange),
                        if (confirmada)
                          _buildMiniBadge('✓', Colors.green),
                        if (estudianteInfo != null)
                          _buildMiniBadge('👤', Colors.blue),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBadge(String emoji, Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  void _mostrarDetalles(Map<String, dynamic> cita) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildDetallesModal(cita),
    );
  }

  Widget _buildDetallesModal(Map<String, dynamic> cita) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header modal
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getColorEstado(cita['estado_cita']?.toString() ?? ''),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Icon(
                    Icons.person,
                    color: _getColorEstado(cita['estado_cita']?.toString() ?? ''),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cita['nombre_estudiante']?.toString() ?? 'Sin nombre',
                        style: GoogleFonts.itim(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sede: ${cita['sede_estudiante']?.toString().toUpperCase() ?? 'SIN SEDE'}',
                        style: GoogleFonts.itim(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Información de contacto
                if (cita['info_estudiante'] != null)
                  _buildInfoSection(
                    '📱 Contacto',
                    [
                      ['Email', cita['info_estudiante']['email'] ?? ''],
                      ['Teléfono', cita['info_estudiante']['telefono'] ?? ''],
                    ],
                  ),
                
                // Información de la cita
                _buildInfoSection(
                  '📅 Cita',
                  [
                    ['Fecha', _formatearFecha(cita['fecha_cita'])],
                    ['Estado', cita['estado_cita']?.toString() ?? ''],
                    ['Confirmada', cita['confirmacion_cita'] == true ? 'Sí' : 'No'],
                  ],
                ),
                
                // Detalles médicos
                _buildInfoSection(
                  '🏥 Detalles',
                  [
                    ['Motivo', cita['motivo_cita']?.toString() ?? ''],
                    ['Diagnóstico', cita['diagnostico']?.toString() ?? ''],
                    ['Notas', cita['notas_adicionales']?.toString() ?? ''],
                  ],
                ),
                
                // Botones de acción
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text('Editar', style: GoogleFonts.itim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.phone, size: 18),
                        label: Text('Llamar', style: GoogleFonts.itim()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<List<String>> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.itim(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      item[0],
                      style: GoogleFonts.itim(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item[1],
                      style: GoogleFonts.itim(
                        fontSize: 12,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Título y estadísticas
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Icon(Icons.calendar_month, color: Colors.blue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestión de Citas',
                        style: GoogleFonts.itim(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'Sede: ${_sedeAdmin.toUpperCase()}',
                        style: GoogleFonts.itim(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contadores
                Row(
                  children: [
                    _buildCounterBadge(
                      '${_totalCitas}',
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildCounterBadge(
                      '${_totalAlertas}',
                      Icons.warning,
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Barra de búsqueda
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar citas...',
                hintStyle: GoogleFonts.itim(color: Colors.grey.shade500),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Filtros
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Sede: $_filtroSede', () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildSedeFilterDialog(),
                    );
                  }),
                  const SizedBox(width: 8),
                  _buildFilterChip('Estado: $_filtroEstado', () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildEstadoFilterDialog(),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounterBadge(String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.itim(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.itim(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildSedeFilterDialog() {
    return AlertDialog(
      title: Text('Filtrar por sede', style: GoogleFonts.itim()),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _sedesDisponibles.length,
          itemBuilder: (context, index) {
            final sede = _sedesDisponibles[index];
            return ListTile(
              title: Text(
                sede == 'todas' ? 'Todas las sedes' : sede.toUpperCase(),
                style: GoogleFonts.itim(),
              ),
              leading: Icon(
                _filtroSede == sede ? Icons.check_circle : Icons.circle_outlined,
                color: _filtroSede == sede ? Colors.blue : Colors.grey,
              ),
              onTap: () {
                setState(() => _filtroSede = sede);
                _aplicarFiltros();
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEstadoFilterDialog() {
    return AlertDialog(
      title: Text('Filtrar por estado', style: GoogleFonts.itim()),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _estadosDisponibles.length,
          itemBuilder: (context, index) {
            final estado = _estadosDisponibles[index];
            return ListTile(
              title: Text(
                estado == 'todas' ? 'Todos los estados' : estado,
                style: GoogleFonts.itim(),
              ),
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _filtroEstado == estado 
                      ? _getColorEstado(estado)
                      : Colors.transparent,
                  border: Border.all(
                    color: _filtroEstado == estado 
                        ? _getColorEstado(estado)
                        : Colors.grey,
                  ),
                ),
              ),
              onTap: () {
                setState(() => _filtroEstado = estado);
                _aplicarFiltros();
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          _buildHeader(),
          
          Expanded(
            child: _loading
                ? _buildLoading()
                : _citasFiltradas.isEmpty
                    ? _buildEmptyState()
                    : _buildGridCitas(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _initData,
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.refresh, color: Colors.white),
      ),
    );
  }

  Widget _buildGridCitas() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: _citasFiltradas.length,
      itemBuilder: (context, index) => _buildCitaCard(_citasFiltradas[index], index),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.blue.shade600,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando citas...',
            style: GoogleFonts.itim(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sede: ${_sedeAdmin.toUpperCase()}',
            style: GoogleFonts.itim(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            _searchController.text.isNotEmpty
                ? 'No se encontraron resultados'
                : 'No hay citas disponibles',
            style: GoogleFonts.itim(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sede: ${_sedeAdmin.toUpperCase()}',
            style: GoogleFonts.itim(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initData,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text('Actualizar', style: GoogleFonts.itim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}