import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_persistence_service.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final LocalAuthentication _localAuth;
  final FlutterSecureStorage _secureStorage;
  late final AuthPersistenceService _persistenceService;

  static const String _emailKey = 'biometric_email';
  static const String _passwordKey = 'biometric_password';

  FirebaseAuthRepository(
    this._firebaseAuth,
    this._firestore,
    this._localAuth,
    this._secureStorage,
  ) {
    _persistenceService = AuthPersistenceService(_firebaseAuth, _secureStorage);
    _configurePersistence();
  }

  Future<void> _configurePersistence() async {
    await _persistenceService.configurePersistence();
  }

  // Obtiene el documento de usuario de forma segura con timeout y caídas controladas
  Future<DocumentSnapshot<Map<String, dynamic>>?> _getUserDocSafe(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .get()
          .timeout(const Duration(seconds: 8));
      return doc;
    } on FirebaseException catch (fe) {
      if (fe.code == 'unavailable' || fe.code == 'permission-denied') {
        return null;
      }
      rethrow;
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  // Crea/actualiza el documento de usuario de forma segura (best‑effort) con timeout
  Future<void> _setUserDocSafe(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set(data)
          .timeout(const Duration(seconds: 8));
    } on FirebaseException catch (fe) {
      if (fe.code == 'unavailable' || fe.code == 'permission-denied') {
        return;
      }
      rethrow;
    } on TimeoutException {
      return;
    }
  }

  @override
  Future<UserEntity?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        final uid = credential.user!.uid;
        final userDoc = await _getUserDocSafe(uid);

        UserEntity userEntity;
        if (userDoc != null && userDoc.exists) {
          final data = userDoc.data()!;
          userEntity = UserEntity(
            id: uid,
            name: data['name'] ?? '',
            email: data['email'] ?? '',
            role: data['role'] ?? 'Estudiante',
          );
        } else {
          final userData = {
            'name': credential.user!.displayName ?? 'Usuario',
            'email': credential.user!.email ?? email,
            'role': 'Estudiante',
            'createdAt': FieldValue.serverTimestamp(),
          };
          await _setUserDocSafe(uid, userData);

          userEntity = UserEntity(
            id: uid,
            name: userData['name'] as String,
            email: userData['email'] as String,
            role: userData['role'] as String,
          );
        }

        await _saveCredentialsForBiometrics(email, password);
        await _persistenceService.saveAuthState(credential.user!);
        return userEntity;
      }
      throw Exception('No se pudo autenticar al usuario');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('No existe una cuenta con este correo electrónico');
        case 'wrong-password':
          throw Exception('Contraseña incorrecta');
        case 'invalid-email':
          throw Exception('El formato del correo electrónico no es válido');
        case 'user-disabled':
          throw Exception('Esta cuenta ha sido deshabilitada');
        case 'too-many-requests':
          throw Exception('Demasiados intentos fallidos. Intenta más tarde');
        default:
          throw Exception('Error de autenticación: ${e.message}');
      }
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }

  @override
  Future<UserEntity> registerWithEmailAndPassword(
    String name,
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Error al crear usuario');
      }

      final userEntity = UserEntity(
        id: credential.user!.uid,
        name: name,
        email: email,
        role: 'Estudiante',
      );

      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(credential.user!.uid);

      batch.set(userRef, {
        'name': name,
        'email': email,
        'role': 'Estudiante',
        'createdAt': FieldValue.serverTimestamp(),
      });

      try {
        await batch.commit().timeout(const Duration(seconds: 8));
      } on FirebaseException catch (fe) {
        if (fe.code == 'permission-denied') {
          throw Exception('No tienes permisos para registrar datos en Firestore');
        }
        // Si Firestore está offline u otro error de disponibilidad, continuar.
      } on TimeoutException {
        // Continuar y no bloquear el registro por lentitud de red.
      }

      await _persistenceService.saveAuthState(credential.user!);
      
      return userEntity;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'La contraseña es muy débil';
          break;
        case 'email-already-in-use':
          errorMessage = 'Este email ya está registrado';
          break;
        case 'invalid-email':
          errorMessage = 'El email no es válido';
          break;
        default:
          errorMessage = 'Error al registrarse: ${e.message}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Error al registrarse: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _clearStoredCredentials();
    await _persistenceService.clearPersistedData();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      final isValidPersistence = await _persistenceService.validatePersistedAuth();
      if (!isValidPersistence) {
        return null;
      }

      await _persistenceService.refreshTokenIfNeeded();

      final userDoc = await _getUserDocSafe(user.uid);
      if (userDoc != null && userDoc.exists) {
        final data = userDoc.data()!;
        return UserEntity(
          id: user.uid,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? 'Estudiante',
        );
      }
      return UserEntity(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
        role: 'Estudiante',
      );
    }
    return null;
  }

  @override
  Future<bool> canUseBiometrics() async {
    final isAvailable = await _localAuth.canCheckBiometrics;
    final isDeviceSupported = await _localAuth.isDeviceSupported();
    return isAvailable && isDeviceSupported;
  }

  @override
  Future<bool> authenticateWithBiometrics() async {
    try {
      final isAuthenticated = await _localAuth.authenticate(
        localizedReason: 'Autentícate para acceder a la aplicación',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        final credentials = await _getStoredCredentials();
        if (credentials != null) {
          final result = await signInWithEmailAndPassword(
            credentials['email']!,
            credentials['password']!,
          );
          return result != null;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveCredentialsForBiometrics(String email, String password) async {
    try {
      await _secureStorage.write(key: _emailKey, value: email);
      await _secureStorage.write(key: _passwordKey, value: password);
    } catch (e) {
      // Si no se pueden guardar las credenciales, no es crítico
    }
  }

  Future<Map<String, String>?> _getStoredCredentials() async {
    try {
      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);
      
      if (email != null && password != null) {
        return {'email': email, 'password': password};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> _clearStoredCredentials() async {
    try {
      await _secureStorage.delete(key: _emailKey);
      await _secureStorage.delete(key: _passwordKey);
    } catch (e) {
      // Si no se pueden limpiar las credenciales, no es crítico
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((user) async {
      if (user != null) {
        final userDoc = await _getUserDocSafe(user.uid);
        if (userDoc != null && userDoc.exists) {
          final data = userDoc.data()!;
          return UserEntity(
            id: user.uid,
            name: data['name'] ?? '',
            email: data['email'] ?? '',
            role: data['role'] ?? 'Estudiante',
          );
        }
        return UserEntity(
          id: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
          role: 'Estudiante',
        );
      }
      return null;
    });
  }
}
