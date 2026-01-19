import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LogService {
  static SharedPreferences? _prefs;
  static const String _logKey = 'app_logs';

  static Future<void> _initPrefs() async {
    if (kIsWeb && _prefs == null) {
      _prefs = await SharedPreferences.getInstance();
    }
  }

  static Future<String> _getLogFilePath() async {
    if (kIsWeb) {
      throw UnsupportedError(
          'getApplicationDocumentsDirectory no está soportado en web');
    }
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/logs.txt';
  }

  /// Llama a esta función desde cualquier lugar:
  /// LogService.log("Texto del log", "Línea opcional", "Más detalles opcionales");
  static Future<void> log(
    String text, {
    String? linea,
    String? context,
  }) async {
    if (kIsWeb) {
      await _initPrefs();
      final timestamp = DateTime.now().toIso8601String();
      final logText = "[$timestamp] $text\n";

      // Obtener logs existentes
      final existingLogs = _prefs!.getString(_logKey) ?? '';
      // Agregar nuevo log
      final newLogs = existingLogs + logText;
      // Guardar logs (mantener solo los últimos 1000 caracteres para evitar problemas de memoria)
      final logsToSave = newLogs.length > 10000
          ? newLogs.substring(newLogs.length - 10000)
          : newLogs;
      await _prefs!.setString(_logKey, logsToSave);
    } else {
      final filePath = await _getLogFilePath();
      final file = File(filePath);

      final timestamp = DateTime.now().toIso8601String();
      final logText = "[$timestamp] $text\n";

      await file.writeAsString(logText, mode: FileMode.append, flush: true);
    }
  }

  /// Lee todos los logs si lo necesitas.
  static Future<List<String>> readLogs() async {
    if (kIsWeb) {
      await _initPrefs();
      final logs = _prefs!.getString(_logKey);
      if (logs == null || logs.isEmpty) {
        return ['Sin logs'];
      }
      return logs.split('\n').where((line) => line.isNotEmpty).toList();
    } else {
      final filePath = await _getLogFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.isEmpty) {
          return ['Sin logs'];
        }
        return content.split('\n').where((line) => line.isNotEmpty).toList();
      } else {
        return ['Sin logs'];
      }
    }
  }

  /// Borra todos los logs.
  static Future<void> clearLogs() async {
    if (kIsWeb) {
      await _initPrefs();
      await _prefs!.remove(_logKey);
    } else {
      final filePath = await _getLogFilePath();
      final file = File(filePath);
      if (await file.exists()) {
        await file.writeAsString('');
      }
    }
  }
}
