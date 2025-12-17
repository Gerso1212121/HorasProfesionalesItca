import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;

class CifradoService {
  static const String _keyName = 'chat_encryption_key';
  static const String _cifradoMarker = 'ENC:'; // Marcador para texto cifrado

  // Generar clave de cifrado PERMANENTE y CONSISTENTE
  static Future<String> _generarClaveCifrado() async {
    final prefs = await SharedPreferences.getInstance();
    String? clave = prefs.getString(_keyName);

    if (clave == null) {
      // Generar clave PERMANENTE basada en el email del usuario
      final email = prefs.getString('user_email') ?? 'default_user@itca.edu.sv';
      final salt = 'itca_encryption_salt_2024_v2';
      final combined = email + salt;

      // Crear clave determinística usando SHA256-like (simplificado)
      final bytes = utf8.encode(combined);
      var hash = base64Url.encode(bytes);

      // Asegurar longitud exacta de 32 caracteres base64
      while (hash.length < 32) {
        hash += hash;
      }
      hash = hash.substring(0, 32);

      // Convertir a base64 para almacenar
      clave = base64Url.encode(utf8.encode(hash));

      await prefs.setString(_keyName, clave);
      developer.log('🔐 Clave PERMANENTE generada para: $email');
    }

    return clave;
  }

  // Obtener bytes de clave consistentes
  static Future<List<int>> _obtenerClaveBytes() async {
    final claveBase64 = await _generarClaveCifrado();
    final decoded = base64Url.decode(claveBase64);

    // Asegurar 32 bytes
    if (decoded.length < 32) {
      final expanded = List<int>.filled(32, 0);
      for (int i = 0; i < 32; i++) {
        expanded[i] = decoded[i % decoded.length];
      }
      return expanded;
    }

    return decoded.sublist(0, 32);
  }

  // Cifrar texto - CON MARCADOR
  static Future<String> cifrarTexto(String texto) async {
    try {
      if (texto.isEmpty) return texto;

      // Si ya está cifrado (tiene marcador), no cifrar de nuevo
      if (texto.startsWith(_cifradoMarker)) {
        developer.log('⚠️ Texto ya cifrado, omitiendo');
        return texto;
      }

      // Verificar si ya es base64 (podría ser ya texto cifrado sin marcador)
      if (_esBase64Valido(texto) && texto.length > 20) {
        developer.log('⚠️ Posible texto ya cifrado (base64), omitiendo');
        return texto;
      }

      final claveBytes = await _obtenerClaveBytes();
      final textoBytes = utf8.encode(texto);

      // Cifrado XOR simple pero consistente
      final cifradoBytes = List<int>.generate(textoBytes.length, (i) {
        return textoBytes[i] ^ claveBytes[i % claveBytes.length];
      });

      final base64Result = base64Url.encode(cifradoBytes);
      final resultado = '$_cifradoMarker$base64Result';

      developer.log(
          '🔐 Cifrado exitoso: ${texto.length} chars → ${resultado.length} chars');
      return resultado;
    } catch (e) {
      developer.log('❌ Error en cifrarTexto: $e');
      // Fallback seguro: devolver texto original
      return texto;
    }
  }

  // Descifrar texto - INTELIGENTE
  static Future<String> descifrarTexto(String texto) async {
    try {
      if (texto.isEmpty) return texto;

      // CASO 1: Tiene marcador de cifrado
      if (texto.startsWith(_cifradoMarker)) {
        final base64Cifrado = texto.substring(_cifradoMarker.length);

        if (!_esBase64Valido(base64Cifrado)) {
          developer.log('⚠️ Marcador ENC: pero base64 inválido');
          return texto;
        }

        try {
          final claveBytes = await _obtenerClaveBytes();
          final cifradoBytes = base64Url.decode(base64Cifrado);

          final descifradoBytes = List<int>.generate(cifradoBytes.length, (i) {
            return cifradoBytes[i] ^ claveBytes[i % claveBytes.length];
          });

          final resultado = utf8.decode(descifradoBytes);
          developer
              .log('🔐 Descifrado con marcador: ${resultado.length} chars');
          return resultado;
        } catch (e) {
          developer.log('❌ Error descifrando texto con marcador: $e');
          return texto;
        }
      }

      // CASO 2: Es base64 válido (texto cifrado antiguo sin marcador)
      if (_esBase64Valido(texto) && texto.length > 10) {
        try {
          final claveBytes = await _obtenerClaveBytes();
          final cifradoBytes = base64Url.decode(texto);

          final descifradoBytes = List<int>.generate(cifradoBytes.length, (i) {
            return cifradoBytes[i] ^ claveBytes[i % claveBytes.length];
          });

          final resultado = utf8.decode(descifradoBytes);

          // Verificar que el resultado sea texto legible
          if (_esTextoLegible(resultado)) {
            developer.log(
                '🔐 Descifrado sin marcador (legible): ${resultado.length} chars');
            return resultado;
          } else {
            developer.log('⚠️ Descifrado sin marcador pero no legible');
            return texto; // Mantener original si no es legible
          }
        } catch (e) {
          developer.log('❌ Error descifrando base64 sin marcador: $e');
          return texto;
        }
      }

      // CASO 3: Texto no cifrado (ya está legible)
      developer.log('📝 Texto no cifrado, manteniendo original');
      return texto;
    } catch (e) {
      developer.log('❌ Error general en descifrarTexto: $e');
      return texto;
    }
  }

