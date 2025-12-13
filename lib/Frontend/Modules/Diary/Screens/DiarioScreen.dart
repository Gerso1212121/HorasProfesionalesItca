import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Modules/Diary/Screens/NoteScreen.dart';
import 'package:horas2/Frontend/Modules/Profile/Screens/ProfileScreen.dart';
import 'package:intl/intl.dart';

class DiarioScreen extends StatefulWidget {
  const DiarioScreen({super.key});

  @override
  State<DiarioScreen> createState() => _DiarioScreenState();
}

class _DiarioScreenState extends State<DiarioScreen> {
  // Datos de ejemplo mejorados
  final List<Map<String, dynamic>> _entradas = [
    {
      'id': 1,
      'fecha': DateTime(2024, 2, 15),
      'titulo': 'Un día increíble en la playa',
      'contenido': 'Hoy fue un día maravilloso lleno de aprendizajes y momentos especiales que quiero recordar siempre. El atardecer fue espectacular...',
      'emoji': '😊',
      'imagenes': 3,
      'hora': '10:30 AM',
      'colorSet': 0,
    },
    {
      'id': 2,
      'fecha': DateTime(2024, 2, 14),
      'titulo': 'Reflexiones nocturnas',
      'contenido': 'Estaba pensando en lo rápido que pasa el tiempo y en todas las cosas que quiero lograr este año. Necesito enfocarme más...',
      'emoji': '🤔',
      'imagenes': 1,
      'hora': '11:15 PM',
      'colorSet': 1,
    },
    {
      'id': 3,
      'fecha': DateTime(2024, 2, 13),
      'titulo': 'Día productivo en el trabajo',
      'contenido': 'Terminé todos mis pendientes y me siento muy satisfecho con lo que logré hoy en el proyecto nuevo. El equipo colaboró excelentemente...',
      'emoji': '🚀',
      'imagenes': 2,
      'hora': '6:45 PM',
      'colorSet': 2,
    },
    {
      'id': 4,
      'fecha': DateTime(2024, 2, 12),
      'titulo': 'Cena familiar especial',
      'contenido': 'Hoy nos reunimos toda la familia después de mucho tiempo. Fue emocionante ver a todos juntos y compartir historias...',
      'emoji': '❤️',
      'imagenes': 4,
      'hora': '8:20 PM',
      'colorSet': 3,
    },
    {
      'id': 5,
      'fecha': DateTime(2024, 2, 11),
      'titulo': 'Aprendizaje constante',
      'contenido': 'Hoy dediqué tiempo a aprender nuevas habilidades. Me enfoqué en desarrollo personal y encontré recursos increíbles...',
      'emoji': '📚',
      'imagenes': 0,
      'hora': '4:30 PM',
      'colorSet': 0,
    },
  ];

  // Conjuntos de colores para las tarjetas
  final List<Map<String, dynamic>> _colorSets = [
    {
      'primary': Color(0xFF4285F4),
      'light': Color(0xFFE8F0FE),
      'accent': Color(0xFFD2E3FC),
      'text': Color(0xFF1A73E8),
      'badge': Color(0xFF4285F4),
    },
    {
      'primary': Color(0xFF34A853),
      'light': Color(0xFFE6F4EA),
      'accent': Color(0xFFCEEAD6),
      'text': Color(0xFF188038),
      'badge': Color(0xFF34A853),
    },
    {
      'primary': Color(0xFFFBBC05),
      'light': Color(0xFFFEF7E0),
      'accent': Color(0xFFFEEFC3),
      'text': Color(0xFFF9AB00),
      'badge': Color(0xFFFBBC05),
    },
    {
      'primary': Color(0xFFEA4335),
      'light': Color(0xFFFCE8E6),
      'accent': Color(0xFFFAD2CF),
      'text': Color(0xFFD93025),
      'badge': Color(0xFFEA4335),
    },
    {
      'primary': Color(0xFF8E24AA),
      'light': Color(0xFFF3E5F5),
      'accent': Color(0xFFE1BEE7),
      'text': Color(0xFF7B1FA2),
      'badge': Color(0xFF8E24AA),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header elegante
          SliverAppBar(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            floating: true,
            snap: true,
            expandedHeight: 140,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF4285F4).withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            title: Text(
              'Mi Diario',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A237E),
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.calendar_month_rounded,
                      color: const Color(0xFF4285F4), size: 22),
                  onPressed: () {
                    // Acción del calendario
                  },
                ),
              ),
            ],
          ),

          // Filtros y estadísticas
          SliverToBoxAdapter(
            child: _buildStatsHeader(),
          ),

          // Lista de entradas
          if (_entradas.isEmpty)
            SliverFillRemaining(
              child: _buildEmptyState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return _buildDiaryCard(_entradas[index]);
                  },
                  childCount: _entradas.length,
                ),
              ),
            ),

          // Espacio al final
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),

      // Botón de nueva entrada
