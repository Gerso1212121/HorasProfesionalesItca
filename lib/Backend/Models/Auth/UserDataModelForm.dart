class UserDataForm {
  final String nombre;
  final String telefono;
  final String? carnet;
  final String? sede;
  final String? carrera;
  final String? anioIngreso;

  UserDataForm({
    required this.nombre,
    required this.telefono,
    this.carnet,
    this.sede,
    this.carrera,
    this.anioIngreso,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'carnet': carnet,
      'sede': sede,
      'carrera': carrera,
      'anioIngreso': anioIngreso,
    };
  }
}

class ITCAOptions {
  static const List<String> sedes = [
    'Sede Central San Salvador',
    'Sede Santa Ana',
    'Sede San Miguel',
    'Sede La Unión',
    'Sede San Vicente',
    'Sede Zacatecoluca',
  ];

  static const List<String> carreras = [
    'Ingeniería en Sistemas y Computación',
    'Ingeniería Industrial',
    'Ingeniería Eléctrica',
    'Ingeniería Mecánica',
    'Ingeniería en Mantenimiento Aeronáutico',
    'Ingeniería en Desarrollo de Software',
    'Técnico en Electrónica',
    'Técnico en Mecánica Automotriz',
    'Técnico en Redes y Telecomunicaciones',
    'Técnico en Desarrollo Web',
  ];

  static List<String> get aniosIngreso {
    return List<String>.generate(
      10,
      (index) => (DateTime.now().year - 9 + index).toString(),
    );
  }
}