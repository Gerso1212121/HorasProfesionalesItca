import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Modelos
import 'package:horas2/Frontend/Modules/Excercises/Data/Models/ExerciseSession.dart';
import 'package:horas2/Frontend/Modules/Excercises/Data/Models/EjercicioModel.dart';

// Servicios
import 'package:horas2/Frontend/Modules/Excercises/Services/ProgressService.dart';
import 'package:horas2/Frontend/Modules/Excercises/ViewModel/ExerciseService.dart';
// import 'package:horas2/Backend/Data/API/GPTService.dart'; // Mantenemos importado si lo usas

class ExerciseViewModel extends ChangeNotifier {
  // --------------------------------------------------------
  // 1. SERVICIOS E INICIALIZACIÓN
  // --------------------------------------------------------
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ExerciseService _exerciseService = ExerciseService();
  
  // NUEVO: Servicio para el progreso local
  final ProgressService _progressService = ProgressService();

  // --------------------------------------------------------
  // 2. ESTADO DE DATOS (Supabase - Ejercicios)
  // --------------------------------------------------------
  List<EjercicioModel> _allExercises = [];
  bool _isLoadingExercises = true;
  String _error = '';

  // --------------------------------------------------------
  // 3. ESTADO DE USUARIO/UI (Teammate Logic)
  // --------------------------------------------------------
  String? _studentName;
  bool _isLoadingName = false;
  bool _isLoadingMessage = false;
  String _exerciseMessage = "";
  
  // Cache estático
  static String? _cachedExerciseMessage;
  static String? _cachedStudentName;
  static DateTime? _cachedDate;

  // --------------------------------------------------------
  // 4. NUEVO ESTADO: PROGRESO Y ESTADÍSTICAS
  // --------------------------------------------------------
  bool isLoadingProgress = false;
  List<ExerciseSession> recentHistory = [];
  
  // Inicializamos mapas vacíos o con ceros
  Map<String, dynamic> stats = {
    'minutes': 0, 
    'sessions': 0, 
    'streak': 0
  };
  
  Map<int, double> weeklyData = {
    1: 0.0, 2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0, 7: 0.0
  };

  // --------------------------------------------------------
  // 5. GETTERS
  // --------------------------------------------------------
  bool get isLoading => _isLoadingExercises || _isLoadingName;
  String get error => _error;
  
  List<String> get categorias {
    if (_allExercises.isEmpty) return [];
    final categories = _allExercises.map((e) => e.categoria).toSet().toList();
    categories.sort();
    return categories;
  }

  String? get studentName => _studentName;
  String get exerciseMessage => _exerciseMessage;
  bool get isLoadingExerciseMessage => _isLoadingMessage;

  // --------------------------------------------------------
  // 6. CONSTRUCTOR E INIT
  // --------------------------------------------------------
  ExerciseViewModel() {
    _init();
  }

  Future<void> _init() async {
    // Cargamos todo lo esencial en paralelo
    await Future.wait([
      _loadStudentName(),
      fetchExercises(),
    ]);

    // Generamos mensaje si tenemos nombre
    if (_studentName != null) {
      _loadExerciseMessage();
    }
  }

  // =========================================================
  // LOGICA A: EJERCICIOS (SUPABASE)
  // =========================================================

  Future<void> fetchExercises() async {
    _isLoadingExercises = true;
    _error = '';
    notifyListeners();

    try {
      // print('🏋️ Cargando ejercicios desde Supabase...');
      final rawData = await _exerciseService.getAllExercises();
      
      _allExercises = rawData.map((json) => EjercicioModel.fromJson(json)).toList();
      // print('✅ ${_allExercises.length} ejercicios cargados.');
      
    } catch (e) {
      print('❌ Error cargando ejercicios: $e');
      _error = 'No se pudieron cargar los ejercicios.';
    } finally {
      _isLoadingExercises = false;
      notifyListeners();
    }
  }

  List<EjercicioModel> getExercisesByCategory(String category) {
    return _allExercises.where((e) => e.categoria == category).toList();
  }

  // =========================================================
  // LOGICA B: USUARIO (FIRESTORE)
  // =========================================================

  Future<void> _loadStudentName() async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (_cachedStudentName != null) {
      _studentName = _cachedStudentName;
      return;
    }

    _isLoadingName = true;
    notifyListeners();

    try {
      final doc = await _firestore.collection('estudiantes').doc(user.uid).get();
      if (doc.exists) {
        _studentName = doc.data()?['nombre']?.toString();
        _cachedStudentName = _studentName;
      }
    } catch (e) {
      print('❌ Error nombre estudiante: $e');
    } finally {
      _isLoadingName = false;
      notifyListeners();
    }
  }

  // =========================================================
  // LOGICA C: MENSAJES MOTIVACIONALES
  // =========================================================
  
  Future<void> _loadExerciseMessage() async {
    final today = DateTime.now();
    final isSameDay = _cachedDate != null && 
        _cachedDate!.day == today.day && 
        _cachedDate!.month == today.month;

    if (isSameDay && _cachedExerciseMessage != null) {
      _exerciseMessage = _cachedExerciseMessage!;
      return;
    }

    _isLoadingMessage = true;
    notifyListeners();

    try {
      // Fallback temporal o lógica GPT
      final msg = _studentName != null 
          ? "$_studentName, ¿listo para fortalecer tu mente hoy?" 
          : "Tu bienestar es prioridad. ¡Comencemos!";

      _exerciseMessage = msg;
      _cachedExerciseMessage = msg;
      _cachedDate = today;
      
    } catch (e) {
      _exerciseMessage = "¡Tómate un momento para respirar!";
    } finally {
      _isLoadingMessage = false;
      notifyListeners();
    }
  }

  // =========================================================
  // LOGICA D: NUEVO PROGRESO (LOCAL STORAGE)
  // =========================================================

  // Método para cargar datos (Llamar al abrir la pantalla de progreso)
  Future<void> loadProgressData() async {
    isLoadingProgress = true;
    // notifyListeners(); // Descomentar si quieres ver spinner inmediato
    
    try {
      final history = await _progressService.getHistory();
      final statistics = await _progressService.getStats();
      final weekly = await _progressService.getWeeklyActivity();

      recentHistory = history;
      stats = statistics;
      weeklyData = weekly;
    } catch (e) {
      debugPrint("Error cargando progreso: $e");
    } finally {
      isLoadingProgress = false;
      notifyListeners();
    }
  }

  // Método para registrar ejercicio completado
  Future<void> completeExercise(String title, String category, int minutes) async {
    final newSession = ExerciseSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      date: DateTime.now(),
      durationMinutes: minutes,
    );

    await _progressService.saveSession(newSession);
    
    // Recargar datos para actualizar la UI si estamos viendo el progreso
    await loadProgressData(); 
  }
}