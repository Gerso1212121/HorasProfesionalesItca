import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];
    if (url == null || key == null)
      throw Exception("Variables Supabase no definidas");
    await Supabase.initialize(url: url, anonKey: key);
  }

  static SupabaseClient client() => Supabase.instance.client;

  final SupabaseClient _supabase = Supabase.instance.client;

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
}
