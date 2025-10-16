import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_app_tests/App/Data/Models/sesion_chat.dart';

class ChatStorage {
  static Future<void> saveSesionChat(SesionChat sesion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sesionesJson = prefs.getString('sesiones_chat') ?? '[]';
      final sesiones = jsonDecode(sesionesJson) as List;

      // Agregar nueva sesión
      sesiones.add(sesion.toJson());

      await prefs.setString('sesiones_chat', jsonEncode(sesiones));
    } catch (e) {
      print('Error guardando sesión: $e');
      rethrow;
    }
  }

  static Future<List<SesionChat>> getSesionesChat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sesionesJson = prefs.getString('sesiones_chat') ?? '[]';
      final sesiones = jsonDecode(sesionesJson) as List;

      return sesiones.map((json) => SesionChat.fromJson(json)).toList();
    } catch (e) {
      print('Error cargando sesiones: $e');
      return [];
    }
  }

  static Future<void> deleteSesionChat(String fecha) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sesionesJson = prefs.getString('sesiones_chat') ?? '[]';
      final sesiones = jsonDecode(sesionesJson) as List;

      // Filtrar sesiones (eliminar la que coincida con la fecha)
      final sesionesActualizadas =
          sesiones.where((sesion) => sesion['fecha'] != fecha).toList();

      await prefs.setString('sesiones_chat', jsonEncode(sesionesActualizadas));
    } catch (e) {
      print('Error eliminando sesión: $e');
      rethrow;
    }
  }
}
