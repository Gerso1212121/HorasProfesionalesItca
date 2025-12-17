// lib/Frontend/Modules/Diary/Models/DiaryDatabase.dart
import 'package:horas2/Frontend/Modules/Diary/model/diario_entry.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DiaryDatabase {
  static final DiaryDatabase _instance = DiaryDatabase._internal();
  static Database? _database;

  factory DiaryDatabase() {
    return _instance;
  }

  DiaryDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'diary_entries.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE diary_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        date TEXT NOT NULL,
        mood TEXT NOT NULL,
        content_json TEXT NOT NULL,
        compressed_image_paths TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Índices para mejorar el rendimiento
    await db.execute('''
      CREATE INDEX idx_date ON diary_entries(date)
    ''');
  }

  // CRUD Operations
  Future<int> insertEntry(DiaryEntry entry) async {
    final db = await database;
    return await db.insert('diary_entries', entry.toMap());
  }

  Future<List<DiaryEntry>> getAllEntries() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = 
        await db.query('diary_entries', orderBy: 'date DESC');
    return List.generate(maps.length, (i) => DiaryEntry.fromMap(maps[i]));
  }

  Future<int> updateEntry(DiaryEntry entry) async {
    final db = await database;
    return await db.update(
      'diary_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteEntry(int id) async {
    final db = await database;
    return await db.delete(
      'diary_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<DiaryEntry?> getEntryById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'diary_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return DiaryEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<List<DiaryEntry>> getEntriesByDate(DateTime date) async {
    final db = await database;
    final dateStr = date.toIso8601String().split('T')[0];
    final List<Map<String, dynamic>> maps = await db.query(
      'diary_entries',
      where: 'date LIKE ?',
      whereArgs: ['$dateStr%'],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => DiaryEntry.fromMap(maps[i]));
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}