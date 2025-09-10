import 'package:volunupt/domain/repositories/auth_repository.dart';

class CheckAuthStatusUseCase {
  final AuthRepository authRepository;

  CheckAuthStatusUseCase({required this.authRepository});

  Future<String?> call() async {
    final token = await authRepository.getToken();
    if (token != null) {
      return await authRepository.getUserRole();
    }
    return null;
  }
}
