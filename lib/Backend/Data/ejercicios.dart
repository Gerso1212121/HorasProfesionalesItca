// Modelos auxiliares para el servicio
import 'package:firebase_auth/firebase_auth.dart';
import 'package:horas2/Backend/Data/modalejercicio.dart';
import 'package:horas2/DB/DatabaseHelper.dart';

enum CategoriaEjercicio {
  reduccionAnsiedad,
  gestionEstres,
  bienestarGeneral,
  mejoraAutoestima,
  relajacion, // ya está bien
  emocional, // ya está bien
}

extension CategoriaEjercicioExtension on CategoriaEjercicio {
  String get nombre {
    switch (this) {
      case CategoriaEjercicio.reduccionAnsiedad:
        return 'Reducción de Ansiedad';
      case CategoriaEjercicio.gestionEstres:
        return 'Gestión del Estrés';
      case CategoriaEjercicio.bienestarGeneral:
        return 'Bienestar General';
      case CategoriaEjercicio.mejoraAutoestima:
        return 'Mejora de Autoestima';
      case CategoriaEjercicio.relajacion:
        return 'Relajación';
      case CategoriaEjercicio.emocional:
        return 'Gestión Emocional';
    }
  }
}

class RecomendacionEjercicio {
  final EjercicioPsicologico ejercicio;
  final double puntuacionRecomendacion;
  final List<String> razones;
  final String? motivoPersonalizacion;

  RecomendacionEjercicio({
    required this.ejercicio,
    required this.puntuacionRecomendacion,
    required this.razones,
    this.motivoPersonalizacion,
  });
}

class EstadisticasEjercicios {
  final int totalEjerciciosRealizados;
  final int minutosTotal;
  final Map<TipoEjercicio, int> ejerciciosPorTipo;
  final double promedioCalificacion;
  final int rachaActual;
  final int rachaMaxima;
  final TipoEjercicio? tipoFavorito;
  final List<ProgresoEjercicio> ejerciciosRecientes;

  EstadisticasEjercicios({
    required this.totalEjerciciosRealizados,
    required this.minutosTotal,
    required this.ejerciciosPorTipo,
    required this.promedioCalificacion,
    required this.rachaActual,
    required this.rachaMaxima,
    this.tipoFavorito,
    required this.ejerciciosRecientes,
  });
}

/// Servicio principal para gestionar ejercicios psicológicos y su progreso
///
/// Este servicio proporciona funcionalidades para:
/// - Obtener ejercicios recomendados personalizados
/// - Registrar progreso de ejercicios
/// - Calcular estadísticas del usuario
/// - Gestionar caché de datos para mejorar rendimiento
class EjerciciosService {
  static final EjerciciosService _instance = EjerciciosService._internal();
  factory EjerciciosService() => _instance;
  EjerciciosService._internal();

  final _auth = FirebaseAuth.instance;
  final _dbHelper = DatabaseHelper.instance;

  // Cache para mejorar rendimiento
  List<EjercicioPsicologico>? _ejerciciosCache;
  List<RecomendacionEjercicio>? _recomendacionesCache;
  EstadisticasEjercicios? _estadisticasCache;
  DateTime? _lastCacheUpdate;

  // Duración del cache (5 minutos)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Obtiene el ID del estudiante actual desde Firebase Auth
  Future<int> _getEstudianteId() async {
    final uid = _auth.currentUser?.uid;
    final email = _auth.currentUser?.email;
    if (uid == null) throw Exception('Usuario no autenticado');
    return await _dbHelper.getOrCreateEstudianteByUID(uid, email);
  }

  /// Inicializa ejercicios predeterminados si no existen
  Future<void> inicializarEjerciciosPredeterminados() async {
    final ejerciciosExistentes = await obtenerTodosLosEjercicios();
    if (ejerciciosExistentes.isNotEmpty) return;

    final ejerciciosPredeterminados = _crearEjerciciosPredeterminados();

    for (final ejercicio in ejerciciosPredeterminados) {
      await _dbHelper.insertEjercicio(ejercicio.toMap());
    }
  }

