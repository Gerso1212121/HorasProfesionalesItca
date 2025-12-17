import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Data/Models/ExerciseSession.dart';

class ProgressService {
  static const String _keyHistory = 'exercise_history';
  
  // 1. Guardar una nueva sesión
  Future<void> saveSession(ExerciseSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    // Insertamos al principio de la lista (el más reciente primero)
    history.insert(0, session);
    
    // Convertimos a String y guardamos
    final String jsonString = jsonEncode(history.map((e) => e.toJson()).toList());
    await prefs.setString(_keyHistory, jsonString);
  }

  // 2. Obtener todo el historial
  Future<List<ExerciseSession>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_keyHistory);
    
    if (jsonString == null) return [];

    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((e) => ExerciseSession.fromJson(e)).toList();
  }

  // 3. Calcular Estadísticas (Minutos, Sesiones, Racha)
  Future<Map<String, dynamic>> getStats() async {
    final history = await getHistory();
    
    int totalMinutes = 0;
    int totalSessions = history.length;
    
    for (var session in history) {
      totalMinutes += session.durationMinutes;
    }

    return {
      'minutes': totalMinutes,
      'sessions': totalSessions,
      'streak': _calculateStreak(history),
    };
  }

  // 4. Datos para el Gráfico (Últimos 7 días)
  // Devuelve un mapa donde la clave es el día de la semana (1=Lun, 7=Dom) y el valor es el % de meta (0.0 a 1.0)
  Future<Map<int, double>> getWeeklyActivity() async {
    final history = await getHistory();
    final now = DateTime.now();
    
    // Inicializar mapa con 0
    Map<int, double> activity = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};

    for (var session in history) {
      final difference = now.difference(session.date).inDays;
      // Solo tomamos en cuenta ejercicios de los últimos 7 días
      if (difference < 7 && difference >= 0) {
        int weekday = session.date.weekday; // 1 = Lunes, 7 = Domingo
        // Sumamos minutos. Asumimos que 45 minutos es el 100% de la barra (ajustable)
        double value = (activity[weekday] ?? 0) + (session.durationMinutes / 45.0);
        activity[weekday] = value > 1.0 ? 1.0 : value; // Tope visual en 100%
      }
    }
    return activity;
  }

  // Lógica simple de racha (Días consecutivos)
  int _calculateStreak(List<ExerciseSession> history) {
    if (history.isEmpty) return 0;
    
    // Ordenamos por fecha descendente por seguridad
    history.sort((a, b) => b.date.compareTo(a.date));

    int streak = 0;
    DateTime today = DateTime.now();
    // Quitamos la hora para comparar solo fechas
    DateTime currentDate = DateTime(today.year, today.month, today.day);

    // Verificamos si hizo ejercicio hoy
    bool exerciseToday = history.any((s) => 
      s.date.year == today.year && 
      s.date.month == today.month && 
      s.date.day == today.day
    );

    // Si no hizo hoy, miramos si hizo ayer para mantener la racha viva
    if (!exerciseToday) {
      currentDate = currentDate.subtract(const Duration(days: 1));
    }

    // Contamos hacia atrás
    while (true) {
      bool found = history.any((s) => 
        s.date.year == currentDate.year && 
        s.date.month == currentDate.month && 
        s.date.day == currentDate.day
      );

      if (found) {
        streak++;
        currentDate = currentDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }
}