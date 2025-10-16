//import 'package:ai_app_tests/Data/models/ejercicio_model.dart';
import 'dart:convert';

enum EstadoCompletado {
  completado,
  incompleto,
  abandonado,
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
      estado: EstadoCompletado.values.firstWhere(
        (e) => e.name == map['estado'],
        orElse: () => EstadoCompletado.incompleto,
      ),
      puntuacion: map['puntuacion'] as int?,
      notas: map['notas'] as String?,
      datosAdicionales: map['datos_adicionales'] != null
          ? jsonDecode(map['datos_adicionales'] as String)
              as Map<String, dynamic>
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
