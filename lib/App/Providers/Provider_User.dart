import 'package:flutter/material.dart';

class UsuarioProvider with ChangeNotifier {
  Map<String, dynamic>? _usuario;

  Map<String, dynamic>? get usuario => _usuario;

  void setUsuario(Map<String, dynamic> data) {
    _usuario = data;
    notifyListeners();
  }

  void limpiarUsuario() {
    _usuario = null;
    notifyListeners();
  }

  bool get estaAutenticado => _usuario != null;
}
