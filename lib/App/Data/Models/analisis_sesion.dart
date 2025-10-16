class AnalisisSesion {
  final int? id;
  final String fechaSesion;
  final String temaGeneral;
  final Map<String, double> emociones; // emoción -> porcentaje
  final String nivelRiesgo; // bajo, medio, alto, crítico
  final double puntuacionRiesgo; // 0-100
  final List<String> palabrasClave;
  final String resumenAnalisis;
  final int idSesionChat; // referencia a la sesión original

  AnalisisSesion({
    this.id,
    required this.fechaSesion,
    required this.temaGeneral,
    required this.emociones,
    required this.nivelRiesgo,
    required this.puntuacionRiesgo,
    required this.palabrasClave,
    required this.resumenAnalisis,
    required this.idSesionChat,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha_sesion': fechaSesion,
      'tema_general': temaGeneral,
      'emociones': emociones,
      'nivel_riesgo': nivelRiesgo,
      'puntuacion_riesgo': puntuacionRiesgo,
      'palabras_clave': palabrasClave,
      'resumen_analisis': resumenAnalisis,
      'id_sesion_chat': idSesionChat,
    };
  }

  factory AnalisisSesion.fromJson(Map<String, dynamic> json) {
    return AnalisisSesion(
      id: json['id'],
      fechaSesion: json['fecha_sesion'] ?? '',
      temaGeneral: json['tema_general'] ?? '',
      emociones: Map<String, double>.from(json['emociones'] ?? {}),
      nivelRiesgo: json['nivel_riesgo'] ?? 'bajo',
      puntuacionRiesgo: (json['puntuacion_riesgo'] ?? 0.0).toDouble(),
      palabrasClave: List<String>.from(json['palabras_clave'] ?? []),
      resumenAnalisis: json['resumen_analisis'] ?? '',
      idSesionChat: json['id_sesion_chat'] ?? 0,
    );
  }
}
