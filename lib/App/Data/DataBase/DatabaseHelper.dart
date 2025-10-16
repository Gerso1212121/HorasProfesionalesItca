import 'dart:io';
import 'package:ai_app_tests/App/utils/Utils_ServiceLog.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class DatabaseHelper {
  static const _databaseName = "aplicacion_movil.db";
  static const _databaseVersion = 6;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  //Configuración de Supabase
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ===============================================
  // CONFIGURACIÓN Y INICIALIZACIÓN DE LA BASE DE DATOS
  // ===============================================

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  // ===============================================
  //TODO CREACIÓN DE TABLAS

  // ===============================================

  Future<void> _onCreate(Database db, int version) async {
    // Crear tablas en orden (respetando las foreign keys)

    // Tabla estudiante (usuario logueado)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS "estudiante" (
        "id_estudiante" INTEGER PRIMARY KEY AUTOINCREMENT,
        "uid_firebase" TEXT UNIQUE,
        "nombre" TEXT,
        "apellido" TEXT,
        "correo" TEXT,
        "telefono" TEXT,
        "sede" TEXT,
        "carrera" TEXT,
        "año" TEXT,
        "fecha_sincronizacion" TEXT
      )
    ''');

    // Tabla sede
    await db.execute('''
      CREATE TABLE IF NOT EXISTS "sede" (
        "id_sede" INTEGER PRIMARY KEY AUTOINCREMENT,
        "nombre_sede" TEXT NOT NULL,
        "direccion_sede" TEXT NOT NULL
      )
    ''');

    // Tabla bienestar
    await db.execute('''
      CREATE TABLE IF NOT EXISTS "bienestar" (
        "id_bienestar" INTEGER PRIMARY KEY AUTOINCREMENT,
        "nombre" TEXT,
        "apellido" TEXT,
        "telefono" INTEGER,
        "correo" TEXT,
        "id_sede" INTEGER,
        FOREIGN KEY("id_sede") REFERENCES "sede"("id_sede")
      )
    ''');

    // Tabla sesiones
    await db.execute('''
      CREATE TABLE IF NOT EXISTS "sesiones" (
        "id_sesion" INTEGER PRIMARY KEY AUTOINCREMENT,
        "fecha_sesion" DATE NOT NULL,
        "tiempo_sesion" TIME NOT NULL,
        "id_estudiante_sesion" INTEGER NOT NULL,
        FOREIGN KEY("id_estudiante_sesion") REFERENCES "estudiante"("id_estudiante")
      )
    ''');

    // Tabla chatbot
    await db.execute('''
      CREATE TABLE IF NOT EXISTS "chatbot" (
        "id_chatbot" INTEGER PRIMARY KEY AUTOINCREMENT,
        "id_estudiante" INTEGER,
        "id_sesion" INTEGER,
        FOREIGN KEY("id_sesion") REFERENCES "sesiones"("id_sesion"),
        FOREIGN KEY("id_estudiante") REFERENCES "estudiante"("id_estudiante")
      )
    ''');

    // Tabla ia_diagnostico
    await db.execute('''
      CREATE TABLE IF NOT EXISTS "ia_diagnostico" (
        "id_diagnostico" INTEGER PRIMARY KEY AUTOINCREMENT,
        "analisis" TEXT,
        "puntos_importantes" TEXT,
        "id_chatbot" INTEGER,
        FOREIGN KEY("id_chatbot") REFERENCES "chatbot"("id_chatbot")
      )
    ''');

    await db.execute('''
