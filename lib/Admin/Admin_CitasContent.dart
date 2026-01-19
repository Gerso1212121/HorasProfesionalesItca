import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  Future<Map<String, dynamic>?> getInfoEstudianteByUid(String uid) async {
    try {
      print('🔍 Buscando estudiante por UID: $uid');
      
      if (uid.isEmpty || uid == 'null') {
        print('⚠️ UID vacío o nulo');
        return null;
      }
      
      // Buscar en la colección de estudiantes de Firestore por UID
      final doc = await _firestore
          .collection('estudiantes')
          .doc(uid)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        print('✅ Estudiante encontrado por UID: ${doc.id}');
        
        return {
          'uid': doc.id,
          'sede': data['sede'] ?? 'Sin sede',
          'correo': data['correo'] ?? '',
          'nombre': '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}'.trim(),
          'telefono': data['telefono'] ?? '',
          'carnet': data['carnet'] ?? '',
          'carrera': data['carrera'] ?? '',
          'anio_ingreso': data['anio_ingreso'] ?? '',
          'tipo_usuario': data['tipo_usuario'] ?? '',
          'verificado_itca': data['verificado_itca'] ?? false,
        };
      } else {
        print('⚠️ No se encontró estudiante con UID: $uid');
        return null;
      }
    } catch (e) {
      print('❌ Error obteniendo info estudiante por UID: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getAllEstudiantes() async {
    try {
      print('🔍 Obteniendo TODOS los estudiantes...');
      
      final querySnapshot = await _firestore
          .collection('estudiantes')
          .get();

      print('✅ Total estudiantes en BD: ${querySnapshot.docs.length}');
      
      if (querySnapshot.docs.isNotEmpty) {
        print('📋 Primer estudiante de la lista:');
        final firstDoc = querySnapshot.docs.first.data();
        print('  Nombre: ${firstDoc['nombre']} ${firstDoc['apellido']}');
        print('  Correo: ${firstDoc['correo']}');
        print('  Sede: ${firstDoc['sede']}');
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'anio_ingreso': data['anio_ingreso'] ?? '',
          'apellido': data['apellido'] ?? '',
          'carnet': data['carnet'] ?? '',
          'carrera': data['carrera'] ?? '',
          'correo': data['correo'] ?? '',
          'nombre': data['nombre'] ?? '',
          'sede': data['sede'] ?? '',
          'telefono': data['telefono'] ?? '',
          'tipo_usuario': data['tipo_usuario'] ?? '',
          'verificado_itca': data['verificado_itca'] ?? false,
          'nombre_completo': '${data['nombre'] ?? ''} ${data['apellido'] ?? ''}'.trim(),
        };
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo todos los estudiantes: $e');
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
  List<Map<String, dynamic>> _estudiantes = [];
  String _filtroEstado = 'todas';
  String _filtroSede = 'todas';
  List<String> _sedesDisponibles = ['todas'];
  List<String> _estadosDisponibles = ['todas'];
  
  // Estadísticas
  int _totalCitas = 0;
  int _totalEstudiantes = 0;

  @override
  void initState() {
    super.initState();
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
      print('\n========================================');
      print('🔄 INICIANDO CARGA DE DATOS - MODO ADMIN');
      print('========================================\n');
      
      // 1. Obtener TODOS los estudiantes
      final estudiantes = await _service.getAllEstudiantes();
      
      // 2. Obtener todas las citas de Supabase
      print('📋 Obteniendo citas de Supabase...');
      final citas = await _service.getCitas();
      print('✅ Citas obtenidas: ${citas.length}');
      
      // 3. Enriquecer cada cita con información del estudiante
      print('\n🔗 Enlazando citas con estudiantes...');
      final citasEnriquecidas = <Map<String, dynamic>>[];
      
      int citasConEstudiante = 0;
      int citasSinEstudiante = 0;
      
      for (final cita in citas) {
        final estudianteUid = cita['estudiante_uid']?.toString();
        
        if (estudianteUid != null && estudianteUid.isNotEmpty && estudianteUid != 'null') {
          print('\n🔍 Procesando cita con UID: $estudianteUid');
          
          // Buscar información del estudiante
          final estudianteInfo = await _service.getInfoEstudianteByUid(estudianteUid);
          
          if (estudianteInfo != null) {
            print('✅ Estudiante encontrado: ${estudianteInfo['nombre']}');
            citasConEstudiante++;
            
            Map<String, dynamic> citaModificada = Map.from(cita);
            citaModificada['sede_estudiante'] = estudianteInfo['sede'] ?? 'Sin sede';
            citaModificada['info_estudiante'] = estudianteInfo;
            citaModificada['nombre_estudiante'] = estudianteInfo['nombre'];
            citaModificada['correo_estudiante'] = estudianteInfo['correo'];
            citaModificada['telefono_estudiante'] = estudianteInfo['telefono'];
            
            citasEnriquecidas.add(citaModificada);
          } else {
            print('⚠️ Estudiante NO encontrado para UID: $estudianteUid');
            citasSinEstudiante++;
            
            // Añadir cita sin info de estudiante
            Map<String, dynamic> citaModificada = Map.from(cita);
            citaModificada['sede_estudiante'] = 'Sin sede';
            citaModificada['info_estudiante'] = null;
            citaModificada['nombre_estudiante'] = 'Usuario no encontrado';
            citaModificada['correo_estudiante'] = '';
            citaModificada['telefono_estudiante'] = '';
            
            citasEnriquecidas.add(citaModificada);
          }
        } else {
          print('⚠️ Cita sin UID válido');
          citasSinEstudiante++;
          
          // Añadir cita sin UID
          Map<String, dynamic> citaModificada = Map.from(cita);
          citaModificada['sede_estudiante'] = 'Sin sede';
          citaModificada['info_estudiante'] = null;
          citaModificada['nombre_estudiante'] = 'Usuario no identificado';
          citaModificada['correo_estudiante'] = '';
          citaModificada['telefono_estudiante'] = '';
          
          citasEnriquecidas.add(citaModificada);
        }
      }
      
      print('\n📊 RESULTADOS DEL ENLACE:');
      print('  Total citas: ${citas.length}');
      print('  Citas con estudiante encontrado: $citasConEstudiante');
      print('  Citas sin estudiante: $citasSinEstudiante');
      print('  Citas enriquecidas: ${citasEnriquecidas.length}');
      
      // 4. Extraer sedes únicas de las citas enriquecidas
      final sedesSet = <String>{};
      final estadosSet = <String>{};
      
      for (final cita in citasEnriquecidas) {
        final sede = cita['sede_estudiante']?.toString() ?? '';
        final estado = cita['estado_cita']?.toString().toLowerCase() ?? '';
        
        if (sede.isNotEmpty && sede != 'Sin sede') sedesSet.add(sede);
        if (estado.isNotEmpty) estadosSet.add(estado);
      }
      
      final sedesList = sedesSet.toList()..sort();
      final estadosList = estadosSet.toList()..sort();
      
      setState(() {
        _citas = citasEnriquecidas;
        _citasFiltradas = citasEnriquecidas;
        _estudiantes = estudiantes;
        _sedesDisponibles = ['todas', ...sedesList];
        _estadosDisponibles = ['todas', ...estadosList];
        _totalCitas = citasEnriquecidas.length;
        _totalEstudiantes = estudiantes.length;
        _loading = false;
      });
      
      _aplicarFiltros();
      
      print('\n✅ CARGA COMPLETADA:');
      print('👥 Estudiantes en BD: $estudiantes.length');
      print('📅 Citas mostradas: ${_citas.length}');
      print('🎯 Citas filtradas: ${_citasFiltradas.length}');
      print('📍 Sedes disponibles: ${_sedesDisponibles.length}');
      
      if (_citas.isNotEmpty) {
        print('\n🔍 PRIMERA CITA:');
        final primeraCita = _citas.first;
        print('  Nombre: ${primeraCita['nombre_estudiante']}');
        print('  Sede: ${primeraCita['sede_estudiante']}');
        print('  Motivo: ${primeraCita['motivo_cita']}');
        print('  Estado: ${primeraCita['estado_cita']}');
      }
      
    } catch (e) {
      print('❌ ERROR inicializando datos: $e');
      print('🔄 Stack trace: ${e.toString()}');
      setState(() => _loading = false);
    }
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
      final correo = cita['correo_estudiante']?.toString().toLowerCase() ?? '';
      final estudianteInfo = cita['info_estudiante'] as Map<String, dynamic>?;
      final carnet = estudianteInfo?['carnet']?.toString().toLowerCase() ?? '';
      final telefono = cita['telefono_estudiante']?.toString().toLowerCase() ?? '';
      final carrera = estudianteInfo?['carrera']?.toString().toLowerCase() ?? '';
      
      return nombre.contains(query) ||
             motivo.contains(query) ||
             diagnostico.contains(query) ||
             sede.contains(query) ||
             estado.contains(query) ||
             correo.contains(query) ||
             carnet.contains(query) ||
             telefono.contains(query) ||
             carrera.contains(query);
    }).toList();
    
    setState(() => _citasFiltradas = resultados);
  }

  void _aplicarFiltros() {
    List<Map<String, dynamic>> resultados = _citas;
    
    // Filtrar por sede
    if (_filtroSede != 'todas') {
      resultados = resultados.where((cita) {
        final sede = cita['sede_estudiante']?.toString() ?? '';
        return sede == _filtroSede;
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
    final sede = cita['sede_estudiante']?.toString() ?? 'Sin sede';
    final estudianteInfo = cita['info_estudiante'] as Map<String, dynamic>?;
    final confirmada = cita['confirmacion_cita'] == true;
    final carnet = estudianteInfo?['carnet']?.toString() ?? '';
    final verificadoItca = estudianteInfo?['verificado_itca'] == true;
    final tipoUsuario = estudianteInfo?['tipo_usuario']?.toString() ?? '';
    final esEstudianteItca = tipoUsuario == 'estudiante_itca';

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
                          estudianteInfo != null ? Icons.person : Icons.person_off,
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
                            if (carnet.isNotEmpty)
                              Text(
                                'Carnet: $carnet',
                                style: GoogleFonts.itim(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
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
                          sede,
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
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (estudianteInfo == null)
                        _buildMiniBadge('❓', Colors.grey, 'Usuario no encontrado'),
                      if (diagnostico != 'Sin diagnóstico')
                        _buildMiniBadge('💊', Colors.purple, 'Tiene diagnóstico'),
                      if (notas != null && notas.isNotEmpty)
                        _buildMiniBadge('📝', Colors.orange, 'Tiene notas'),
                      if (confirmada)
                        _buildMiniBadge('✓', Colors.green, 'Confirmada'),
                      if (verificadoItca)
                        _buildMiniBadge('✅', Colors.blue, 'Verificado ITCA'),
                      if (carnet.isNotEmpty)
                        _buildMiniBadge('#', Colors.teal, 'Carnet: $carnet'),
                      if (esEstudianteItca)
                        _buildMiniBadge('🎓', Colors.purple, 'Estudiante ITCA'),
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

  Widget _buildMiniBadge(String emoji, Color color, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
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
    final estudianteInfo = cita['info_estudiante'] as Map<String, dynamic>?;
    final esEstudianteItca = estudianteInfo?['tipo_usuario'] == 'estudiante_itca';
    final verificadoItca = estudianteInfo?['verificado_itca'] == true;
    final tieneEstudiante = estudianteInfo != null;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
                    tieneEstudiante ? Icons.person : Icons.person_off,
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
                        cita['nombre_estudiante']?.toString() ?? 'Usuario no identificado',
                        style: GoogleFonts.itim(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sede: ${cita['sede_estudiante']?.toString() ?? 'SIN SEDE'}',
                        style: GoogleFonts.itim(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      if (estudianteInfo?['carnet'] != null)
                        Text(
                          'Carnet: ${estudianteInfo!['carnet']}',
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
                // Información del estudiante
                if (tieneEstudiante)
                  _buildInfoSection(
                    '👤 Información del Estudiante',
                    [
                      ['Carnet', estudianteInfo!['carnet'] ?? 'No tiene'],
                      ['Correo', estudianteInfo['correo'] ?? 'No tiene'],
                      ['Teléfono', estudianteInfo['telefono'] ?? 'No tiene'],
                      ['Carrera', estudianteInfo['carrera'] ?? 'No especificada'],
                      ['Año Ingreso', estudianteInfo['anio_ingreso'] ?? 'No especificado'],
                      ['Tipo Usuario', estudianteInfo['tipo_usuario'] ?? 'No especificado'],
                      ['Verificado ITCA', verificadoItca ? '✅ Sí' : '❌ No'],
                      ['Estudiante ITCA', esEstudianteItca ? '✅ Sí' : '❌ No'],
                    ],
                  )
                else
                  _buildInfoSection(
                    '👤 Información del Estudiante',
                    [
                      ['Estado', '❌ NO ENCONTRADO'],
                      ['UID en cita', cita['estudiante_uid']?.toString() ?? 'No disponible'],
                      ['Nota', 'El estudiante con este UID no existe en la base de datos de estudiantes'],
                    ],
                  ),
                
                // Información de la cita
                _buildInfoSection(
                  '📅 Información de la Cita',
                  [
                    ['Fecha', _formatearFecha(cita['fecha_cita'])],
                    ['Estado', cita['estado_cita']?.toString() ?? 'No especificado'],
                    ['Confirmada', cita['confirmacion_cita'] == true ? '✅ Sí' : '❌ No'],
                  ],
                ),
                
                // Detalles médicos
                _buildInfoSection(
                  '🏥 Detalles Médicos',
                  [
                    ['Motivo', cita['motivo_cita']?.toString() ?? 'No especificado'],
                    ['Diagnóstico', cita['diagnostico']?.toString() ?? 'Sin diagnóstico'],
                    ['Notas Adicionales', cita['notas_adicionales']?.toString() ?? 'No hay notas'],
                  ],
                ),
                
                // Botones de acción
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Implementar edición
                        },
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
                        onPressed: () {
                          final telefono = estudianteInfo?['telefono'] ?? '';
                          if (telefono.isNotEmpty) {
                            // TODO: Implementar llamada
                          }
                        },
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
                    width: 100,
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
                        'Gestión de Citas - ADMIN',
                        style: GoogleFonts.itim(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'Vista completa de todas las sedes',
                        style: GoogleFonts.itim(
                          fontSize: 12,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Contadores
                Row(
                  children: [
                    _buildCounterBadge(
                      '$_totalCitas',
                      Icons.calendar_today,
                      Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildCounterBadge(
                      '$_totalEstudiantes',
                      Icons.group,
                      Colors.green,
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
                hintText: 'Buscar por nombre, carnet, motivo, sede...',
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
                sede == 'todas' ? 'Todas las sedes' : sede,
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
        childAspectRatio: 1.6,
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
            'Vista completa - Todas las sedes',
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
                : 'No hay citas registradas',
            style: GoogleFonts.itim(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estudiantes en BD: $_totalEstudiantes',
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