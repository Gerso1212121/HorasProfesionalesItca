import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class CifradoService {
  static const String _keyName = 'chat_encryption_key';

  // Generar clave de cifrado PERMANENTE para el usuario
  static Future<String> _generarClaveCifrado() async {
    final prefs = await SharedPreferences.getInstance();
    String? clave = prefs.getString(_keyName);

    if (clave == null) {
      // Generar clave PERMANENTE basada en el email del usuario
      // Esto asegura que siempre sea la misma clave
      final email = prefs.getString('user_email') ?? 'default_user';
      final salt = 'chat_encryption_salt_2024';
      final combined = email + salt;

      // Crear clave determinística basada en el email
      final bytes = utf8.encode(combined);
      final hash = base64Url.encode(bytes);

      // Asegurar que tenga 32 bytes
      final keyBytes = utf8.encode(hash.padRight(32, '0').substring(0, 32));
      clave = base64Url.encode(keyBytes);

      await prefs.setString(_keyName, clave);
      developer.log('🔐 Clave PERMANENTE generada para: $email');
    } else {
      developer.log('🔐 Clave existente recuperada');
    }

    return clave;
  }

  // Cifrar texto usando XOR simple
  static Future<String> cifrarTexto(String texto) async {
    try {
      if (texto.isEmpty) return texto;

      final clave = await _generarClaveCifrado();
      final claveBytes = base64Url.decode(clave);

      // Cifrar usando XOR
      final textoBytes = utf8.encode(texto);
      final cifradoBytes = List<int>.generate(textoBytes.length, (i) {
        return textoBytes[i] ^ claveBytes[i % claveBytes.length];
      });

      final resultado = base64Url.encode(cifradoBytes);
      developer
          .log('🔐 Texto cifrado correctamente: ${texto.length} caracteres');
      return resultado;
    } catch (e) {
      developer.log('❌ Error cifrando texto: $e');
      return texto; // Fallback: devolver texto original si falla
    }
  }

  // Descifrar texto usando XOR simple
  static Future<String> descifrarTexto(String textoCifrado) async {
    try {
      if (textoCifrado.isEmpty) return textoCifrado;

      final clave = await _generarClaveCifrado();
      final claveBytes = base64Url.decode(clave);

      // Descifrar usando XOR
      final cifradoBytes = base64Url.decode(textoCifrado);
      final descifradoBytes = List<int>.generate(cifradoBytes.length, (i) {
        return cifradoBytes[i] ^ claveBytes[i % claveBytes.length];
      });

      final resultado = utf8.decode(descifradoBytes);
      developer.log(
          '🔐 Texto descifrado correctamente: ${resultado.length} caracteres');
      return resultado;
    } catch (e) {
      developer.log('❌ Error descifrando texto: $e');
      return textoCifrado; // Fallback: devolver texto original si falla
    }
  }

  // Verificar si un string es base64 válido
  static bool _esBase64Valido(String texto) {
    try {
      base64Url.decode(texto);
      return true;
    } catch (e) {
      return false;
    }
  }

  // CIFRAR MENSAJES - MÉTODO SIMPLE Y DIRECTO
  static Future<List<Map<String, dynamic>>> cifrarMensajes(
      List<Map<String, dynamic>> mensajes) async {
    final mensajesCifrados = <Map<String, dynamic>>[];

    developer.log('🔐 CIFRANDO ${mensajes.length} MENSAJES...');

    for (final mensaje in mensajes) {
      final mensajeCifrado = Map<String, dynamic>.from(mensaje);

      if (mensajeCifrado['contenido'] != null) {
        final contenidoOriginal = mensajeCifrado['contenido'].toString();
        if (contenidoOriginal.isNotEmpty) {
          mensajeCifrado['contenido'] = await cifrarTexto(contenidoOriginal);
          mensajeCifrado['cifrado'] = true;
        }
      }

      mensajesCifrados.add(mensajeCifrado);
    }

    developer.log('🔐 ${mensajesCifrados.length} mensajes cifrados');
    return mensajesCifrados;
  }

  // DESCIFRAR MENSAJES - MÉTODO SIMPLE Y DIRECTO
  static Future<List<Map<String, dynamic>>> descifrarMensajes(
      List<Map<String, dynamic>> mensajes) async {
    final mensajesDescifrados = <Map<String, dynamic>>[];

    developer.log('🔐 DESCIFRANDO ${mensajes.length} MENSAJES...');

    for (final mensaje in mensajes) {
      final mensajeDescifrado = Map<String, dynamic>.from(mensaje);

      if (mensajeDescifrado['contenido'] != null) {
        final contenido = mensajeDescifrado['contenido'].toString();

        if (contenido.isNotEmpty) {
          // SIEMPRE intentar descifrar si es base64
          if (_esBase64Valido(contenido)) {
            try {
              developer.log('🔐 Intentando descifrar: $contenido');
              final contenidoDescifrado = await descifrarTexto(contenido);
              mensajeDescifrado['contenido'] = contenidoDescifrado;
              developer.log('✅ Descifrado exitoso: $contenidoDescifrado');
            } catch (e) {
              developer.log('❌ Error descifrando, manteniendo original: $e');
            }
          } else {
            developer.log('📝 No es base64, manteniendo original: $contenido');
          }
        }
      }

      mensajesDescifrados.add(mensajeDescifrado);
    }

    developer.log('🔐 ${mensajesDescifrados.length} mensajes procesados');
    return mensajesDescifrados;
  }

  // Limpiar clave cuando el usuario cierre sesión
  static Future<void> limpiarClave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    developer.log('🔐 Clave de cifrado limpiada');
  }

  // Verificar si la clave existe
  static Future<bool> tieneClave() async {
    final prefs = await SharedPreferences.getInstance();
    final clave = prefs.getString(_keyName);
    return clave != null;
  }
}
