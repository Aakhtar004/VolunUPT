import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInUsecase {
  final AuthRepository _authRepository;

  SignInUsecase(this._authRepository);

  Future<UserEntity?> call(String email, String password) async {
    return await _authRepository.signInWithEmailAndPassword(email, password);
  }
}