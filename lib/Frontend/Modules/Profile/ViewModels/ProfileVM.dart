import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importante para el Plan B
import 'package:go_router/go_router.dart';
import 'package:horas2/Backend/Data/Services/DataBase/DatabaseHelper.dart';
import 'package:horas2/Frontend/Routes/RouterGo.dart';

class ProfileVM extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Instancia Firestore
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  bool _isLoading = true;
  Map<String, dynamic>? _usuario;

  // Getters
  bool get isLoading => _isLoading;
  Map<String, dynamic>? get usuario => _usuario;

  // Lógica encapsulada para saber si es ITCA
  bool get esEstudianteItca {
    if (_usuario == null) return false;
    final email = _usuario!['correo']?.toString().toLowerCase() ?? '';
    return email.endsWith('@itca.edu.sv');
  }

  ProfileVM() {
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;

      if (currentUser != null) {
        final uid = currentUser.uid;
        
        // 1. INTENTO A: Buscar en base de datos local (SQLite)
        Map<String, dynamic>? datosUsuario = await _dbHelper.getEstudiantePorUID(uid);

        // 2. INTENTO B: Si es null en local, buscamos en Firestore (Nube)
        if (datosUsuario == null) {
          print('⚠️ No encontrado en SQLite, buscando en Firestore...');
          final doc = await _firestore.collection('estudiantes').doc(uid).get();
          
          if (doc.exists) {
            datosUsuario = doc.data();
            // Opcional: Aquí podrías guardar en SQLite para la próxima vez
            // await _dbHelper.insertEstudiante(datosUsuario!); 
            print('✅ Recuperado desde Firestore');
          }
        }

        // 3. Verificamos si encontramos datos en algún lado
        if (datosUsuario != null) {
          _usuario = datosUsuario;
        } else {
          // Si no está ni en local ni en nube, ahí sí es un error
          print('❌ Usuario no encontrado en ninguna base de datos');
          _usuario = null;
          // Opcional: forzar logout si es crítico
        }
      }
    } catch (e) {
      print('❌ Error cargando perfil: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout(BuildContext context) async {
    try {
      await _dbHelper.deleteEstudianteActual();
      await _auth.signOut();

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