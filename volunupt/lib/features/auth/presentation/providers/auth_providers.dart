import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/biometric_auth_usecase.dart';
import '../../data/repositories/firebase_auth_repository.dart';
import '../../data/services/session_manager_service.dart';
import '../../data/services/auth_persistence_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final localAuthProvider = Provider<LocalAuthentication>((ref) => LocalAuthentication());

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(
    ref.read(firebaseAuthProvider),
    ref.read(firestoreProvider),
    ref.read(localAuthProvider),
    ref.read(secureStorageProvider),
  );
});

final signInUsecaseProvider = Provider<SignInUsecase>((ref) {
  return SignInUsecase(ref.read(authRepositoryProvider));
});

final registerUsecaseProvider = Provider<RegisterUsecase>((ref) {
  return RegisterUsecase(ref.read(authRepositoryProvider));
});

final biometricAuthUsecaseProvider = Provider<BiometricAuthUsecase>((ref) {
  return BiometricAuthUsecase(ref.read(authRepositoryProvider));
});

final authStateProvider = StreamProvider<UserEntity?>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<UserEntity?>((ref) {
  return ref.read(authRepositoryProvider).getCurrentUser();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthRepository _authRepository;
  final SessionManagerService _sessionManager;

  AuthNotifier(this._authRepository, this._sessionManager) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() async {
    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        await _sessionManager.startSession();
      }
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  void updateActivity() {
    _sessionManager.updateActivity();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signInWithEmailAndPassword(email, password);
      if (user != null) {
        await _sessionManager.startSession();
      }
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.registerWithEmailAndPassword(name, email, password);
      if (user != null) {
        await _sessionManager.startSession();
      }
      state = AsyncValue.data(user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> signOut() async {
    try {
      await _sessionManager.endSession();
      await _authRepository.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      return await _authRepository.authenticateWithBiometrics();
    } catch (e) {
      return false;
    }
  }

  Future<bool> canUseBiometrics() async {
    try {
      return await _authRepository.canUseBiometrics();
    } catch (e) {
      return false;
    }
  }
}

final authPersistenceServiceProvider = Provider<AuthPersistenceService>((ref) {
  return AuthPersistenceService(
    ref.read(firebaseAuthProvider),
    ref.read(secureStorageProvider),
  );
});

final sessionManagerProvider = Provider<SessionManagerService>((ref) {
  return SessionManagerService(
    ref.read(secureStorageProvider),
    ref.read(firebaseAuthProvider),
  );
});

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
  return AuthNotifier(
    ref.read(authRepositoryProvider),
    ref.read(sessionManagerProvider),
  );
});