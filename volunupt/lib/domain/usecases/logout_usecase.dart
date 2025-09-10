import 'package:volunupt/domain/repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository authRepository;

  LogoutUseCase({required this.authRepository});

  Future<void> call() async {
    return await authRepository.logout();
  }
}
