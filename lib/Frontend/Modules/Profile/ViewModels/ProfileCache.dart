// Profile/ViewModels/ProfileCache.dart
class ProfileCache {
  static Map<String, dynamic>? _cachedUserData;
  static DateTime? _lastCacheTime;
  
  // Guardar en caché
  static void cacheUserData(Map<String, dynamic> userData) {
    _cachedUserData = Map<String, dynamic>.from(userData);
    _lastCacheTime = DateTime.now();
  }
  
  // Obtener datos cacheados
  static Map<String, dynamic>? getCachedUserData() {
    // Solo devolver si los datos tienen menos de 5 minutos
    if (_lastCacheTime != null && 
        DateTime.now().difference(_lastCacheTime!).inMinutes < 5) {
      return _cachedUserData;
    }
    return null;
  }
  
  // Limpiar caché
  static void clearCache() {
    _cachedUserData = null;
    _lastCacheTime = null;
  }
  
  // Verificar si hay datos cacheados
  static bool hasCachedData() {
    return _cachedUserData != null && 
           _lastCacheTime != null && 
           DateTime.now().difference(_lastCacheTime!).inMinutes < 5;
  }
}