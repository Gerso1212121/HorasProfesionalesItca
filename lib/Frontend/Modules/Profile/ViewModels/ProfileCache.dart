class ProfileCache {
  static Map<String, dynamic>? _cachedUserData;
  static DateTime? _lastCacheTime;
  static String? _cachedUserId;
  
  static void cacheUserData(Map<String, dynamic> userData) {
    try {
      final uid = userData['uid_firebase']?.toString() ?? 
                 userData['uid']?.toString();
      
      if (uid == null) {
        print('⚠️ No se puede cachear: sin UID en datos');
        return;
      }
      
      _cachedUserData = Map<String, dynamic>.from(userData);
      _lastCacheTime = DateTime.now();
      _cachedUserId = uid;
      
      print('💾 Caché actualizada para usuario: $uid');
      print('   - Hora: $_lastCacheTime');
      print('   - Campos: ${_cachedUserData?.keys.toList()}');
    } catch (e) {
      print('❌ Error cacheando datos: $e');
    }
  }
  
  static Map<String, dynamic>? getCachedUserData() {
    if (_cachedUserData == null || 
        _lastCacheTime == null || 
        _cachedUserId == null) {
      return null;
    }
    
    // Los datos expiran después de 2 minutos
    if (DateTime.now().difference(_lastCacheTime!).inMinutes >= 2) {
      print('⏰ Caché expirada (más de 2 minutos)');
      clearCache();
      return null;
    }
    
    print('🔍 Datos cacheados disponibles para: $_cachedUserId');
    return _cachedUserData;
  }
  
  static void clearCache() {
    print('🧹 Limpiando caché completa');
    _cachedUserData = null;
    _lastCacheTime = null;
    _cachedUserId = null;
  }
  
  static bool hasValidCacheForUser(String? userId) {
    if (userId == null || _cachedUserId == null) return false;
    
    return _cachedUserId == userId && 
           _cachedUserData != null &&
           _lastCacheTime != null &&
           DateTime.now().difference(_lastCacheTime!).inMinutes < 2;
  }
}