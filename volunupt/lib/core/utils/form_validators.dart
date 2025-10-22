class FormValidators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'El correo electrónico es requerido';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return 'Ingresa un correo electrónico válido';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'La contraseña es requerida';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    /*if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'La contraseña debe contener al menos una mayúscula, una minúscula y un número';
    }*/

    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }

    if (value != password) {
      return 'Las contraseñas no coinciden';
    }

    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'El nombre es requerido';
    }

    if (value.trim().length < 2) {
      return 'El nombre debe tener al menos 2 caracteres';
    }

    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(value)) {
      return 'El nombre solo puede contener letras y espacios';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Ingresa un número de teléfono válido';
    }

    return null;
  }

  static String? validateStudentCode(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length < 6 || value.length > 12) {
      return 'El código debe tener entre 6 y 12 caracteres';
    }

    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value)) {
      return 'El código solo puede contener letras y números';
    }

    return null;
  }

  static String? validateCareer(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.trim().length < 3) {
      return 'La carrera debe tener al menos 3 caracteres';
    }

    return null;
  }

  static String? validateSemester(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final semester = int.tryParse(value);
    if (semester == null || semester < 1 || semester > 12) {
      return 'Ingresa un semestre válido (1-12)';
    }

    return null;
  }

  static String? validateEventTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El título del evento es requerido';
    }

    if (value.trim().length < 5) {
      return 'El título debe tener al menos 5 caracteres';
    }

    if (value.trim().length > 100) {
      return 'El título no puede exceder 100 caracteres';
    }

    return null;
  }

  static String? validateEventDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La descripción del evento es requerida';
    }

    if (value.trim().length < 20) {
      return 'La descripción debe tener al menos 20 caracteres';
    }

    if (value.trim().length > 1000) {
      return 'La descripción no puede exceder 1000 caracteres';
    }

    return null;
  }

  static String? validateEventCapacity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La capacidad del evento es requerida';
    }

    final capacity = int.tryParse(value);
    if (capacity == null || capacity < 1) {
      return 'La capacidad debe ser un número mayor a 0';
    }

    if (capacity > 1000) {
      return 'La capacidad no puede exceder 1000 personas';
    }

    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es requerido';
    }
    return null;
  }

  static String? validateMinLength(
    String? value,
    int minLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length < minLength) {
      return '$fieldName debe tener al menos $minLength caracteres';
    }

    return null;
  }

  static String? validateMaxLength(
    String? value,
    int maxLength,
    String fieldName,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (value.length > maxLength) {
      return '$fieldName no puede exceder $maxLength caracteres';
    }

    return null;
  }
}
