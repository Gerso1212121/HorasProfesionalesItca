// lib/Backend/Data/Services/LocalStorageService.dart
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  static const String _hasSeenWelcomeKey = 'has_seen_welcome';
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    if (_prefs != null) return _prefs!;
    
    print('🔧 Inicializando SharedPreferences...');
    try {
      _prefs = await SharedPreferences.getInstance();
      print('✅ SharedPreferences inicializado');
      return _prefs!;
    } catch (e) {
      print('❌ Error inicializando SharedPreferences: $e');
      rethrow;
    }
  }

  // Guardar que el usuario ya vio el WelcomeScreen
  Future<void> setHasSeenWelcome(bool value) async {
    try {
      final prefs = await this.prefs;
      final success = await prefs.setBool(_hasSeenWelcomeKey, value);
      print('💾 setHasSeenWelcome($value) - Éxito: $success');
      if (!success) {
        print('⚠️ No se pudo guardar el valor en SharedPreferences');
      }
    } catch (e) {
      print('❌ Error en setHasSeenWelcome: $e');
      rethrow;
    }
  }

  // Verificar si el usuario ya vio el WelcomeScreen
  Future<bool> getHasSeenWelcome() async {
    try {
      final prefs = await this.prefs;
      final hasSeen = prefs.getBool(_hasSeenWelcomeKey) ?? false;
      print('📖 getHasSeenWelcome() = $hasSeen');
      return hasSeen;
    } catch (e) {
      print('❌ Error en getHasSeenWelcome: $e');
      return false; // Por defecto false si hay error
    }
  }

  // Limpiar el cache
  Future<void> clearWelcomeCache() async {
    try {
      final prefs = await this.prefs;
      final success = await prefs.remove(_hasSeenWelcomeKey);
      print('🧹 clearWelcomeCache() - Éxito: $success');
    } catch (e) {
      print('❌ Error en clearWelcomeCache: $e');
    }
  }
}