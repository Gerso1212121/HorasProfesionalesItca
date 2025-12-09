// lib/Backend/Utils/ConnectivityService.dart
import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static final StreamController<bool> _connectionController = 
      StreamController<bool>.broadcast();

  static Stream<bool> get connectionStream => _connectionController.stream;
  static bool _isConnected = true;
  static bool _isCheckingRealConnection = false;

  static bool get isConnected => _isConnected;

  static Future<void> initialize() async {
    // Verificar estado inicial CON verificación real
    await _checkRealConnection();
    
    // Escuchar cambios en la conectividad
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) async {
        // Cuando cambia la conectividad, verificar si hay internet REAL
        await _checkRealConnection();
      },
    );
  }

  static Future<void> _checkRealConnection() async {
    if (_isCheckingRealConnection) return;
    _isCheckingRealConnection = true;
    
    try {
      // 1. Primero verificar conectividad básica
      final List<ConnectivityResult> results = 
          await _connectivity.checkConnectivity();
      
      final bool hasBasicConnectivity = _hasBasicConnectivity(results);
      
      if (!hasBasicConnectivity) {
        // Sin conectividad básica = definitivamente sin internet
        _updateConnectionStatus(false);
        _isCheckingRealConnection = false;
        return;
      }
      
      // 2. Si hay conectividad básica, verificar internet REAL
      final bool hasRealInternet = await _hasRealInternetConnection();
      
      _updateConnectionStatus(hasRealInternet);
      
    } catch (e) {
      print('❌ Error verificando conexión: $e');
      _updateConnectionStatus(false);
    } finally {
      _isCheckingRealConnection = false;
    }
  }

  static bool _hasBasicConnectivity(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }


static Future<bool> _hasRealInternetConnection() async {
  try {
      final result = await InternetAddress.lookup('google.com').timeout(Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
    return false;
  }
}


  static void _updateConnectionStatus(bool isConnected) {
    if (_isConnected != isConnected) {
      _isConnected = isConnected;
      _connectionController.add(isConnected);
      print('🌐 Estado de internet REAL: $isConnected');
    }
  }

  static Future<bool> checkConnection() async {
    try {
      return await _hasRealInternetConnection();
    } catch (e) {
      return false;
    }
  }

  static void dispose() {
    _subscription?.cancel();
    _connectionController.close();
  }
}