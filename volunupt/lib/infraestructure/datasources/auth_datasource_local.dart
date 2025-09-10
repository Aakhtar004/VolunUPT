// Datos hardcodeados de usuarios
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:volunupt/domain/entities/auth_credentials.dart';
import 'package:volunupt/domain/entities/register_credentials.dart';
import 'package:volunupt/domain/entities/user.dart';

class AuthDatasourceLocal {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  static const String usersKey = 'users_list';

  Future<List<Map<String, dynamic>>> _getUsers() async {
    final usersJson = await storage.read(key: usersKey);
    if (usersJson == null || usersJson.isEmpty) return [];
    return usersJson.split('|').map((e) {
      final stringMap = Uri.splitQueryString(e);
      return Map<String, dynamic>.from(stringMap);
    }).toList();
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    final usersString = users
        .map((u) => Uri(queryParameters: u).query)
        .join('|');
    await storage.write(key: usersKey, value: usersString);
  }

  Future<User> login(AuthCredentials credentials) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final inputEmail = credentials.email.trim();
    final inputPassword = credentials.password;
    final users = await _getUsers();
    final userData = users.firstWhere(
      (u) => u['email'] == inputEmail && u['password'] == inputPassword,
      orElse: () => <String, dynamic>{},
    );
    if (userData.isNotEmpty) {
      return User(
        id: userData['id']!,
        email: userData['email']!,
        token: userData['token']!,
        role: userData['role']!,
        fullName: userData['fullName']!,
      );
    } else {
      throw Exception('Usuario o contraseña incorrectos');
    }
  }

  Future<User> register(RegisterCredentials credentials) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final users = await _getUsers();
    if (users.any((u) => u['email'] == credentials.email)) {
      throw Exception('El correo ya está registrado');
    }
    final newUser = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'email': credentials.email,
      'password': credentials.password,
      'token': 'token_${credentials.email}',
      'role': credentials.role,
      'fullName': credentials.fullName,
    };
    users.add(newUser);
    await _saveUsers(users);
    return User(
      id: newUser['id']!,
      email: newUser['email']!,
      token: newUser['token']!,
      role: newUser['role']!,
      fullName: newUser['fullName']!,
    );
    // ...nueva lógica ya implementada arriba...
  }
}