  // Verificar si es base64 válido (robusto)
  static bool _esBase64Valido(String texto) {
    try {
      if (texto.isEmpty) return false;

      // Limpiar espacios y saltos
      final limpio = texto.trim().replaceAll(RegExp(r'\s+'), '');

      // Patrón base64 más flexible
      final base64Pattern = RegExp(r'^[A-Za-z0-9+/=_-]+$');
      if (!base64Pattern.hasMatch(limpio)) return false;

      // Verificar longitud mínima para evitar falsos positivos
      if (limpio.length < 4) return false;

      // Intentar decodificar
      final decoded = base64Url.decode(limpio);
      return decoded.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Verificar si texto es legible (no binario)
  static bool _esTextoLegible(String texto) {
    if (texto.isEmpty) return false;

    // Contar caracteres imprimibles vs no imprimibles
    final imprimibles =
        RegExp(r'[\p{L}\p{M}\p{N}\p{P}\p{Z}\p{S}]', unicode: true);
    int countImprimibles = 0;

    for (int i = 0; i < min(texto.length, 100); i++) {
      if (imprimibles.hasMatch(texto[i])) {
        countImprimibles++;
      }
    }

    // Si al menos 70% son imprimibles, considerar legible
    final ratio = countImprimibles / min(texto.length, 100);
    return ratio > 0.7;
  }

  // CIFRAR LISTA DE MENSAJES

  static Future<List<Map<String, dynamic>>> cifrarMensajes(
      List<Map<String, dynamic>> mensajes) async {
    final mensajesCifrados = <Map<String, dynamic>>[];

    developer.log('🔐 INICIANDO CIFRADO de ${mensajes.length} mensajes');

    for (final mensaje in mensajes) {
      try {
        final mensajeCifrado = Map<String, dynamic>.from(mensaje);

        // CORRECCIÓN: Cifrar mensajes del usuario (no solo "Usuario")
        // Los mensajes del usuario real tienen emisor = _nombreUsuario
        final esUsuario = mensaje['emisor'] != "Sistema" &&
            mensaje['emisor'] != "Asistente" &&
            mensaje['emisor'] != "TYPING_INDICATOR";

        if (esUsuario && mensajeCifrado['contenido'] != null) {
          final contenidoOriginal = mensajeCifrado['contenido'].toString();
          if (contenidoOriginal.isNotEmpty &&
              contenidoOriginal != 'TYPING_INDICATOR' &&
              !contenidoOriginal.startsWith('ENC:')) {
            // No cifrar si ya está cifrado

            mensajeCifrado['contenido'] = await cifrarTexto(contenidoOriginal);
            mensajeCifrado['cifrado'] = true;

            developer.log('   🔐 Cifrado mensaje de: ${mensaje['emisor']}');
          }
        }

        mensajesCifrados.add(mensajeCifrado);
      } catch (e) {
        developer.log('❌ Error cifrando mensaje individual: $e');
        mensajesCifrados.add(mensaje); // Mantener original si falla
      }
    }

    developer.log('✅ CIFRADO COMPLETADO: ${mensajesCifrados.length} mensajes');
    return mensajesCifrados;
  }

  // DESCIFRAR LISTA DE MENSAJES
  static Future<List<Map<String, dynamic>>> descifrarMensajes(
      List<Map<String, dynamic>> mensajes) async {
    final mensajesDescifrados = <Map<String, dynamic>>[];

    developer.log('🔐 INICIANDO DESCIFRADO de ${mensajes.length} mensajes');

    for (final mensaje in mensajes) {
      try {
        final mensajeDescifrado = Map<String, dynamic>.from(mensaje);

        if (mensajeDescifrado['contenido'] != null) {
          final contenido = mensajeDescifrado['contenido'].toString();
          if (contenido.isNotEmpty && contenido != 'TYPING_INDICATOR') {
            mensajeDescifrado['contenido'] = await descifrarTexto(contenido);
          }
        }

        mensajesDescifrados.add(mensajeDescifrado);
      } catch (e) {
        developer.log('❌ Error descifrando mensaje individual: $e');
        mensajesDescifrados.add(mensaje); // Mantener original si falla
      }
    }

    developer
        .log('✅ DESCIFRADO COMPLETADO: ${mensajesDescifrados.length} mensajes');
    return mensajesDescifrados;
  }

  // Limpiar clave al cerrar sesión
  static Future<void> limpiarClave() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    developer.log('🔐 Clave de cifrado limpiada');
  }

  // Verificar si existe clave
  static Future<bool> tieneClave() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyName);
  }

  // Diagnóstico de estado
  static Future<void> diagnostico() async {
    final tiene = await tieneClave();
    developer.log('🔍 DIAGNÓSTICO CIFRADO:');
    developer.log('   ¿Tiene clave almacenada?: $tiene');
    if (tiene) {
      final clave = await _generarClaveCifrado();
      developer.log('   Longitud clave: ${clave.length} chars');
    }
  }
}