  /// Obtiene ejercicios recomendados basados en el perfil del usuario
  Future<List<RecomendacionEjercicio>> obtenerEjerciciosRecomendados() async {
    // Verificar cache
    if (_isCacheValid() && _recomendacionesCache != null) {
      return _recomendacionesCache!;
    }

    final idEstudiante = await _getEstudianteId();

    // Cargar datos en paralelo para mejor rendimiento
    final futures = await Future.wait([
      _dbHelper.getDiarioStatistics(idEstudiante),
      obtenerProgresoUsuario(),
      obtenerTodosLosEjercicios(),
    ]);

    final estadisticasDiario = futures[0] as Map<String, dynamic>;
    final ejerciciosRealizados = futures[1] as List<ProgresoEjercicio>;
    final todosEjercicios = futures[2] as List<EjercicioPsicologico>;

    final recomendaciones = <RecomendacionEjercicio>[];

    for (final ejercicio in todosEjercicios) {
      final puntuacion = _calcularPuntuacionRecomendacion(
          ejercicio, estadisticasDiario, ejerciciosRealizados);

      if (puntuacion > 0.3) {
        // Solo recomendar ejercicios con puntuación > 30%
        final razones = _generarRazonesRecomendacion(
            ejercicio, estadisticasDiario, ejerciciosRealizados);

        recomendaciones.add(RecomendacionEjercicio(
          ejercicio: ejercicio,
          puntuacionRecomendacion: puntuacion,
          razones: razones,
          motivoPersonalizacion:
              _generarMotivoPersonalizacion(estadisticasDiario),
        ));
      }
    }

    // Ordenar por puntuación descendente
    recomendaciones.sort((a, b) =>
        b.puntuacionRecomendacion.compareTo(a.puntuacionRecomendacion));

    final result = recomendaciones.take(6).toList();

    // Actualizar cache
    _recomendacionesCache = result;
    _lastCacheUpdate = DateTime.now();

    return result;
  }

  /// Obtiene todos los ejercicios disponibles
  Future<List<EjercicioPsicologico>> obtenerTodosLosEjercicios() async {
    // Verificar cache
    if (_isCacheValid() && _ejerciciosCache != null) {
      return _ejerciciosCache!;
    }

    final ejerciciosMap = await _dbHelper.getAllEjercicios();
    final result =
        ejerciciosMap.map((map) => EjercicioPsicologico.fromMap(map)).toList();

    // Actualizar cache
    _ejerciciosCache = result;
    _lastCacheUpdate = DateTime.now();

    return result;
  }

  /// Obtiene ejercicios por tipo específico
  Future<List<EjercicioPsicologico>> obtenerEjerciciosPorTipo(
      TipoEjercicio tipo) async {
    final ejerciciosMap = await _dbHelper.getEjerciciosByTipo(tipo.name);
    return ejerciciosMap
        .map((map) => EjercicioPsicologico.fromMap(map))
        .toList();
  }

  /// Registra el progreso de un ejercicio
  Future<ProgresoEjercicio> registrarProgreso({
    required int idEjercicio,
    required int duracionReal,
    required EstadoCompletado estado,
    int? puntuacion,
    String? notas,
    Map<String, dynamic>? datosAdicionales,
    String? emocion,
  }) async {
    final idEstudiante = await _getEstudianteId();

    // Combinar datos adicionales con la emoción
    final datosCompletos = <String, dynamic>{};
    if (datosAdicionales != null) {
      datosCompletos.addAll(datosAdicionales);
    }
    if (emocion != null) {
      datosCompletos['emocion'] = emocion;
    }

    final progreso = ProgresoEjercicio(
      idEjercicio: idEjercicio,
      idEstudiante: idEstudiante,
      fechaRealizacion: DateTime.now(),
      duracionReal: duracionReal,
      estado: estado,
      puntuacion: puntuacion,
      notas: notas,
      datosAdicionales: datosCompletos.isNotEmpty ? datosCompletos : null,
    );

    final id = await _dbHelper.insertProgresoEjercicio(progreso.toMap());

    // Limpiar cache al registrar nuevo progreso
    clearCache();

    return progreso.copyWith(id: id);
  }

