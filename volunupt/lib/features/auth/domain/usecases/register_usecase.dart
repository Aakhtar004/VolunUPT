import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUsecase {
  final AuthRepository _authRepository;

  RegisterUsecase(this._authRepository);

  Future<UserEntity> call(String name, String email, String password) async {
    return await _authRepository.registerWithEmailAndPassword(name, email, password);
  }
}