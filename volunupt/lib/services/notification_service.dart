import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'notifications';

  // Obtener todas las notificaciones del usuario
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromSnapshot(doc))
            .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  // Obtener notificaciones no leídas
  static Stream<List<NotificationModel>> getUnreadNotifications(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromSnapshot(doc))
            .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)));
  }

  // Contar notificaciones no leídas
  static Stream<int> getUnreadNotificationCount(String userId) {
    return getUnreadNotifications(userId)
        .map((notifications) => notifications.length);
  }

  // Marcar notificación como leída
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      throw Exception('Error al marcar notificación como leída: $e');
    }
  }

  // Marcar todas las notificaciones como leídas
  static Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error al marcar todas las notificaciones como leídas: $e');
    }
  }

  // Eliminar notificación
  static Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(notificationId)
          .delete();
    } catch (e) {
      throw Exception('Error al eliminar notificación: $e');
    }
  }

  // Crear nueva notificación
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedEventId,
    String? relatedSubEventId,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final notification = NotificationModel(
        notificationId: '', // Se asignará automáticamente
        userId: userId,
        title: title,
        message: message,
        type: type,
        timestamp: DateTime.now(),
        relatedEventId: relatedEventId,
        relatedSubEventId: relatedSubEventId,
        actionUrl: actionUrl,
        metadata: metadata,
      );

      await _firestore
          .collection(_collection)
          .add(notification.toMap());
    } catch (e) {
      throw Exception('Error al crear notificación: $e');
    }
  }

  // Crear notificación para múltiples usuarios
  static Future<void> createBulkNotifications({
    required List<String> userIds,
    required String title,
    required String message,
    required NotificationType type,
    String? relatedEventId,
    String? relatedSubEventId,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final batch = _firestore.batch();
      final timestamp = DateTime.now();

      for (final userId in userIds) {
        final notification = NotificationModel(
          notificationId: '', // Se asignará automáticamente
          userId: userId,
          title: title,
          message: message,
          type: type,
          timestamp: timestamp,
          relatedEventId: relatedEventId,
          relatedSubEventId: relatedSubEventId,
          actionUrl: actionUrl,
          metadata: metadata,
        );

        final docRef = _firestore.collection(_collection).doc();
        batch.set(docRef, notification.toMap());
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error al crear notificaciones masivas: $e');
    }
  }

  // Limpiar notificaciones antiguas (más de 30 días)
  static Future<void> cleanOldNotifications(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // Primero obtenemos todas las notificaciones del usuario
      final userNotifications = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      int deletedCount = 0;
      
      // Filtramos en el cliente para evitar índices compuestos
      for (final doc in userNotifications.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        
        if (timestamp.isBefore(thirtyDaysAgo)) {
          batch.delete(doc.reference);
          deletedCount++;
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
      }
    } catch (e) {
      // Error silencioso para no interrumpir la experiencia del usuario
      debugPrint('Advertencia: No se pudieron limpiar las notificaciones antiguas: $e');
    }
  }
}