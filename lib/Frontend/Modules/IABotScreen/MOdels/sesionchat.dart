import 'package:horas2/Frontend/Modules/IABotScreen/MOdels/mensajes.dart';

class SesionChat {
  final String fecha;
  final String usuario;
  final String resumen;
  final List<Mensaje> mensajes;
  final List<String> etiquetas;
  final String? tituloDinamico;

  SesionChat({
    required this.fecha,
    required this.usuario,
    required this.resumen,
    required this.mensajes,
    required this.etiquetas,
    this.tituloDinamico,
  });

  Map<String, dynamic> toJson() {
    return {
      'fecha': fecha,
      'usuario': usuario,
      'resumen': resumen,
      'mensajes': mensajes.map((m) => m.toJson()).toList(),
      'etiquetas': etiquetas,
      'tituloDinamico': tituloDinamico,
    };
  }

  factory SesionChat.fromJson(Map<String, dynamic> json) {
    return SesionChat(
      fecha: json['fecha'] ?? '',
      usuario: json['usuario'] ?? '',
      resumen: json['resumen'] ?? '',
      mensajes: (json['mensajes'] as List<dynamic>?)
              ?.map((m) => Mensaje.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      etiquetas: List<String>.from(json['etiquetas'] ?? []),
      tituloDinamico: json['tituloDinamico'],
    );
  }
}
