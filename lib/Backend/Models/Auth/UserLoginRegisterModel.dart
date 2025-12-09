import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? nombre;
  final String? apellido;
  final String? fotoUrl;
  final DateTime? fechaCreacion;
  final bool emailVerificado;
  final bool? datosCompletados;

  UserModel({
    required this.uid,
    required this.email,
    this.nombre,
    this.apellido,
    this.fotoUrl,
    this.fechaCreacion,
    required this.emailVerificado,
    this.datosCompletados = false,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      nombre: data['nombre'],
      apellido: data['apellido'],
      fotoUrl: data['fotoUrl'],
      fechaCreacion: data['fechaCreacion'] != null 
          ? (data['fechaCreacion'] as Timestamp).toDate()
          : null,
      emailVerificado: data['emailVerificado'] ?? false,
      datosCompletados: data['datosCompletados'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'nombre': nombre,
      'apellido': apellido,
      'fotoUrl': fotoUrl,
      'fechaCreacion': fechaCreacion,
      'emailVerificado': emailVerificado,
      'datosCompletados': datosCompletados,
    };
  }
}