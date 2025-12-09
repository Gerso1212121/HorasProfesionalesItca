import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDataVM extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _esItca = false;
  bool get esItca => _esItca;

  User? _user;
  User? get user => _user;
  
  String? _correo;
  String? get correo => _correo;
  
  // Para cargar datos existentes
  bool _hasExistingData = false;
  bool get hasExistingData => _hasExistingData;

  // Validators
  String? validateNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa un nombre y un apellido';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (!value.contains(' ')) {
      return 'Por favor ingresa nombre y apellido separados por espacio';
    }
    return null;
  }

  String? validateTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu teléfono';
    }
    if (value.length < 8) {
      return 'El teléfono debe tener al menos 8 dígitos';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Solo se permiten números';
    }
    return null;
  }

  String? validateCarnet(String? value, bool esItca) {
    if (esItca) {
      if (value == null || value.isEmpty) {
        return 'Por favor ingresa tu carnet';
      }
      if (value.length != 6) {
        return 'El carnet debe tener exactamente 6 dígitos';
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
        return 'Solo se permiten números';
      }
    }
    return null;
  }

  // Nueva función: Validar si el carnet ya existe
  Future<String?> validarCarnetExistente(String? carnet) async {
    try {
      // Validar si el carnet es null o vacío
      if (carnet == null || carnet.isEmpty) {
        return null; // Deja que validateCarnet maneje el error de campo vacío
      }
      
      // Limpiar el carnet (quitar espacios)
      final carnetLimpio = carnet.trim();
      
      // Validar formato básico (por si se llama directamente)
      if (carnetLimpio.length != 6) {
        return null; // Deja que validateCarnet maneje el error de formato
      }
      
      // Consultar en Firestore si existe algún documento con este carnet
      final querySnapshot = await _firestore
          .collection('estudiantes')
          .where('carnet', isEqualTo: carnetLimpio)
          .limit(1)
          .get();

      // Si el carnet existe y no pertenece al usuario actual
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final uidExistente = doc.id;
        
        // Si el usuario actual es diferente al dueño del carnet
        if (_user != null && uidExistente != _user!.uid) {
          return 'Este número de carnet ya está registrado por otro estudiante';
        }
      }
      
      return null; // Carnet disponible
    } catch (e) {
      print('❌ Error validando carnet: $e');
      return 'Error al verificar el carnet. Intenta de nuevo';
    }
  }

  // Validación completa del carnet (formato + existencia)
  Future<String?> validarCarnetCompleto(String? value, bool esItca) async {
    if (!esItca) return null;
    
    // Primero validar formato básico
    final errorFormato = validateCarnet(value, esItca);
    if (errorFormato != null) {
      return errorFormato;
    }

    // Si el formato es válido, verificar existencia en la base de datos
    final errorExistencia = await validarCarnetExistente(value);
    return errorExistencia;
  }

  // Validar si el teléfono ya existe
  Future<String?> validarTelefonoExistente(String? telefono) async {
    try {
      // Validar si el teléfono es null o vacío
      if (telefono == null || telefono.isEmpty) {
        return null; // Deja que validateTelefono maneje el error de campo vacío
      }
      
      // Limpiar el teléfono (quitar espacios, guiones, etc.)
      final telefonoLimpio = telefono.trim().replaceAll(RegExp(r'[\s\-]+'), '');
      
      // Validar formato básico (por si se llama directamente)
      if (telefonoLimpio.length < 8) {
        return null; // Deja que validateTelefono maneje el error de formato
      }
      
      // Consultar en Firestore si existe algún documento con este teléfono
      final querySnapshot = await _firestore
          .collection('estudiantes')
          .where('telefono', isEqualTo: telefonoLimpio)
          .limit(1)
          .get();

      // Si el teléfono existe y no pertenece al usuario actual
      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final uidExistente = doc.id;
        
        // Si el usuario actual es diferente al dueño del teléfono
        if (_user != null && uidExistente != _user!.uid) {
          return 'Este número de teléfono ya está registrado por otro usuario';
        }
      }
      
      return null; // Teléfono disponible
    } catch (e) {
      print('❌ Error validando teléfono: $e');
      return 'Error al verificar el teléfono. Intenta de nuevo';
    }
  }

  // Validación completa del teléfono (formato + existencia)
  Future<String?> validarTelefonoCompleto(String? value) async {
    // Primero validar formato básico
    final errorFormato = validateTelefono(value);
    if (errorFormato != null) {
      return errorFormato;
    }

    // Si el formato es válido, verificar existencia en la base de datos
    final errorExistencia = await validarTelefonoExistente(value!);
    return errorExistencia;
  }

  Future<void> verificarCorreoItca() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null && currentUser.email != null) {
      final correoUsuario = currentUser.email!.trim().toLowerCase();
      final esItcaResult = correoUsuario.endsWith('@itca.edu.sv');
      
      _user = currentUser;
      _correo = correoUsuario;
      _esItca = esItcaResult;
      notifyListeners();
    }
  }

  Future<void> loadUserData(String uid) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final doc = await _firestore
          .collection('estudiantes')
          .doc(uid)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        _hasExistingData = true;
        
        // Aquí podrías cargar los datos en variables si quieres
        // Por ejemplo:
        // _nombre = data?['nombre'];
        // _apellido = data?['apellido'];
        // etc.
        
        print('✅ Usuario ya tiene datos registrados');
      } else {
        _hasExistingData = false;
        print('📝 Usuario necesita completar datos');
      }
    } catch (e) {
      print('❌ Error cargando datos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> guardarDatos({
    required String nombre,
    required String telefono,
    String? carnet,
    String? sede,
    String? carrera,
    String? anioIngreso,
  }) async {
    if (_user == null) return false;

    // Validar que el teléfono no exista (por si acaso)
    final telefonoError = await validarTelefonoExistente(telefono);
    if (telefonoError != null) {
      print('❌ Teléfono ya existe: $telefonoError');
      return false;
    }

    // Si es ITCA, validar que el carnet no exista
    if (_esItca && carnet != null && carnet.isNotEmpty) {
      final carnetError = await validarCarnetExistente(carnet);
      if (carnetError != null) {
        print('❌ Carnet ya existe: $carnetError');
        return false;
      }
    }

    _isLoading = true;
    notifyListeners();

    try {
      final nombreCompleto = nombre.split(' ');
      final nombreSolo = nombreCompleto.isNotEmpty ? nombreCompleto.first : '';
      final apellidoSolo = nombreCompleto.length > 1 ? nombreCompleto.sublist(1).join(' ') : '';

      // Limpiar el teléfono antes de guardar
      final telefonoLimpio = telefono.trim().replaceAll(RegExp(r'[\s\-]+'), '');

      Map<String, dynamic> userData = {
        'uid': _user!.uid,
        'nombre': nombreSolo,
        'apellido': apellidoSolo,
        'correo': _user!.email,
        'telefono': telefonoLimpio,
        'fecha_sincronizacion': DateTime.now().toIso8601String(),
        'tipo_usuario': _esItca ? 'estudiante_itca' : 'usuario_externo',
        'fecha_registro': FieldValue.serverTimestamp(),
      };

      if (_esItca) {
        // Limpiar el carnet antes de guardar
        final carnetLimpio = carnet?.trim() ?? '';
        
        userData.addAll({
          'carnet': carnetLimpio,
          'sede': sede,
          'carrera': carrera,
          'anio_ingreso': anioIngreso,
          'verificado_itca': true,
        });
      }

      await _firestore
          .collection('estudiantes')
          .doc(_user!.uid)
          .set(userData, SetOptions(merge: true));

      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}