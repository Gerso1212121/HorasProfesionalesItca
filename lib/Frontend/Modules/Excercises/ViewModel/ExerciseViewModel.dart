// HomeScreen/ViewModels/ExerciseViewModel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:horas2/Backend/Data/API/GPTService.dart';

class ExerciseViewModel with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Estados
  String? _studentName;
  bool _isLoadingName = false;
  bool _isLoadingExerciseMessage = false;
  String _exerciseMessage = "";
  String _exercisePrompt = "";
  
  // Cache
  static String? _cachedExerciseMessage;
  static String? _cachedStudentNameForExercise;
  static DateTime? _cachedExerciseDate;
  
  // Getters
  String? get studentName => _studentName;
  bool get isLoadingName => _isLoadingName;
  bool get isLoadingExerciseMessage => _isLoadingExerciseMessage;
  String get exerciseMessage => _exerciseMessage;
  String get exercisePrompt => _exercisePrompt;
  
  // Constructor
  ExerciseViewModel() {
    _init();
  }
  
  Future<void> _init() async {
    await _loadStudentName();
    
    // Si tenemos nombre, cargar mensaje de ejercicio
    if (_studentName != null && _studentName!.isNotEmpty) {
      await _loadExerciseMessage();
    }
  }
  
  // ================= CARGA DE NOMBRE DEL ESTUDIANTE =================
  
  Future<void> _loadStudentName() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    
    final uid = currentUser.uid;
    
    // Verificar cache primero
    if (ExerciseViewModel._userNameCache.containsKey(uid)) {
      _studentName = ExerciseViewModel._userNameCache[uid];
      print('✅ Nombre cargado desde cache: $_studentName');
      return;
    }
    
    // Cargar desde Firestore
    _isLoadingName = true;
    notifyListeners();
    
    try {
      print('📡 Obteniendo nombre desde Firestore para $uid...');
      
      final doc = await _firestore
          .collection('estudiantes')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        final nombre = (data?['nombre'] ?? '').toString().trim();
        
        if (nombre.isNotEmpty) {
          _studentName = nombre;
          ExerciseViewModel._userNameCache[uid] = nombre;
          print('✅ Nombre obtenido: $nombre');
        } else {
          print('⚠️ Documento existe pero no tiene nombre');
          _studentName = null;
        }
      } else {
        print('⚠️ No existe documento en estudiantes/$uid');
        _studentName = null;
      }
    } catch (e) {
      print('❌ Error obteniendo nombre: $e');
      _studentName = null;
    } finally {
      _isLoadingName = false;
      notifyListeners();
    }
  }
  
  // ================= GENERAR MENSAJE DE EJERCICIO =================
  
  Future<void> _loadExerciseMessage() async {
    final hasName = _studentName != null && _studentName!.isNotEmpty;
    final nombre = hasName ? _studentName! : 'estudiante';
    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month}-${today.day}";
    
    // Verificar cache para hoy
    if (_shouldUseCachedExerciseMessage(nombre, todayKey)) {
      _exerciseMessage = _cachedExerciseMessage!;
      print('✅ Mensaje de ejercicio cargado desde cache: $_exerciseMessage');
      return;
    }
    
    // Generar nuevo mensaje
    _isLoadingExerciseMessage = true;
    notifyListeners();
    
    await _generateNewExerciseMessage(nombre, todayKey);
  }
  
  bool _shouldUseCachedExerciseMessage(String currentNombre, String todayKey) {
    if (_cachedExerciseMessage == null || 
        _cachedStudentNameForExercise == null || 
        _cachedExerciseDate == null) {
      return false;
    }
    
    if (_cachedStudentNameForExercise != currentNombre) {
      return false;
    }
    
    final cachedDateKey = "${_cachedExerciseDate!.year}-${_cachedExerciseDate!.month}-${_cachedExerciseDate!.day}";
    if (cachedDateKey != todayKey) {
      print('🔄 Mensaje en cache es de ayer, generando nuevo para hoy');
      return false;
    }
    
    return true;
  }
  
  Future<void> _generateNewExerciseMessage(String nombre, String todayKey) async {
    try {
      final hasName = _studentName != null && _studentName!.isNotEmpty;
      
      String prompt;
      
      if (hasName) {
        prompt = '''
Eres un psicólogo estudiantil motivacional. Genera un mensaje breve y alentador para ${_studentName} para invitarlo a realizar un ejercicio de bienestar emocional.

IMPORTANTE:
- Usa SOLO el nombre "${_studentName}" exactamente así
- Máximo 40 caracteres
- Tono cálido, cercano y motivador
- Incluye una invitación directa a hacer un ejercicio
- NO uses comillas
- NO digas "Hola" ni saludes
- Dirígete directamente a ${_studentName}
- Ejemplo: "${_studentName}, ¿listo para un ejercicio que te ayude a reflexionar hoy?"''';
      } else {
        prompt = '''
Eres un psicólogo estudiantil motivacional. Genera un mensaje breve y alentador para estudiantes invitándolos a realizar un ejercicio de bienestar emocional.

IMPORTANTE:
- NO uses ningún nombre de persona
- Máximo 40 caracteres
- Tono cálido, cercano y motivador
- Incluye una invitación directa a hacer un ejercicio
- NO uses comillas
- NO digas "Hola" ni saludes
- Ejemplo: "¿Listo para un ejercicio que te ayude a reflexionar hoy?"''';
      }
      
      _exercisePrompt = prompt;
      
      final respuesta = await GPTService.getResponse([
        {
          "role": "system",
          "content": hasName
            ? "Eres un psicólogo estudiantil que escribe mensajes breves y motivadores para invitar a estudiantes a realizar ejercicios de bienestar emocional. Usas el nombre real del estudiante."
            : "Eres un psicólogo estudiantil que escribe mensajes breves y motivadores generales para invitar a estudiantes a realizar ejercicios de bienestar emocional."
        },
        {"role": "user", "content": prompt}
      ]);
      
      final mensajeGenerado = respuesta.trim();
      
      if (mensajeGenerado.isNotEmpty) {
        // Actualizar cache
        _cachedExerciseMessage = mensajeGenerado;
        _cachedStudentNameForExercise = nombre;
        _cachedExerciseDate = DateTime.now();
        
        // Actualizar estado
        _exerciseMessage = mensajeGenerado;
        print('💬 Nuevo mensaje de ejercicio generado: $_exerciseMessage');
      } else {
        _fallbackToDefaultExerciseMessage(hasName);
      }
    } catch (e) {
      print('❌ Error generando mensaje de ejercicio: $e');
      _fallbackToDefaultExerciseMessage(_studentName != null && _studentName!.isNotEmpty);
    } finally {
      _isLoadingExerciseMessage = false;
      notifyListeners();
    }
  }
  
  void _fallbackToDefaultExerciseMessage(bool hasName) {
    _exerciseMessage = hasName
      ? "${_studentName}, ¿te animas a un ejercicio de reflexión hoy?"
      : "¿Listo para un ejercicio de bienestar emocional hoy?";
  }
  
  // Forzar recarga del mensaje
  Future<void> refreshExerciseMessage() async {
    if (_studentName != null && _studentName!.isNotEmpty) {
      await _generateNewExerciseMessage(_studentName!, 
        "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}");
    }
  }
  
  // Cache estático para nombres
  static Map<String, String> _userNameCache = {};
  
  // Limpiar cache
  static void clearCache() {
    _cachedExerciseMessage = null;
    _cachedStudentNameForExercise = null;
    _cachedExerciseDate = null;
    _userNameCache.clear();
    print('🧹 Cache de ExerciseViewModel limpiado');
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}