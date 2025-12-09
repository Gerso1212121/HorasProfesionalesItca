class SedeContactService {
  // Mapa de contactos de bienestar estudiantil por sede
  static const Map<String, Map<String, String>> _contactosPorSede = {
    'san miguel': {
      'nombre': 'Bienestar Estudiantil Regional San Miguel',
      'email': 'pcoreas@itca.edu.sv',
      'telefono': '7854-6266 / 2669-2298',
      'descripcion': 'Bienestar Estudiantil Regional San Miguel'
    },
    'la unión': {
      'nombre': 'Bienestar Estudiantil Regional La Unión',
      'email': 'brivas@itca.edu.sv',
      'telefono': '2668-4747',
      'descripcion': 'Bienestar Estudiantil Regional La Unión'
    },
    'zacatecoluca': {
      'nombre': 'Bienestar Estudiantil Regional Zacatecoluca',
      'email': 'falvarado@itca.edu.sv',
      'telefono': '2132-7445',
      'descripcion': 'Bienestar Estudiantil Regional Zacatecoluca'
    },
    'santa tecla': {
      'nombre': 'Bienestar Estudiantil Sede Central',
      'email': 'reramirez@itca.edu.sv',
      'telefono': '2132-7477',
      'descripcion': 'Bienestar Estudiantil Sede Central'
    },
    'sede central': {
      'nombre': 'Bienestar Estudiantil Sede Central',
      'email': 'reramirez@itca.edu.sv',
      'telefono': '2132-7477',
      'descripcion': 'Bienestar Estudiantil Sede Central'
    },
  };

  // Contacto adicional para sede central
  static const Map<String, String> _contactoAdicionalCentral = {
    'email': 'yancy.argueta@itca.edu.sv',
    'descripcion': 'Contacto adicional Sede Central'
  };

  /// Obtiene los contactos de bienestar estudiantil para una sede específica
  /// La sede se normaliza (convierte a minúsculas y maneja variaciones)
  static Map<String, String>? getContactosPorSede(String? sede) {
    if (sede == null || sede.isEmpty) {
      return null;
    }

    // Normalizar la sede
    String sedeNormalizada = _normalizarSede(sede);

    // Buscar en el mapa de contactos
    return _contactosPorSede[sedeNormalizada];
  }

  /// Normaliza el nombre de la sede para hacer coincidencias insensibles a mayúsculas
  /// y maneja variaciones comunes
  static String _normalizarSede(String sede) {
    String normalizada = sede.toLowerCase().trim();

    // Manejar variaciones comunes
    switch (normalizada) {
      case 'san miguel':
      case 'san miguel':
        return 'san miguel';
      case 'la unión':
      case 'la union':
      case 'la unión':
        return 'la unión';
      case 'zacatecoluca':
      case 'zacate coluca':
        return 'zacatecoluca';
      case 'santa tecla':
      case 'santa tecla':
        return 'santa tecla';
      case 'sede central':
        return 'sede central';
      default:
        return normalizada;
    }
  }

  /// Genera un mensaje de contacto personalizado para crisis
  static String generarMensajeCrisis(String? sede) {
    final contactos = getContactosPorSede(sede);

    if (contactos == null) {
      // Fallback a San Miguel si no se encuentra la sede
      final contactosDefault = _contactosPorSede['san miguel']!;
      return _generarMensajeCrisisTexto(contactosDefault);
    }

    return _generarMensajeCrisisTexto(contactos);
  }

  /// Genera el texto del mensaje de crisis
  static String _generarMensajeCrisisTexto(Map<String, String> contactos) {
    return "🚨 ALERTA: Tu vida es valiosa y mereces ayuda profesional INMEDIATA.\n\n"
        "📞 CONTACTA AHORA:\n"
        "🏥 ${contactos['descripcion']}\n"
        "📧 Email: ${contactos['email']}\n"
        "📱 Teléfono: ${contactos['telefono']}\n\n"
        "💙 No estás solo. Hay personas que pueden ayudarte. Por favor, contacta YA.";
  }

  /// Genera información de contacto para el prompt del sistema
  static String generarInfoContactoParaPrompt(String? sede) {
    final contactos = getContactosPorSede(sede);

    if (contactos == null) {
      // Fallback a San Miguel
      final contactosDefault = _contactosPorSede['san miguel']!;
      return _generarInfoContactoTexto(contactosDefault);
    }

    return _generarInfoContactoTexto(contactos);
  }

  /// Genera el texto de información de contacto para el prompt
  static String _generarInfoContactoTexto(Map<String, String> contactos) {
    String info = "📞 ${contactos['descripcion']}\n"
        "📧 Email: ${contactos['email']}\n"
        "📱 Teléfono: ${contactos['telefono']}";

    // Agregar contacto adicional para sede central
    if (contactos['descripcion']?.contains('Sede Central') == true) {
      info += "\n📧 Contacto adicional: ${_contactoAdicionalCentral['email']}";
    }

    return info;
  }

  /// Obtiene todas las sedes disponibles
  static List<String> getSedesDisponibles() {
    return _contactosPorSede.keys.toList();
  }

  /// Verifica si una sede tiene contactos configurados
  static bool tieneContactos(String? sede) {
    if (sede == null || sede.isEmpty) return false;
    String sedeNormalizada = _normalizarSede(sede);
    return _contactosPorSede.containsKey(sedeNormalizada);
  }
}
