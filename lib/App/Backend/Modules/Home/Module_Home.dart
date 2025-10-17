import 'package:ai_app_tests/App/Backend/Modules/Module_ChatIA.dart';
import 'package:ai_app_tests/App/Backend/Modules/Home/Module_Diary.dart';
import 'package:ai_app_tests/Frontend/Widgets/ACTIVIY_CARDCHAT.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Data/DataBase/DatabaseHelper.dart';
import '../../../../Frontend/Widgets/ACTIVITY_CARD.dart';
import '../../../../Frontend/Widgets/CalendarWidget.dart';
import '../../../../Frontend/Widgets/PsychologyCardWidget.dart';
import '../../../../Frontend/Widgets/MODULODETAILSSCREEN.dart';
import '../../../Services/SampleDataLoader.dart';
import '../../../../Frontend/Screens/MetasAcademicasScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showCalendar = false;
  DateTime? _selectedDay = DateTime.now();
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _psychologyModulos = [];
  bool _isLoadingPsychology = true;

  @override
  void initState() {
    super.initState();
    _loadPsychologyModulos();
  }

  Future<void> _syncPsychologyData() async {
    try {
      // Mostrar indicador de carga
      setState(() => _isLoadingPsychology = true);

      // Sincronizar con Supabase
      await _databaseHelper.syncAllData();

      // Recargar datos locales
      final modulos = await _databaseHelper.readModulos();
      setState(() {
        _psychologyModulos = modulos
            .take(4)
            .toList(); // Reducido a 4 para dar espacio al módulo estático
        _isLoadingPsychology = false;
      });

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos sincronizados correctamente'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoadingPsychology = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al sincronizar: $e'),
            backgroundColor: const Color(0xFFF44336),
          ),
        );
      }
    }
  }

  Future<void> _loadPsychologyModulos() async {
    setState(() => _isLoadingPsychology = true);
    try {
      // Primero intentar cargar desde Supabase
      final modulos = await _databaseHelper.readModulos();

      // Si no hay módulos, cargar datos de ejemplo
      if (modulos.isEmpty) {
        await SampleDataLoader.loadSamplePsychologyModules();
        // Volver a cargar después de insertar datos de ejemplo
        final modulosConEjemplos = await _databaseHelper.readModulos();
        setState(() {
          _psychologyModulos =
              modulosConEjemplos.take(4).toList(); // Reducido a 4
          _isLoadingPsychology = false;
        });
      } else {
        // Tomar solo los primeros 4 módulos para dar espacio al módulo estático
        setState(() {
          _psychologyModulos = modulos.take(4).toList();
          _isLoadingPsychology = false;
        });
      }
    } catch (e) {
      print('Error cargando módulos de psicología: $e');
      setState(() => _isLoadingPsychology = false);
    }
  }

  void _toggleCalendar() {
    setState(() {
      _showCalendar = !_showCalendar;
    });
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
    });
  }

  String _getMonthName(int month) {
    const months = [
      'enero',
      'febrero',
      'marzo',
      'abril',
      'mayo',
      'junio',
      'julio',
      'agosto',
      'septiembre',
      'octubre',
      'noviembre',
      'diciembre'
    ];
    return months[month - 1];
  }

  Widget _buildMetasAcademicasCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MetasAcademicasScreen(),
          ),
        );
      },
      child: Container(
        width: 280,
        height: 200,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8), // Verde suave
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge "DESTACADO"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'DESTACADO',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.star,
                      color: Color(0xFF4CAF50),
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Título fijo
              Text(
                "Metas y planificación académica",
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Descripción fija
              Expanded(
                child: Text(
                  'Aprende a planificar tu estudio con inteligencia emocional y técnicas efectivas como la matriz de Eisenhower y Pomodoro.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black54,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 8),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Módulo guía',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF4CAF50),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Leer ahora',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DatabaseHelper dbHelper = DatabaseHelper.instance;
    final usuarioFuture = dbHelper
        .getEstudiantePorUID(FirebaseAuth.instance.currentUser?.uid ?? '');
    final String fraseMotivacional =
        "Cada día es una nueva oportunidad para crecer.";

    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(140),
                ),
              ),
              padding: const EdgeInsets.only(top: 100, bottom: 24),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _toggleCalendar,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF66B7D),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _showCalendar
                                  ? 'Frase diaria'
                                  : '${_selectedDay!.day.toString().padLeft(2, '0')} de ${_getMonthName(_selectedDay!.month)} de ${_selectedDay!.year}',
                              style: GoogleFonts.itim(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_showCalendar)
                    CalendarWidget(
                      selectedDay: _selectedDay!,
                      onDaySelected: _onDaySelected,
                      onClose: () => setState(() => _showCalendar = false),
                    )
                  else
                    Column(
                      children: [
                        // Bienvenida con datos del usuario
                        FutureBuilder<Map<String, dynamic>?>(
                          future: usuarioFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text(
                                '¡Bienvenido!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              );
                            } else if (snapshot.hasError) {
                              return Text(
                                '¡Bienvenido!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              );
                            } else {
                              final usuario = snapshot.data;
                              return Text(
                                '¡Bienvenido, ${usuario?['nombre'] ?? 'Usuario'}!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        // Mascota
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/cerebron.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Text(
                                'Frase motivacional del día',
                                style: GoogleFonts.itim(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                fraseMotivacional,
                                style: GoogleFonts.itim(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Diario(),
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF66B7D),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 6,
                                  shadowColor:
                                      const Color.fromARGB(100, 246, 107, 125),
                                ),
                                child: Text(
                                  'Iniciar diario',
                                  style: GoogleFonts.itim(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sección de Psicología
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Psicología',
                        style: GoogleFonts.itim(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: _isLoadingPsychology
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _psychologyModulos.length +
                                1, // +1 for the static card
                            itemBuilder: (context, index) {
                              // First item is always the static card
                              if (index == 0) {
                                // Retornamos la card fija usando el método auxiliar
                                return _buildMetasAcademicasCard(context);
                              }

                              // Other items are dynamic modules (adjusted index)
                              final adjustedIndex = index - 1;
                              if (adjustedIndex < _psychologyModulos.length) {
                                final modulo =
                                    _psychologyModulos[adjustedIndex];
                                return PsychologyCardWidget(
                                  modulo: modulo,
                                  index: adjustedIndex +
                                      1, // Offset by 1 to maintain color pattern
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ModuloDetailScreen(
                                          modulo: modulo,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }

                              // If no modules available, show empty state
                              return Container(
                                width: 280,
                                height: 200,
                                margin: const EdgeInsets.only(right: 16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.psychology_outlined,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No hay más módulos',
                                        style: GoogleFonts.itim(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 30),
                  // Sección de Chats Recientes
                  Text(
                    'Chats Recientes',
                    style: GoogleFonts.itim(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        ActivityChatCard(
                          topic: 'Bienestar Emocional',
                          summary:
                              'Hablamos sobre el balance emocional y estrategias para mantener una mentalidad positiva en el día a día...',
                          backgroundColor: Color(0xFFFFF2CC),
                          emojiIcon: '😊',
                        ),
                        ActivityChatCard(
                          topic: 'Conversación Anterior',
                          summary:
                              'Discusión sobre prácticas de mindfulness y meditación guiada para mejorar la concentración y reducir la ansiedad...',
                          backgroundColor: Color(0xFFD0E5F8),
                          customIcon: Icons.self_improvement_rounded,
                        ),
                        ActivityChatCard(
                          topic: 'Metas Personales',
                          summary:
                              'Conversación acerca de establecer objetivos realistas y planificar pasos concretos para alcanzar tus metas...',
                          backgroundColor: Color(0xFFE8D7FF),
                          emojiIcon: '🎯',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: const MascotaFlotanteExpandible(),
    );
  }
}

// Widget flotante de la mascota (de home.dart original)
class MascotaFlotanteExpandible extends StatefulWidget {
  const MascotaFlotanteExpandible({super.key});

  @override
  State<MascotaFlotanteExpandible> createState() =>
      _MascotaFlotanteExpandibleState();
}

class _MascotaFlotanteExpandibleState extends State<MascotaFlotanteExpandible>
    with SingleTickerProviderStateMixin {
  bool _expandido = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _expandido = !_expandido;
      _expandido ? _controller.forward() : _controller.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_expandido) ...[
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatAi()),
              );
            },
            icon: const Icon(Icons.chat_bubble, color: Colors.white),
            label:
                const Text("Ir al Chat", style: TextStyle(color: Colors.white)),
            heroTag: 'chatBtn',
            backgroundColor: const Color(0xFFF66B7D),
          ),
          const SizedBox(height: 10),
        ],
        FloatingActionButton(
          onPressed: _toggleExpand,
          backgroundColor: Colors.transparent,
          elevation: 0,
          heroTag: 'mascotaBtn',
          mini: false,
          child: Image.asset(
            'assets/images/cerebron.png',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}
