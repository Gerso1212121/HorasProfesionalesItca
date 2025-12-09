// HomeScreen/Models/HomeViewModel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:horas2/Backend/Data/API/GPTService.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Models/ChatSuggestion.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/Models/PsychologyModulo.dart';
import 'package:horas2/Frontend/Modules/HomeScreen/ViewModels/MetasAcademicas/SampleDataLoader.dart';

class HomeViewModel with ChangeNotifier {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Estado
  bool _showCalendar = false;
  DateTime _selectedDay = DateTime.now();
  List<PsychologyModulo> _psychologyModulos = [];
  bool _isLoadingPsychology = true;
  List<ChatSuggestion> _chatSuggestions = [];
  bool _isLoadingSuggestions = false;
  String? _lastUserId;
  String? _studentName;
  StreamSubscription<User?>? _authStateSubscription;
  
  // CACHE DE FRASE EN MEMORIA
  static String? _cachedFraseMotivacional;
  static String? _cachedStudentNameForFrase;
  static DateTime? _cachedFraseDate; // Solo fecha, sin hora
  
  // CACHE DE NOMBRE EN MEMORIA
  static Map<String, String> _userNameCache = {};
  
  // Estados de carga
  String _fraseMotivacional = ""; // Mantenemos vacío inicialmente
  bool _isLoadingFrase = false;
  bool _shouldShowFraseSkeleton = false;
  bool _isLoadingName = false;
  bool _isInitialized = false;

  // Getters
  bool get showCalendar => _showCalendar;
  DateTime get selectedDay => _selectedDay;
  List<PsychologyModulo> get psychologyModulos => _psychologyModulos;
  bool get isLoadingPsychology => _isLoadingPsychology;
  String get fraseMotivacional => _fraseMotivacional;
  bool get isLoadingFrase => _isLoadingFrase;
  bool get shouldShowFraseSkeleton => _shouldShowFraseSkeleton;
  List<ChatSuggestion> get chatSuggestions => _chatSuggestions;
  bool get isLoadingSuggestions => _isLoadingSuggestions;
  String? get studentName => _studentName;
  bool get isLoadingName => _isLoadingName;

  // Constructor
  HomeViewModel() {
    // PRIMERO: Intentar cargar cache inmediatamente
    _tryLoadFraseFromCacheInstantly();
    
    // LUEGO: Iniciar carga asíncrona
    _init();
  }

