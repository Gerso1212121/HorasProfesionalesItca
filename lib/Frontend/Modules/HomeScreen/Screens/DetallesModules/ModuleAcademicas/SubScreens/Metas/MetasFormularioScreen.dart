import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleAcademicas/SubScreens/Metas/MetasHistorialScreen.dart';
import 'package:intl/intl.dart';

class MetasFormularioScreen extends StatefulWidget {
  const MetasFormularioScreen({super.key});

  @override
  State<MetasFormularioScreen> createState() => _MetasFormularioScreenState();
}

class _MetasFormularioScreenState extends State<MetasFormularioScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isLoading = true;
  int? _idEstudiante;
  List<Map<String, dynamic>> _metasActivas = [];
  int _currentMetaIndex = 0;
  Map<String, dynamic>? _metaActual;
  List<Map<String, dynamic>> _tareasMetaActual = [];

  final List<String> _moodEmojis = [
    '😃',
    '😊',
    '😐',
    '😔',
    '😟',
    '😌',
    '🤔',
    '😴'
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await _loadMetasActivas();
    setState(() => _isLoading = false);

    // Mostrar modal si no hay metas activas
    if (_metasActivas.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCrearMetaModal();
      });
    }
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final estudiante = await _dbHelper.getEstudiantePorUID(uid);
      if (estudiante != null) {
        _idEstudiante = estudiante['id_estudiante'] as int;
      }
    }
  }

  Future<void> _loadMetasActivas() async {
    if (_idEstudiante == null) return;

    final db = await _dbHelper.database;
    _metasActivas = await db.query(
      'metas_semanales',
      where: 'id_estudiante = ? AND estado = ?',
      whereArgs: [_idEstudiante, 'activa'],
      orderBy: 'fecha_creacion ASC', // Más viejas primero
    );

    if (_metasActivas.isNotEmpty) {
      _metaActual = _metasActivas[_currentMetaIndex];
      await _loadTareasMetaActual();
    }
  }

  Future<void> _loadTareasMetaActual() async {
    if (_metaActual == null) return;

    _tareasMetaActual =
        await _dbHelper.getTareasPorMeta(_metaActual!['id_meta'] as int);
    setState(() {});
  }

  bool _metaNecesitaEvaluacion(Map<String, dynamic> meta) {
    final fechaFin = DateTime.parse(meta['fecha_fin']);
    final hoy = DateTime.now();
    final resultado = meta['resultado'] as String?;

    // Si ya pasó la fecha fin y no tiene evaluación
    return hoy.isAfter(fechaFin) && (resultado == null || resultado.isEmpty);
  }

  void _showCrearMetaModal({Map<String, dynamic>? metaParaEditar}) {
    final specificController =
        TextEditingController(text: metaParaEditar?['especifica'] ?? '');
    final measurableController =
        TextEditingController(text: metaParaEditar?['medible'] ?? '');
    final achievableController =
        TextEditingController(text: metaParaEditar?['alcanzable'] ?? '');
    final relevantController =
        TextEditingController(text: metaParaEditar?['relevante'] ?? '');

    DateTime fechaInicio = metaParaEditar != null
        ? DateTime.parse(metaParaEditar['fecha_inicio'])
        : DateTime.now();
    DateTime fechaFin = metaParaEditar != null
        ? DateTime.parse(metaParaEditar['fecha_fin'])
        : DateTime.now().add(const Duration(days: 6));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFFF2FFFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        metaParaEditar != null
                            ? 'Editar Meta SMART'
                            : 'Nueva Meta SMART',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMetaField(
                          'Específica',
                          'Define exactamente qué quieres lograr',
                          specificController),
                      const SizedBox(height: 16),
                      _buildMetaField('Medible', 'Cómo vas a medir tu progreso',
                          measurableController),
                      const SizedBox(height: 16),
                      _buildMetaField(
                          'Alcanzable',
                          'Es realista con tus capacidades',
                          achievableController),
                      const SizedBox(height: 16),
                      _buildMetaField('Relevante',
                          'Por qué es importante para ti', relevantController),
                      const SizedBox(height: 16),

                      // Temporal - Fechas
                      Text(
                        'Temporal',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              'Inicio',
                              fechaInicio,
                              (date) => setModalState(() => fechaInicio = date),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDateField(
                              'Fin',
                              fechaFin,
                              (date) => setModalState(() => fechaFin = date),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Botones
                      Row(
                        children: [
                          if (metaParaEditar != null)
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final confirm = await _showConfirmDialog(
                                    '¿Eliminar meta?',
                                    'Esta acción no se puede deshacer',
                                  );
                                  if (confirm == true) {
                                    await _dbHelper.deleteMetaSemanal(
                                        metaParaEditar['id_meta']);
                                    Navigator.pop(context);
                                    await _loadMetasActivas();
                                    _showSuccess('Meta eliminada');
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text('Eliminar',
                                    style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)),
                              ),
                            ),
                          if (metaParaEditar != null) const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_validateMetaForm(
                                    specificController,
                                    measurableController,
                                    achievableController,
                                    relevantController)) {
                                  if (metaParaEditar != null) {
                                    await _actualizarMeta(
                                      metaParaEditar['id_meta'],
                                      specificController.text,
                                      measurableController.text,
                                      achievableController.text,
                                      relevantController.text,
                                      fechaInicio,
                                      fechaFin,
                                    );
                                  } else {
                                    await _crearMeta(
                                      specificController.text,
                                      measurableController.text,
                                      achievableController.text,
                                      relevantController.text,
                                      fechaInicio,
                                      fechaFin,
                                    );
                                  }
                                  Navigator.pop(context);
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4CAF50),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                metaParaEditar != null
                                    ? 'Actualizar Meta'
                                    : 'Crear Meta',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEvaluacionModal(Map<String, dynamic> meta) {
    String resultadoSeleccionado = '';
    final factoresController = TextEditingController();
    final mejorasController = TextEditingController();
    final reflexionController = TextEditingController();
    final fraseController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFFF2FFFF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(Icons.assignment_turned_in,
                        color: Color(0xFF2196F3), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Evaluación Semanal',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          meta['especifica'],
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '¿Lograste tu meta SMART?',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildResultadoOption(
                              'Sí',
                              resultadoSeleccionado,
                              (val) => setModalState(
                                  () => resultadoSeleccionado = val)),
                          const SizedBox(width: 8),
                          _buildResultadoOption(
                              'Parcialmente',
                              resultadoSeleccionado,
                              (val) => setModalState(
                                  () => resultadoSeleccionado = val)),
                          const SizedBox(width: 8),
                          _buildResultadoOption(
                              'No',
                              resultadoSeleccionado,
                              (val) => setModalState(
                                  () => resultadoSeleccionado = val)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: factoresController,
                        decoration: InputDecoration(
                          labelText: '¿Qué te ayudó más a lograrlo?',
                          hintText: 'Usar Pomodoro, tener horarios claros...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: mejorasController,
                        decoration: InputDecoration(
                          labelText: '¿Qué puedes mejorar la próxima semana?',
                          hintText: 'Planificar mejor, cambiar horarios...',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: reflexionController,
                        decoration: InputDecoration(
                          labelText: 'Reflexión de la semana',
                          hintText: '¿Cómo te sentiste? ¿Qué aprendiste?',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: fraseController,
                        decoration: InputDecoration(
                          labelText: 'Frase motivadora',
                          hintText: '"Cada paso cuenta hacia mi objetivo"',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: resultadoSeleccionado.isEmpty
                              ? null
                              : () async {
                                  await _completarEvaluacion(
                                    meta['id_meta'],
                                    resultadoSeleccionado,
                                    factoresController.text,
                                    mejorasController.text,
                                    reflexionController.text,
                                    fraseController.text,
                                  );
                                  Navigator.pop(context);
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Completar Evaluación',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultadoOption(
      String option, String selected, Function(String) onTap) {
    final isSelected = selected == option;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(option),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF2196F3).withOpacity(0.2)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: const Color(0xFF2196F3), width: 2)
                : null,
          ),
          child: Text(
            option,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFF2196F3) : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Future<void> _completarEvaluacion(int idMeta, String resultado,
      String factores, String mejoras, String reflexion, String frase) async {
    final db = await _dbHelper.database;
    await db.update(
      'metas_semanales',
      {
        'resultado': resultado,
        'factores_ayuda': factores,
        'mejoras': mejoras,
        'reflexion': reflexion,
        'frase_motivacional': frase,
        'estado': 'completada',
      },
      where: 'id_meta = ?',
      whereArgs: [idMeta],
    );

    await _loadMetasActivas();
    _showSuccess('¡Evaluación completada exitosamente!');
  }

  Future<void> _actualizarMeta(
      int idMeta,
      String especifica,
      String medible,
      String alcanzable,
      String relevante,
      DateTime inicio,
      DateTime fin) async {
    await _dbHelper.updateMetaSemanal(idMeta, {
      'especifica': especifica,
      'medible': medible,
      'alcanzable': alcanzable,
      'relevante': relevante,
      'fecha_inicio': DateFormat('yyyy-MM-dd').format(inicio),
      'fecha_fin': DateFormat('yyyy-MM-dd').format(fin),
      'temporal':
          '${DateFormat('dd/MM/yyyy').format(inicio)} - ${DateFormat('dd/MM/yyyy').format(fin)}',
    });

    await _loadMetasActivas();
    _showSuccess('Meta actualizada exitosamente');
  }

  Widget _buildDateField(
      String label, DateTime date, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime.now().subtract(const Duration(days: 365)),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _validateMetaForm(
      TextEditingController specific,
      TextEditingController measurable,
      TextEditingController achievable,
      TextEditingController relevant) {
    if (specific.text.isEmpty ||
        measurable.text.isEmpty ||
        achievable.text.isEmpty ||
        relevant.text.isEmpty) {
      _showError('Completa todos los campos SMART');
      return false;
    }
    return true;
  }

  Future<void> _crearMeta(String especifica, String medible, String alcanzable,
      String relevante, DateTime inicio, DateTime fin) async {
    if (_idEstudiante == null) return;

    final metaData = {
      'id_estudiante': _idEstudiante,
      'fecha_inicio': DateFormat('yyyy-MM-dd').format(inicio),
      'fecha_fin': DateFormat('yyyy-MM-dd').format(fin),
      'especifica': especifica,
      'medible': medible,
      'alcanzable': alcanzable,
      'relevante': relevante,
      'temporal':
          '${DateFormat('dd/MM/yyyy').format(inicio)} - ${DateFormat('dd/MM/yyyy').format(fin)}',
      'estado': 'activa',
      'fecha_creacion': DateTime.now().toIso8601String(),
    };

    await _dbHelper.insertMetaSemanal(metaData);
    await _loadMetasActivas();
    _showSuccess('Meta creada exitosamente');
  }

  void _showEditarTareaModal(Map<String, dynamic> tarea) {
    final actividadController = TextEditingController(text: tarea['actividad']);

    // Parsear la hora existente o usar hora actual
    TimeOfDay horaTarea = TimeOfDay.now();
    if (tarea['hora'] != null && (tarea['hora'] as String).isNotEmpty) {
      try {
        final horaParts = (tarea['hora'] as String).split(':');
        horaTarea = TimeOfDay(
          hour: int.parse(horaParts[0]),
          minute: int.parse(horaParts[1]),
        );
      } catch (e) {
        // Si hay error al parsear, usar hora actual
      }
    }

    // Parsear el día de la semana para obtener una fecha aproximada
    final diasSemana = {
      'Lunes': 1,
      'Martes': 2,
      'Miércoles': 3,
      'Jueves': 4,
      'Viernes': 5,
      'Sábado': 6,
      'Domingo': 7,
    };

    final diaNumero = diasSemana[tarea['dia_semana']] ?? 1;
    final hoy = DateTime.now();
    final diferenciaDias = diaNumero - hoy.weekday;
    DateTime fechaTarea = hoy.add(Duration(days: diferenciaDias));

    // Asegurarse de que la fecha esté dentro del rango de la meta
    final fechaInicio = DateTime.parse(_metaActual!['fecha_inicio']);
    final fechaFin = DateTime.parse(_metaActual!['fecha_fin']);

    if (fechaTarea.isBefore(fechaInicio)) {
      fechaTarea = fechaTarea.add(const Duration(days: 7));
    } else if (fechaTarea.isAfter(fechaFin)) {
      fechaTarea = fechaTarea.subtract(const Duration(days: 7));
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF2FFFF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Editar Tarea',
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirm = await _showConfirmDialog(
                          '¿Eliminar tarea?',
                          'Esta acción no se puede deshacer',
                        );
                        if (confirm == true) {
                          final db = await _dbHelper.database;
                          await db.delete('tareas_diarias',
                              where: 'id_tarea = ?',
                              whereArgs: [tarea['id_tarea']]);
                          Navigator.pop(context);
                          await _loadTareasMetaActual();
                          _showSuccess('Tarea eliminada');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: actividadController,
                  decoration: InputDecoration(
                    labelText: 'Actividad',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Fecha
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaTarea,
                      firstDate: DateTime.parse(_metaActual!['fecha_inicio']),
                      lastDate: DateTime.parse(_metaActual!['fecha_fin']),
                    );
                    if (picked != null) {
                      setModalState(() => fechaTarea = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF4CAF50)),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, dd MMMM', 'es').format(fechaTarea),
                          style: GoogleFonts.inter(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hora
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: horaTarea,
                    );
                    if (picked != null) {
                      setModalState(() => horaTarea = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 12),
                        Text(
                          '${horaTarea.hour.toString().padLeft(2, '0')}:${horaTarea.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Cancelar', style: GoogleFonts.inter()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (actividadController.text.isNotEmpty) {
                            final diaSemana = _getDiaSemana(fechaTarea.weekday);
                            final horaFormateada =
                                '${horaTarea.hour.toString().padLeft(2, '0')}:${horaTarea.minute.toString().padLeft(2, '0')}';

                            await _dbHelper
                                .updateTareaDiaria(tarea['id_tarea'], {
                              'actividad': actividadController.text,
                              'dia_semana': diaSemana,
                              'hora': horaFormateada,
                            });
                            Navigator.pop(context);
                            await _loadTareasMetaActual();
                            _showSuccess('Tarea actualizada');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Guardar',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

  void _showCrearTareaModal() {
    if (_metaActual == null) return;

    final actividadController = TextEditingController();
    DateTime fechaTarea = DateTime.now();
    TimeOfDay horaTarea = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF2FFFF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                Text(
                  'Nueva Tarea',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: actividadController,
                  decoration: InputDecoration(
                    labelText: 'Actividad',
                    hintText: 'Ej: Estudiar matemáticas',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                // Fecha
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: fechaTarea,
                      firstDate: DateTime.parse(_metaActual!['fecha_inicio']),
                      lastDate: DateTime.parse(_metaActual!['fecha_fin']),
                    );
                    if (picked != null) {
                      setModalState(() => fechaTarea = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Color(0xFF4CAF50)),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('EEEE, dd MMMM', 'es').format(fechaTarea),
                          style: GoogleFonts.inter(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Hora
                InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: horaTarea,
                    );
                    if (picked != null) {
                      setModalState(() => horaTarea = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF4CAF50)),
                        const SizedBox(width: 12),
                        Text(
                          '${horaTarea.hour.toString().padLeft(2, '0')}:${horaTarea.minute.toString().padLeft(2, '0')}',
                          style: GoogleFonts.inter(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (actividadController.text.isNotEmpty) {
                        await _crearTarea(
                            actividadController.text, fechaTarea, horaTarea);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Crear Tarea',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _crearTarea(
      String actividad, DateTime fecha, TimeOfDay hora) async {
    if (_metaActual == null) return;

    final db = await _dbHelper.database;
    final diaSemana = _getDiaSemana(fecha.weekday);
    final horaFormateada =
        '${hora.hour.toString().padLeft(2, '0')}:${hora.minute.toString().padLeft(2, '0')}';

    await db.insert('tareas_diarias', {
      'id_meta': _metaActual!['id_meta'],
      'dia_semana': diaSemana,
      'actividad': actividad,
      'hora': horaFormateada,
      'completada': 0,
      'estado_emocional': '',
    });

    await _loadTareasMetaActual();
    _showSuccess('Tarea creada exitosamente');
  }

  String _getDiaSemana(int weekday) {
    const dias = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    return dias[weekday - 1];
  }

  Future<bool?> _showConfirmDialog(String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text(content, style: GoogleFonts.inter()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                Text('Confirmar', style: GoogleFonts.inter(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaField(
      String label, String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
        ),
      ),
      maxLines: 2,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: const Color(0xFF4CAF50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF2FFFF),
        appBar: AppBar(
          title: Text('Mis Metas', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      appBar: AppBar(
        title: Text('Mis Metas',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Ver historial',
            onPressed: () {
              if (_idEstudiante != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        MetasHistorialScreen(idEstudiante: _idEstudiante!),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: _metasActivas.isEmpty ? _buildEmptyState() : _buildDashboard(),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 24),
          Text(
            'No tienes metas activas',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Crea tu primera meta SMART',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Cards de metas con scroll horizontal
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: PageController(viewportFraction: 0.9),
              onPageChanged: (index) {
                setState(() {
                  _currentMetaIndex = index;
                  _metaActual = _metasActivas[index];
                });
                _loadTareasMetaActual();
              },
              itemCount: _metasActivas.length,
              itemBuilder: (context, index) =>
                  _buildMetaCard(_metasActivas[index], index),
            ),
          ),

          // Lista de tareas
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tareas',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_tareasMetaActual.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(Icons.task_outlined,
                              size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'No hay tareas aún',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._tareasMetaActual.map((tarea) => _buildTareaCard(tarea)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaCard(Map<String, dynamic> meta, int index) {
    final tareasTotal = _tareasMetaActual.length;
    final tareasCompletadas =
        _tareasMetaActual.where((t) => t['completada'] == 1).length;
    final fechaInicio = DateTime.parse(meta['fecha_inicio']);
    final fechaFin = DateTime.parse(meta['fecha_fin']);
    final diasTotal = fechaFin.difference(fechaInicio).inDays + 1;
    final diasTranscurridos =
        DateTime.now().difference(fechaInicio).inDays.clamp(0, diasTotal);

    final progresoTareas =
        tareasTotal > 0 ? tareasCompletadas / tareasTotal : 0.0;
    final progresoDias = diasTotal > 0 ? diasTranscurridos / diasTotal : 0.0;

    // Verificar si necesita evaluación (solo si completó los días)
    final diasCompletados = progresoDias >= 1.0;
    final necesitaEvaluacion = diasCompletados && _metaNecesitaEvaluacion(meta);

    // Colores según estado
    final cardColors = diasCompletados
        ? [const Color(0xFF2196F3), const Color(0xFF42A5F5)] // Azul
        : [const Color(0xFF4CAF50), const Color(0xFF66BB6A)]; // Verde

    return GestureDetector(
      onTap: () {
        if (necesitaEvaluacion) {
          _showEvaluacionModal(meta);
        } else if (!diasCompletados) {
          // Solo permite editar si no ha completado los días
          _showCrearMetaModal(metaParaEditar: meta);
        }
      },
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: cardColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: cardColors[0].withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        meta['especifica'],
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${index + 1}/${_metasActivas.length}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Progreso de tareas
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tareas',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$tareasCompletadas/$tareasTotal',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progresoTareas,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progreso de días
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Días',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '$diasTranscurridos/$diasTotal días',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progresoDias,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),

                if (diasCompletados)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.assignment_turned_in,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            necesitaEvaluacion
                                ? 'Toca para evaluar'
                                : 'Evaluada',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Notificación roja solo si necesita evaluación
            if (necesitaEvaluacion)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTareaCard(Map<String, dynamic> tarea) {
    final completada = tarea['completada'] == 1;
    final estadoEmocional = tarea['estado_emocional'] as String? ?? '';

    return GestureDetector(
      onTap: () => _showEditarTareaModal(tarea),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: completada
              ? Border.all(color: const Color(0xFF4CAF50), width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap: () async {
                await _dbHelper.toggleTareaCompletada(
                    tarea['id_tarea'], !completada);
                await _loadTareasMetaActual();
              },
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color:
                      completada ? const Color(0xFF4CAF50) : Colors.transparent,
                  border: Border.all(
                    color: completada
                        ? const Color(0xFF4CAF50)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: completada
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),

            // Info de tarea
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tarea['actividad'] ?? '',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration:
                          completada ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tarea['dia_semana']} ${tarea['hora'] ?? ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Estado emocional
            if (estadoEmocional.isNotEmpty)
              Text(estadoEmocional, style: const TextStyle(fontSize: 24))
            else
              PopupMenuButton<String>(
                icon:
                    Icon(Icons.add_reaction_outlined, color: Colors.grey[400]),
                onSelected: (emoji) async {
                  await _dbHelper.updateEstadoEmocional(
                      tarea['id_tarea'], emoji);
                  await _loadTareasMetaActual();
                },
                itemBuilder: (context) => _moodEmojis.map((emoji) {
                  return PopupMenuItem(
                    value: emoji,
                    child: Text(emoji, style: const TextStyle(fontSize: 24)),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_metaActual != null)
          FloatingActionButton(
            heroTag: 'add_task',
            onPressed: _showCrearTareaModal,
            backgroundColor: const Color(0xFF66BB6A),
            child: const Icon(Icons.add_task),
          ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'add_meta',
          onPressed: _showCrearMetaModal,
          backgroundColor: const Color(0xFF4CAF50),
          child: const Icon(Icons.flag),
        ),
      ],
    );
  }
}
