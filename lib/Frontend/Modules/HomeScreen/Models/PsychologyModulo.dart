class PsychologyModulo {
  final String id;
  final String titulo;
  final String contenido;
  final String fechaCreacion;
  final String fechaActualizacion;
  final bool sincronizado;

  PsychologyModulo({
    required this.id,
    required this.titulo,
    required this.contenido,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    required this.sincronizado,
  });

  factory PsychologyModulo.fromMap(Map<String, dynamic> map) {
    return PsychologyModulo(
      id: map['id'] as String,
      titulo: map['titulo'] as String,
      contenido: map['contenido'] as String,
      fechaCreacion: map['fecha_creacion'] as String,
      fechaActualizacion: map['fecha_actualizacion'] as String,
      sincronizado: (map['sincronizado'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'contenido': contenido,
      'fecha_creacion': fechaCreacion,
      'fecha_actualizacion': fechaActualizacion,
      'sincronizado': sincronizado ? 1 : 0,
    };
  }
}