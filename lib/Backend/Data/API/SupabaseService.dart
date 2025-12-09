

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || key == null) throw Exception("Variables Supabase no definidas");
    await Supabase.initialize(url: url, anonKey: key);
  }

  static SupabaseClient client() => Supabase.instance.client;


  final SupabaseClient _supabase = Supabase.instance.client;
  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  Future<List<Map<String, dynamic>>> getModules() async {
    try {
      final response = await _supabase
          .from('modulos')
          .select('*')
          .order('fecha_creacion', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo módulos: $e');
      rethrow;
    }
  }

  Future<void> toggleModuleFavorite({
    required String moduleId,
    required String userId,
    required bool isFavorite,
  }) async {
    try {
      // Primero, verificar si ya existe una entrada
      final existing = await _supabase
          .from('favoritos_modulos')
          .select()
          .eq('modulo_id', moduleId)
          .eq('usuario_id', userId)
          .single()
          .catchError((_) => null);
      
      if (existing != null) {
        // Actualizar existente
        await _supabase
            .from('favoritos_modulos')
            .update({'is_favorite': isFavorite})
            .eq('id', existing['id']);
      } else {
        // Crear nuevo
        await _supabase.from('favoritos_modulos').insert({
          'modulo_id': moduleId,
          'usuario_id': userId,
          'is_favorite': isFavorite,
          'fecha_creacion': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getModuleById(String moduleId) async {
    try {
      final response = await _supabase
          .from('modulos')
          .select()
          .eq('id', moduleId)
          .single();
      
      return response;
    } catch (e) {
      print('Error obteniendo módulo por ID: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getFavoriteModules(String userId) async {
    try {
      final response = await _supabase
          .from('favoritos_modulos')
          .select('modulo_id')
          .eq('usuario_id', userId)
          .eq('is_favorite', true);
      
      final moduleIds = response.map((item) => item['modulo_id'] as String).toList();
      
      if (moduleIds.isEmpty) return [];
      
      final modules = await _supabase
          .from('modulos')
          .select()
          .inFilter('id', moduleIds);
      
      return List<Map<String, dynamic>>.from(modules);
    } catch (e) {
      print('Error obteniendo módulos favoritos: $e');
      return [];
    }
  }
}