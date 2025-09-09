import 'package:volunupt/domain/entities/auth_credentials.dart';
import 'package:volunupt/domain/entities/register_credentials.dart';
import 'package:volunupt/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> login(AuthCredentials credentials);
  Future<User> register(RegisterCredentials credentials); // 🆕 Nuevo método
  Future<void> logout();
  Future<String?> getToken();
}
