import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:uuid/uuid.dart';

class SampleDataLoader {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  /// Cargar datos de ejemplo para módulos de psicología
  static Future<void> loadSamplePsychologyModules() async {
    try {
      // Verificar si ya existen módulos
      final existingModules = await _db.readModulos();
      if (existingModules.isNotEmpty) {
        print('Ya existen módulos en la base de datos');
        return;
      }

      final now = DateTime.now();
      const uuid = Uuid();

      // Módulos de ejemplo
      final sampleModules = [
        {
          'id': uuid.v4(),
          'titulo': 'Introducción a la Mindfulness',
          'contenido': '''
# Introducción a la Mindfulness

## ¿Qué es Mindfulness?

**Mindfulness** o *atención plena* es la práctica de prestar atención al momento presente de manera consciente y sin juicio.

### Beneficios principales:

- **Reducción del estrés**: Ayuda a manejar mejor las situaciones estresantes
- **Mayor concentración**: Mejora la capacidad de enfoque
- **Bienestar emocional**: Promueve la estabilidad emocional
- **Mejor sueño**: Contribuye a un descanso más reparador

## Ejercicio básico de respiración

1. Siéntate en una posición cómoda
2. Cierra los ojos suavemente
3. Respira de manera natural
4. Observa cada inhalación y exhalación
5. Si tu mente divaga, regresa gentilmente a la respiración

> "La vida solo está disponible en el momento presente" - Thich Nhat Hanh

## Práctica diaria

Dedica al menos **5-10 minutos** diarios a esta práctica. Puedes incrementar gradualmente el tiempo conforme te sientas más cómodo.

### Consejos para principiantes:
- Comienza con sesiones cortas
- Sé paciente contigo mismo
- La constancia es más importante que la perfección
          ''',
          'fecha_creacion': now.toIso8601String(),
          'fecha_actualizacion': now.toIso8601String(),
          'sincronizado': true,
        },
        {
          'id': uuid.v4(),
          'titulo': 'Manejo del Estrés y la Ansiedad',
          'contenido': '''
# Manejo del Estrés y la Ansiedad

El estrés y la ansiedad son respuestas naturales del cuerpo, pero cuando se vuelven excesivos pueden afectar nuestra calidad de vida.

## Técnicas de manejo inmediato

### 1. Técnica 5-4-3-2-1
Identifica:
- **5 cosas** que puedes ver
- **4 cosas** que puedes tocar
- **3 cosas** que puedes escuchar
- **2 cosas** que puedes oler
- **1 cosa** que puedes saborear

### 2. Respiración profunda
- Inhala por 4 segundos
- Mantén por 4 segundos
- Exhala por 6 segundos
- Repite 5-10 veces

## Estrategias a largo plazo

### Ejercicio regular
La actividad física libera endorfinas naturales que mejoran el estado de ánimo.

### Sueño adecuado
Dormir 7-9 horas diarias es fundamental para la regulación emocional.

### Red de apoyo
Mantener conexiones sociales saludables proporciona soporte emocional.

> Recuerda: buscar ayuda profesional es siempre una opción válida y recomendada.
          ''',
          'fecha_creacion':
              now.subtract(const Duration(days: 5)).toIso8601String(),
          'fecha_actualizacion':
              now.subtract(const Duration(days: 2)).toIso8601String(),
          'sincronizado': true,
        },
        {
          'id': uuid.v4(),
          'titulo': 'Autoestima y Confianza Personal',
          'contenido': '''
# Autoestima y Confianza Personal

La autoestima es la valoración que tenemos de nosotros mismos. Es fundamental para nuestro bienestar psicológico.

## ¿Qué es la autoestima?

La autoestima incluye:
- **Autoconcepto**: Lo que pensamos sobre nosotros
- **Autoaceptación**: Cómo nos aceptamos
- **Autorespeto**: Cómo nos tratamos

## Señales de autoestima saludable

✅ Te sientes cómodo siendo tú mismo  
✅ Puedes manejar críticas constructivas  
✅ No necesitas aprobación constante  
✅ Estableces límites saludables  
✅ Celebras tus logros  

## Ejercicios para mejorar la autoestima

### 1. Diario de gratitud
Escribe 3 cosas por las que estás agradecido cada día.

### 2. Afirmaciones positivas
Repite frases como:
- "Soy valioso tal como soy"
- "Merezco respeto y amor"
- "Estoy creciendo y mejorando cada día"

### 3. Desafía pensamientos negativos
Cuando tengas un pensamiento negativo sobre ti mismo, pregúntate:
- ¿Es esto realmente cierto?
- ¿Qué evidencia tengo?
- ¿Qué le diría a un amigo en esta situación?

## Recuerda
El desarrollo de la autoestima es un proceso gradual. Sé paciente y compasivo contigo mismo.
          ''',
          'fecha_creacion':
              now.subtract(const Duration(days: 10)).toIso8601String(),
          'fecha_actualizacion':
              now.subtract(const Duration(days: 1)).toIso8601String(),
          'sincronizado': true,
        },
        {
          'id': uuid.v4(),
          'titulo': 'Relaciones Interpersonales Saludables',
          'contenido': '''
# Relaciones Interpersonales Saludables

Las relaciones saludables son fundamentales para nuestro bienestar emocional y mental.

## Características de relaciones saludables

### Comunicación efectiva
- **Escucha activa**: Prestar atención genuina
- **Expresión clara**: Comunicar necesidades y sentimientos
- **Empatía**: Entender la perspectiva del otro

### Respeto mutuo
- Valorar las diferencias
- Respetar los límites personales
- Evitar críticas destructivas

### Confianza
- Cumplir promesas
- Ser honesto y transparente
- Mantener confidencialidad

## Habilidades de comunicación

### 1. Técnica del "Yo"
En lugar de decir: *"Tú siempre llegas tarde"*  
Di: *"Yo me siento frustrado cuando llegamos tarde"*

### 2. Escucha activa
- Mantén contacto visual
- No interrumpas
- Haz preguntas aclaratorias
- Refleja lo que escuchaste

### 3. Resolución de conflictos
1. **Identifica** el problema real
2. **Expresa** tus sentimientos sin atacar
3. **Escucha** la perspectiva del otro
4. **Busca** soluciones juntos
5. **Comprométete** con acciones específicas

## Señales de alerta en relaciones

⚠️ Control excesivo  
⚠️ Falta de respeto  
⚠️ Manipulación emocional  
⚠️ Aislamiento social  
⚠️ Violencia física o verbal  

> Si identificas estas señales, busca ayuda profesional.

## Construyendo relaciones saludables

- **Invierte tiempo** en las personas importantes
- **Sé auténtico** en tus interacciones
- **Practica la gratitud** hacia otros
- **Establece límites** claros y saludables
- **Perdona** cuando sea apropiado
          ''',
          'fecha_creacion':
              now.subtract(const Duration(days: 15)).toIso8601String(),
          'fecha_actualizacion':
              now.subtract(const Duration(days: 3)).toIso8601String(),
          'sincronizado': true,
        },
        {
          'id': uuid.v4(),
          'titulo': 'Técnicas de Relajación y Meditación',
          'contenido': '''
# Técnicas de Relajación y Meditación

La relajación y meditación son herramientas poderosas para reducir el estrés y mejorar el bienestar mental.

## Beneficios de la meditación

- **Reduce el estrés** y la ansiedad
- **Mejora la concentración** y el enfoque
- **Aumenta la autoconciencia**
- **Promueve el bienestar emocional**
- **Puede mejorar el sueño**

## Técnicas de relajación

### 1. Relajación muscular progresiva
1. Acuéstate cómodamente
2. Tensa los músculos de los pies por 5 segundos
3. Relaja y siente la diferencia
4. Continúa con pantorrillas, muslos, abdomen, etc.
5. Termina con la cabeza y cuello

### 2. Visualización guiada
- Imagina un lugar tranquilo y seguro
- Usa todos tus sentidos (vista, sonidos, olores)
- Permanece en este lugar mental por 10-15 minutos
- Regresa gradualmente al presente

### 3. Meditación de respiración
1. Siéntate con la espalda recta
2. Cierra los ojos suavemente
3. Respira naturalmente
4. Cuenta las respiraciones del 1 al 10
5. Si pierdes la cuenta, vuelve a empezar

## Meditación para principiantes

### Empezar pequeño
- Comienza con **2-5 minutos** diarios
- Incrementa gradualmente el tiempo
- La constancia es más importante que la duración

### Encontrar tu momento
- **Mañana**: Para empezar el día con calma
- **Tarde**: Para hacer una pausa en el día
- **Noche**: Para relajarse antes de dormir

### Apps recomendadas
- Headspace
- Calm
- Insight Timer
- Ten Percent Happier

> "La meditación no se trata de detener los pensamientos, sino de no dejarse llevar por ellos"

## Obstáculos comunes

### "No puedo parar de pensar"
Es normal. El objetivo no es eliminar pensamientos, sino observarlos sin juzgar.

### "No tengo tiempo"
Incluso 2-3 minutos pueden ser beneficiosos. Trata de integrarlo en tu rutina existente.

### "No sé si lo estoy haciendo bien"
No hay una forma "perfecta". Si estás presente y consciente, lo estás haciendo bien.

## Crear un espacio de meditación

- **Lugar tranquilo**: Minimiza distracciones
- **Posición cómoda**: Silla o cojín
- **Ambiente**: Luz suave, temperatura agradable
- **Rutina**: Mismo horario y lugar cada día
          ''',
          'fecha_creacion':
              now.subtract(const Duration(days: 20)).toIso8601String(),
          'fecha_actualizacion':
              now.subtract(const Duration(days: 4)).toIso8601String(),
          'sincronizado': true,
        },
        {
          'id': uuid.v4(),
          'titulo': 'Inteligencia Emocional y Autorregulación',
          'contenido': '''
# Inteligencia Emocional y Autorregulación

La inteligencia emocional es la capacidad de reconocer, entender y manejar nuestras emociones de manera efectiva.

## Componentes de la inteligencia emocional

### 1. Autoconciencia emocional
- Reconocer tus emociones cuando ocurren
- Entender las causas de tus sentimientos
- Identificar la diferencia entre pensamientos y emociones

### 2. Autorregulación
- Manejar emociones difíciles de manera constructiva
- Adaptarse a los cambios
- Mantener el control en situaciones estresantes

### 3. Motivación interna
- Establecer y perseguir metas personales
- Mantener optimismo a pesar de los obstáculos
- Buscar satisfacción en logros personales

### 4. Empatía
- Entender las emociones de otros
- Mostrar sensibilidad hacia diferentes perspectivas
- Brindar apoyo emocional cuando es necesario

### 5. Habilidades sociales
- Comunicarse efectivamente
- Resolver conflictos de manera constructiva
- Trabajar en equipo y liderar cuando es necesario

## Estrategias de autorregulación

### Técnica STOP
Cuando sientas una emoción intensa:
- **S**top - Detente
- **T**ake a breath - Respira profundamente
- **O**bserve - Observa lo que sientes
- **P**roceed - Procede con intención

### Técnica del semáforo emocional
- **Rojo**: Parar, reconocer la emoción
- **Amarillo**: Pensar en opciones y consecuencias
- **Verde**: Elegir la mejor respuesta y actuar

### Diario emocional
Registra diariamente:
- ¿Qué emociones sentí hoy?
- ¿Qué las causó?
- ¿Cómo las manejé?
- ¿Qué podría hacer diferente?

## Desarrollando empatía

### Escucha activa
- Presta atención completa
- No juzgues ni interrumpas
- Haz preguntas para entender mejor
- Refleja lo que escuchaste

### Perspectiva del otro
Pregúntate:
- ¿Cómo se siente esta persona?
- ¿Qué podría estar causando sus emociones?
- ¿Cómo me sentiría yo en su situación?

## Beneficios de la inteligencia emocional

- **Mejores relaciones**: Comunicación más efectiva
- **Liderazgo**: Capacidad de inspirar y motivar
- **Resiliencia**: Mejor manejo del estrés y adversidad
- **Toma de decisiones**: Equilibrio entre lógica y emoción
- **Bienestar general**: Mayor satisfacción personal

## Ejercicios prácticos

### 1. Reconocimiento emocional
Durante el día, pregúntate cada hora: "¿Qué estoy sintiendo ahora mismo?"

### 2. Respiración consciente
Antes de reaccionar emocionalmente, toma 3 respiraciones profundas.

### 3. Reformulación positiva
Cambia pensamientos negativos por perspectivas más equilibradas.

Ejemplo:
- Negativo: "Soy terrible en esto"
- Reformulado: "Esto es desafiante, pero puedo aprender y mejorar"
          ''',
          'fecha_creacion':
              now.subtract(const Duration(days: 25)).toIso8601String(),
          'fecha_actualizacion':
              now.subtract(const Duration(days: 5)).toIso8601String(),
          'sincronizado': true,
        },
        {
          'id': uuid.v4(),
          'titulo': 'Establecimiento de Límites Saludables',
          'contenido': '''
# Establecimiento de Límites Saludables

Los límites son fundamentales para mantener relaciones saludables y proteger nuestro bienestar emocional y mental.

## ¿Qué son los límites?

Los límites son las reglas y directrices que establecemos para nosotros mismos sobre cómo queremos ser tratados por otros.

### Tipos de límites:

- **Físicos**: Espacio personal, contacto físico
- **Emocionales**: Sentimientos, pensamientos privados
- **Mentales**: Valores, opiniones, creencias
- **Digitales**: Redes sociales, tecnología
- **Tiempo**: Disponibilidad, compromisos

## Señales de límites poco saludables

### Límites demasiado rígidos:
- Dificultad para confiar en otros
- Mantener a las personas a distancia
- Evitar relaciones íntimas
- Dificultad para pedir ayuda

### Límites demasiado permeables:
- Dificultad para decir "no"
- Absorber emociones de otros
- Permitir abuso o maltrato
- Sentirse responsable por los problemas de otros

## Cómo establecer límites saludables

### 1. Identifica tus necesidades
- ¿Qué te hace sentir incómodo?
- ¿Cuándo te sientes resentido?
- ¿Qué comportamientos no toleras?

### 2. Comunica claramente
- Usa frases en primera persona
- Sé específico y directo
- Mantén un tono calmado pero firme
- Explica las consecuencias si es necesario

### 3. Mantén consistencia
- No cambies tus límites constantemente
- Hazlos cumplir de manera consistente
- No hagas excepciones por culpa o presión

## Frases útiles para establecer límites

### Para el trabajo:
- "No puedo quedarme después del horario hoy"
- "Necesito tiempo para pensar en esa propuesta"
- "Eso no está dentro de mis responsabilidades"

### Para relaciones personales:
- "Necesito algo de tiempo para mí mismo"
- "No me siento cómodo discutiendo ese tema"
- "Aprecio tu preocupación, pero puedo manejarlo"

### Para familiares:
- "Respeto tu opinión, pero he tomado mi decisión"
- "No voy a participar en esa conversación"
- "Necesito que respetes mi elección"

## Desafíos comunes

### Culpa
Es normal sentir culpa al principio. Recuerda que establecer límites es un acto de autocuidado, no de egoísmo.

### Resistencia de otros
Algunas personas pueden no respetar tus límites inicialmente. Mantente firme y consistente.

### Miedo al rechazo
Teme que establecer límites aleje a las personas. Las relaciones saludables respetan los límites.

## Límites digitales

### En redes sociales:
- Limita el tiempo de pantalla
- No compartes información personal excesiva
- Bloquea o silencia contenido negativo
- No respondas inmediatamente a todos los mensajes

### En el trabajo remoto:
- Establece horarios específicos
- Crea un espacio de trabajo dedicado
- No revises correos fuera del horario laboral
- Comunica tu disponibilidad claramente

## Autocuidado y límites

### Límites contigo mismo:
- No te critiques excesivamente
- Establece expectativas realistas
- Date tiempo para descansar
- Perdónate por los errores

### Práctica regular:
- Revisa y ajusta tus límites regularmente
- Celebra cuando mantienes tus límites
- Busca apoyo cuando sea difícil
- Practica la autocompasión

> Recuerda: Establecer límites no es construir muros, es construir puertas con cerraduras a las que solo tú tienes la llave.
          ''',
          'fecha_creacion':
              now.subtract(const Duration(days: 30)).toIso8601String(),
          'fecha_actualizacion':
              now.subtract(const Duration(days: 6)).toIso8601String(),
          'sincronizado': true,
        },
      ];

    // Insertar módulos en la base de datos local
    for (final module in sampleModules) {
      await _db.createModulo(
        id: module['id'] as String,
        titulo: module['titulo'] as String,
        contenido: module['contenido'] as String,
        fechaCreacion: DateTime.parse(module['fecha_creacion'] as String),
        fechaActualizacion:
            DateTime.parse(module['fecha_actualizacion'] as String),
        sincronizado: module['sincronizado'] as bool, // Ya es int, no necesita conversión
      );
    }

    print('Módulos de ejemplo cargados exitosamente');
  } catch (e) {
    print('Error cargando módulos de ejemplo: $e');
  }
  }

 

  /// Sincronizar y cargar todos los datos de ejemplo
  static Future<void> loadAllSampleData() async {
    await loadSamplePsychologyModules();
   }

  /// Limpiar todos los datos de ejemplo
  static Future<void> clearAllSampleData() async {
    try {
      await _db.clearLocalData();
      print('Datos de ejemplo eliminados');
    } catch (e) {
      print('Error eliminando datos de ejemplo: $e');
    }
  }
}
