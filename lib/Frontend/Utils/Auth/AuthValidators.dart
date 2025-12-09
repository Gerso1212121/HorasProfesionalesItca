// lib/Frontend/Utils/Auth/AuthValidators.dart
class AuthValidators {
  // Validación de email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu correo electrónico';
    }

    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
      caseSensitive: false,
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Por favor ingresa un correo válido';
    }

    return null;
  }

  // Validación de contraseña (para login)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu contraseña';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  // Validación de contraseña (para registro - más estricta)
  static String? validatePasswordForRegistration(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa una contraseña';
    }

    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }

    // Verificar que tenga al menos una letra mayúscula
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Debe contener al menos una letra mayúscula';
    }

    // Verificar que tenga al menos un número
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Debe contener al menos un número';
    }

    // Verificar que tenga al menos un carácter especial
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Debe contener al menos un carácter especial';
    }

    return null;
  }

  // Validación de confirmación de contraseña
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Por favor confirma tu contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  // Validación de nombre
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu nombre';
    }

    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    // Solo letras y espacios
    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'El nombre solo puede contener letras y espacios';
    }

    return null;
  }

  // Validación de teléfono
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu número de teléfono';
    }

    // Remover espacios, guiones, paréntesis
    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Debe contener solo números
    if (!RegExp(r'^[0-9]+$').hasMatch(cleanedPhone)) {
      return 'El teléfono debe contener solo números';
    }

    // Longitud mínima y máxima (ajustar según país)
    if (cleanedPhone.length < 8 || cleanedPhone.length > 15) {
      return 'El teléfono debe tener entre 8 y 15 dígitos';
    }

    return null;
  }

  // Validación de código de estudiante ITCA
  static String? validateStudentCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu código de estudiante';
    }

    // Formato: letras seguidas de números (ej: ITCA001234)
    final codeRegex = RegExp(r'^[A-Z]{2,}\d{4,}$', caseSensitive: true);

    if (!codeRegex.hasMatch(value)) {
      return 'Formato inválido. Ejemplo: ITCA001234';
    }

    return null;
  }

  // Validación de edad mínima (18 años)
  static String? validateAge(DateTime? birthDate) {
    if (birthDate == null) {
      return 'Por favor selecciona tu fecha de nacimiento';
    }

    final now = DateTime.now();
    final age = now.year - birthDate.year;

    // Ajustar si aún no ha pasado el cumpleaños este año
    final hasHadBirthday = (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);

    final actualAge = hasHadBirthday ? age : age - 1;

    if (actualAge < 18) {
      return 'Debes tener al menos 18 años';
    }

    if (actualAge > 100) {
      return 'Por favor verifica tu fecha de nacimiento';
    }

    return null;
  }

  static String? validateNombre(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa un nombre y un apellido';
    }
    if (value.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }
    if (!value.contains(' ')) {
      return 'Por favor ingresa nombre y apellido separados por espacio';
    }
    return null;
  }

  static String? validateTelefono(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor ingresa tu teléfono';
    }
    if (value.length < 8) {
      return 'El teléfono debe tener al menos 8 dígitos';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Solo se permiten números';
    }
    return null;
  }

  static String? validateCarnet(String? value, bool esItca) {
    if (esItca) {
      if (value == null || value.isEmpty) {
        return 'Por favor ingresa tu carnet';
      }
      if (value.length != 6) {
        return 'El carnet debe tener exactamente 6 dígitos';
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
        return 'Solo se permiten números';
      }
    }
    return null;
  }

  static String? validateRequired(
      String? value, bool esItca, String fieldName) {
    if (esItca && (value == null || value.isEmpty)) {
      return 'Por favor selecciona tu $fieldName';
    }
    return null;
  }
}
