import 'package:volunupt/domain/entities/auth_credentials.dart';
import 'package:volunupt/domain/entities/user.dart';
import 'package:volunupt/domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository authRepository;

  LoginUseCase({required this.authRepository});

  Future<User> call(AuthCredentials credentials) async {
    return await authRepository.login(credentials);
  }
}
