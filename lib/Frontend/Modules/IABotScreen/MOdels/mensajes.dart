class Mensaje {
  final String emisor;
  final String contenido;
  final String fecha;

  Mensaje({
    required this.emisor,
    required this.contenido,
    required this.fecha,
  });

  Map<String, dynamic> toJson() {
    return {
      'emisor': emisor,
      'contenido': contenido,
      'fecha': fecha,
    };
  }

  factory Mensaje.fromJson(Map<String, dynamic> json) {
    return Mensaje(
      emisor: json['emisor'] ?? '',
      contenido: json['contenido'] ?? '',
      fecha: json['fecha'] ?? '',
    );
  }
}