  /// Obtiene el progreso completo del usuario
  Future<List<ProgresoEjercicio>> obtenerProgresoUsuario() async {
    final idEstudiante = await _getEstudianteId();
    final progresoMap =
        await _dbHelper.getProgresoEjerciciosByStudent(idEstudiante);
    return progresoMap.map((map) => ProgresoEjercicio.fromMap(map)).toList();
  }

  /// Obtiene estadísticas detalladas del usuario
  Future<EstadisticasEjercicios> obtenerEstadisticas() async {
    // Verificar cache
    if (_isCacheValid() && _estadisticasCache != null) {
      return _estadisticasCache!;
    }

    // Cargar datos en paralelo
    final futures = await Future.wait([
      obtenerProgresoUsuario(),
      obtenerTodosLosEjercicios(),
    ]);

    final progreso = futures[0] as List<ProgresoEjercicio>;
    final ejercicios = futures[1] as List<EjercicioPsicologico>;

    final ejerciciosCompletados =
        progreso.where((p) => p.estado == EstadoCompletado.completado).toList();

    final ejerciciosPorTipo = <TipoEjercicio, int>{};
    int minutosTotal = 0;
    double sumaCalificaciones = 0;
    int calificacionesCount = 0;

    for (final p in ejerciciosCompletados) {
      minutosTotal += p.duracionReal;

      if (p.puntuacion != null) {
        sumaCalificaciones += p.puntuacion!;
        calificacionesCount++;
      }

      // Obtener tipo de ejercicio
      final ejercicio = ejercicios.firstWhere((e) => e.id == p.idEjercicio,
          orElse: () => ejercicios.first);

      ejerciciosPorTipo[ejercicio.tipo] =
          (ejerciciosPorTipo[ejercicio.tipo] ?? 0) + 1;
    }

    final tipoFavorito = ejerciciosPorTipo.isNotEmpty
        ? ejerciciosPorTipo.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key
        : null;

    final rachaActual = _calcularRachaActual(ejerciciosCompletados);
    final rachaMaxima = _calcularRachaMaxima(ejerciciosCompletados);

    final result = EstadisticasEjercicios(
      totalEjerciciosRealizados: ejerciciosCompletados.length,
      minutosTotal: minutosTotal,
      ejerciciosPorTipo: ejerciciosPorTipo,
      promedioCalificacion: calificacionesCount > 0
          ? sumaCalificaciones / calificacionesCount
          : 0,
      rachaActual: rachaActual,
      rachaMaxima: rachaMaxima,
      tipoFavorito: tipoFavorito,
      ejerciciosRecientes: progreso.take(5).toList(),
    );

    // Actualizar cache
    _estadisticasCache = result;
    _lastCacheUpdate = DateTime.now();

    return result;
  }

  /// Verifica si el cache es válido
  bool _isCacheValid() {
    if (_lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) < _cacheDuration;
  }

  /// Limpia el cache cuando sea necesario
  void clearCache() {
    _ejerciciosCache = null;
    _recomendacionesCache = null;
    _estadisticasCache = null;
    _lastCacheUpdate = null;
  }

