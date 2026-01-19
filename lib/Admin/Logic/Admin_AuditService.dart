import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

/// Servicio para registrar todas las acciones de los administradores
/// en una tabla de auditoría para mantener un historial completo de cambios.
class AuditService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Registra una acción en la tabla de auditoría
  ///
  /// [tableName] - Nombre de la tabla afectada
  /// [action] - Tipo de acción (CREATE, UPDATE, DELETE, STATUS_CHANGE, etc.)
  /// [recordId] - ID del registro afectado
  /// [oldValues] - Valores anteriores (para updates y deletes)
  /// [newValues] - Valores nuevos (para creates y updates)
  /// [adminId] - ID del administrador que realizó la acción
  /// [details] - Detalles adicionales opcionales
  static Future<void> logAction({
    required String tableName,
    required String action,
    required String recordId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? adminId,
    String? details,
  }) async {
    try {
      // Obtener información del admin actual si no se proporciona
      final currentAdminId = adminId ?? _supabase.auth.currentUser?.id;

      if (currentAdminId == null) {
        throw Exception('No se puede determinar el administrador actual');
      }

      // Obtener información del admin para el log
      final adminInfo = await _supabase
          .from('admins')
          .select('username, name')
          .eq('id', currentAdminId)
          .maybeSingle();

      // Preparar los datos para insertar
      final auditData = {
        'table_name': tableName,
        'action': action,
        'record_id': recordId,
        'admin_id': currentAdminId,
        'admin_username': adminInfo?['username'] ?? 'unknown',
        'admin_name': adminInfo?['name'] ?? 'unknown',
        'old_values':
            oldValues != null ? jsonEncode(_cleanValues(oldValues)) : null,
        'new_values':
            newValues != null ? jsonEncode(_cleanValues(newValues)) : null,
        'changes': _getChanges(oldValues, newValues),
        'details': details,
        'ip_address': await _getClientIP(),
        'user_agent': await _getUserAgent(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Insertar en la tabla de auditoría
      await _supabase.from('admin_audit_log').insert(auditData);
    } catch (e) {
      // Si falla el audit, no debería fallar la operación principal
      // Solo loguear el error
      print('Error registrando auditoría: $e');
    }
  }

  /// Método específico para loguear login/logout
  static Future<void> logAuthAction({
    required String action, // 'LOGIN', 'LOGOUT', 'FAILED_LOGIN'
    String? adminId,
    String? username,
    String? details,
  }) async {
    try {
      final currentAdminId = adminId ?? _supabase.auth.currentUser?.id;

      final auditData = {
        'table_name': 'auth',
        'action': action,
        'record_id': currentAdminId ?? 'unknown',
        'admin_id': currentAdminId,
        'admin_username': username ?? 'unknown',
        'admin_name': username ?? 'unknown',
        'details': details,
        'ip_address': await _getClientIP(),
        'user_agent': await _getUserAgent(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _supabase.from('admin_audit_log').insert(auditData);
    } catch (e) {
      print('Error registrando auditoría de auth: $e');
    }
  }

  /// Obtiene la lista de auditorías con filtros opcionales
  static Future<List<Map<String, dynamic>>> getAuditLogs({
    String? tableName,
    String? action,
    String? adminId,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('admin_audit_log').select('''
          id, table_name, action, record_id, admin_id, admin_username, admin_name,
          old_values, new_values, changes, details, ip_address, timestamp,
          created_at
        ''');

      if (tableName != null) {
        query = query.eq('table_name', tableName);
      }
      if (action != null) {
        query = query.eq('action', action);
      }
      if (adminId != null) {
        query = query.eq('admin_id', adminId);
      }
      if (fromDate != null) {
        query = query.gte('timestamp', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('timestamp', toDate.toIso8601String());
      }

      final response = await query
          .order('timestamp', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error obteniendo logs de auditoría: $e');
      return [];
    }
  }

  /// Obtiene estadísticas de auditoría
  static Future<Map<String, dynamic>> getAuditStats({
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query =
          _supabase.from('admin_audit_log').select('action, admin_username');

      if (fromDate != null) {
        query = query.gte('timestamp', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('timestamp', toDate.toIso8601String());
      }

      final response = await query;
      final logs = List<Map<String, dynamic>>.from(response);

      // Contar por acción
      final actionCounts = <String, int>{};
      final adminCounts = <String, int>{};

      for (final log in logs) {
        final action = log['action'] as String;
        final admin = log['admin_username'] as String;

        actionCounts[action] = (actionCounts[action] ?? 0) + 1;
        adminCounts[admin] = (adminCounts[admin] ?? 0) + 1;
      }

      return {
        'total_actions': logs.length,
        'actions_by_type': actionCounts,
        'actions_by_admin': adminCounts,
        'period_start': fromDate?.toIso8601String(),
        'period_end': toDate?.toIso8601String(),
      };
    } catch (e) {
      print('Error obteniendo estadísticas de auditoría: $e');
      return {
        'total_actions': 0,
        'actions_by_type': <String, int>{},
        'actions_by_admin': <String, int>{},
      };
    }
  }

  /// Limpia valores sensibles antes de guardarlos en el log
  static Map<String, dynamic> _cleanValues(Map<String, dynamic> values) {
    final cleaned = Map<String, dynamic>.from(values);

    // Remover campos sensibles
    cleaned.remove('password');
    cleaned.remove('password_hash');
    cleaned.remove('auth_token');
    cleaned.remove('refresh_token');

    // Truncar campos muy largos
    cleaned.forEach((key, value) {
      if (value is String && value.length > 1000) {
        cleaned[key] = '${value.substring(0, 1000)}...';
      }
    });

    return cleaned;
  }

  /// Genera un resumen de los cambios realizados
  static String? _getChanges(
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
  ) {
    if (oldValues == null || newValues == null) {
      return null;
    }

    final changes = <String>[];
    final allKeys = {...oldValues.keys, ...newValues.keys};

    for (final key in allKeys) {
      final oldValue = oldValues[key];
      final newValue = newValues[key];

      if (oldValue != newValue) {
        changes.add('$key: "$oldValue" → "$newValue"');
      }
    }

    return changes.isEmpty ? null : changes.join(', ');
  }

  /// Intenta obtener la IP del cliente (limitado en aplicaciones móviles)
  static Future<String?> _getClientIP() async {
    try {
      // En aplicaciones móviles, obtener la IP local es complicado.
      // Aquí simplemente retornamos un placeholder.
      return 'mobile_app';
    } catch (e) {
      return null;
    }
  }

  /// Intenta obtener el user agent
  static Future<String?> _getUserAgent() async {
    try {
      // En aplicaciones móviles, el user agent no es tan relevante.
      // Aquí simplemente retornamos un placeholder.
      return 'Flutter Mobile App';
    } catch (e) {
      return null;
    }
  }

  /// Registra acciones masivas (como imports o exports)
  static Future<void> logBulkAction({
    required String action,
    required String tableName,
    required int recordsAffected,
    String? details,
    String? adminId,
  }) async {
    await logAction(
      tableName: tableName,
      action: 'BULK_$action',
      recordId: 'bulk_operation',
      details: '$details - $recordsAffected registros afectados',
      adminId: adminId,
    );
  }

  /// Registra errores importantes del sistema
  static Future<void> logSystemError({
    required String error,
    String? context,
    String? adminId,
  }) async {
    await logAction(
      tableName: 'system',
      action: 'ERROR',
      recordId: 'system_error',
      details: 'Error: $error${context != null ? ' - Contexto: $context' : ''}',
      adminId: adminId,
    );
  }
}
