import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthPersistenceService {
  final FirebaseAuth _firebaseAuth;
  final FlutterSecureStorage _secureStorage;

  static const String _lastLoginKey = 'last_login_timestamp';
  static const String _tokenRefreshKey = 'token_refresh_timestamp';
  static const String _userIdKey = 'persisted_user_id';

  AuthPersistenceService(this._firebaseAuth, this._secureStorage);

  Future<void> configurePersistence() async {
    await _firebaseAuth.setPersistence(Persistence.LOCAL);
  }

  Future<void> saveAuthState(User user) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();

    await Future.wait([
      _secureStorage.write(key: _lastLoginKey, value: timestamp),
      _secureStorage.write(key: _userIdKey, value: user.uid),
    ]);
  }

  Future<void> updateTokenRefresh() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    await _secureStorage.write(key: _tokenRefreshKey, value: timestamp);
  }

  Future<bool> validatePersistedAuth() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return false;

      final storedUserId = await _secureStorage.read(key: _userIdKey);
      if (storedUserId != currentUser.uid) return false;

      final token = await currentUser.getIdToken(false);
      if (token?.isEmpty != false) return false;

      await updateTokenRefresh();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> refreshTokenIfNeeded() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return false;

      final lastRefreshStr = await _secureStorage.read(key: _tokenRefreshKey);
      if (lastRefreshStr != null) {
        final lastRefresh = DateTime.fromMillisecondsSinceEpoch(
          int.parse(lastRefreshStr),
        );
        final timeSinceRefresh = DateTime.now().difference(lastRefresh);

        if (timeSinceRefresh.inMinutes < 30) {
          return true;
        }
      }

      final token = await currentUser.getIdToken(true);
      if (token?.isNotEmpty == true) {
        await updateTokenRefresh();
        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<Duration?> getTimeSinceLastLogin() async {
    try {
      final lastLoginStr = await _secureStorage.read(key: _lastLoginKey);
      if (lastLoginStr == null) return null;

      final lastLogin = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastLoginStr),
      );
      return DateTime.now().difference(lastLogin);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearPersistedData() async {
    await Future.wait([
      _secureStorage.delete(key: _lastLoginKey),
      _secureStorage.delete(key: _tokenRefreshKey),
      _secureStorage.delete(key: _userIdKey),
    ]);
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<bool> isTokenValid() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser == null) return false;

      final token = await currentUser.getIdToken(false);
      return token?.isNotEmpty == true;
    } catch (e) {
      return false;
    }
  }
}
