class DiarioEntry {
  final int? idDiario;
  final String fecha;
  final String contenido;
  final String timestamp;
  final int idEstudiante;
  final String? categoria;
  final String? estadoAnimo;
  final int? valoracion;
  final List<String>? etiquetas;

  DiarioEntry({
    this.idDiario,
    required this.fecha,
    required this.contenido,
    required this.timestamp,
    required this.idEstudiante,
    this.categoria,
    this.estadoAnimo,
    this.valoracion,
    this.etiquetas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_diario': idDiario,
      'fecha': fecha,
      'contenido': contenido,
      'timestamp': timestamp,
      'id_estudiante': idEstudiante,
      'categoria': categoria,
      'estado_animo': estadoAnimo,
      'valoracion': valoracion,
      'etiquetas': etiquetas?.join(','),
    };
  }

  factory DiarioEntry.fromMap(Map<String, dynamic> map) {
    return DiarioEntry(
      idDiario: map['id_diario'] as int?,
      fecha: map['fecha'] as String,
      contenido: map['contenido'] as String,
      timestamp: map['timestamp'] as String,
      idEstudiante: map['id_estudiante'] as int,
      categoria: map['categoria'] as String?,
      estadoAnimo: map['estado_animo'] as String?,
      valoracion: map['valoracion'] as int?,
      etiquetas: map['etiquetas'] != null
          ? (map['etiquetas'] as String).split(',')
          : null,
    );
  }

  DiarioEntry copyWith({
    int? idDiario,
    String? fecha,
    String? contenido,
    String? timestamp,
    int? idEstudiante,
    String? categoria,
    String? estadoAnimo,
    int? valoracion,
    List<String>? etiquetas,
  }) {
    return DiarioEntry(
      idDiario: idDiario ?? this.idDiario,
      fecha: fecha ?? this.fecha,
      contenido: contenido ?? this.contenido,
      timestamp: timestamp ?? this.timestamp,
      idEstudiante: idEstudiante ?? this.idEstudiante,
      categoria: categoria ?? this.categoria,
      estadoAnimo: estadoAnimo ?? this.estadoAnimo,
      valoracion: valoracion ?? this.valoracion,
      etiquetas: etiquetas ?? this.etiquetas,
    );
  }
}

// Enum para Estado de Ánimo
enum EstadoAnimo {
  muyFeliz('Muy feliz', '😄', 5),
  feliz('Feliz', '😊', 4),
  neutral('Neutral', '😐', 3),
  cansado('Cansado', '😴', 2),
  triste('Triste', '😢', 2),
  muyTriste('Muy triste', '😭', 1),
  ansioso('Ansioso', '😰', 2),
  relajado('Relajado', '😌', 4),
  enojado('Enojado', '😠', 1),
  emocionado('Emocionado', '🤩', 5);

  final String nombre;
  final String emoji;
  final int valor;
  const EstadoAnimo(this.nombre, this.emoji, this.valor);
}

// Enum para Categoría de Entrada
enum CategoriaEntrada {
  personal('Personal'),
  academico('Académico'),
  salud('Salud'),
  relaciones('Relaciones'),
  trabajo('Trabajo'),
  reflexion('Reflexión'),
  metas('Metas'),
  gratitud('Gratitud');

  final String nombre;
  const CategoriaEntrada(this.nombre);
}
