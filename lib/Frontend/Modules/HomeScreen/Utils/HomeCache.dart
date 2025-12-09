// HomeScreen/Models/HomeCache.dart
import 'package:horas2/Frontend/Modules/HomeScreen/Models/PsychologyModulo.dart';

class HomeCache {
  static List<PsychologyModulo>? _cachedPsychologyModules;
  static DateTime? _lastPsychologyCacheTime;
  
  static const Duration _cacheDuration = Duration(minutes: 30);
  
  // Guardar módulos de psicología en caché
  static void cachePsychologyModules(List<PsychologyModulo> modules) {
    _cachedPsychologyModules = List<PsychologyModulo>.from(modules);
    _lastPsychologyCacheTime = DateTime.now();
  }
  
  // Obtener módulos cacheados
  static List<PsychologyModulo>? getCachedPsychologyModules() {
    if (_cachedPsychologyModules != null && 
        _lastPsychologyCacheTime != null &&
        DateTime.now().difference(_lastPsychologyCacheTime!) < _cacheDuration) {
      return _cachedPsychologyModules;
    }
    return null;
  }
  
  // Verificar si hay datos cacheados válidos
  static bool hasValidPsychologyCache() {
    return _cachedPsychologyModules != null && 
           _lastPsychologyCacheTime != null &&
           DateTime.now().difference(_lastPsychologyCacheTime!) < _cacheDuration;
  }
  
  // Limpiar caché de psicología
  static void clearPsychologyCache() {
    _cachedPsychologyModules = null;
    _lastPsychologyCacheTime = null;
  }
  
  // Verificar tiempo restante de caché (para debugging)
  static Duration? getCacheTimeRemaining() {
    if (_lastPsychologyCacheTime == null) return null;
    final elapsed = DateTime.now().difference(_lastPsychologyCacheTime!);
    if (elapsed > _cacheDuration) return Duration.zero;
    return _cacheDuration - elapsed;
  }
}