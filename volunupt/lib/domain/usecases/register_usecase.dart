import 'package:volunupt/domain/entities/register_credentials.dart';
import 'package:volunupt/domain/entities/user.dart';
import 'package:volunupt/domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository authRepository;

  RegisterUseCase({required this.authRepository});

  Future<User> call(RegisterCredentials credentials) async {
    // Validaciones de negocio
    if (!credentials.isValid) {
      throw Exception('Invalid registration data');
    }

    if (!credentials.doPasswordsMatch) {
      throw Exception('Passwords do not match');
    }

    if (!credentials.isPasswordValid) {
      throw Exception('Password must be at least 6 characters long');
    }

    return await authRepository.register(credentials);
  }
}
