import 'package:volunupt/domain/entities/auth_credentials.dart';
import 'package:volunupt/domain/entities/register_credentials.dart';
import 'package:volunupt/domain/entities/user.dart';

class AuthDatasourceLocal {
  // Datos hardcodeados de usuarios
  static const Map<String, Map<String, dynamic>> _users = {
    'ALUMNO1': {
      'id': '1',
      'password': 'ALUMNO1',
      'email': 'alumno1@upt.pe',
      'role': 'student',
      'token': 'token_alumno1',
    },
    'INGENIERO1': {
      'id': '2',
      'password': 'INGENIERO1',
      'email': 'ingeniero1@upt.pe',
      'role': 'engineer',
      'token': 'token_ingeniero1',
    },
  };

  Future<User> login(AuthCredentials credentials) async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 500));

    // CORREGIR AQUÍ: Verificar por email O por username
    final inputEmail = credentials.email.trim();
    final inputPassword = credentials.password;

    // Buscar usuario por email o por username (clave del mapa)
    Map<String, dynamic>? foundUserData;
    String? foundUsername;

    // Buscar por username (clave del mapa)
    for (String username in _users.keys) {
      final userData = _users[username]!;

      // Verificar si coincide por username o por email
      if (username.toUpperCase() == inputEmail.toUpperCase() ||
          userData['email'] == inputEmail) {
        foundUserData = userData;
        foundUsername = username;
        break;
      }
    }

    // Verificar si se encontró el usuario y la contraseña es correcta
    if (foundUserData != null && foundUserData['password'] == inputPassword) {
      return User(
        id: foundUserData['id'],
        email: foundUserData['email'],
        token: foundUserData['token'],
        role: foundUserData['role'],
      );
    }

    throw Exception('Credenciales incorrectas');
  }

  Future<User> register(RegisterCredentials credentials) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Simular registro exitoso
    return User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: credentials.email,
      token: 'temp_registration_token',
      role: 'student',
    );
  }
}
