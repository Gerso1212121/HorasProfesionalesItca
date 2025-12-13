// lib/Backend/Data/Services/Remote/ExerciseService.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class ExerciseService {
  final SupabaseClient _supabase;

  ExerciseService() : _supabase = Supabase.instance.client;

  // Obtener todos los ejercicios
  Future<List<Map<String, dynamic>>> getAllExercises() async {
    try {
      final response = await _supabase
          .from('ejercicios') // Nombre de la tabla
          .select('*')
          .order('fecha_creacion', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error obteniendo ejercicios: $e');
      throw Exception('Error al obtener ejercicios: $e');
    }
  }

  // Obtener ejercicio por ID
  Future<Map<String, dynamic>?> getExerciseById(int id) async {
    try {
      final response = await _supabase
          .from('ejercicios')
          .select('*')
          .eq('id_ejercicio', id)
          .single();

      return response as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error obteniendo ejercicio por ID: $e');
      return null;
    }
  }
}