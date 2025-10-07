import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import '../../domain/entities/user_profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';

class FirebaseProfileRepository implements ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  FirebaseProfileRepository(this._firestore, this._storage);

  @override
  Future<UserProfileEntity?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return UserProfileEntity(
        id: doc.id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? 'estudiante',
        photoUrl: data['photoUrl'],
        phone: data['phone'],
        studentCode: data['studentCode'],
        career: data['career'],
        semester: data['semester'] ?? 1,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        biometricEnabled: data['biometricEnabled'] ?? false,
        notificationsEnabled: data['notificationsEnabled'] ?? true,
      );
    } catch (e) {
      throw Exception('Error al obtener perfil de usuario: $e');
    }
  }

  @override
  Future<void> updateUserProfile(UserProfileEntity profile) async {
    try {
      await _firestore.collection('users').doc(profile.id).update({
        'name': profile.name,
        'phone': profile.phone,
        'studentCode': profile.studentCode,
        'career': profile.career,
        'semester': profile.semester,
        'updatedAt': FieldValue.serverTimestamp(),
        'biometricEnabled': profile.biometricEnabled,
        'notificationsEnabled': profile.notificationsEnabled,
      });
    } catch (e) {
      throw Exception('Error al actualizar perfil: $e');
    }
  }

  @override
  Future<void> updateProfilePhoto(String userId, String photoPath) async {
    try {
      final file = File(photoPath);
      final ref = _storage.ref().child('profile_photos').child('$userId.jpg');
      
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar foto de perfil: $e');
    }
  }

  @override
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      final ref = _storage.ref().child('profile_photos').child('$userId.jpg');
      await ref.delete();
      
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al eliminar foto de perfil: $e');
    }
  }

  @override
  Future<void> updateBiometricSettings(String userId, bool enabled) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'biometricEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar configuración biométrica: $e');
    }
  }

  @override
  Future<void> updateNotificationSettings(String userId, bool enabled) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'notificationsEnabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al actualizar configuración de notificaciones: $e');
    }
  }

  @override
  Stream<UserProfileEntity?> watchUserProfile(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      return UserProfileEntity(
        id: doc.id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? 'estudiante',
        photoUrl: data['photoUrl'],
        phone: data['phone'],
        studentCode: data['studentCode'],
        career: data['career'],
        semester: data['semester'] ?? 1,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        biometricEnabled: data['biometricEnabled'] ?? false,
        notificationsEnabled: data['notificationsEnabled'] ?? true,
      );
    });
  }
}