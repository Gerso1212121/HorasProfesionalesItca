import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'PomodoroScreen.dart';
import 'MetasFormularioScreen.dart';

class MetasAcademicasScreen extends StatefulWidget {
  const MetasAcademicasScreen({Key? key}) : super(key: key);

  @override
  State<MetasAcademicasScreen> createState() => _MetasAcademicasScreenState();
}

class _MetasAcademicasScreenState extends State<MetasAcademicasScreen> {
  final String moduleContent = '''# Metas y planificación académica

## Planifica tu Estudio con Inteligencia Emocional

### 1. ¿Qué es la inteligencia emocional aplicada al estudio?
La inteligencia emocional es la capacidad para reconocer y manejar tus emociones y las de los demás. En el contexto académico, te permite regular el estrés, mantener la motivación, organizar mejor tu tiempo y alcanzar tus metas con equilibrio emocional.

### 2. Habilidades emocionales que mejoran el rendimiento:

- **Autoconciencia**: Reconocer cómo te sientes antes de estudiar.
- **Autorregulación**: Gestionar la ansiedad, frustración o pereza.
- **Motivación**: Estudiar con propósito y disciplina.
- **Empatía**: Colaborar y aprender con otros.
- **Habilidades sociales**: Comunicarte efectivamente con docentes y compañeros.

### 3. Planificación académica emocionalmente inteligente

**Paso 1: Evalúa tu estado emocional antes de estudiar**
✓ ¿Cómo me siento ahora?
✓ ¿Qué necesito para concentrarme mejor?
✓ ¿Hay algo que me esté afectando emocionalmente?

**Paso 2: Define tus metas SMART (Específicas, Medibles, Alcanzables, Relevantes, Temporales)**
Ejemplo: "Estudiar 30 minutos de matemáticas, tres días esta semana para prepararme para el examen del lunes."

**Paso 3: Prioriza tus tareas**
Utiliza la matriz de Eisenhower:
- Urgente e importante: hazlo ahora.
- Importante, no urgente: planifícalo.
- Urgente, no importante: delégalo o hazlo rápido.
- No urgente ni importante: elimínalo.

**Paso 4: Usa la técnica Pomodoro**
- Trabaja 25 minutos 100% enfocado.
- Descansa 5 minutos.
- Repite 4 veces y toma un descanso largo (15-30 minutos).

**Paso 5: Reflexiona al final del día**
✓ ¿Cumplí mis metas?
✓ ¿Cómo me sentí estudiando hoy?
✓ ¿Qué mejoraría mañana?

### 4. Tips emocionales para estudiar mejor

- Estudia en bloques cortos para evitar saturarte.
- Premia tus logros con descansos saludables.
- Rodéate de mensajes motivadores (frases, imágenes, música relajante).
- Ten compasión contigo mismo si no logras todo. Ajusta, no te castigues.

### 5. Frases motivacionales

- "No tienes que ser el mejor, solo mejorar cada día."
- "Estudiar con calma es estudiar con inteligencia."
- "Tus emociones no son enemigas, sólo necesitan ser escuchadas."

### 6. Recomendación final:
Combina la organización académica con la inteligencia emocional. No basta con planificar el tiempo, también debes gestionar tu energía mental y emocional. Practica esta guía durante una semana y evalúa los cambios en tu enfoque, rendimiento y bienestar.''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2FFFF),
      body: CustomScrollView(
        slivers: [
          // App Bar personalizado
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF86A8E7),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Metas y Planificación Académica',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB2F5DB), Color(0xFF86A8E7)],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.tablet_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),

          // Contenido del módulo
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botones de acción principales
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Herramientas de Productividad',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            // Botón Pomodoro
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const PomodoroScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.timer,
                                    color: Colors.white),
                                label: Text(
                                  'Pomodoro',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF66B7D),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Botón Formulario
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const MetasFormularioScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.assignment,
                                    color: Colors.white),
                                label: Text(
                                  'Mis Metas',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Contenido en Markdown
                  Container(
                    width: double.infinity,
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
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: MarkdownBody(
                        data: moduleContent,
                        styleSheet: MarkdownStyleSheet(
                          h1: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                          h2: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                          h3: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.3,
                          ),
                          p: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black87,
                            height: 1.6,
                          ),
                          strong: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          em: GoogleFonts.inter(
                            fontStyle: FontStyle.italic,
                            color: Colors.black87,
                          ),
                          blockquote: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border(
                              left: BorderSide(
                                color: const Color(0xFF86A8E7),
                                width: 4,
                              ),
                            ),
                          ),
                          code: GoogleFonts.sourceCodePro(
                            fontSize: 14,
                            color: const Color(0xFFD32F2F),
                            backgroundColor: Colors.grey[100],
                          ),
                          codeblockDecoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          listBullet: GoogleFonts.inter(
                            fontSize: 16,
                            color: const Color(0xFF86A8E7),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Tips adicionales
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF4CAF50).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: const Color(0xFF4CAF50),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Consejo del experto',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4CAF50),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Usar el timer Pomodoro junto con un plan de metas claras puede incrementar tu productividad hasta un 40%. Empieza definiendo tus metas en el formulario y luego usa el Pomodoro para ejecutarlas.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
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
        ],
      ),
    );
  }
}
