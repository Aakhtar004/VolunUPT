import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:volunupt/domain/entities/user.dart';
import 'package:volunupt/domain/entities/auth_credentials.dart';
import 'package:volunupt/domain/entities/register_credentials.dart';
import 'package:volunupt/domain/repositories/auth_repository.dart';
import 'package:volunupt/infraestructure/datasources/auth_datasource_local.dart';

class AuthRepositoryImplLocal implements AuthRepository {
  final AuthDatasourceLocal datasource;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  AuthRepositoryImplLocal(this.datasource);

  @override
  Future<User> login(AuthCredentials credentials) async {
    debugPrint('Repository Local: Iniciando login');
    final user = await datasource.login(credentials);

    debugPrint('Repository Local: Guardando datos en storage');
    await storage.write(key: 'token', value: user.token);
    await storage.write(key: 'user_id', value: user.id);
    await storage.write(key: 'user_email', value: user.email);
    await storage.write(key: 'user_role', value: user.role);

    debugPrint('Repository Local: Login completado');
    return user;
  }

  @override
  Future<User> register(RegisterCredentials credentials) async {
    debugPrint('Repository Local: Iniciando registro');
    final user = await datasource.register(credentials);

    debugPrint('Repository Local: Guardando datos en storage');
    await storage.write(key: 'token', value: user.token);
    await storage.write(key: 'user_id', value: user.id);
    await storage.write(key: 'user_email', value: user.email);
    await storage.write(key: 'user_role', value: user.role);

    debugPrint('Repository Local: Registro completado');
    return user;
  }

  @override
  Future<void> logout() async {
    debugPrint('Repository Local: Eliminando datos del storage');
    await storage.delete(key: 'token');
    await storage.delete(key: 'user_id');
    await storage.delete(key: 'user_email');
    await storage.delete(key: 'user_role');
  }

  @override
  Future<String?> getToken() async {
    return await storage.read(key: 'token');
  }

  // Método adicional para obtener el role del usuario
  Future<String?> getUserRole() async {
    return await storage.read(key: 'user_role');
  }
}
