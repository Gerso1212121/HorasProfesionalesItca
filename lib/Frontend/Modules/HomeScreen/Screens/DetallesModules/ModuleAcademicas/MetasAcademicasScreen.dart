


//* Toma el modulo local metas academicas

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:horas2/Frontend/Constants/AppConstants.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleAcademicas/SubScreens/Metas/MetasFormularioScreen.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Screens/DetallesModules/ModuleAcademicas/SubScreens/Pomodoro/POMODURO.dart';

class MetasAcademicasScreen extends StatefulWidget {
  const MetasAcademicasScreen({Key? key}) : super(key: key);

  @override
  State<MetasAcademicasScreen> createState() => _MetasAcademicasScreenState();
}

class _MetasAcademicasScreenState extends State<MetasAcademicasScreen> {
  final String moduleContent = '''#

## Planifica tu Estudio con Inteligencia Emocional

###
###

### 1. ¿Qué es la inteligencia emocional aplicada al estudio?
La inteligencia emocional es la capacidad para reconocer y manejar tus emociones y las de los demás. En el contexto académico, te permite regular el estrés, mantener la motivación, organizar mejor tu tiempo y alcanzar tus metas con equilibrio emocional.


###
###
### 2. Habilidades emocionales que mejoran el rendimiento:\n

✓ **Autoconciencia**: Reconocer cómo te sientes antes de estudiar.\n
✓ **Autorregulación**: Gestionar la ansiedad, frustración o pereza.\n
✓ **Motivación**: Estudiar con propósito y disciplina.\n
✓ **Empatía**: Colaborar y aprender con otros.\n
✓ **Habilidades sociales**: Comunicarte efectivamente con docentes y compañeros.\n

### 3. Planificación académica emocionalmente inteligente\n

**Paso 1: Evalúa tu estado emocional antes de estudiar**\n
- ¿Cómo me siento ahora?\n
- ¿Qué necesito para concentrarme mejor?\n
- ¿Hay algo que me esté afectando emocionalmente?\n

**Paso 2: Define tus metas SMART (Específicas, Medibles, Alcanzables, Relevantes, Temporales)**\n
Ejemplo: "Estudiar 30 minutos de matemáticas, tres días esta semana para prepararme para el examen del lunes."\n
###
###
**Paso 3: Prioriza tus tareas**\n
Utiliza la matriz de Eisenhower:\n
- Urgente e importante: hazlo ahora.\n
- Importante, no urgente: planifícalo.\n
- Urgente, no importante: delégalo o hazlo rápido.\n
- No urgente ni importante: elimínalo.\n
###
###
**Paso 4: Usa la técnica Pomodoro**\n
- Trabaja 25 minutos 100% enfocado.\n
- Descansa 5 minutos.\n
- Repite 4 veces y toma un descanso largo (15-30 minutos).\n
###
###
**Paso 5: Reflexiona al final del día**\n
- ¿Cumplí mis metas?\n
- ¿Cómo me sentí estudiando hoy?\n
- ¿Qué mejoraría mañana?\n
###
###
### 4. Tips emocionales para estudiar mejor\n

✓ Estudia en bloques cortos para evitar saturarte.\n
✓ Premia tus logros con descansos saludables.\n
✓ Rodéate de mensajes motivadores (frases, imágenes, música relajante).\n
✓ Ten compasión contigo mismo si no logras todo. Ajusta, no te castigues.\n

### 5. Frases motivacionales\n

✓ "No tienes que ser el mejor, solo mejorar cada día."\n
✓ "Estudiar con calma es estudiar con inteligencia."\n
✓ "Tus emociones no son enemigas, sólo necesitan ser escuchadas."\n

### 6. Recomendación final:\n
Combina la organización académica con la inteligencia emocional. No basta con planificar el tiempo, también debes gestionar tu energía mental y emocional. Practica esta guía durante una semana y evalúa los cambios en tu enfoque, rendimiento y bienestar.\n''';

  // Markdown stylesheet con fuentes mixtas (Inter para contenido, Handwriting para títulos)
  final MarkdownStyleSheet _markdownStyleSheet = MarkdownStyleSheet(
    h1: GoogleFonts.itim(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1A1A1A),
      height: 1.3,
    ),
    h2: GoogleFonts.itim(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF1A1A1A),
      height: 1.3,
    ),
    h3: GoogleFonts.itim(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.primary,
      height: 1.3,
    ),
    p: GoogleFonts.inter(
      fontSize: 14,
      color: const Color(0xFF404040),
      height: 1.6,
    ),
    strong: const TextStyle(fontWeight: FontWeight.bold),
    em: const TextStyle(fontStyle: FontStyle.italic),
    blockquote: GoogleFonts.itim(
      fontSize: 14,
      fontStyle: FontStyle.italic,
      color: const Color(0xFF86A8E7),
    ),
    blockquoteDecoration: BoxDecoration(
      color: const Color(0xFFF0F9FF),
      borderRadius: BorderRadius.circular(8),
      border: Border(
        left: BorderSide(color: const Color(0xFF86A8E7), width: 4),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FDFF),
      body: CustomScrollView(
        slivers: [
          // App Bar mejorado
          _buildAppBar(),
          // Contenido principal
          _buildContent(),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      
      expandedHeight: 150.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF86A8E7),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: EdgeInsets.only(bottom: 16, left: 6),
        title: Text(
          'Metas y Planificación',
          style: GoogleFonts.itim(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        background: Container(
          child: Center(
            child: Icon(
              Icons.trending_up_rounded,
              size: 70,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Tarjeta de herramientas
            _buildToolsCard(),
            const SizedBox(height: 20),
            // Contenido del módulo
            _buildModuleContent(),
            const SizedBox(height: 6),
            // Consejo del experto
            _buildExpertTip(),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Herramientas de Productividad',
              style: GoogleFonts.itim(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildToolButton(
                  icon: Icons.timer_outlined,
                  label: 'Pomodoro',
                  color: const Color(0xFFF66B7D),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>  PomodoroTimerScreen()),
                  ),
                ),
                const SizedBox(width: 12),
                _buildToolButton(
                  icon: Icons.assignment_outlined,
                  label: 'Mis Metas',
                  color: const Color(0xFF4CAF50),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MetasFormularioScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.itim(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleContent() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF86A8E7).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_stories_rounded,
                      color: const Color(0xFF86A8E7),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Guía completa',
                    style: GoogleFonts.itim(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              MarkdownBody(
                data: moduleContent,
                styleSheet: _markdownStyleSheet,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpertTip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: const Color(0xFF4CAF50),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Consejo del experto',
                      style: GoogleFonts.itim(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Usar el timer Pomodoro junto con un plan de metas claras puede incrementar tu productividad hasta un 40%. Empieza definiendo tus metas en el formulario y luego usa el Pomodoro para ejecutarlas.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF404040),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}