  /// Carga datos iniciales en paralelo
  Future<Map<String, dynamic>> cargarDatosIniciales() async {
    try {
      // Inicializar ejercicios predeterminados si es necesario
      await inicializarEjerciciosPredeterminados();

      // Cargar todos los datos en paralelo
      final futures = await Future.wait([
        obtenerEjerciciosRecomendados(),
        obtenerEstadisticas(),
      ]);

      return {
        'recomendaciones': futures[0] as List<RecomendacionEjercicio>,
        'estadisticas': futures[1] as EstadisticasEjercicios,
        'success': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  // Métodos privados para cálculos y recomendaciones

  double _calcularPuntuacionRecomendacion(
    EjercicioPsicologico ejercicio,
    Map<String, dynamic> estadisticasDiario,
    List<ProgresoEjercicio> historialEjercicios,
  ) {
    double puntuacion = 0.5; // Puntuación base

    // Analizar estado de ánimo del diario
    final estadoAnimoComun =
        estadisticasDiario['estadoAnimoMasComun'] as String?;
    if (estadoAnimoComun != null) {
      puntuacion += _ajustarPorEstadoAnimo(ejercicio.tipo, estadoAnimoComun);
    }

    // Considerar ejercicios no realizados recientemente
    final ejerciciosRecientes = historialEjercicios
        .where((p) => p.fechaRealizacion
            .isAfter(DateTime.now().subtract(const Duration(days: 7))))
        .map((p) => p.idEjercicio)
        .toSet();

    if (!ejerciciosRecientes.contains(ejercicio.id)) {
      puntuacion += 0.2; // Bonus por variedad
    }

    // Ajustar por dificultad según experiencia del usuario
    final totalEjercicios = historialEjercicios.length;
    if (totalEjercicios < 5 &&
        ejercicio.dificultad == NivelDificultad.principiante) {
      puntuacion += 0.3;
    } else if (totalEjercicios >= 10 &&
        ejercicio.dificultad == NivelDificultad.avanzado) {
      puntuacion += 0.2;
    }

    return puntuacion.clamp(0.0, 1.0);
  }

  double _ajustarPorEstadoAnimo(
      TipoEjercicio tipoEjercicio, String estadoAnimo) {
    switch (estadoAnimo.toLowerCase()) {
      case 'ansioso':
        if (tipoEjercicio == TipoEjercicio.respiracion ||
            tipoEjercicio == TipoEjercicio.relajacion) return 0.4;
        break;
      case 'triste':
      case 'muy triste':
        if (tipoEjercicio == TipoEjercicio.autoestima ||
            tipoEjercicio == TipoEjercicio.emocional) return 0.3;
        break;
      case 'cansado':
        if (tipoEjercicio == TipoEjercicio.mindfulness ||
            tipoEjercicio == TipoEjercicio.relajacion) return 0.3;
        break;
      case 'enojado':
        if (tipoEjercicio == TipoEjercicio.respiracion ||
            tipoEjercicio == TipoEjercicio.mindfulness) return 0.3;
        break;
      // Agregar más estados de ánimo si es necesario
    }
    return 0.0;
  }

  List<String> _generarRazonesRecomendacion(
    EjercicioPsicologico ejercicio,
    Map<String, dynamic> estadisticasDiario,
    List<ProgresoEjercicio> historialEjercicios,
  ) {
    final razones = <String>[];

    final estadoAnimoComun =
        estadisticasDiario['estadoAnimoMasComun'] as String?;
    if (estadoAnimoComun != null) {
      switch (estadoAnimoComun.toLowerCase()) {
        case 'ansioso':
          if (ejercicio.tipo == TipoEjercicio.respiracion) {
            razones.add(
                'Ideal para reducir la ansiedad que has estado experimentando');
          }
          break;
        case 'triste':
          if (ejercicio.tipo == TipoEjercicio.autoestima) {
            razones.add('Puede ayudarte a mejorar tu estado de ánimo');
          }
          break;
      }
    }

    if (ejercicio.dificultad == NivelDificultad.principiante &&
        historialEjercicios.length < 5) {
      razones.add('Perfecto para comenzar tu práctica de bienestar');
    }

    if (ejercicio.duracionMinutos <= 10) {
      razones.add('Ejercicio corto, ideal para tu rutina diaria');
    }

    return razones;
  }

  String? _generarMotivoPersonalizacion(
      Map<String, dynamic> estadisticasDiario) {
    final totalEntradas = estadisticasDiario['totalEntradas'] as int? ?? 0;
    final estadoAnimoComun =
        estadisticasDiario['estadoAnimoMasComun'] as String?;

    if (totalEntradas > 10 && estadoAnimoComun != null) {
      return 'Basado en tu actividad en el diario, hemos personalizado estas recomendaciones para ti';
    }

    return null;
  }

  int _calcularRachaActual(List<ProgresoEjercicio> ejerciciosCompletados) {
    if (ejerciciosCompletados.isEmpty) return 0;

    ejerciciosCompletados
        .sort((a, b) => b.fechaRealizacion.compareTo(a.fechaRealizacion));

    int racha = 0;
    DateTime fechaActual = DateTime.now();

    for (final ejercicio in ejerciciosCompletados) {
      final diferenciaDias =
          fechaActual.difference(ejercicio.fechaRealizacion).inDays;
      if (diferenciaDias <= racha + 1) {
        racha++;
        fechaActual = ejercicio.fechaRealizacion;
      } else {
        break;
      }
    }

    return racha;
  }

  int _calcularRachaMaxima(List<ProgresoEjercicio> ejerciciosCompletados) {
    if (ejerciciosCompletados.isEmpty) return 0;

    ejerciciosCompletados
        .sort((a, b) => a.fechaRealizacion.compareTo(b.fechaRealizacion));

    int rachaMaxima = 0;
    int rachaActual = 1;

    for (int i = 1; i < ejerciciosCompletados.length; i++) {
      final diferenciaDias = ejerciciosCompletados[i]
          .fechaRealizacion
          .difference(ejerciciosCompletados[i - 1].fechaRealizacion)
          .inDays;

      if (diferenciaDias <= 1) {
        rachaActual++;
      } else {
        rachaMaxima = rachaMaxima > rachaActual ? rachaMaxima : rachaActual;
        rachaActual = 1;
      }
    }

    return rachaMaxima > rachaActual ? rachaMaxima : rachaActual;
  }

  // Crear ejercicios predeterminados
  List<EjercicioPsicologico> _crearEjerciciosPredeterminados() {
    final ahora = DateTime.now();
    return [
      // Ejercicios de Respiración
      EjercicioPsicologico(
        titulo: 'Respiración 4-7-8',
        descripcion:
            'Técnica de respiración para reducir ansiedad y promover relajación',
        categoria: CategoriaEjercicio.reduccionAnsiedad.nombre,
        tipo: TipoEjercicio.respiracion,
        duracionMinutos: 5,
        dificultad: NivelDificultad.principiante,
        objetivos: [
          'Reducir ansiedad',
          'Mejorar relajación',
          'Controlar respiración'
        ],
        instrucciones: [
          'Siéntate cómodamente con la espalda recta',
          'Inhala por la nariz contando hasta 4',
          'Mantén la respiración contando hasta 7',
          'Exhala por la boca contando hasta 8',
          'Repite el ciclo 4-6 veces'
        ],
        fechaCreacion: ahora,
      ),
      EjercicioPsicologico(
        titulo: 'Respiración Diafragmática',
        descripcion:
            'Ejercicio para fortalecer la respiración profunda y reducir estrés',
        categoria: CategoriaEjercicio.gestionEstres.nombre,
        tipo: TipoEjercicio.respiracion,
        duracionMinutos: 10,
        dificultad: NivelDificultad.intermedio,
        objetivos: [
          'Fortalecer diafragma',
          'Reducir estrés',
          'Mejorar oxigenación'
        ],
        instrucciones: [
          'Acuéstate boca arriba con las rodillas dobladas',
          'Coloca una mano en el pecho y otra en el abdomen',
          'Respira lentamente por la nariz',
          'Asegúrate de que se mueva más la mano del abdomen',
          'Exhala lentamente por la boca',
          'Continúa por 10 minutos'
        ],
        fechaCreacion: ahora,
      ),

      // Ejercicios de Meditación
      EjercicioPsicologico(
        titulo: 'Meditación Guiada para Principiantes',
        descripcion: 'Meditación guiada de 10 minutos para calmar la mente',
        categoria: CategoriaEjercicio.bienestarGeneral.nombre,
        tipo: TipoEjercicio.mindfulness,
        duracionMinutos: 10,
        dificultad: NivelDificultad.principiante,
        objetivos: [
          'Reducir estrés',
          'Mejorar concentración',
          'Desarrollar atención plena'
        ],
        instrucciones: [
          'Siéntate en un lugar tranquilo y cómodo',
          'Cierra los ojos y enfócate en tu respiración',
          'Sigue las instrucciones del audio guiado',
          'No juzgues tus pensamientos, déjalos pasar',
          'Permanece en esta práctica durante los 10 minutos completos'
        ],
        fechaCreacion: ahora,
      ),
      EjercicioPsicologico(
        titulo: 'Meditación de Escaneo Corporal',
        descripcion: 'Técnica para liberar tensión corporal y relajarse',
        categoria: CategoriaEjercicio.relajacion.nombre,
        tipo: TipoEjercicio.mindfulness,
        duracionMinutos: 15,
        dificultad: NivelDificultad.intermedio,
        objetivos: [
          'Reducir tensión muscular',
          'Mejorar conexión mente-cuerpo',
          'Promover relajación profunda'
        ],
        instrucciones: [
          'Acuéstate boca arriba en una posición cómoda',
          'Enfócate en sentir cada parte de tu cuerpo',
          'Comienza por los dedos de los pies y sube lentamente',
          'Libera conscientemente la tensión en cada área',
          'Respira profundamente durante todo el ejercicio'
        ],
        fechaCreacion: ahora,
      ),
      EjercicioPsicologico(
        titulo: 'Meditación de Amor Benevolente',
        descripcion: 'Práctica para cultivar sentimientos positivos',
        categoria: CategoriaEjercicio.emocional.nombre,
        tipo: TipoEjercicio.mindfulness,
        duracionMinutos: 12,
        dificultad: NivelDificultad.intermedio,
        objetivos: [
          'Aumentar compasión',
          'Mejorar relaciones interpersonales',
          'Reducir sentimientos negativos'
        ],
        instrucciones: [
          'Siéntate en una postura cómoda',
          'Visualiza a alguien que amas',
          'Repite frases de bondad y amor',
          'Extiende estos sentimientos progresivamente',
          'Inclúyete a ti mismo en estos deseos positivos'
        ],
        fechaCreacion: ahora,
      ),

      // Ejercicios de Autoestima
      EjercicioPsicologico(
        titulo: 'Afirmaciones Positivas',
        descripcion:
            'Ejercicio para fortalecer la autoestima y el autoconcepto positivo',
        categoria: CategoriaEjercicio.mejoraAutoestima.nombre,
        tipo: TipoEjercicio.autoestima,
        duracionMinutos: 8,
        dificultad: NivelDificultad.principiante,
        objetivos: [
          'Mejorar autoestima',
          'Desarrollar autoconcepto positivo',
          'Reducir autocrítica'
        ],
        instrucciones: [
          'Párate frente a un espejo o siéntate cómodamente',
          'Repite en voz alta: "Soy valioso/a y merezco respeto"',
          'Continúa con: "Tengo fortalezas únicas y valiosas"',
          'Añade: "Estoy creciendo y mejorando cada día"',
          'Repite cada afirmación 3 veces con convicción',
          'Termina con una sonrisa genuina'
        ],
        fechaCreacion: ahora,
      ),
      EjercicioPsicologico(
        titulo: 'Registro de Logros',
        descripcion: 'Reflexión sobre logros y cualidades personales',
        categoria: CategoriaEjercicio.mejoraAutoestima.nombre,
        tipo: TipoEjercicio.autoestima,
        duracionMinutos: 15,
        dificultad: NivelDificultad.intermedio,
        objetivos: [
          'Identificar fortalezas',
          'Recordar logros pasados',
          'Reforzar autoimagen positiva'
        ],
        instrucciones: [
          'Haz una lista de al menos 5 logros personales',
          'Escribe 3 cualidades positivas que te ayudaron',
          'Reflexiona sobre cómo superaste desafíos',
          'Visualiza cómo aplicas estas cualidades ahora',
          'Guarda tu lista para revisarla periódicamente'
        ],
        fechaCreacion: ahora,
      ),
    ];
  }
}
