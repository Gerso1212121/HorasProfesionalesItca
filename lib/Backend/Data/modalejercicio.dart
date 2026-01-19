import 'dart:convert';
import 'package:flutter/material.dart';

enum TipoEjercicio {
  respiracion,
  mindfulness,
  autoestima,
  cognitivo,
  relajacion,
  emocional,
}

extension TipoEjercicioExtension on TipoEjercicio {
  String get nombre {
    switch (this) {
      case TipoEjercicio.respiracion:
        return 'Respiración';
      case TipoEjercicio.mindfulness:
        return 'Mindfulness';
      case TipoEjercicio.autoestima:
        return 'Autoestima';
      case TipoEjercicio.cognitivo:
        return 'Cognitivo';
      case TipoEjercicio.relajacion:
        return 'Relajación';
      case TipoEjercicio.emocional:
        return 'Emocional';
    }
  }

  Color get color {
    switch (this) {
      case TipoEjercicio.respiracion:
        return Colors.blue.shade600;
      case TipoEjercicio.mindfulness:
        return Colors.purple.shade600;
      case TipoEjercicio.autoestima:
        return Colors.orange.shade600;
      case TipoEjercicio.cognitivo:
        return Colors.teal.shade600;
      case TipoEjercicio.relajacion:
        return Colors.green.shade600;
      case TipoEjercicio.emocional:
        return Colors.pink.shade600;
    }
  }

  IconData get icono {
    switch (this) {
      case TipoEjercicio.respiracion:
        return Icons.air;
      case TipoEjercicio.mindfulness:
        return Icons.self_improvement;
      case TipoEjercicio.autoestima:
        return Icons.favorite;
      case TipoEjercicio.cognitivo:
        return Icons.psychology;
      case TipoEjercicio.relajacion:
        return Icons.spa;
      case TipoEjercicio.emocional:
        return Icons.emoji_emotions;
    }
  }
}

enum NivelDificultad {
  principiante,
  intermedio,
  avanzado,
}

extension NivelDificultadExtension on NivelDificultad {
  String get nombre {
    switch (this) {
      case NivelDificultad.principiante:
        return 'Principiante';
      case NivelDificultad.intermedio:
        return 'Intermedio';
      case NivelDificultad.avanzado:
        return 'Avanzado';
    }
  }

  Color get color {
    switch (this) {
      case NivelDificultad.principiante:
        return Colors.green;
      case NivelDificultad.intermedio:
        return Colors.orange;
      case NivelDificultad.avanzado:
        return Colors.red;
    }
  }
}

enum EstadoCompletado {
  completado,
  en_progreso,
  abandonado,
}

extension EstadoCompletadoExtension on EstadoCompletado {
  String get nombre {
    switch (this) {
      case EstadoCompletado.completado:
        return 'Completado';
      case EstadoCompletado.en_progreso:
        return 'En Progreso';
      case EstadoCompletado.abandonado:
        return 'Abandonado';
      default:
        return 'Desconocido'; // Manejo de caso por defecto
    }
  }

  Color get color {
    switch (this) {
      case EstadoCompletado.completado:
        return Colors.green;
      case EstadoCompletado.en_progreso:
        return Colors.orange;
      case EstadoCompletado.abandonado:
        return Colors.red;
      default:
        return Colors.grey; // Manejo de caso por defecto
    }
  }
}

class EjercicioPsicologico {
  final int? id;
  final String titulo;
  final String descripcion;
  final String categoria;
  final TipoEjercicio tipo;
  final int duracionMinutos;
  final NivelDificultad dificultad;
  final List<String> objetivos;
  final List<String> instrucciones;
  final DateTime fechaCreacion;

  EjercicioPsicologico({
    this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.tipo,
    required this.duracionMinutos,
    required this.dificultad,
    required this.objetivos,
    required this.instrucciones,
    required this.fechaCreacion,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_ejercicio': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'tipo': tipo.name,
      'duracion_minutos': duracionMinutos,
      'dificultad': dificultad.name,
      'objetivos': objetivos.join('|'),
      'instrucciones': instrucciones.join('|'),
      'fecha_creacion': fechaCreacion.toIso8601String(),
    };
  }

  factory EjercicioPsicologico.fromMap(Map<String, dynamic> map) {
    return EjercicioPsicologico(
      id: map['id_ejercicio'] as int?,
      titulo: map['titulo'] as String,
      descripcion: map['descripcion'] as String,
      categoria: map['categoria'] as String,
      tipo: TipoEjercicio.values.firstWhere((e) => e.name == map['tipo']),
      duracionMinutos: map['duracion_minutos'] as int,
      dificultad:
          NivelDificultad.values.firstWhere((e) => e.name == map['dificultad']),
      objetivos: (map['objetivos'] as String).split('|'),
      instrucciones: (map['instrucciones'] as String).split('|'),
      fechaCreacion: DateTime.parse(map['fecha_creacion'] as String),
    );
  }
}

class ProgresoEjercicio {
  final int? id;
  final int idEjercicio;
  final int idEstudiante;
  final DateTime fechaRealizacion;
  final int duracionReal;
  final EstadoCompletado estado;
  final int? puntuacion;
  final String? notas;
  final Map<String, dynamic>? datosAdicionales;

  ProgresoEjercicio({
    this.id,
    required this.idEjercicio,
    required this.idEstudiante,
    required this.fechaRealizacion,
    required this.duracionReal,
    required this.estado,
    this.puntuacion,
    this.notas,
    this.datosAdicionales,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_ejercicio': idEjercicio,
      'id_estudiante': idEstudiante,
      'fecha_realizacion': fechaRealizacion.toIso8601String(),
      'duracion_real': duracionReal,
      'estado': estado.name,
      'puntuacion': puntuacion,
      'notas': notas,
      'datos_adicionales':
          datosAdicionales != null ? jsonEncode(datosAdicionales) : null,
    };
  }

  factory ProgresoEjercicio.fromMap(Map<String, dynamic> map) {
    return ProgresoEjercicio(
      id: map['id'] as int?,
      idEjercicio: map['id_ejercicio'] as int,
      idEstudiante: map['id_estudiante'] as int,
      fechaRealizacion: DateTime.parse(map['fecha_realizacion'] as String),
      duracionReal: map['duracion_real'] as int,
      estado:
          EstadoCompletado.values.firstWhere((e) => e.name == map['estado']),
      puntuacion: map['puntuacion'] as int?,
      notas: map['notas'] as String?,
      datosAdicionales: map['datos_adicionales'] != null
          ? jsonDecode(map['datos_adicionales'] as String)
          : null,
    );
  }

  ProgresoEjercicio copyWith({
    int? id,
    int? idEjercicio,
    int? idEstudiante,
    DateTime? fechaRealizacion,
    int? duracionReal,
    EstadoCompletado? estado,
    int? puntuacion,
    String? notas,
    Map<String, dynamic>? datosAdicionales,
  }) {
    return ProgresoEjercicio(
      id: id ?? this.id,
      idEjercicio: idEjercicio ?? this.idEjercicio,
      idEstudiante: idEstudiante ?? this.idEstudiante,
      fechaRealizacion: fechaRealizacion ?? this.fechaRealizacion,
      duracionReal: duracionReal ?? this.duracionReal,
      estado: estado ?? this.estado,
      puntuacion: puntuacion ?? this.puntuacion,
      notas: notas ?? this.notas,
      datosAdicionales: datosAdicionales ?? this.datosAdicionales,
    );
  }
}
