import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity> registerWithEmailAndPassword(String name, String email, String password);
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Future<bool> canUseBiometrics();
  Future<bool> authenticateWithBiometrics();
  Stream<UserEntity?> get authStateChanges;
}