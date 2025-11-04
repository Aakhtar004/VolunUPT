import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/models.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Dominios permitidos
  static const List<String> _allowedDomains = ['@virtual.upt.pe'];

  // Stream del estado de autenticación
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Usuario actual
  static User? get currentUser => _auth.currentUser;

  // Verificar si hay un usuario autenticado
  static bool get isAuthenticated => currentUser != null;

  /// Iniciar sesión con Google
  static Future<UserModel?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Flujo específico para Web: usar popup (o redirect como fallback)
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        provider.addScope('email');

        UserCredential userCredential;
        try {
          userCredential = await _auth.signInWithPopup(provider);
        } catch (_) {
          // Fallback si el navegador bloquea popups
          await _auth.signInWithRedirect(provider);
          userCredential = await _auth.getRedirectResult();
        }

        final User? user = userCredential.user;
        if (user == null) return null;

        // Validar dominio
        final email = user.email ?? '';
        final isAllowed = _allowedDomains.any((d) => email.endsWith(d));
        if (!isAllowed) {
          await _auth.signOut();
          throw Exception(
            'Solo se permiten cuentas institucionales: @virtual.upt.pe',
          );
        }

        // Crear/actualizar en Firestore
        return await _createOrUpdateUser(user);
      } else {
        // Flujo para móviles/escritorio
        await _googleSignIn.signOut(); // Forzar selector de cuenta
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          return null; // Cancelado
        }

        final isAllowedMobile = _allowedDomains.any(
          (d) => googleUser.email.endsWith(d),
        );
        if (!isAllowedMobile) {
          await _googleSignIn.signOut();
          throw Exception(
            'Solo se permiten cuentas institucionales: @virtual.upt.pe',
          );
        }

        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;
        if (user == null) return null;
        return await _createOrUpdateUser(user);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Crear o actualizar usuario en Firestore
  static Future<UserModel> _createOrUpdateUser(User user) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      UserModel userModel;

      if (userDoc.exists) {
        // Usuario existente - actualizar información
        userModel = UserModel.fromSnapshot(userDoc);

        // Actualizar campos que pueden haber cambiado
        final updatedData = {
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'lastLogin': Timestamp.now(),
        };

        await _firestore.collection('users').doc(user.uid).update(updatedData);

        // Crear modelo actualizado
        userModel = UserModel(
          uid: userModel.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoURL: user.photoURL ?? '',
          role: userModel.role,
          totalHours: userModel.totalHours,
        );
      } else {
        // Nuevo usuario - crear registro
        userModel = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoURL: user.photoURL ?? '',
          role: UserRole.estudiante, // Por defecto es estudiante
          totalHours: 0.0,
        );

        final userData = userModel.toMap();
        userData['createdAt'] = Timestamp.now();
        userData['lastLogin'] = Timestamp.now();

        await _firestore.collection('users').doc(user.uid).set(userData);
      }

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtener datos del usuario actual desde Firestore
  static Future<UserModel?> getCurrentUserData() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return UserModel.fromSnapshot(userDoc);
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Cerrar sesión
  static Future<void> signOut() async {
    try {
      await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      rethrow;
    }
  }

  /// Verificar si la sesión sigue siendo válida
  static Future<bool> isSessionValid() async {
    try {
      final user = currentUser;
      if (user == null) return false;

      // Recargar el usuario para verificar que el token sigue siendo válido
      await user.reload();
      return _auth.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  /// Actualizar el último acceso del usuario
  static Future<void> updateLastAccess() async {
    try {
      final user = currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastAccess': Timestamp.now(),
        });
      }
    } catch (e) {
      return;
    }
  }

  /// Stream para escuchar cambios en los datos del usuario
  static Stream<UserModel?> getUserDataStream() {
    final user = currentUser;
    if (user == null) {
      return Stream.value(null);
    }

    return _firestore.collection('users').doc(user.uid).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists) {
        return UserModel.fromSnapshot(snapshot);
      }
      return null;
    });
  }
}
