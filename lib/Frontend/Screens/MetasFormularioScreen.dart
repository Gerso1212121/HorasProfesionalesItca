import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetasFormularioScreen extends StatefulWidget {
  const MetasFormularioScreen({Key? key}) : super(key: key);

  @override
  State<MetasFormularioScreen> createState() => _MetasFormularioScreenState();
}

class _MetasFormularioScreenState extends State<MetasFormularioScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para META SMART
  final TextEditingController _specificController = TextEditingController();
  final TextEditingController _measurableController = TextEditingController();
  final TextEditingController _achievableController = TextEditingController();
  final TextEditingController _relevantController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // Controllers para checklist diario
  final List<Map<String, dynamic>> _dailyTasks = List.generate(7, (index) {
    final days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return {
      'day': days[index],
      'task': TextEditingController(),
      'time': TextEditingController(),
      'completed': false,
      'mood': '',
      'isExpanded': false, // Nuevo: para controlar expansión
    };
  });

  // Controllers para evaluación semanal
  final TextEditingController _weeklyReflectionController = TextEditingController();
  final TextEditingController _helpfulFactorsController = TextEditingController();
  final TextEditingController _improvementsController = TextEditingController();
  final TextEditingController _motivationalPhraseController = TextEditingController();

  String _weeklyGoalAchieved = '';
  DateTime _weekStart = DateTime.now();
  DateTime _weekEnd = DateTime.now().add(const Duration(days: 6));

  final List<String> _moodEmojis = ['😃', '😊', '😐', '😔', '😟', '😌', '🤔', '😴'];
  final List<String> _activityIcons = ['🏃', '💼', '📚', '🎨', '🎵', '🧘', '🍎', '👨‍💻', '🧹', '🛌'];
  final List<String> _activityTypes = ['Ejercicio', 'Trabajo', 'Estudio', 'Creatividad', 'Música', 'Meditación', 'Alimentación', 'Tecnología', 'Limpieza', 'Descanso'];

  @override
  void initState() {
    super.initState();
    _calculateWeekDates();
  }

  void _calculateWeekDates() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    setState(() {
      _weekStart = monday;
      _weekEnd = monday.add(const Duration(days: 6));
    });
  }

  @override
  void dispose() {
    _specificController.dispose();
    _measurableController.dispose();
    _achievableController.dispose();
    _relevantController.dispose();
    _timeController.dispose();
    _weeklyReflectionController.dispose();
    _helpfulFactorsController.dispose();
    _improvementsController.dispose();
    _motivationalPhraseController.dispose();

    for (var task in _dailyTasks) {
      (task['task'] as TextEditingController).dispose();
      (task['time'] as TextEditingController).dispose();
    }

    super.dispose();
  }

  String _formatDate(DateTime date) {
    final months = [
      'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
      'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'
    ];
    return '${date.day} de ${months[date.month - 1]}';
  }

  void _showActivityPicker(int taskIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Selecciona un tipo de actividad',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.9,
              ),
              itemCount: _activityTypes.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    final task = _dailyTasks[taskIndex];
                    (task['task'] as TextEditingController).text = _activityTypes[index];
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _activityIcons[index],
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _activityTypes[index],
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(int taskIndex) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((selectedTime) {
      if (selectedTime != null) {
        final task = _dailyTasks[taskIndex];
        (task['time'] as TextEditingController).text = selectedTime.format(context);
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      appBar: AppBar(
        title: Text(
          'Planificador Semanal',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showTips,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado con fechas de la semana
              _buildWeekHeader(),

              const SizedBox(height: 24),

              // META SMART Section
              _buildSectionTitle('🎯 Meta SMART de la semana'),
              _buildSmartGoalSection(),

              const SizedBox(height: 24),

              // Checklist Diario Section
              _buildSectionTitle('✅ Checklist Diario'),
              _buildDailyChecklistSection(),

              const SizedBox(height: 24),

              // Evaluación Semanal Section
              _buildSectionTitle('📈 Evaluación semanal'),
              _buildWeeklyEvaluationSection(),

              const SizedBox(height: 24),

              // Botón para guardar
              _buildSaveButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4CAF50),
            const Color(0xFF45a049),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Semana Actual',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(_weekStart)} - ${_formatDate(_weekEnd)}',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${DateTime.now().difference(_weekStart).inDays + 1}° día de la semana',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF2E7D32),
        ),
      ),
    );
  }

  Widget _buildSmartGoalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFE8F5E9),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSmartField(
            'Específica',
            '¿Qué quieres lograr exactamente?',
            Icons.bubble_chart,
            _specificController,
          ),
          _buildSmartField(
            'Medible',
            '¿Cómo medirás tu progreso?',
            Icons.analytics,
            _measurableController,
          ),
          _buildSmartField(
            'Alcanzable',
            '¿Es realista para ti?',
            Icons.flag,
            _achievableController,
          ),
          _buildSmartField(
            'Relevante',
            '¿Por qué es importante?',
            Icons.star,
            _relevantController,
          ),
          _buildSmartField(
            'Temporal',
            '¿Para cuándo lo completarás?',
            Icons.access_time,
            _timeController,
          ),
        ],
      ),
    );
  }

  Widget _buildSmartField(
      String label, String hint, IconData icon, TextEditingController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                hintText: hint,
                border: InputBorder.none,
                labelStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              maxLines: 2,
              style: GoogleFonts.inter(fontSize: 14),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChecklistSection() {
    return Column(
      children: [
        // Header con estadísticas
        _buildDailyStats(),
        const SizedBox(height: 16),
        
        // Lista de días
        ...List.generate(_dailyTasks.length, (index) {
          return _buildInteractiveTaskCard(_dailyTasks[index], index);
        }),
        
        // Botón para agregar actividad rápida
        _buildQuickAddButton(),
      ],
    );
  }

  Widget _buildDailyStats() {
    final completedTasks = _dailyTasks.where((task) => task['completed']).length;
    final totalTasks = _dailyTasks.where((task) => (task['task'] as TextEditingController).text.isNotEmpty).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('${_dailyTasks.length}', 'Días', Icons.calendar_today),
          _buildStatItem('$totalTasks', 'Actividades', Icons.list),
          _buildStatItem('$completedTasks', 'Completadas', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF4CAF50),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInteractiveTaskCard(Map<String, dynamic> taskData, int index) {
    final isExpanded = taskData['isExpanded'] as bool;
    final hasActivity = (taskData['task'] as TextEditingController).text.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () {
            setState(() {
              taskData['isExpanded'] = !isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header del día
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4CAF50).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        taskData['day'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (hasActivity)
                      Icon(
                        taskData['completed'] ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: taskData['completed'] ? const Color(0xFF4CAF50) : Colors.grey,
                      ),
                    const SizedBox(width: 8),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                    ),
                  ],
                ),

                if (hasActivity) const SizedBox(height: 12),

                // Contenido cuando hay actividad
                if (hasActivity && !isExpanded)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          (taskData['task'] as TextEditingController).text,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            decoration: taskData['completed'] 
                                ? TextDecoration.lineThrough 
                                : TextDecoration.none,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if ((taskData['time'] as TextEditingController).text.isNotEmpty)
                        Text(
                          (taskData['time'] as TextEditingController).text,
                          style: GoogleFonts.inter(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),

                // Contenido expandido
                if (isExpanded) ...[
                  const SizedBox(height: 16),
                  
                  // Selector de actividad
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showActivityPicker(index),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add_circle_outline, 
                                    color: const Color(0xFF4CAF50), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    (taskData['task'] as TextEditingController).text.isEmpty
                                        ? 'Seleccionar actividad'
                                        : (taskData['task'] as TextEditingController).text,
                                    style: GoogleFonts.inter(
                                      color: (taskData['task'] as TextEditingController).text.isEmpty
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Selector de hora
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _showTimePicker(index),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, 
                                    color: const Color(0xFF4CAF50), size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  (taskData['time'] as TextEditingController).text.isEmpty
                                      ? 'Seleccionar hora'
                                      : (taskData['time'] as TextEditingController).text,
                                  style: GoogleFonts.inter(
                                    color: (taskData['time'] as TextEditingController).text.isEmpty
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Estado emocional
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Cómo te sentiste?',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _moodEmojis.map((emoji) {
                          final isSelected = taskData['mood'] == emoji;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                taskData['mood'] = isSelected ? '' : emoji;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF4CAF50).withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4CAF50)
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Botones de acción
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              taskData['completed'] = !taskData['completed'];
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: taskData['completed'] 
                                ? Colors.grey 
                                : const Color(0xFF4CAF50),
                            side: BorderSide(
                              color: taskData['completed'] 
                                  ? Colors.grey 
                                  : const Color(0xFF4CAF50),
                            ),
                          ),
                          child: Text(
                            taskData['completed'] ? 'Marcar como pendiente' : 'Marcar como completada',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            (taskData['task'] as TextEditingController).clear();
                            (taskData['time'] as TextEditingController).clear();
                            taskData['completed'] = false;
                            taskData['mood'] = '';
                          });
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
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
  }

  Widget _buildQuickAddButton() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey[300]!),
        ),
        child: InkWell(
          onTap: _showQuickAddDialog,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: const Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                Text(
                  'Agregar actividad rápida',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickAddDialog() {
    String selectedActivity = '';
    String selectedTime = '';
    List<bool> selectedDays = List.generate(7, (index) => false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar actividad rápida', style: GoogleFonts.inter()),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector de actividad
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(20),
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: _activityTypes.length,
                        itemBuilder: (context, index) => InkWell(
                          onTap: () {
                            selectedActivity = _activityTypes[index];
                            Navigator.pop(context);
                            setState(() {});
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_activityIcons[index], style: const TextStyle(fontSize: 24)),
                              Text(_activityTypes[index], 
                                  style: GoogleFonts.inter(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.add_circle_outline, color: const Color(0xFF4CAF50)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          selectedActivity.isEmpty ? 'Seleccionar actividad' : selectedActivity,
                          style: GoogleFonts.inter(
                            color: selectedActivity.isEmpty ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Selector de hora
              InkWell(
                onTap: () {
                  showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  ).then((time) {
                    if (time != null) {
                      selectedTime = time.format(context);
                      setState(() {});
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: const Color(0xFF4CAF50)),
                      const SizedBox(width: 8),
                      Text(
                        selectedTime.isEmpty ? 'Seleccionar hora' : selectedTime,
                        style: GoogleFonts.inter(
                          color: selectedTime.isEmpty ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Selector de días
              Text('Seleccionar días:', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: List.generate(7, (index) {
                  final days = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
                  return FilterChip(
                    label: Text(days[index]),
                    selected: selectedDays[index],
                    onSelected: (selected) {
                      selectedDays[index] = selected;
                      setState(() {});
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: const Color(0xFF4CAF50).withOpacity(0.2),
                    checkmarkColor: const Color(0xFF4CAF50),
                  );
                }),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () {
              for (int i = 0; i < selectedDays.length; i++) {
                if (selectedDays[i]) {
                  final task = _dailyTasks[i];
                  (task['task'] as TextEditingController).text = selectedActivity;
                  (task['time'] as TextEditingController).text = selectedTime;
                }
              }
              Navigator.pop(context);
              setState(() {});
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4CAF50)),
            child: Text('Agregar', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyEvaluationSection() {
    // ... (mantener la misma implementación de la evaluación semanal)
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
          Text(
            '¿Lograste tu meta SMART?',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildGoalAchievementOption('Sí'),
              _buildGoalAchievementOption('Parcialmente'),
              _buildGoalAchievementOption('No'),
            ],
          ),

          const SizedBox(height: 20),

          TextFormField(
            controller: _helpfulFactorsController,
            decoration: InputDecoration(
              labelText: '¿Qué te ayudó más a lograrlo?',
              hintText: 'Usar Pomodoro, tener horarios claros, evitar distracciones...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _improvementsController,
            decoration: InputDecoration(
              labelText: '¿Qué puedes mejorar la próxima semana?',
              hintText: 'Planificar mejor, cambiar horarios, usar nuevas estrategias...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
            ),
            maxLines: 2,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _weeklyReflectionController,
            decoration: InputDecoration(
              labelText: 'Reflexión de la semana',
              hintText: '¿Cómo te sentiste esta semana? ¿Qué aprendiste?',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _motivationalPhraseController,
            decoration: InputDecoration(
              labelText: 'Frase motivadora para esta semana',
              hintText: '"Cada paso cuenta hacia mi objetivo"',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4CAF50)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalAchievementOption(String option) {
    final isSelected = _weeklyGoalAchieved == option;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _weeklyGoalAchieved = option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF4CAF50).withOpacity(0.2)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
              width: 2,
            ),
          ),
          child: Text(
            option,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? const Color(0xFF4CAF50) : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _savePlanner,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Guardar Planificación',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('💡 Tips para tu planificación', style: GoogleFonts.inter()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTipItem('🎯', 'Define metas claras y específicas'),
              _buildTipItem('⏰', 'Establece horarios realistas'),
              _buildTipItem('📝', 'Divide tareas grandes en pasos pequeños'),
              _buildTipItem('🔄', 'Revisa y ajusta tu plan regularmente'),
              _buildTipItem('🎉', 'Celebra tus logros por pequeños que sean'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Entendido', style: GoogleFonts.inter(color: const Color(0xFF4CAF50))),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: GoogleFonts.inter())),
        ],
      ),
    );
  }

  void _savePlanner() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Planificación guardada exitosamente',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      _showSaveSummary();
    }
  }

  void _showSaveSummary() {
    // ... (mantener la misma implementación)
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Resumen de tu Planificación', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Meta SMART definida: ✓', style: GoogleFonts.inter(color: const Color(0xFF4CAF50))),
                Text('Actividades semanales: ${_dailyTasks.where((task) => (task['task'] as TextEditingController).text.isNotEmpty).length}/7', style: GoogleFonts.inter()),
                Text('Tareas completadas: ${_dailyTasks.where((task) => task['completed']).length}', style: GoogleFonts.inter()),
                if (_weeklyGoalAchieved.isNotEmpty)
                  Text('Evaluación: $_weeklyGoalAchieved', style: GoogleFonts.inter()),
                const SizedBox(height: 12),
                Text(
                  'Recuerda revisar tu progreso regularmente y usar el timer Pomodoro para ejecutar tus tareas planificadas.',
                  style: GoogleFonts.inter(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Entendido', style: GoogleFonts.inter(color: const Color(0xFF4CAF50))),
            ),
          ],
        );
      },
    );
  }
}