CREATE TABLE agenda_cita (
  id_agendacita        INTEGER PRIMARY KEY,              
  fecha_cita           TEXT    NOT NULL,                 
  motivo_cita          TEXT,
  confirmacion_cita    INTEGER DEFAULT 0,                 
  estado_cita          TEXT DEFAULT 'programada',
  notas_adicionales    TEXT,
  diagnostico          TEXT,
  nombre_estudiante    TEXT NOT NULL,
  admin_id             TEXT,                             
  estudiante_uid       TEXT,
  fecha_creacion       TEXT DEFAULT CURRENT_TIMESTAMP,   
  admin_confirmador    TEXT,
  fecha_confirmacion   TEXT,
  FOREIGN KEY (admin_id) REFERENCES admins(id) ON DELETE RESTRICT
)
''');

    // Tabla calendario
    await db.execute('''
      CREATE TABLE IF NOT EXISTS "calendario" (
        "id_calendario" INTEGER PRIMARY KEY AUTOINCREMENT,
        "actividad" TEXT,
        "date_activity" DATE,
        "id_estudiante" INTEGER,
        FOREIGN KEY("id_estudiante") REFERENCES "estudiante"("id_estudiante")
      )
    ''');

    // Tabla contacto_emergencia
    await db.execute('''
      CREATE TABLE IF NOT EXISTS "contacto_emergencia" (
        "id_contacto" INTEGER PRIMARY KEY AUTOINCREMENT,
        "nombre_contacto" TEXT,
        "apellido_contacto" TEXT,
        "telefono_contacto" TEXT,
        "id_estudiante" INTEGER,
        FOREIGN KEY("id_estudiante") REFERENCES "estudiante"("id_estudiante")
      )
    ''');

    // Tabla modulos
    await db.execute('''
      CREATE TABLE modulos (
        id TEXT PRIMARY KEY,
        titulo TEXT NOT NULL,
        contenido TEXT NOT NULL,
        fecha_creacion TEXT NOT NULL,
        fecha_actualizacion TEXT NOT NULL,
        sincronizado INTEGER DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE modulo_imagenes (
        id TEXT PRIMARY KEY,
        modulo_id TEXT NOT NULL,
        url TEXT NOT NULL,
        orden INTEGER DEFAULT 0,
        FOREIGN KEY (modulo_id) REFERENCES modulos (id) ON DELETE CASCADE
      )
    ''');

    //TODO ELIMINAR ESTA TABLA SI NO SE USA

    // Tabla usuario
    await db.execute('''
      CREATE TABLE IF NOT EXISTS "usuario" (
        "id_usuario" INTEGER PRIMARY KEY AUTOINCREMENT,
        "nombre_usuario" TEXT,
        "correo" TEXT,
        "pass" TEXT,
        "id_estudiante" INTEGER,
        FOREIGN KEY("id_estudiante") REFERENCES "estudiante"("id_estudiante")
      )
    ''');

    // --- INICIO DE LAS TABLAS DE EJERCICIOS Y PROGRESO ---
    // Crear tabla ejercicios
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ejercicios (
        id_ejercicio INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        categoria TEXT,
        tipo TEXT NOT NULL,
        duracion_minutos INTEGER,
        dificultad TEXT,
        objetivos TEXT,
        instrucciones TEXT,
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Crear tabla progreso_ejercicio
    await db.execute('''
      CREATE TABLE IF NOT EXISTS progreso_ejercicio (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        id_ejercicio INTEGER,
        id_estudiante INTEGER,
        fecha_realizacion TEXT,
        duracion_real INTEGER,
        estado TEXT,
        puntuacion INTEGER,
        notas TEXT,
        datos_adicionales TEXT,
        FOREIGN KEY (id_ejercicio) REFERENCES ejercicios (id_ejercicio),
        FOREIGN KEY (id_estudiante) REFERENCES estudiante (id)
      )
    ''');
    // --- FIN DE LAS TABLAS DE EJERCICIOS Y PROGRESO ---

    // Tabla diario_entries
    await db.execute('''
      CREATE TABLE IF NOT EXISTS diario_entries (
        id_diario INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT NOT NULL,
        contenido TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        id_estudiante INTEGER NOT NULL,
        categoria TEXT,
        estado_animo TEXT,
        valoracion INTEGER,
        etiquetas TEXT,
        FOREIGN KEY(id_estudiante) REFERENCES estudiante(id_estudiante)
      )
    ''');

    // Crear tabla libros
    await db.execute('''
      CREATE TABLE libros (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        contenido TEXT NOT NULL,
        fecha_subido TEXT NOT NULL,
        tamaño INTEGER NOT NULL,
        sincronizado INTEGER DEFAULT 1
      )
    ''');
  }

  // ===============================================
  //TODO MÉTODOS CRUD PARA ESTUDIANTE

  // ===============================================

  // Inserta un estudiante desde Firebase
  Future<int> insertEstudianteFromFirebase(
      Map<String, dynamic> estudiante) async {
    Database db = await database;
    return await db.insert('estudiante', estudiante,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Obtiene el estudiante actual (el primero en la tabla)
  Future<Map<String, dynamic>?> getEstudianteActual() async {
    Database db = await database;
    final result = await db.query('estudiante', limit: 1);
    return result.isNotEmpty ? result.first : null;
  }

  // Actualiza un estudiante por UID
  Future<Map<String, dynamic>?> getEstudiantePorUID(String uid) async {
    Database db = await database;
    final result = await db.query(
      'estudiante',
      where: 'uid_firebase = ?',
      whereArgs: [uid],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Obtiene estudiante por UID
  Future<Map<String, dynamic>?> getEstudianteByUID(String uid) async {
    final db = await database;

    final List<Map<String, dynamic>> resultados = await db.query(
      'estudiante',
      where: 'uid_firebase = ?',
      whereArgs: [uid],
      limit: 1,
    );

    // Si se encontró un estudiante, devuelve el primer (y único) resultado
    if (resultados.isNotEmpty) {
      return resultados.first;
    }

    // Si no se encontró ningún estudiante, devuelve null
    return null;
  }

  // Método para obtener o crear estudiante por UID
  Future<int> getOrCreateEstudianteByUID(String uid, String? email) async {
    Database db = await database;

    // Buscar si existe el estudiante
    final result = await db.query(
      'estudiante',
      where: 'uid_firebase = ?',
      whereArgs: [uid],
    );

    if (result.isNotEmpty) {
      return result.first['id_estudiante'] as int;
    }

    // Crear nuevo estudiante
    final estudiante = {
      'uid_firebase': uid,
      'correo': email,
      'fecha_sincronizacion': DateTime.now().toIso8601String(),
    };

    return await db.insert('estudiante', estudiante);
  }

  // Cuenta el número de estudiantes en la base de datos
  Future<int> countEstudiantes() async {
    Database db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM estudiante');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Actualizar estudiante desde Firebase
  Future<int> updateEstudianteFromFirebase(
      String uid, Map<String, dynamic> estudiante) async {
    Database db = await database;
    return await db.update(
      'estudiante',
      estudiante,
      where: 'uid_firebase = ?',
      whereArgs: [uid],
    );
  }

  // Actualizar emoción del estudiante
  Future<int> actualizarEmocionEstudiante(
      String uidFirebase, String nuevaEmocion) async {
    final db = await database;

    final nuevosValores = {
      'emocion': nuevaEmocion,
    };

    return await db.update(
      'estudiante',
      nuevosValores,
      where: 'uid_firebase = ?',
      whereArgs: [uidFirebase],
    );
  }

  // Eliminar estudiante actual
  Future<int> deleteEstudianteActual() async {
    Database db = await database;
    return await db.delete('estudiante');
  }

  // Verificar si existe estudiante con UID
  Future<bool> existeEstudianteConUID(String uid) async {
    Database db = await database;
    final result = await db.query(
      'estudiante',
      where: 'uid_firebase = ?',
      whereArgs: [uid],
    );
    return result.isNotEmpty;
  }

  // ===============================================
  //TODO MÉTODOS CRUD PARA CALENDARIO

  // ===============================================

  // Insertar actividad en el calendario
  Future<int> insertActividad(Map<String, dynamic> actividad) async {
    Database db = await database;
    return await db.insert('calendario', actividad);
  }

  // Obtener actividades por estudiante
  Future<List<Map<String, dynamic>>> getActividadesPorEstudiante(
      int idEstudiante) async {
    Database db = await database;
    return await db.query(
      'calendario',
      where: 'id_estudiante = ?',
      whereArgs: [idEstudiante],
    );
  }

  // ===============================================
  //TODO MÉTODOS CRUD PARA SESIONES

  // ===============================================

  // Insertar sesión
  Future<int> insertSesion(Map<String, dynamic> sesion) async {
    Database db = await database;
    return await db.insert('sesiones', sesion);
  }

  // Obtener sesiones por estudiante
  Future<List<Map<String, dynamic>>> getSesionesPorEstudiante(
      int idEstudiante) async {
    Database db = await database;
    return await db.query(
      'sesiones',
      where: 'id_estudiante_sesion = ?',
      whereArgs: [idEstudiante],
    );
  }

  // ===============================================
  //TODO MÉTODOS CRUD PARA EJERCICIOS

  // ===============================================

  //LOCAL

  // Insertar ejercicio
  Future<int> insertEjercicio(Map<String, dynamic> ejercicio) async {
    Database db = await database;
    return await db.insert('ejercicios', ejercicio);
  }

  // Obtener todos los ejercicios
  Future<List<Map<String, dynamic>>> getAllEjercicios() async {
    Database db = await database;
    return await db.query('ejercicios');
  }

  // Obtener ejercicios por tipo
  Future<List<Map<String, dynamic>>> getEjerciciosByTipo(String tipo) async {
    Database db = await database;
    return await db.query(
      'ejercicios',
      where: 'tipo = ?',
      whereArgs: [tipo],
    );
  }

  //Borrar Todos los ejercicios
  Future<int> deleteAllEjercicios() async {
    Database db = await database;
    return await db.delete('ejercicios');
  }

  // SUPABASE

  Future<Map<String, dynamic>?> createEjercicio({
    required String titulo,
    String? descripcion,
    String? categoria,
    required String tipo,
    int? duracionMinutos,
    String? dificultad,
    String? objetivos,
    String? instrucciones,
  }) async {
    try {
      final data = {
        'titulo': titulo,
        'descripcion': descripcion,
        'categoria': categoria,
        'tipo': tipo,
        'duracion_minutos': duracionMinutos,
        'dificultad': dificultad,
        'objetivos': objetivos,
        'instrucciones': instrucciones,
        'fecha_creacion': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase.from('ejercicios').insert(data).select().single();

      return response;
    } catch (e) {
      LogService.log('Error creating ejercicio: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> readEjercicios() async {
    try {
      final response = await _supabase
          .from('ejercicios')
          .select()
          .order('fecha_creacion', ascending: false);

      // Guardar en SQLite
      final db = await database;
      await db.delete('ejercicios');

      for (var ejercicio in response) {
        await db.insert('ejercicios', ejercicio);
      }

      return response;
    } catch (e) {
      LogService.log('Error reading ejercicios: $e');
      // Si falla, retornar datos locales
      final db = await database;
      return await db.query('ejercicios');
    }
  }

  Future<bool> updateEjercicio(int id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('ejercicios').update(data).eq('id_ejercicio', id);

      return true;
    } catch (e) {
      LogService.log('Error updating ejercicio: $e');
      return false;
    }
  }

  Future<bool> deleteEjercicio(int id) async {
    try {
      await _supabase.from('ejercicios').delete().eq('id_ejercicio', id);

      return true;
    } catch (e) {
      LogService.log('Error deleting ejercicio: $e');
      return false;
    }
  }

  Future<void> syncEjercicios() async {
    await deleteAllEjercicios();
    await readEjercicios();
  }

  // ===============================================
  //TODO MÉTODOS CRUD PARA PROGRESO DE EJERCICIOS

  // ===============================================

  // Insertar progreso de ejercicio
  Future<int> insertProgresoEjercicio(Map<String, dynamic> progreso) async {
    Database db = await database;
    return await db.insert('progreso_ejercicio', progreso);
  }

  // Obtener progreso de ejercicios por estudiante
  Future<List<Map<String, dynamic>>> getProgresoEjerciciosByStudent(
      int idEstudiante) async {
    Database db = await database;
    return await db.query(
      'progreso_ejercicio',
      where: 'id_estudiante = ?',
      whereArgs: [idEstudiante],
      orderBy: 'fecha_realizacion DESC',
    );
  }

  // ===============================================
  //TODO MÉTODOS CRUD PARA DIARIO

  // ===============================================

  // Insertar entrada de diario
  Future<int> insertDiarioEntryEnhanced(Map<String, dynamic> entry) async {
    Database db = await database;
    return await db.insert('diario_entries', entry);
  }

  // Obtener entradas de diario con filtros
  Future<List<Map<String, dynamic>>> getDiarioEntriesFiltered(
    int idEstudiante, {
    String? categoria,
    String? estadoAnimo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? busqueda,
  }) async {
    Database db = await database;

    String where = 'id_estudiante = ?';
    List<dynamic> whereArgs = [idEstudiante];

    if (categoria != null) {
      where += ' AND categoria = ?';
      whereArgs.add(categoria);
    }

    if (estadoAnimo != null) {
      where += ' AND estado_animo = ?';
      whereArgs.add(estadoAnimo);
    }

    if (fechaInicio != null) {
      where += ' AND fecha >= ?';
      whereArgs.add(DateFormat('yyyy-MM-dd').format(fechaInicio));
    }

    if (fechaFin != null) {
      where += ' AND fecha <= ?';
      whereArgs.add(DateFormat('yyyy-MM-dd').format(fechaFin));
    }

    if (busqueda != null && busqueda.isNotEmpty) {
      where +=
          ' AND (contenido LIKE ? OR categoria LIKE ? OR estado_animo LIKE ?)';
      whereArgs.addAll(['%$busqueda%', '%$busqueda%', '%$busqueda%']);
    }

    return await db.query(
      'diario_entries',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'fecha DESC, timestamp DESC',
    );
  }

  // Actualizar entrada de diario
  Future<int> updateDiarioEntryEnhanced(
      int id, Map<String, dynamic> entry) async {
    Database db = await database;
    return await db.update(
      'diario_entries',
      entry,
      where: 'id_diario = ?',
      whereArgs: [id],
    );
  }

  // Eliminar entrada de diario
  Future<int> deleteDiarioEntry(int id) async {
    Database db = await database;
    return await db.delete(
      'diario_entries',
      where: 'id_diario = ?',
      whereArgs: [id],
    );
  }

  // ===============================================
  //TODO MÉTODOS PARA CITAS Y ANÁLISIS

  // ===============================================

  // Obtener información completa de citas (con JOIN)
  Future<List<Map<String, dynamic>>> getCitasCompletas() async {
    Database db = await database;
    return await db.rawQuery('''
      SELECT 
        ac.id_agendacita,
        ac.fecha_cita,
        ac.motivo_cita,
        ac.confirmacion_cita,
        e.nombre || ' ' || e.apellido as nombre_estudiante,
        b.nombre || ' ' || b.apellido as nombre_bienestar
      FROM agenda_cita ac
      JOIN estudiante e ON ac.id_estudiante = e.id_estudiante
      JOIN bienestar b ON ac.id_bienestar = b.id_bienestar
    ''');
  }

  // Obtener todos los análisis históricos
  Future<List<Map<String, dynamic>>> getTodosLosAnalisis() async {
    final db = await database;
    return await db.query(
      'analisis_sesiones',
      orderBy: 'fecha_creacion DESC',
    );
  }

  // Obtener análisis por nivel de riesgo
  Future<List<Map<String, dynamic>>> getAnalisisPorRiesgo(
      String nivelRiesgo) async {
    final db = await database;
    return await db.query(
      'analisis_sesiones',
      where: 'nivel_riesgo = ?',
      whereArgs: [nivelRiesgo],
      orderBy: 'fecha_creacion DESC',
    );
  }

  // ===============================================
  //TODO ESTADÍSTICAS DEL DIARIO

  // ===============================================

  Future<Map<String, dynamic>> getDiarioStatistics(int idEstudiante) async {
    Database db = await database;

    // Total de entradas
    final totalResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM diario_entries WHERE id_estudiante = ?',
        [idEstudiante]);
    final totalEntradas = totalResult.first['count'] as int;

    // Entradas este mes
    final now = DateTime.now();
    final firstDayMonth = DateTime(now.year, now.month, 1);
    final monthResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM diario_entries WHERE id_estudiante = ? AND fecha >= ?',
        [idEstudiante, DateFormat('yyyy-MM-dd').format(firstDayMonth)]);
    final entradasEsteMes = monthResult.first['count'] as int;

    // Estado de ánimo más común
    final estadoResult = await db.rawQuery(
        'SELECT estado_animo, COUNT(*) as count FROM diario_entries WHERE id_estudiante = ? AND estado_animo IS NOT NULL GROUP BY estado_animo ORDER BY count DESC LIMIT 1',
        [idEstudiante]);
    final estadoAnimoMasComun =
        estadoResult.isNotEmpty ? estadoResult.first['estado_animo'] : null;

    // Categoría más usada
    final categoriaResult = await db.rawQuery(
        'SELECT categoria, COUNT(*) as count FROM diario_entries WHERE id_estudiante = ? AND categoria IS NOT NULL GROUP BY categoria ORDER BY count DESC LIMIT 1',
        [idEstudiante]);
    final categoriaMasUsada =
        categoriaResult.isNotEmpty ? categoriaResult.first['categoria'] : null;

    // Promedio de valoración
    final valoracionResult = await db.rawQuery(
        'SELECT AVG(valoracion) as avg FROM diario_entries WHERE id_estudiante = ? AND valoracion IS NOT NULL',
        [idEstudiante]);
    final promedioValoracion = valoracionResult.first['avg'] as double? ?? 0.0;

    // Racha de escritura
    final rachaResult = await db.rawQuery(
        'SELECT fecha FROM diario_entries WHERE id_estudiante = ? ORDER BY fecha DESC',
        [idEstudiante]);

    int rachaEscritura = 0;
    if (rachaResult.isNotEmpty) {
      DateTime fechaActual = DateTime.now();
      for (final row in rachaResult) {
        final fechaStr = row['fecha'] as String;
        final fecha = DateTime.parse(fechaStr);
        final diferencia = fechaActual.difference(fecha).inDays;

        if (diferencia == rachaEscritura) {
          rachaEscritura++;
        } else {
          break;
        }
      }
    }

    return {
      'totalEntradas': totalEntradas,
      'entradasEsteMes': entradasEsteMes,
      'estadoAnimoMasComun': estadoAnimoMasComun,
      'categoriaMasUsada': categoriaMasUsada,
      'promedioValoracion': promedioValoracion,
      'rachaEscritura': rachaEscritura,
    };
  }

  // ===============================================
  //TODO MÉTODOS UTILITARIOS Y ADMINISTRACIÓN

  // ===============================================

  // Cerrar la base de datos
  Future<void> close() async {
    Database db = await database;
    await db.close();
  }

  // Obtener todas las tablas de la base de datos
  Future<List<String>> getTables() async {
    final db = await database;
    final tables = await db.query(
      'sqlite_master',
      where: 'type = ?',
      whereArgs: ['table'],
      orderBy: 'name',
    );
    // Filtrar las tablas que no son del sistema
    return tables
        .map((e) => e['name'] as String)
        .where(
            (name) => !name.startsWith('sqlite_') && name != 'android_metadata')
        .toList();
  }

  // Exportar la base de datos a un archivo (para escritorio/móvil)
  Future<String> exportDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    // Aquí puedes implementar la lógica para copiar el archivo a una ubicación accesible
    // Por ejemplo, al directorio de descargas del usuario.
    // Esto es solo un ejemplo, la implementación real puede variar.
    // final newPath = join(await getExternalStorageDirectory(), 'database_backup.db');
    // await File(path).copy(newPath);

    return path; // Retornar la ruta del archivo de la DB
  }

  // Obtener los datos de una tabla de forma genérica
  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    final db = await database;
    return await db.query(tableName);
  }

  // Obtener el esquema (columnas) de una tabla
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async {
    final db = await database;
    return await db.rawQuery('PRAGMA table_info("$tableName")');
  }

  // Eliminar un registro por ID
  Future<void> deleteRecord(
      String tableName, int id, String primaryKeyColumn) async {
    final db = await database;
    await db.delete(
      tableName,
      where: '$primaryKeyColumn = ?',
      whereArgs: [id],
    );
  }

  // Limpiar una tabla completa
  Future<void> clearTable(String tableName) async {
    final db = await database;
    await db.delete(tableName);
  }

  //TODO Sincronización con Supabase

  // =================== AGENDA CITA ===================

  Future<Map<String, dynamic>?> createAgendaCita({
    required DateTime fechaCita,
    String? motivoCita,
    bool confirmacionCita = false,
    String estadoCita = 'programada',
    String? notasAdicionales,
    String? diagnostico,
    required String nombreEstudiante,
    required String estudianteUid,
    String? adminId,
    String? adminConfirmador,
    DateTime? fechaConfirmacion,
  }) async {
    try {
      final data = {
        'fecha_cita': fechaCita.toIso8601String(),
        'motivo_cita': motivoCita,
        'confirmacion_cita': confirmacionCita,
        'estado_cita': estadoCita,
        'notas_adicionales': notasAdicionales,
        'diagnostico': diagnostico,
        'nombre_estudiante': nombreEstudiante,
        'estudiante_uid': estudianteUid,
        'admin_id': adminId,
        'admin_confirmador': adminConfirmador,
        'fecha_confirmacion': fechaConfirmacion?.toIso8601String(),
        'fecha_creacion': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase.from('agenda_cita').insert(data).select().single();

      return response;
    } catch (e, stack) {
      LogService.log('Error creating agenda cita: $e\n$stack');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> readAgendaCitas() async {
    try {
      final response = await _supabase
          .from('agenda_cita')
          .select()
          .order('fecha_cita', ascending: true);

      LogService.log(
          'Sincronizando ${response.length} citas desde Supabase...');
      LogService.log('Respuesta de Supabase: $response');
      // Guardar en SQLite
      final db = await database;
      print('Borrando citas locales antes de sincronizar...');
      await db.delete('agenda_cita');
      for (var cita in response) {
        LogService.log('Cita guardada localmente: ${cita['id_agendacita']}');
      }
      LogService.log('Total citas sincronizadas: ${response.length}');
      return response;
    } catch (e) {
      LogService.log('Error reading agenda citas: $e');
      // Si falla, retornar datos locales
      final db = await database;
      return await db.query('agenda_cita');
    }
  }

  Future<List<Map<String, dynamic>>> readAgendaCitasPorUid({
    required String estudianteUid,
  }) async {
    try {
      // Llamada a la función RPC en Supabase
      final response = await _supabase.rpc(
        'get_citas_usuario',
        params: {'p_estudiante_uid': estudianteUid},
      );

      // En algunas versiones de supabase_flutter 2.x, response es directamente List<dynamic>
      if (response == null) {
        print('No se encontraron citas para el usuario: $estudianteUid');
        return [];
      }

      if (response is! List) {
        print(
            'Warning: RPC response no es una lista, es: ${response.runtimeType}');
        return [];
      }

      // Convertimos cada elemento a Map<String, dynamic>
      return (response as List)
          .map((cita) => Map<String, dynamic>.from(cita))
          .toList();
    } catch (e, stack) {
      LogService.log('Error reading agenda citas: $e');
      print(stack);
      return [];
    }
  }

  Future<bool> updateAgendaCita(int id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('agenda_cita').update(data).eq('id_agendacita', id);

      return true;
    } catch (e) {
      LogService.log('Error updating agenda cita: $e');
      return false;
    }
  }

  Future<bool> deleteAgendaCita(int id) async {
    try {
      await _supabase.from('agenda_cita').delete().eq('id_agendacita', id);

      return true;
    } catch (e) {
      LogService.log('Error deleting agenda cita: $e');
      return false;
    }
  }

  // =================== LIBROS ===================

  Future<Map<String, dynamic>?> createLibro({
    required String id,
    required String nombre,
    required String contenido,
    required DateTime fechaSubido,
    required int tamano,
    bool sincronizado = true,
  }) async {
    try {
      final data = {
        'id': id,
        'nombre': nombre,
        'contenido': contenido,
        'fecha_subido': fechaSubido.toIso8601String(),
        'tamaño': tamano,
        'sincronizado': sincronizado,
      };

      final response =
          await _supabase.from('libros').insert(data).select().single();

      return response;
    } catch (e) {
      LogService.log('Error creating libro: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> readLibros() async {
    try {
      final response = await _supabase
          .from('libros')
          .select()
          .order('fecha_subido', ascending: false);

      // Guardar en SQLite
      final db = await database;
      await db.delete('libros');

      for (var libro in response) {
        await db.insert('libros', {
          'id': libro['id'],
          'nombre': libro['nombre'],
          'contenido': libro['contenido'],
          'fecha_subido': libro['fecha_subido'],
          'tamaño': libro['tamaño'],
          'sincronizado': libro['sincronizado'] ? 1 : 0,
        });
      }

      return response;
    } catch (e) {
      LogService.log('Error reading libros: $e');
      // Si falla, retornar datos locales
      final db = await database;
      return await db.query('libros');
    }
  }

  Future<bool> updateLibro(String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('libros').update(data).eq('id', id);

      return true;
    } catch (e) {
      LogService.log('Error updating libro: $e');
      return false;
    }
  }

  Future<bool> deleteLibro(String id) async {
    try {
      await _supabase.from('libros').delete().eq('id', id);

      return true;
    } catch (e) {
      LogService.log('Error deleting libro: $e');
      return false;
    }
  }

  // =================== MODULOS ===================

  Future<Map<String, dynamic>?> createModulo({
    required String id,
    required String titulo,
    required String contenido,
    required DateTime fechaCreacion,
    required DateTime fechaActualizacion,
    bool sincronizado = true,
  }) async {
    try {
      final data = {
        'id': id,
        'titulo': titulo,
        'contenido': contenido,
        'fecha_creacion': fechaCreacion.toIso8601String(),
        'fecha_actualizacion': fechaActualizacion.toIso8601String(),
        'sincronizado': sincronizado,
      };

      final response =
          await _supabase.from('modulos').insert(data).select().single();

      return response;
    } catch (e) {
      LogService.log('Error creating modulo: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> readModulos() async {
    try {
      final response = await _supabase
          .from('modulos')
          .select()
          .order('fecha_creacion', ascending: false);

      // Guardar en SQLite
      final db = await database;
      await db.delete('modulos');

      for (var modulo in response) {
        await db.insert('modulos', {
          'id': modulo['id'],
          'titulo': modulo['titulo'],
          'contenido': modulo['contenido'],
          'fecha_creacion': modulo['fecha_creacion'],
          'fecha_actualizacion': modulo['fecha_actualizacion'],
          'sincronizado': modulo['sincronizado'] ? 1 : 0,
        });
      }

      return response;
    } catch (e) {
      LogService.log('Error reading modulos: $e');
      // Si falla, retornar datos locales
      final db = await database;
      return await db.query('modulos');
    }
  }

  Future<bool> updateModulo(String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('modulos').update(data).eq('id', id);

      return true;
    } catch (e) {
      LogService.log('Error updating modulo: $e');
      return false;
    }
  }

  Future<bool> deleteModulo(String id) async {
    try {
      await _supabase.from('modulos').delete().eq('id', id);

      return true;
    } catch (e) {
      LogService.log('Error deleting modulo: $e');
      return false;
    }
  }

  // =================== MODULO IMAGENES ===================

  Future<Map<String, dynamic>?> createModuloImagen({
    required String filePath,
    required String moduloId,
    int orden = 0,
  }) async {
    try {
      // Generar nombre único
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

      // Subir imagen al bucket
      final uploadResponse = await _supabase.storage
          .from('modulo_imagenes') // nombre del bucket en Supabase
          .upload(fileName, File(filePath));

      if (uploadResponse.isEmpty) {
        throw Exception('Error al subir la imagen');
      }

      // Obtener URL pública
      final imageUrl =
          _supabase.storage.from('modulo_imagenes').getPublicUrl(fileName);

      // Insertar registro en la tabla
      final data = {
        'id': const Uuid().v4(),
        'modulo_id': moduloId,
        'url': imageUrl,
        'orden': orden,
      };

      final response = await _supabase
          .from('modulo_imagenes')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      LogService.log('Error creando módulo imagen: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> readModuloImagenes(
      {String? moduloId}) async {
    try {
      var query = _supabase.from('modulo_imagenes').select();

      if (moduloId != null) {
        query = query.eq('modulo_id', moduloId);
      }

      final response = await query.order('orden', ascending: true);

      // Guardar en SQLite
      final db = await database;
      if (moduloId != null) {
        await db.delete('modulo_imagenes',
            where: 'modulo_id = ?', whereArgs: [moduloId]);
      } else {
        await db.delete('modulo_imagenes');
      }

      for (var imagen in response) {
        await db.insert('modulo_imagenes', imagen);
      }

      return response;
    } catch (e) {
      LogService.log('Error reading modulo imagenes: $e');
      // Si falla, retornar datos locales
      final db = await database;
      if (moduloId != null) {
        return await db.query('modulo_imagenes',
            where: 'modulo_id = ?', whereArgs: [moduloId]);
      }
      return await db.query('modulo_imagenes');
    }
  }

  Future<bool> updateModuloImagen(String id, Map<String, dynamic> data) async {
    try {
      await _supabase.from('modulo_imagenes').update(data).eq('id', id);

      return true;
    } catch (e) {
      LogService.log('Error updating modulo imagen: $e');
      return false;
    }
  }

  Future<bool> deleteModuloImagen(String id) async {
    try {
      await _supabase.from('modulo_imagenes').delete().eq('id', id);

      return true;
    } catch (e) {
      LogService.log('Error deleting modulo imagen: $e');
      return false;
    }
  }

  // =================== UTILIDADES ===================

  Future<void> syncAllData() async {
    await readEjercicios();
    await readLibros();
    await readModulos();
    await readModuloImagenes();
  }

  Future<void> clearLocalData() async {
    final db = await database;
    await db.delete('agenda_cita');
    await db.delete('ejercicios');
    await db.delete('libros');
    await db.delete('modulos');
    await db.delete('modulo_imagenes');
  }

  // Añadir estos métodos a la clase DatabaseHelper

// =================== GESTIÓN DE ARCHIVOS MULTIMEDIA ===================

  /// Sube un archivo (imagen o video) al storage de Supabase
  Future<Map<String, dynamic>?> uploadFileToStorage({
    required String filePath,
    required String bucketName,
    String? customFileName,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('El archivo no existe en la ruta especificada');
      }

      // Generar nombre único si no se proporciona uno personalizado
      final fileName = customFileName ??
          '${DateTime.now().millisecondsSinceEpoch}_${filePath.split('/').last}';

      // Subir archivo al bucket
      final uploadResponse =
          await _supabase.storage.from(bucketName).upload(fileName, file);

      if (uploadResponse.isEmpty) {
        throw Exception('Error al subir el archivo');
      }

      // Obtener URL pública
      final publicUrl =
          _supabase.storage.from(bucketName).getPublicUrl(fileName);

      // Obtener información del archivo
      final fileSize = await file.length();
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Determinar tipo de archivo
      String tipoArchivo = 'unknown';
      if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension)) {
        tipoArchivo = 'image';
      } else if (['mp4', 'avi', 'mov', 'wmv', 'flv', 'webm']
          .contains(fileExtension)) {
        tipoArchivo = 'video';
      }

      return {
        'fileName': fileName,
        'publicUrl': publicUrl,
        'fileSize': fileSize,
        'fileType': tipoArchivo,
        'extension': fileExtension,
      };
    } catch (e) {
      LogService.log('Error uploading file: $e');
      return null;
    }
  }

  /// Elimina un archivo del storage de Supabase
  Future<bool> deleteFileFromStorage({
    required String fileName,
    required String bucketName,
  }) async {
    try {
      await _supabase.storage.from(bucketName).remove([fileName]);
      return true;
    } catch (e) {
      LogService.log('Error deleting file: $e');
      return false;
    }
  }

  /// Crea una imagen asociada a un módulo con archivo subido
  Future<Map<String, dynamic>?> createModuloImagenWithFile({
    required String filePath,
    required String moduloId,
    int orden = 0,
    String? descripcion,
  }) async {
    try {
      // Subir archivo
      final uploadResult = await uploadFileToStorage(
        filePath: filePath,
        bucketName: 'modulo_archivos', // Nombre del bucket
      );

      if (uploadResult == null) {
        throw Exception('Error al subir el archivo');
      }

      // Insertar registro en la tabla
      final data = {
        'id': const Uuid().v4(),
        'modulo_id': moduloId,
        'url': uploadResult['publicUrl'],
        'orden': orden,
        'tipo_archivo': uploadResult['fileType'],
        'nombre_archivo': uploadResult['fileName'],
        'tamaño': uploadResult['fileSize'],
        'descripcion': descripcion,
      };

      final response = await _supabase
          .from('modulo_imagenes')
          .insert(data)
          .select()
          .single();

      // También guardar en SQLite local
      final db = await database;
      await db.insert('modulo_imagenes', {
        'id': data['id'],
        'modulo_id': data['modulo_id'],
        'url': data['url'],
        'orden': data['orden'],
        'tipo_archivo': data['tipo_archivo'],
        'nombre_archivo': data['nombre_archivo'],
        'tamaño': data['tamaño'],
        'descripcion': data['descripcion'],
      });

      return response;
    } catch (e) {
      LogService.log('Error creando módulo imagen con archivo: $e');
      return null;
    }
  }

  /// Elimina una imagen/video del módulo y del storage
  Future<bool> deleteModuloImagenWithFile(String id) async {
    try {
      // Obtener información del archivo antes de eliminarlo
      final response = await _supabase
          .from('modulo_imagenes')
          .select('nombre_archivo')
          .eq('id', id)
          .single();

      final nombreArchivo = response['nombre_archivo'] as String?;

      // Eliminar registro de la base de datos
      await _supabase.from('modulo_imagenes').delete().eq('id', id);

      // Eliminar archivo del storage si existe
      if (nombreArchivo != null) {
        await deleteFileFromStorage(
          fileName: nombreArchivo,
          bucketName: 'modulo_archivos',
        );
      }

      // También eliminar de SQLite local
      final db = await database;
      await db.delete('modulo_imagenes', where: 'id = ?', whereArgs: [id]);

      return true;
    } catch (e) {
      LogService.log('Error eliminando módulo imagen con archivo: $e');
      return false;
    }
  }

  /// Actualiza el esquema de la tabla modulo_imagenes para incluir nuevos campos
  Future<void> updateModuloImagenesSchema() async {
    final db = await database;

    try {
      // Añadir nuevas columnas si no existen
      await db
          .execute('ALTER TABLE modulo_imagenes ADD COLUMN tipo_archivo TEXT');
      await db.execute(
          'ALTER TABLE modulo_imagenes ADD COLUMN nombre_archivo TEXT');
      await db.execute('ALTER TABLE modulo_imagenes ADD COLUMN tamaño INTEGER');
      await db
          .execute('ALTER TABLE modulo_imagenes ADD COLUMN descripcion TEXT');
    } catch (e) {
      // Las columnas ya existen, continuar
      LogService.log('Columnas ya existen o error al añadir: $e');
    }
  }

  /// Obtiene imágenes/videos de un módulo con información completa
  Future<List<Map<String, dynamic>>> getModuloArchivos(String moduloId) async {
    try {
      final response = await _supabase
          .from('modulo_imagenes')
          .select()
          .eq('modulo_id', moduloId)
          .order('orden', ascending: true);

      // Guardar en SQLite
      final db = await database;
      await db.delete('modulo_imagenes',
          where: 'modulo_id = ?', whereArgs: [moduloId]);

      for (var archivo in response) {
        await db.insert('modulo_imagenes', archivo);
      }

      return response;
    } catch (e) {
      LogService.log('Error reading modulo archivos: $e');
      // Si falla, retornar datos locales
      final db = await database;
      return await db.query('modulo_imagenes',
          where: 'modulo_id = ?', whereArgs: [moduloId]);
    }
  }

  // ===============================================
// MÉTODOS CRUD PARA EMOCIONES GENERALIZADAS (TIEMPO REAL)
// ===============================================

  /// Obtiene las opciones de filtros disponibles desde Supabase
  Future<Map<String, List<String>>> getEmocionesFiltros() async {
    try {
      final response = await _supabase
          .from('emociones_generalizadas')
          .select('sede, carrera, ciclo, emocion');

      Set<String> sedes = {};
      Set<String> carreras = {};
      Set<String> ciclos = {};
      Set<String> emociones = {};

      for (var row in response) {
        if (row['sede'] != null) sedes.add(row['sede']);
        if (row['carrera'] != null) carreras.add(row['carrera']);
        if (row['ciclo'] != null) ciclos.add(row['ciclo']);
        if (row['emocion'] != null) emociones.add(row['emocion']);
      }

      return {
        'sedes': sedes.toList()..sort(),
        'carreras': carreras.toList()..sort(),
        'ciclos': ciclos.toList()..sort(),
        'emociones': emociones.toList()..sort(),
      };
    } catch (e) {
      LogService.log('Error getting emociones filtros: $e');
      return {
        'sedes': <String>[],
        'carreras': <String>[],
        'ciclos': <String>[],
        'emociones': <String>[],
      };
    }
  }

  /// Obtiene estadísticas de emociones con filtros aplicados
  Future<List<Map<String, dynamic>>> getEmocionesEstadisticas({
    String? sede,
    String? carrera,
    String? ciclo,
    String? emocion,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      var query = _supabase.from('emociones_generalizadas').select();

      // Aplicar filtros
      if (sede != null) {
        query = query.eq('sede', sede);
      }
      if (carrera != null) {
        query = query.eq('carrera', carrera);
      }
      if (ciclo != null) {
        query = query.eq('ciclo', ciclo);
      }
      if (emocion != null) {
        query = query.eq('emocion', emocion);
      }
      if (fechaInicio != null) {
        query =
            query.gte('fecha', DateFormat('yyyy-MM-dd').format(fechaInicio));
      }
      if (fechaFin != null) {
        query = query.lte('fecha', DateFormat('yyyy-MM-dd').format(fechaFin));
      }

      final response = await query.order('fecha', ascending: false);
      return response;
    } catch (e) {
      LogService.log('Error getting emociones estadisticas: $e');
      return [];
    }
  }

  /// Obtiene resumen de emociones (totales por período)
  Future<Map<String, dynamic>> getResumenEmociones({
    String? sede,
    String? carrera,
    String? ciclo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      var query =
          _supabase.from('emociones_generalizadas').select('cantidad, fecha');

      // Aplicar filtros
      if (sede != null) {
        query = query.eq('sede', sede);
      }
      if (carrera != null) {
        query = query.eq('carrera', carrera);
      }
      if (ciclo != null) {
        query = query.eq('ciclo', ciclo);
      }
      if (fechaInicio != null) {
        query =
            query.gte('fecha', DateFormat('yyyy-MM-dd').format(fechaInicio));
      }
      if (fechaFin != null) {
        query = query.lte('fecha', DateFormat('yyyy-MM-dd').format(fechaFin));
      }

      final response = await query;

      int total = 0;
      int hoy = 0;
      int semana = 0;
      int mes = 0;

      final now = DateTime.now();
      final fechaHoy = DateFormat('yyyy-MM-dd').format(now);
      final inicioSemana = now.subtract(Duration(days: now.weekday - 1));
      final fechaInicioSemana = DateFormat('yyyy-MM-dd').format(inicioSemana);
      final fechaInicioMes =
          DateFormat('yyyy-MM-dd').format(DateTime(now.year, now.month, 1));

      for (var row in response) {
        final cantidad = (row['cantidad'] as int?) ?? 0;
        final fecha = row['fecha'] as String;

        total += cantidad;

        if (fecha == fechaHoy) {
          hoy += cantidad;
        }

        if (fecha.compareTo(fechaInicioSemana) >= 0) {
          semana += cantidad;
        }

        if (fecha.compareTo(fechaInicioMes) >= 0) {
          mes += cantidad;
        }
      }

      return {
        'total': total,
        'hoy': hoy,
        'semana': semana,
        'mes': mes,
      };
    } catch (e) {
      LogService.log('Error getting resumen emociones: $e');
      return {
        'total': 0,
        'hoy': 0,
        'semana': 0,
        'mes': 0,
      };
    }
  }

  /// Obtiene estadísticas por emoción (para gráficos)
  Future<List<Map<String, dynamic>>> getEmocionesAgrupadas({
    String? sede,
    String? carrera,
    String? ciclo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      var query = _supabase.from('emociones_generalizadas').select();

      // Aplicar filtros
      if (sede != null) {
        query = query.eq('sede', sede);
      }
      if (carrera != null) {
        query = query.eq('carrera', carrera);
      }
      if (ciclo != null) {
        query = query.eq('ciclo', ciclo);
      }
      if (fechaInicio != null) {
        query =
            query.gte('fecha', DateFormat('yyyy-MM-dd').format(fechaInicio));
      }
      if (fechaFin != null) {
        query = query.lte('fecha', DateFormat('yyyy-MM-dd').format(fechaFin));
      }

      final response = await query;

      // Agrupar por emoción
      Map<String, int> agrupado = {};
      for (var row in response) {
        final emocion = row['emocion'] as String;
        final cantidad = (row['cantidad'] as int?) ?? 0;

        agrupado[emocion] = (agrupado[emocion] ?? 0) + cantidad;
      }

      // Convertir a lista ordenada
      List<Map<String, dynamic>> resultado = [];
      agrupado.entries.forEach((entry) {
        resultado.add({
          'emocion': entry.key,
          'total': entry.value,
        });
      });

      // Ordenar por cantidad (mayor a menor)
      resultado
          .sort((a, b) => (b['total'] as int).compareTo(a['total'] as int));

      return resultado;
    } catch (e) {
      LogService.log('Error getting emociones agrupadas: $e');
      return [];
    }
  }

  /// Obtiene tendencia de emociones por fecha
  Future<List<Map<String, dynamic>>> getTendenciaEmociones({
    String? sede,
    String? carrera,
    String? ciclo,
    String? emocion,
    int? ultimosDias = 30,
  }) async {
    try {
      var query = _supabase.from('emociones_generalizadas').select();

      // Aplicar filtros
      if (sede != null) {
        query = query.eq('sede', sede);
      }
      if (carrera != null) {
        query = query.eq('carrera', carrera);
      }
      if (ciclo != null) {
        query = query.eq('ciclo', ciclo);
      }
      if (emocion != null) {
        query = query.eq('emocion', emocion);
      }

      // Filtro de fecha (últimos N días)
      if (ultimosDias != null) {
        final fechaLimite =
            DateTime.now().subtract(Duration(days: ultimosDias));
        query =
            query.gte('fecha', DateFormat('yyyy-MM-dd').format(fechaLimite));
      }

      final response = await query.order('fecha', ascending: true);

      // Agrupar por fecha
      Map<String, int> agrupado = {};
      for (var row in response) {
        final fecha = row['fecha'] as String;
        final cantidad = (row['cantidad'] as int?) ?? 0;

        agrupado[fecha] = (agrupado[fecha] ?? 0) + cantidad;
      }

      // Convertir a lista
      List<Map<String, dynamic>> resultado = [];
      agrupado.entries.forEach((entry) {
        resultado.add({
          'fecha': entry.key,
          'cantidad': entry.value,
        });
      });

      return resultado;
    } catch (e) {
      LogService.log('Error getting tendencia emociones: $e');
      return [];
    }
  }

  /// Crea un nuevo registro de emoción generalizada
  Future<Map<String, dynamic>?> createEmocionGeneralizada({
    required String emocion,
    required String sede,
    required String carrera,
    required String ciclo,
    required DateTime fecha,
    int cantidad = 1,
  }) async {
    try {
      // Verificar si ya existe un registro para esta combinación
      final existing = await _supabase
          .from('emociones_generalizadas')
          .select()
          .eq('emocion', emocion)
          .eq('sede', sede)
          .eq('carrera', carrera)
          .eq('ciclo', ciclo)
          .eq('fecha', DateFormat('yyyy-MM-dd').format(fecha))
          .maybeSingle();

      if (existing != null) {
        // Actualizar cantidad existente
        final nuevaCantidad = (existing['cantidad'] as int) + cantidad;

        final response = await _supabase
            .from('emociones_generalizadas')
            .update({'cantidad': nuevaCantidad})
            .eq('id', existing['id'])
            .select()
            .single();

        return response;
      } else {
        // Crear nuevo registro
        final data = {
          'emocion': emocion,
          'sede': sede,
          'carrera': carrera,
          'ciclo': ciclo,
          'fecha': DateFormat('yyyy-MM-dd').format(fecha),
          'cantidad': cantidad,
        };

        final response = await _supabase
            .from('emociones_generalizadas')
            .insert(data)
            .select()
            .single();

        return response;
      }
    } catch (e) {
      LogService.log('Error creating emocion generalizada: $e');
      return null;
    }
  }

  /// Obtiene reportes avanzados de emociones
  Future<Map<String, dynamic>> getReportesAvanzados({
    String? sede,
    String? carrera,
    String? ciclo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
  }) async {
    try {
      final estadisticas = await getEmocionesEstadisticas(
        sede: sede,
        carrera: carrera,
        ciclo: ciclo,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      final agrupadas = await getEmocionesAgrupadas(
        sede: sede,
        carrera: carrera,
        ciclo: ciclo,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
      );

      final tendencia = await getTendenciaEmociones(
        sede: sede,
        carrera: carrera,
        ciclo: ciclo,
        ultimosDias: 30,
      );

      // Calcular métricas adicionales
      Map<String, int> porSede = {};
      Map<String, int> porCarrera = {};
      Map<String, int> porCiclo = {};

      for (var item in estadisticas) {
        final cantidad = (item['cantidad'] as int?) ?? 0;

        // Agrupar por sede
        final sedeItem = item['sede'] as String;
        porSede[sedeItem] = (porSede[sedeItem] ?? 0) + cantidad;

        // Agrupar por carrera
        final carreraItem = item['carrera'] as String;
        porCarrera[carreraItem] = (porCarrera[carreraItem] ?? 0) + cantidad;

        // Agrupar por ciclo
        final cicloItem = item['ciclo'] as String;
        porCiclo[cicloItem] = (porCiclo[cicloItem] ?? 0) + cantidad;
      }

      return {
        'resumen': await getResumenEmociones(
          sede: sede,
          carrera: carrera,
          ciclo: ciclo,
          fechaInicio: fechaInicio,
          fechaFin: fechaFin,
        ),
        'emociones_agrupadas': agrupadas,
        'tendencia': tendencia,
        'por_sede': porSede,
        'por_carrera': porCarrera,
        'por_ciclo': porCiclo,
        'total_registros': estadisticas.length,
      };
    } catch (e) {
      LogService.log('Error getting reportes avanzados: $e');
      return {
        'resumen': {'total': 0, 'hoy': 0, 'semana': 0, 'mes': 0},
        'emociones_agrupadas': [],
        'tendencia': [],
        'por_sede': {},
        'por_carrera': {},
        'por_ciclo': {},
        'total_registros': 0,
      };
    }
  }

  /// Elimina un registro de emoción generalizada
  Future<bool> deleteEmocionGeneralizada(String id) async {
    try {
      await _supabase.from('emociones_generalizadas').delete().eq('id', id);
      return true;
    } catch (e) {
      LogService.log('Error deleting emocion generalizada: $e');
      return false;
    }
  }

  /// Actualiza la cantidad de una emoción específica
  Future<bool> updateEmocionGeneralizada(String id, int nuevaCantidad) async {
    try {
      await _supabase
          .from('emociones_generalizadas')
          .update({'cantidad': nuevaCantidad}).eq('id', id);
      return true;
    } catch (e) {
      LogService.log('Error updating emocion generalizada: $e');
      return false;
    }
  }

  /// Obtiene estadísticas en tiempo real (para dashboard)
  Future<Map<String, dynamic>> getEstadisticasTiempoReal() async {
    try {
      final ahora = DateTime.now();
      final hoy = DateFormat('yyyy-MM-dd').format(ahora);
      final ayer = DateFormat('yyyy-MM-dd')
          .format(ahora.subtract(const Duration(days: 1)));

      // Emociones de hoy
      final hoyData = await _supabase
          .from('emociones_generalizadas')
          .select('cantidad')
          .eq('fecha', hoy);

      // Emociones de ayer
      final ayerData = await _supabase
          .from('emociones_generalizadas')
          .select('cantidad')
          .eq('fecha', ayer);

      int totalHoy = 0;
      int totalAyer = 0;

      for (var item in hoyData) {
        totalHoy += (item['cantidad'] as int?) ?? 0;
      }

      for (var item in ayerData) {
        totalAyer += (item['cantidad'] as int?) ?? 0;
      }

      // Calcular porcentaje de cambio
      double cambio = 0;
      if (totalAyer > 0) {
        cambio = ((totalHoy - totalAyer) / totalAyer) * 100;
      }

      // Emoción más frecuente hoy
      final emocionHoy = await _supabase
          .from('emociones_generalizadas')
          .select('emocion, cantidad')
          .eq('fecha', hoy);

      Map<String, int> emocionesHoy = {};
      for (var item in emocionHoy) {
        final emocion = item['emocion'] as String;
        final cantidad = (item['cantidad'] as int?) ?? 0;
        emocionesHoy[emocion] = (emocionesHoy[emocion] ?? 0) + cantidad;
      }

      String emocionMasFrecuente = 'N/A';
      int maxCantidad = 0;
      emocionesHoy.forEach((emocion, cantidad) {
        if (cantidad > maxCantidad) {
          maxCantidad = cantidad;
          emocionMasFrecuente = emocion;
        }
      });

      return {
        'total_hoy': totalHoy,
        'total_ayer': totalAyer,
        'cambio_porcentual': cambio,
        'emocion_mas_frecuente': emocionMasFrecuente,
        'cantidad_emocion_frecuente': maxCantidad,
        'ultima_actualizacion': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LogService.log('Error getting estadisticas tiempo real: $e');
      return {
        'total_hoy': 0,
        'total_ayer': 0,
        'cambio_porcentual': 0.0,
        'emocion_mas_frecuente': 'N/A',
        'cantidad_emocion_frecuente': 0,
        'ultima_actualizacion': DateTime.now().toIso8601String(),
      };
    }
  }
}
