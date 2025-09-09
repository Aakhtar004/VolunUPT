import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:volunupt/domain/entities/user.dart';
import 'package:volunupt/domain/entities/auth_credentials.dart';
import 'package:volunupt/domain/entities/register_credentials.dart';
import 'package:volunupt/domain/repositories/auth_repository.dart';
import 'package:volunupt/infraestructure/datasources/auth_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDatasource datasource;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  AuthRepositoryImpl(this.datasource);

  @override
  Future<User> login(AuthCredentials credentials) async {
    debugPrint('Repository: Iniciando login');
    final user = await datasource.login(credentials);

    debugPrint('Repository: Guardando datos en storage');
    await storage.write(key: 'token', value: user.token);
    await storage.write(key: 'user_id', value: user.id);
    await storage.write(key: 'user_email', value: user.email);

    debugPrint('Repository: Login completado');
    return user;
  }

  @override
  Future<User> register(RegisterCredentials credentials) async {
    debugPrint('Repository: Iniciando registro');
    final user = await datasource.register(credentials);

    debugPrint('Repository: Guardando datos en storage');
    await storage.write(key: 'token', value: user.token);
    await storage.write(key: 'user_id', value: user.id);
    await storage.write(key: 'user_email', value: user.email);

    debugPrint('Repository: Registro completado');
    return user;
  }

  @override
  Future<void> logout() async {
    debugPrint('Repository: Eliminando datos del storage');
    await storage.delete(key: 'token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_email');
  }

  @override
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }
}
