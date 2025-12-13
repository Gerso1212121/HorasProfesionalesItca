import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:horas2/Frontend/Routes/RouterGo.dart';

class ProfileVM extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSubscription;

  bool _isLoading = true;
  Map<String, dynamic>? _usuario;
  bool _hasError = false;
  String? _currentUserId;

  // Getters
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get usuario => _usuario;
  bool get hasError => _hasError;
  FirebaseAuth get auth => _auth;
  String? get currentUserId => _currentUserId;

  bool get esEstudianteItca {
    if (_usuario == null) return false;
    final email = _usuario!['correo']?.toString().toLowerCase() ?? '';
    return email.endsWith('@itca.edu.sv');
  }

  ProfileVM() {
    print('🟢 ProfileVM constructor llamado');
    
    // Escuchar cambios de autenticación
    _authSubscription = _auth.authStateChanges().listen((user) {
      print('👤 Cambio en autenticación detectado');
      print('   - Usuario anterior en VM: $_currentUserId');
      print('   - Usuario nuevo de Firebase: ${user?.uid}');
      
      final newUserId = user?.uid;
      
      // Si el usuario cambió, limpiar todo
      if (_currentUserId != null && newUserId != null && _currentUserId != newUserId) {
        print('🔄 ¡USUARIO CAMBIÓ! Limpiando datos antiguos...');
        _resetState();
      }
      
      _currentUserId = newUserId;
      
      // Cargar datos del nuevo usuario
      if (newUserId != null) {
        print('🔄 Cargando datos para nuevo usuario: $newUserId');
        _cargarUsuario();
      } else {
        print('👋 Usuario cerró sesión');
        _resetState();
      }
    });
    
    // Cargar datos iniciales
    _currentUserId = _auth.currentUser?.uid;
    if (_currentUserId != null) {
      Future.delayed(Duration.zero, () {
        _cargarUsuario();
      });
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reiniciar estado completo
  void _resetState() {
    print('🧹 Reiniciando estado de ProfileVM');
    _usuario = null;
    _isLoading = true;
    _hasError = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  // Método público para recargar
  Future<void> cargarUsuario() async {
    print('🔁 cargarUsuario() llamado externamente');
    _isLoading = true;
    _hasError = false;
    notifyListeners();
    
    await _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    try {
      print('🔍 _cargarUsuario() iniciado');
      final currentUser = _auth.currentUser;
      final currentUserId = currentUser?.uid;
      
      print('👤 Usuario actual de Firebase: $currentUserId');
      print('👤 Usuario registrado en VM: $_currentUserId');

      // Verificar que estamos cargando para el usuario correcto
      if (currentUserId != _currentUserId) {
        print('⚠️ Desfase de usuario! Firebase: $currentUserId, VM: $_currentUserId');
        print('🔄 Esperando a que el listener actualice el usuario...');
        return;
      }

      if (currentUser != null) {
        print('🔥 Buscando en Firestore para UID: $currentUserId');
        
        final doc = await _firestore.collection('estudiantes').doc(currentUserId).get();
        
        if (doc.exists && doc.data() != null) {
          final datosFirestore = doc.data()!;
          print('✅ Encontrado en Firestore');
          
          // Verificar UID en los datos
          final uidEnDatos = datosFirestore['uid']?.toString() ?? 
                            datosFirestore['uid_firebase']?.toString();
          
          print('🔍 Verificando UID en datos:');
          print('   - UID esperado: $currentUserId');
          print('   - UID en datos: $uidEnDatos');
          print('   - Coinciden: ${uidEnDatos == currentUserId}');
          
          if (uidEnDatos == currentUserId) {
            _usuario = datosFirestore;
            _hasError = false;
            print('🎯 Datos asignados correctamente para usuario: $currentUserId');
          } else {
            print('❌ Los datos no corresponden al usuario actual');
            _hasError = true;
            _usuario = null;
          }
        } else {
          print('❌ No encontrado en Firestore');
          _hasError = true;
          _usuario = null;
        }
      } else {
        print('❌ No hay usuario autenticado en Firebase');
        _hasError = true;
        _usuario = null;
      }
    } catch (e, stackTrace) {
      print('❌ Error cargando perfil: $e');
      print('📋 Stack trace: $stackTrace');
      _hasError = true;
      _usuario = null;
    } finally {
      print('🏁 _cargarUsuario() finalizado');
      print('   - isLoading: false');
      print('   - hasError: $_hasError');
      print('   - usuario: ${_usuario != null ? "PRESENTE" : "NULO"}');
      print('   - currentUserId en VM: $_currentUserId');
      
      if (_usuario != null) {
        print('📊 Datos del usuario:');
        _usuario!.forEach((key, value) {
          print('   - $key: $value');
        });
      }
      
      _isLoading = false;
      notifyListeners();
      print('🔔 notifyListeners() llamado');
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _auth.signOut();
      _resetState();

      if (context.mounted) {
        context.go(RouteNames.login);
      }
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }
}