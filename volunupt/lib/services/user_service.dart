import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/models.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Actualizar perfil del usuario
  static Future<void> updateUserProfile({
    required String userId,
    String? displayName,
    String? phone,
    String? address,
    String? emergencyContact,
    String? emergencyPhone,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (displayName != null && displayName.isNotEmpty) {
        updateData['displayName'] = displayName;
        // También actualizar en Firebase Auth si es necesario
        await _auth.currentUser?.updateDisplayName(displayName);
      }
      
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (emergencyContact != null) updateData['emergencyContact'] = emergencyContact;
      if (emergencyPhone != null) updateData['emergencyPhone'] = emergencyPhone;
      
      updateData['updatedAt'] = Timestamp.now();

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw Exception('No se pudo actualizar el perfil: $e');
    }
  }

  /// Obtener perfil completo del usuario
  static Future<UserModel?> getUserProfile(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        return UserModel.fromSnapshot(userDoc);
      }
      return null;
    } catch (e) {
      throw Exception('No se pudo obtener el perfil: $e');
    }
  }

  /// Actualizar rol del usuario (solo para administradores)
  static Future<void> updateUserRole(String userId, UserRole newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole.toString().split('.').last,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('No se pudo actualizar el rol: $e');
    }
  }

  /// Obtener usuarios por rol
  static Future<List<UserModel>> getUsersByRole(UserRole role) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role.toString().split('.').last)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios por rol: $e');
    }
  }

  /// Buscar usuarios por nombre o email
  static Future<List<UserModel>> searchUsers(String query) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('displayName', isGreaterThanOrEqualTo: query)
          .where('displayName', isLessThan: '${query}z')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al buscar usuarios: $e');
    }
  }

  /// Obtener estadísticas del usuario
  static Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Obtener registros de asistencia del usuario
      final attendanceQuery = await _firestore
          .collection('attendanceRecords')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'validated')
          .get();

      // Obtener eventos únicos en los que ha participado
      final uniqueEvents = <String>{};
      double totalHours = 0.0;

      for (final doc in attendanceQuery.docs) {
        final data = doc.data();
        uniqueEvents.add(data['baseEventId'] ?? '');
        totalHours += (data['hoursEarned'] ?? 0.0).toDouble();
      }

      // Obtener certificados
      final certificatesQuery = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'totalHours': totalHours,
        'eventsParticipated': uniqueEvents.length,
        'certificatesEarned': certificatesQuery.docs.length,
        'attendanceRecords': attendanceQuery.docs.length,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  /// Actualizar información académica del estudiante
  static Future<void> updateStudentInfo({
    required String userId,
    String? studentCode,
    String? career,
    String? semester,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (studentCode != null) updateData['studentCode'] = studentCode;
      if (career != null) updateData['career'] = career;
      if (semester != null) updateData['semester'] = semester;
      
      updateData['updatedAt'] = Timestamp.now();

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw Exception('No se pudo actualizar la información académica: $e');
    }
  }

  /// Obtener todos los usuarios (para administradores)
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('displayName')
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromSnapshot(doc))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener todos los usuarios: $e');
    }
  }

  /// Verificar si el usuario tiene permisos de administrador
  static Future<bool> isUserAdmin(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        return userData['role'] == 'administrador';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Verificar si el usuario tiene permisos de coordinador o superior
  static Future<bool> isUserCoordinatorOrAbove(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final role = userData['role'];
        return role == 'coordinador' || role == 'administrador';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<int> countUsers() async {
    final q = await _firestore.collection('users').get();
    return q.docs.length;
  }

  /// Stream para escuchar cambios en el perfil del usuario
  static Stream<Map<String, dynamic>?> getUserProfileStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    });
  }

  /// Actualizar foto de perfil
  static Future<void> updateProfilePhoto(String userId, String photoURL) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'photoURL': photoURL,
        'updatedAt': Timestamp.now(),
      });

      // También actualizar en Firebase Auth
      await _auth.currentUser?.updatePhotoURL(photoURL);
    } catch (e) {
      throw Exception('Error al actualizar foto de perfil: $e');
    }
  }

  /// Eliminar usuario (solo para administradores)
  static Future<void> deleteUser(String userId) async {
    try {
      // Eliminar registros relacionados
      final batch = _firestore.batch();

      // Eliminar registros de asistencia
      final attendanceQuery = await _firestore
          .collection('attendanceRecords')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in attendanceQuery.docs) {
        batch.delete(doc.reference);
      }

      // Eliminar registros de inscripción
      final registrationQuery = await _firestore
          .collection('registrations')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in registrationQuery.docs) {
        batch.delete(doc.reference);
      }

      // Eliminar certificados
      final certificatesQuery = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final doc in certificatesQuery.docs) {
        batch.delete(doc.reference);
      }

      // Eliminar QR del estudiante
      final qrDoc = _firestore.collection('studentQRs').doc(userId);
      batch.delete(qrDoc);

      // Finalmente eliminar el usuario
      final userDoc = _firestore.collection('users').doc(userId);
      batch.delete(userDoc);

      await batch.commit();
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  /// Obtener resumen de actividad reciente del usuario
  static Future<List<Map<String, dynamic>>> getRecentActivity(String userId, {int limit = 10}) async {
    try {
      final activities = <Map<String, dynamic>>[];

      // Obtener registros de asistencia recientes
      final attendanceQuery = await _firestore
          .collection('attendanceRecords')
          .where('userId', isEqualTo: userId)
          .orderBy('checkInTime', descending: true)
          .limit(limit)
          .get();

      for (final doc in attendanceQuery.docs) {
        final data = doc.data();
        activities.add({
          'type': 'attendance',
          'title': 'Asistencia registrada',
          'date': (data['checkInTime'] as Timestamp).toDate(),
          'details': 'Horas ganadas: ${data['hoursEarned']}',
        });
      }

      // Obtener certificados recientes
      final certificatesQuery = await _firestore
          .collection('certificates')
          .where('userId', isEqualTo: userId)
          .orderBy('dateIssued', descending: true)
          .limit(limit)
          .get();

      for (final doc in certificatesQuery.docs) {
        final data = doc.data();
        activities.add({
          'type': 'certificate',
          'title': 'Certificado obtenido',
          'date': (data['dateIssued'] as Timestamp).toDate(),
          'details': 'Evento ID: ${data['baseEventId'] ?? 'N/A'}',
        });
      }

      // Ordenar por fecha
      activities.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

      return activities.take(limit).toList();
    } catch (e) {
      throw Exception('Error al obtener actividad reciente: $e');
    }
  }
}