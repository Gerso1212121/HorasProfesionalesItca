import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static DatabaseHelper get instance => _instance;
  DatabaseHelper._internal() {
    // Inicializar databaseFactory para Windows/Desktop
    _initializeDatabaseFactory();
  }

  static bool _initialized = false;
  static SharedPreferences? _prefs;

  void _initializeDatabaseFactory() {
    print("🔍 Verificando inicialización de DatabaseFactory...");
    print("🔍 kIsWeb: $kIsWeb");
    print("🔍 Platform.isWindows: ${!kIsWeb ? Platform.isWindows : 'N/A'}");
    print("🔍 Platform.isLinux: ${!kIsWeb ? Platform.isLinux : 'N/A'}");
    print("🔍 _initialized: $_initialized");

    if (!_initialized && !kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      try {
        print("🔧 Inicializando sqfliteFfiInit()...");
        sqfliteFfiInit();
        print("🔧 Configurando databaseFactory = databaseFactoryFfi...");
        databaseFactory = databaseFactoryFfi;
        _initialized = true;
        print("✅ DatabaseFactory inicializado para Windows/Linux");
      } catch (e) {
        print("❌ Error inicializando DatabaseFactory: $e");
      }
    } else {
      print(
          "ℹ️ DatabaseFactory no necesita inicialización (web o ya inicializado)");
    }
  }

  static Database? _database;

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError(
          'SQLite no está soportado en web. Use los métodos web específicos.');
    }
    if (_database == null || !_database!.isOpen) {
      _database = await _initDatabase();
    }
    return _database!;
  }

  // Método para cerrar la base de datos correctamente
  Future<void> closeDatabase() async {
    if (_database != null && _database!.isOpen) {
      await _database!.close();
      _database = null;
      print('🔒 Base de datos cerrada correctamente');
    }
  }

  Future<Database> _initDatabase() async {
    // Para web, no podemos usar SQLite, así que lanzamos una excepción
    if (kIsWeb) {
      throw UnsupportedError(
          'SQLite no está soportado en web. Use una alternativa como IndexedDB o localStorage.');
    }

    // Asegurar que databaseFactory esté inicializado
    _initializeDatabaseFactory();

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Inicializar SharedPreferences para web
  Future<void> _initPrefs() async {
    if (kIsWeb && _prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla estudiantes
    await db.execute('''
      CREATE TABLE estudiantes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uid_firebase TEXT UNIQUE,
        nombre TEXT,
        apellido TEXT,
        correo TEXT,
        telefono TEXT,
        sede TEXT,
        carrera TEXT,
        año TEXT,
        emocion TEXT,
        fecha_sincronizacion TEXT
      )
    ''');

    // Tabla análisis de sesiones
    await db.execute('''
      CREATE TABLE analisis_sesiones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha_sesion TEXT,
        uid_usuario TEXT,
        tema_general TEXT,
        emociones TEXT,
        nivel_riesgo TEXT,
        puntuacion_riesgo REAL,
        palabras_clave TEXT,
        resumen_analisis TEXT,
        fecha_creacion TEXT
      )
    ''');

    // Tabla diario
    await db.execute('''
      CREATE TABLE diario_entries (
        id_diario INTEGER PRIMARY KEY AUTOINCREMENT,
        fecha TEXT,
        contenido TEXT,
        timestamp TEXT,
        id_estudiante INTEGER,
        categoria TEXT,
        estado_animo TEXT,
        valoracion INTEGER,
        etiquetas TEXT,
        FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id)
      )
    ''');

    // Tabla ejercicios
    await db.execute('''
      CREATE TABLE ejercicios (
        id_ejercicio INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT,
        descripcion TEXT,
        categoria TEXT,
        tipo TEXT,
        duracion_minutos INTEGER,
        dificultad TEXT,
        objetivos TEXT,
        instrucciones TEXT,
        fecha_creacion TEXT
      )
    ''');

    // Tabla progreso ejercicios
    await db.execute('''
      CREATE TABLE progreso_ejercicios (
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
        FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Recrear la tabla ejercicios con la nueva estructura
      await db.execute('DROP TABLE IF EXISTS ejercicios');
      await db.execute('''
        CREATE TABLE ejercicios (
          id_ejercicio INTEGER PRIMARY KEY AUTOINCREMENT,
          titulo TEXT,
          descripcion TEXT,
          categoria TEXT,
          tipo TEXT,
          duracion_minutos INTEGER,
          dificultad TEXT,
          objetivos TEXT,
          instrucciones TEXT,
          fecha_creacion TEXT
        )
      ''');

      // Recrear la tabla progreso_ejercicios con la referencia correcta
      await db.execute('DROP TABLE IF EXISTS progreso_ejercicios');
      await db.execute('''
        CREATE TABLE progreso_ejercicios (
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
          FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id)
        )
      ''');
    }

    if (oldVersion < 3) {
      // Forzar recreación de la tabla progreso_ejercicios para corregir estructura
      await db.execute('DROP TABLE IF EXISTS progreso_ejercicios');
      await db.execute('''
        CREATE TABLE progreso_ejercicios (
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
          FOREIGN KEY (id_estudiante) REFERENCES estudiantes (id)
        )
      ''');
    }
  }

  // METODOS PARA ESTUDIANTES

  // Obtener estudiante por UID
  Future<Map<String, dynamic>?> getEstudiantePorUID(String uid) async {
    if (kIsWeb) {
      await _initPrefs();
      final userData = _prefs!.getString('estudiante_$uid');
      return userData != null
          ? Map<String, dynamic>.from(json.decode(userData))
          : null;
    }

    final db = await database;
    final result = await db.query(
      'estudiantes',
      where: 'uid_firebase = ?',
      whereArgs: [uid],
    );
    return result.isNotEmpty ? result.first : null;
  }

  // Insertar estudiante desde Firebase
  Future<int> insertEstudianteFromFirebase(
      Map<String, dynamic> userData) async {
    if (kIsWeb) {
      await _initPrefs();
      final uid = userData['uid_firebase'] as String;
      await _prefs!.setString('estudiante_$uid', json.encode(userData));
      return 1; // Simular éxito
    }

    final db = await database;
    return await db.insert('estudiantes', userData);
  }

  //Borrar estudiante actual
  Future<void> deleteEstudianteActual() async {
    if (kIsWeb) {
      await _initPrefs();
      final keys =
          _prefs!.getKeys().where((key) => key.startsWith('estudiante_'));
      for (final key in keys) {
        await _prefs!.remove(key);
      }
      return;
    }

    final db = await database;
    await db.delete('estudiantes');
  }

  // Contar estudiantes
  Future<int> countEstudiantes() async {
    if (kIsWeb) {
      await _initPrefs();
      final keys =
          _prefs!.getKeys().where((key) => key.startsWith('estudiante_'));
      return keys.length;
    }

    final db = await database;
    final result =
        await db.rawQuery('SELECT COUNT(*) as count FROM estudiantes');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Obtener o crear estudiante por UID
  Future<int> getOrCreateEstudianteByUID(String uid, String? email) async {
    if (kIsWeb) {
      await _initPrefs();
      final existing = await getEstudiantePorUID(uid);
      if (existing != null) {
        return 1; // Simular ID
      }

      final userData = {
        'uid_firebase': uid,
        'correo': email,
        'fecha_sincronizacion': DateTime.now().toIso8601String(),
      };
      await _prefs!.setString('estudiante_$uid', json.encode(userData));
      return 1; // Simular ID
    }

    final db = await database;
    final existing = await getEstudiantePorUID(uid);

    if (existing != null) {
      return existing['id'] as int;
    }

    return await db.insert('estudiantes', {
      'uid_firebase': uid,
      'correo': email,
      'fecha_sincronizacion': DateTime.now().toIso8601String(),
    });
  }

  // Actualizar emoción del estudiante
  Future<int> actualizarEmocionEstudiante(
      String uidFirebase, String nuevaEmocion) async {
    final db = await database;

    final nuevosValores = {
      'emocion': nuevaEmocion,
    };

    return await db.update(
      'estudiantes',
      nuevosValores,
      where: 'uid_firebase = ?',
      whereArgs: [uidFirebase],
    );
  }

  // Obtener estudiante actual
  Future<Map<String, dynamic>?> getEstudianteByUID(String uid) async {
    final db = await database;

    final List<Map<String, dynamic>> resultados = await db.query(
      'estudiantes',
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

  // METODOS PARA EL ANALISIS DE SESIONES
  Future<int> insertAnalisisSesion(Map<String, dynamic> analisis) async {
    final db = await database;
    return await db.insert('analisis_sesiones', analisis);
  }

  Future<List<Map<String, dynamic>>> getAnalisisPorUsuario(String uid) async {
    final db = await database;
    return await db.query(
      'analisis_sesiones',
      where: 'uid_usuario = ?',
      whereArgs: [uid],
      orderBy: 'fecha_creacion DESC',
    );
  }

  // Métodos para diario
  Future<int> insertDiarioEntryEnhanced(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('diario_entries', entry);
  }

  Future<List<Map<String, dynamic>>> getDiarioEntriesFiltered(
    int idEstudiante, {
    String? categoria,
    String? estadoAnimo,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? busqueda,
  }) async {
    final db = await database;
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

    if (busqueda != null && busqueda.isNotEmpty) {
      where += ' AND contenido LIKE ?';
      whereArgs.add('%$busqueda%');
    }

    return await db.query(
      'diario_entries',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
    );
  }

  Future<Map<String, dynamic>> getDiarioStatistics(int idEstudiante) async {
    final db = await database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM diario_entries WHERE id_estudiante = ?',
      [idEstudiante],
    );

    final thisMonthResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM diario_entries WHERE id_estudiante = ? AND fecha LIKE ?',
      [
        idEstudiante,
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}%'
      ],
    );

    return {
      'totalEntradas': Sqflite.firstIntValue(totalResult) ?? 0,
      'entradasEsteMes': Sqflite.firstIntValue(thisMonthResult) ?? 0,
      'estadoAnimoMasComun': null,
      'categoriaMasUsada': null,
      'promedioValoracion': 0.0,
      'rachaEscritura': 0,
    };
  }

  // Métodos para ejercicios
  Future<int> insertProgresoEjercicio(Map<String, dynamic> progreso) async {
    final db = await database;
    return await db.insert('progreso_ejercicios', progreso);
  }

  Future<List<Map<String, dynamic>>> getProgresoEjercicios(
      int idEstudiante) async {
    final db = await database;
    return await db.query(
      'progreso_ejercicios',
      where: 'id_estudiante = ?',
      whereArgs: [idEstudiante],
      orderBy: 'fecha_realizacion DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getAllEjercicios() async {
    final db = await database;
    return await db.query('ejercicios');
  }

  // Insertar un ejercicio
  Future<int> insertEjercicio(Map<String, dynamic> ejercicio) async {
    final db = await database;
    return await db.insert('ejercicios', ejercicio);
  }

  // Obtener ejercicios por tipo
  Future<List<Map<String, dynamic>>> getEjerciciosByTipo(String tipo) async {
    final db = await database;
    return await db.query(
      'ejercicios',
      where: 'tipo = ?',
      whereArgs: [tipo],
    );
  }

  // Obtener progreso de ejercicios por estudiante
  Future<List<Map<String, dynamic>>> getProgresoEjerciciosByStudent(
      int idEstudiante) async {
    final db = await database;
    return await db.query(
      'progreso_ejercicios',
      where: 'id_estudiante = ?',
      whereArgs: [idEstudiante],
      orderBy: 'fecha_realizacion DESC',
    );
  }

  // Métodos para diario - actualización y eliminación
  Future<void> updateDiarioEntryEnhanced(
      int id, Map<String, dynamic> entry) async {
    final db = await database;
    await db.update(
      'diario_entries',
      entry,
      where: 'id_diario = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDiarioEntry(int id) async {
    final db = await database;
    await db.delete(
      'diario_entries',
      where: 'id_diario = ?',
      whereArgs: [id],
    );
  }

  // Métodos para análisis histórico
  Future<List<Map<String, dynamic>>> getTodosLosAnalisis() async {
    final db = await database;
    return await db.query(
      'analisis_sesiones',
      orderBy: 'fecha_creacion DESC',
    );
  }

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

  // Obtener el esquema (columnas) de una tabla
  Future<List<Map<String, dynamic>>> getTableSchema(String tableName) async {
    if (kIsWeb) {
      throw UnsupportedError('Operación no soportada en web.');
    }
    final db = await database;
    return await db.rawQuery('PRAGMA table_info("$tableName")');
  }

  // Obtener los datos de una tabla de forma genérica
  Future<List<Map<String, dynamic>>> getTableData(String tableName) async {
    if (kIsWeb) {
      throw UnsupportedError('Operación no soportada en web.');
    }
    final db = await database;
    return await db.query(tableName);
  }

  // Limpiar una tabla completa
  Future<void> clearTable(String tableName) async {
    if (kIsWeb) {
      throw UnsupportedError('Operación no soportada en web.');
    }
    final db = await database;
    await db.delete(tableName);
  }

  // Eliminar un registro por ID
  Future<void> deleteRecord(
      String tableName, int id, String primaryKeyColumn) async {
    if (kIsWeb) {
      throw UnsupportedError('Operación no soportada en web.');
    }
    final db = await database;
    await db.delete(
      tableName,
      where: '$primaryKeyColumn = ?',
      whereArgs: [id],
    );
  }

  // Exportar la base de datos a un archivo (para escritorio/móvil)
  Future<String> exportDatabase() async {
    if (kIsWeb) {
      throw UnsupportedError('Operación no soportada en web.');
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_database.db');

    // Aquí puedes implementar la lógica para copiar el archivo a una ubicación accesible
    // Por ejemplo, al directorio de descargas del usuario.
    // Esto es solo un ejemplo, la implementación real puede variar.
    // final newPath = join(await getExternalStorageDirectory(), 'database_backup.db');
    // await File(path).copy(newPath);

    return path; // Retornar la ruta del archivo de la DB
  }
}