floatingActionButton: FloatingActionButton.extended(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteScreen(),
      ),
    );
  },
  backgroundColor: const Color(0xFF4285F4),
  foregroundColor: Colors.white,
  elevation: 8,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  icon: const Icon(Icons.edit_note_rounded, size: 22),
  label: Text(
    'Nueva entrada',
    style: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  ),
),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildStatsHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estadísticas
          Row(
            children: [
              _buildStatItem(
                icon: Icons.book_rounded,
                value: _entradas.length.toString(),
                label: 'Entradas',
                color: const Color(0xFF4285F4),
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                icon: Icons.photo_library_rounded,
                value: _entradas
                    .fold(0, (sum, entry) => sum + (entry['imagenes'] as int))
                    .toString(),
                label: 'Fotos',
                color: const Color(0xFF34A853),
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                icon: Icons.emoji_emotions_rounded,
                value: _entradas.length > 0
                    ? _entradas.last['emoji']
                    : '😊',
                label: 'Hoy',
                color: const Color(0xFFFBBC05),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Título de sección
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tus recuerdos',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A237E),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 14,
                      color: const Color(0xFF4285F4),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Filtrar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4285F4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[100]!,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A237E),
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaryCard(Map<String, dynamic> entry) {
    final colors = _colorSets[entry['colorSet']];
    final fecha = entry['fecha'] as DateTime;
    final esHoy = fecha.day == DateTime.now().day &&
        fecha.month == DateTime.now().month &&
        fecha.year == DateTime.now().year;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: colors['light'] as Color,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con fecha y emoji
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Badge de fecha
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors['light'] as Color,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: (colors['primary'] as Color).withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: colors['primary'] as Color,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              esHoy ? 'HOY' : DateFormat('dd').format(fecha),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: colors['primary'] as Color,
                              ),
                            ),
                            if (!esHoy)
                              Text(
                                DateFormat('MMM', 'es_ES').format(fecha).toUpperCase(),
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: (colors['primary'] as Color).withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Emoji en círculo
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors['accent'] as Color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors['primary'] as Color,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (colors['primary'] as Color).withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        entry['emoji'],
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Título
              Text(
                entry['titulo'],
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A237E),
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Contenido
              Text(
                entry['contenido'],
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF5A5A5A),
                  height: 1.5,
                  letterSpacing: 0.1,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Miniaturas de imágenes (si existen)
              if ((entry['imagenes'] as int) > 0) ...[
                const SizedBox(height: 16),
                _buildImageThumbnails(entry['imagenes'], colors['accent'] as Color),
              ],

              const SizedBox(height: 16),

              // Footer con acciones
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Hora y etiqueta
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors['light'] as Color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: colors['text'] as Color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          entry['hora'],
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors['text'] as Color,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Botón de acción
                  GestureDetector(
                    onTap: () {
                      // Navegar a detalle
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: colors['primary'] as Color,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (colors['primary'] as Color).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Leer más',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ],
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

  Widget _buildImageThumbnails(int count, Color accentColor) {
    // Colores para las miniaturas
    final placeholderColors = [
      accentColor.withOpacity(0.3),
      accentColor.withOpacity(0.4),
      accentColor.withOpacity(0.5),
      accentColor.withOpacity(0.6),
    ];

    return SizedBox(
      height: 70,
      child: Row(
        children: [
          // Miniaturas
          for (int i = 0; i < (count > 4 ? 4 : count); i++)
            Container(
              margin: EdgeInsets.only(right: 8),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: placeholderColors[i % placeholderColors.length],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.photo_rounded,
                  color: Colors.white.withOpacity(0.8),
                  size: 24,
                ),
              ),
            ),

          // Indicador de más imágenes
          if (count > 4)
            Container(
              margin: const EdgeInsets.only(left: 4),
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  '+${count - 4}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustración
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF4285F4).withOpacity(0.1),
                  const Color(0xFF34A853).withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.bookmark_add_rounded,
                size: 80,
                color: const Color(0xFF4285F4),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Texto motivacional
          Text(
            'Tu diario personal',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A237E),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Comienza a documentar tus días,\nreflexiones y momentos especiales',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          // Beneficios
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildBenefitItem(
                  icon: Icons.auto_awesome_rounded,
                  text: 'Reflexiona sobre tu crecimiento',
                  color: const Color(0xFF4285F4),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  icon: Icons.photo_library_rounded,
                  text: 'Guarda fotos de momentos especiales',
                  color: const Color(0xFF34A853),
                ),
                const SizedBox(height: 12),
                _buildBenefitItem(
                  icon: Icons.timeline_rounded,
                  text: 'Visualiza tu progreso personal',
                  color: const Color(0xFFFBBC05),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF5A5A5A),
            ),
          ),
        ),
      ],
    );
  }
}