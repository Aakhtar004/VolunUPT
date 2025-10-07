import '../repositories/auth_repository.dart';

class BiometricAuthUsecase {
  final AuthRepository _authRepository;

  BiometricAuthUsecase(this._authRepository);

  Future<bool> canUseBiometrics() async {
    return await _authRepository.canUseBiometrics();
  }

  Future<bool> authenticateWithBiometrics() async {
    return await _authRepository.authenticateWithBiometrics();
  }
}