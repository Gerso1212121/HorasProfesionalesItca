class ExerciseSession {
  final String id;
  final String title;
  final String category;
  final DateTime date;
  final int durationMinutes;

  ExerciseSession({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    required this.durationMinutes,
  });

  // Convertir a JSON (para guardar en SharedPrefs)
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category,
    'date': date.toIso8601String(),
    'durationMinutes': durationMinutes,
  };

  // Crear desde JSON (para leer de SharedPrefs)
  factory ExerciseSession.fromJson(Map<String, dynamic> json) {
    return ExerciseSession(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      durationMinutes: json['durationMinutes'],
    );
  }
}