  // Método para cargar cache instantáneamente
  void _tryLoadFraseFromCacheInstantly() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      _fraseMotivacional = "Cada día es una nueva oportunidad para crecer.";
      return;
    }
    
    final uid = currentUser.uid;
    
    // Intentar cargar nombre desde cache inmediatamente
    if (_userNameCache.containsKey(uid)) {
      _studentName = _userNameCache[uid];
      print('✅ Nombre cargado instantáneamente en constructor: $_studentName');
    }
    
    // Si tenemos nombre, intentar cargar frase cacheada para hoy
    if (_studentName != null && _studentName!.isNotEmpty) {
      final nombre = _studentName!;
      final today = DateTime.now();
      final todayKey = "${today.year}-${today.month}-${today.day}";
      
      if (_shouldUseCachedFraseForToday(nombre, todayKey)) {
        _fraseMotivacional = _cachedFraseMotivacional!;
        print('✅ Frase cargada instantáneamente en constructor: $_fraseMotivacional');
      }
    }
  }

  void _init() async {
    // Marcar como no inicializado aún
    _isInitialized = false;
    
    // Cargar datos en paralelo
    await Future.wait([
      _loadPsychologyModulos(),
      _loadAllUserData(),
    ]);

    // Cargar conversaciones estáticas
    _loadStaticConversations();
    
    // Marcar como inicializado
    _isInitialized = true;

    _authStateSubscription = _auth.authStateChanges().listen(_handleAuthChange);
  }

  // ================= CARGA COMPLETA DE DATOS DE USUARIO =================
  
  Future<void> _loadAllUserData() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      if (_fraseMotivacional.isEmpty) {
        _fraseMotivacional = "Cada día es una nueva oportunidad para crecer.";
      }
      return;
    }
    
    _lastUserId = currentUser.uid;
    final uid = currentUser.uid;
    
    // 1. CARGAR NOMBRE (con cache instantáneo)
    await _loadStudentNameInstant(uid);
    
    // 2. CARGAR FRASE (con cache por día) - Solo si no se cargó en el constructor
    if (_fraseMotivacional.isEmpty || !_isFraseFromToday()) {
      await _loadFraseForToday();
    }
  }

  // ================= CARGA INSTANTÁNEA DE NOMBRE =================

  Future<void> _loadStudentNameInstant(String uid) async {
    // Verificar cache de nombre primero
    if (_userNameCache.containsKey(uid)) {
      _studentName = _userNameCache[uid];
      print('✅ Nombre cargado instantáneamente desde cache: $_studentName');
      return;
    }
    
    // Si no hay cache, cargar desde Firestore
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
          _userNameCache[uid] = nombre; // Guardar en cache
          print('✅ Nombre obtenido de Firestore: $nombre');
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

  // Verificar si la frase actual es de hoy
  bool _isFraseFromToday() {
    if (_cachedFraseDate == null) return false;
    final today = DateTime.now();
    return _cachedFraseDate!.year == today.year &&
           _cachedFraseDate!.month == today.month &&
           _cachedFraseDate!.day == today.day;
  }

  // ================= CARGA DE FRASE POR DÍA =================
  
  Future<void> _loadFraseForToday() async {
    final hasName = _studentName != null && _studentName!.isNotEmpty;
    final nombre = hasName ? _studentName! : 'general';
    final today = DateTime.now();
    final todayKey = "${today.year}-${today.month}-${today.day}";
    
    // Verificar si hay frase en cache para HOY
    if (_shouldUseCachedFraseForToday(nombre, todayKey)) {
      _fraseMotivacional = _cachedFraseMotivacional!;
      print('✅ Frase cargada desde cache (hoy): $_fraseMotivacional');
      notifyListeners();
      return;
    }
    
    // Si no hay cache para hoy y la frase está vacía, cargar nueva frase
    if (_fraseMotivacional.isEmpty || !_isFraseFromToday()) {
      _shouldShowFraseSkeleton = true;
      _isLoadingFrase = true;
      notifyListeners();
      
      await _loadNewMotivationalQuote(nombre, todayKey);
    }
  }

  bool _shouldUseCachedFraseForToday(String currentNombre, String todayKey) {
    // No hay nada en cache
    if (_cachedFraseMotivacional == null || 
        _cachedStudentNameForFrase == null || 
        _cachedFraseDate == null) {
      return false;
    }
    
    // El cache es para un nombre diferente
    if (_cachedStudentNameForFrase != currentNombre) {
      return false;
    }
    
    // El cache NO es de hoy
    final cachedDateKey = "${_cachedFraseDate!.year}-${_cachedFraseDate!.month}-${_cachedFraseDate!.day}";
    if (cachedDateKey != todayKey) {
      print('🔄 Frase en cache es de ayer ($cachedDateKey), hoy es ($todayKey)');
      return false;
    }
    
    return true;
  }

  Future<void> _loadNewMotivationalQuote(String nombre, String todayKey) async {
    try {
      final hasName = _studentName != null && _studentName!.isNotEmpty;
      
      String prompt;
      
      if (hasName) {
        prompt = '''
Genera una sola frase corta y motivacional en español para ${_studentName}.

IMPORTANTE:
- Usa SOLO el nombre "${_studentName}", NO inventes otros nombres
- Máximo 120 caracteres
- Tono cálido y cercano
- Sin comillas
- Sin mencionar que eres una IA
- Dirígete directamente a ${_studentName}
- Ejemplo: "¡Ánimo, ${_studentName}! Cada esfuerzo cuenta en tu camino"''';
      } else {
        prompt = '''
Genera un consejo breve y motivacional en español para estudiantes.

IMPORTANTE:
- NO uses ningún nombre de persona
- NO incluyas "[nombre]" ni variables de nombre
- Máximo 120 caracteres
- Tono cálido y cercano
- Sin comillas
- Sin mencionar que eres una IA
- Debe ser aplicable a cualquier estudiante
- Ejemplo: "Cada pequeño paso te acerca a grandes logros. ¡Sigue adelante!"''';
      }

      final respuesta = await GPTService.getResponse([
        {
          "role": "system",
          "content": hasName
            ? "Eres un psicólogo estudiantil que escribe frases breves y motivadoras personalizadas con el nombre real del estudiante. NUNCA inventes nombres."
            : "Eres un psicólogo estudiantil que escribe consejos breves y motivadores generales para estudiantes. NUNCA uses nombres de personas."
        },
        {"role": "user", "content": prompt}
      ]);

      final fraseGenerada = respuesta.trim();
      
      if (fraseGenerada.isNotEmpty) {
        // Actualizar cache con fecha de HOY
        _cachedFraseMotivacional = fraseGenerada;
        _cachedStudentNameForFrase = nombre;
        _cachedFraseDate = DateTime.now(); // Solo fecha, sin hora específica
        
        // Actualizar estado
        _fraseMotivacional = fraseGenerada;
        print('💬 Nueva frase generada para hoy y guardada en cache: $_fraseMotivacional');
      } else {
        print('⚠️ Frase vacía recibida de la IA');
        _fallbackToCachedOrDefault(nombre);
      }
    } catch (e) {
      print('❌ Error generando frase motivacional: $e');
      _fallbackToCachedOrDefault(nombre);
    } finally {
      _isLoadingFrase = false;
      _shouldShowFraseSkeleton = false;
      notifyListeners();
    }
  }

  void _fallbackToCachedOrDefault(String nombre) {
    // Intentar usar cache incluso si es de ayer
    if (_cachedFraseMotivacional != null && _cachedStudentNameForFrase == nombre) {
      _fraseMotivacional = _cachedFraseMotivacional!;
      print('✅ Fallback a frase en cache (puede ser de ayer)');
    } else {
      final hasName = _studentName != null && _studentName!.isNotEmpty;
      _fraseMotivacional = hasName
        ? "¡Ánimo, ${_studentName}! Hoy es un gran día para aprender."
        : "Cada día es una nueva oportunidad para crecer.";
      print('✅ Fallback a frase por defecto');
    }
  }

  // Método público para forzar recarga de frase (si quiere nueva hoy)
  Future<void> loadMotivationalQuote({bool forceRefresh = false}) async {
    final hasName = _studentName != null && _studentName!.isNotEmpty;
    final nombre = hasName ? _studentName! : 'general';
    final todayKey = "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
    
    if (forceRefresh) {
      print('🔄 Forzando recarga de frase para hoy...');
      _shouldShowFraseSkeleton = true;
      _isLoadingFrase = true;
      notifyListeners();
      
      await _loadNewMotivationalQuote(nombre, todayKey);
    } else {
      // Solo recargar si no hay cache para hoy
      await _loadFraseForToday();
    }
  }

  // ================= MANEJO DE CAMBIOS DE AUTENTICACIÓN =================
  
  void _handleAuthChange(User? user) async {
    if (user != null) {
      if (_lastUserId != user.uid) {
        _lastUserId = user.uid;
        
        // Cargar datos del NUEVO usuario
        await _loadAllUserData();
        
        // Recargar conversaciones con nuevo nombre
        _loadStaticConversations();
      }
    } else {
      _lastUserId = null;
      _studentName = null;
      _chatSuggestions = [];
      notifyListeners();
    }
  }

  // ================= CONVERSACIONES ESTÁTICAS =================
  
  void _loadStaticConversations() {
    final hasName = _studentName != null && _studentName!.isNotEmpty;
    final nombre = hasName ? _studentName! : '';
    
    _chatSuggestions = [
      ChatSuggestion(
        topic: "Estrés académico",
        summary: "Explora técnicas para manejar la presión y ansiedad durante exámenes y entregas.",
        prompt: hasName 
          ? "¿Qué situaciones académicas te generan más estrés, ${nombre}?"
          : "¿Qué situaciones académicas te generan más estrés?",
        backgroundColor: Color(0xFFE3F2FD),
        emojiIcon: "😓",
        customIcon: Icons.school,
      ),
      ChatSuggestion(
        topic: "Motivación diaria",
        summary: "Descubre cómo mantener la motivación en tus estudios y actividades diarias.",
        prompt: hasName 
          ? "¿Qué te motiva a seguir adelante cada día, ${nombre}?"
          : "¿Qué te motiva a seguir adelante cada día?",
        backgroundColor: Color(0xFFF3E5F5),
        emojiIcon: "🚀",
        customIcon: Icons.emoji_events,
      ),
      ChatSuggestion(
        topic: "Relaciones sociales",
        summary: "Aprende a desarrollar y mantener relaciones saludables en tu entorno estudiantil.",
        prompt: hasName 
          ? "¿Cómo te sientes acerca de tus relaciones sociales actuales, ${nombre}?"
          : "¿Cómo te sientes acerca de tus relaciones sociales actuales?",
        backgroundColor: Color(0xFFE8F5E9),
        emojiIcon: "👥",
        customIcon: Icons.group,
      ),
      ChatSuggestion(
        topic: "Autoestima",
        summary: "Reflexiona sobre tu autoconcepto y fortalece tu confianza personal.",
        prompt: hasName 
          ? "¿Qué aspectos de ti mismo/a valoras más, ${nombre}?"
          : "¿Qué aspectos de ti mismo/a valoras más?",
        backgroundColor: Color(0xFFFFF3E0),
        emojiIcon: "💪",
        customIcon: Icons.self_improvement,
      ),
      ChatSuggestion(
        topic: "Gestión del tiempo",
        summary: "Organiza mejor tus tareas y encuentra equilibrio entre estudio y descanso.",
        prompt: hasName 
          ? "¿Cómo organizas tu tiempo actualmente, ${nombre}?"
          : "¿Cómo organizas tu tiempo actualmente?",
        backgroundColor: Color(0xFFE0F7FA),
        emojiIcon: "⏰",
        customIcon: Icons.access_time,
      ),
    ];
    
    _isLoadingSuggestions = false;

        WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mover la lógica que requiere notifyListeners aquí
      notifyListeners(); // Ahora se llama después del build
    });
  }

  // ================= MÉTODOS RESTANTES =================
  
  void toggleCalendar() {
    _showCalendar = !_showCalendar;
    notifyListeners();
  }

  void selectDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  Future<void> syncPsychologyData() async {
    try {
      _isLoadingPsychology = true;
      notifyListeners();

      await _databaseHelper.syncAllData();
      await _loadPsychologyModulos();
    } catch (e) {
      rethrow;
    } finally {
      _isLoadingPsychology = false;
      notifyListeners();
    }
  }

  Future<void> _loadPsychologyModulos() async {
    try {
      final modulos = await _databaseHelper.readModulos();

      if (modulos.isEmpty) {
        await SampleDataLoader.loadSamplePsychologyModules();
        final modulosConEjemplos = await _databaseHelper.readModulos();

        if (modulosConEjemplos.isEmpty) {
          _psychologyModulos = [];
        } else {
          _psychologyModulos =
              modulosConEjemplos.take(4).map(PsychologyModulo.fromMap).toList();
        }
      } else {
        _psychologyModulos =
            modulos.take(4).map(PsychologyModulo.fromMap).toList();
      }
    } catch (e) {
      print('❌ Error cargando módulos de psicología: $e');
      try {
        await SampleDataLoader.loadSamplePsychologyModules();
        final modulosRespaldo = await _databaseHelper.readModulos();
        _psychologyModulos =
            modulosRespaldo.take(4).map(PsychologyModulo.fromMap).toList();
      } catch (e2) {
        _psychologyModulos = [];
      }
    } finally {
      _isLoadingPsychology = false;
      notifyListeners();
    }
  }

  List<ChatSuggestion> get todaySuggestions {
    if (_chatSuggestions.isEmpty) {
      _loadStaticConversations();
    }
    return _chatSuggestions;
  }

  // Método para limpiar cache (útil para testing)
  static void clearCache() {
    _cachedFraseMotivacional = null;
    _cachedStudentNameForFrase = null;
    _cachedFraseDate = null;
    _userNameCache.clear();
    print('🧹 Cache completo limpiado');
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}