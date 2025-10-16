class Estudiante {
  int? idEstudiante;
  String? uidFirebase;
  String? nombre;
  String? apellido;
  String? correo;
  DateTime? fechaSincronizacion;
  String? telefono;
  String? carrera;
  String? sede;
  int? year;

  Estudiante({
    this.idEstudiante,
    this.uidFirebase,
    this.nombre,
    this.apellido,
    this.correo,
    this.fechaSincronizacion,
    this.telefono,
    this.carrera,
    this.sede,
    this.year,
  });

  factory Estudiante.fromMap(Map<String, dynamic> map) {
    return Estudiante(
      idEstudiante: map['id_estudiante'],
      uidFirebase: map['uid_firebase'],
      nombre: map['nombre'],
      apellido: map['apellido'],
      correo: map['correo'],
      fechaSincronizacion: map['fecha_sincronizacion'] != null
          ? DateTime.parse(map['fecha_sincronizacion'])
          : null,
      telefono: map['telefono'],
      carrera: map['carrera'],
      sede: map['sede'],
      year: map['year'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_estudiante': idEstudiante,
      'uid_firebase': uidFirebase,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'fecha_sincronizacion': fechaSincronizacion?.toIso8601String(),
      'telefono': telefono,
      'carrera': carrera,
      'sede': sede,
      'year': year,
    };
  }

  Map<String, dynamic> toMapForFirebaseInsert() {
    return {
      'uid_firebase': uidFirebase,
      'nombre': nombre,
      'apellido': apellido,
      'correo': correo,
      'fecha_sincronizacion': fechaSincronizacion?.toIso8601String(),
      'telefono': telefono,
      'carrera': carrera,
      'sede': sede,
      'year': year,
    };
  }

  String get nombreCompleto => '${nombre ?? ''} ${apellido ?? ''}'.trim();

  bool get needsSync {
    if (fechaSincronizacion == null) return true;
    return DateTime.now().difference(fechaSincronizacion!).inHours > 24;
  }

  @override
  String toString() {
    return 'Estudiante{idEstudiante: $idEstudiante, uidFirebase: $uidFirebase, nombre: $nombre, apellido: $apellido, correo: $correo, telefono: $telefono, carrera: $carrera, sede: $sede, year: $year}';
  }
}

// Modelo para Actividad del Calendario
class ActividadCalendario {
  int? idCalendario;
  String? actividad;
  DateTime? dateActivity;
  int? idEstudiante;

  ActividadCalendario({
    this.idCalendario,
    this.actividad,
    this.dateActivity,
    this.idEstudiante,
  });

  factory ActividadCalendario.fromMap(Map<String, dynamic> map) {
    return ActividadCalendario(
      idCalendario: map['id_calendario'],
      actividad: map['actividad'],
      dateActivity: map['date_activity'] != null
          ? DateTime.parse(map['date_activity'])
          : null,
      idEstudiante: map['id_estudiante'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_calendario': idCalendario,
      'actividad': actividad,
      'date_activity': dateActivity?.toIso8601String().split('T')[0],
      'id_estudiante': idEstudiante,
    };
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'actividad': actividad,
      'date_activity': dateActivity?.toIso8601String().split('T')[0],
      'id_estudiante': idEstudiante,
    };
  }
}

// Modelo para Sesión
class Sesion {
  int? idSesion;
  DateTime? fechaSesion;
  String? tiempoSesion; // Guardado como string en formato HH:MM
  int? idEstudianteSesion;

  Sesion({
    this.idSesion,
    this.fechaSesion,
    this.tiempoSesion,
    this.idEstudianteSesion,
  });

  factory Sesion.fromMap(Map<String, dynamic> map) {
    return Sesion(
      idSesion: map['id_sesion'],
      fechaSesion: map['fecha_sesion'] != null
          ? DateTime.parse(map['fecha_sesion'])
          : null,
      tiempoSesion: map['tiempo_sesion'],
      idEstudianteSesion: map['id_estudiante_sesion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id_sesion': idSesion,
      'fecha_sesion': fechaSesion?.toIso8601String().split('T')[0],
      'tiempo_sesion': tiempoSesion,
      'id_estudiante_sesion': idEstudianteSesion,
    };
  }

  Map<String, dynamic> toMapForInsert() {
    return {
      'fecha_sesion': fechaSesion?.toIso8601String().split('T')[0],
      'tiempo_sesion': tiempoSesion,
      'id_estudiante_sesion': idEstudianteSesion,
    };
  }
}
