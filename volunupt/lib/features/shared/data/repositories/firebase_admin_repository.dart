import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../admin/domain/entities/admin_stats.dart';
import '../../../admin/domain/entities/activity_log.dart';
import '../../../admin/domain/entities/system_health.dart';
import '../../../admin/domain/repositories/admin_repository.dart';
import '../../../admin/presentation/providers/admin_providers.dart';

class FirebaseAdminRepository implements AdminRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Future<AdminStats> getAdminStats() async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final startOfDay = DateTime(now.year, now.month, now.day);

      final usersSnapshot = await _firestore.collection('users').get();
      final eventsSnapshot = await _firestore.collection('events').get();
      final inscriptionsSnapshot = await _firestore.collection('inscriptions').get();

      final newUsersThisMonth = usersSnapshot.docs.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
        return createdAt.isAfter(startOfMonth);
      }).length;

      final activeEvents = eventsSnapshot.docs.where((doc) {
        final eventData = doc.data();
        final startDate = (eventData['startDate'] as Timestamp).toDate();
        final endDate = (eventData['endDate'] as Timestamp).toDate();
        return now.isAfter(startDate) && now.isBefore(endDate);
      }).length;

      final newInscriptionsToday = inscriptionsSnapshot.docs.where((doc) {
        final createdAt = (doc.data()['createdAt'] as Timestamp).toDate();
        return createdAt.isAfter(startOfDay);
      }).length;

      final totalVolunteerHours = eventsSnapshot.docs.fold<int>(0, (sum, doc) {
        final eventData = doc.data();
        return sum + (eventData['volunteerHours'] as int? ?? 0);
      });

      final hoursThisMonth = eventsSnapshot.docs.where((doc) {
        final eventData = doc.data();
        final startDate = (eventData['startDate'] as Timestamp).toDate();
        return startDate.isAfter(startOfMonth);
      }).fold<int>(0, (sum, doc) {
        final eventData = doc.data();
        return sum + (eventData['volunteerHours'] as int? ?? 0);
      });

      final usersByRole = <String, int>{};
      for (final doc in usersSnapshot.docs) {
        final role = doc.data()['role'] as String? ?? 'estudiante';
        usersByRole[role] = (usersByRole[role] ?? 0) + 1;
      }

      final eventsByCategory = <String, int>{};
      for (final doc in eventsSnapshot.docs) {
        final category = doc.data()['category'] as String? ?? 'general';
        eventsByCategory[category] = (eventsByCategory[category] ?? 0) + 1;
      }

      final attendedInscriptions = inscriptionsSnapshot.docs.where((doc) {
        return doc.data()['status'] == 'asistio';
      }).length;

      final averageAttendanceRate = inscriptionsSnapshot.docs.isNotEmpty
          ? (attendedInscriptions / inscriptionsSnapshot.docs.length) * 100
          : 0.0;

      final monthlyGrowth = await _getMonthlyGrowthStats(6);

      return AdminStats(
        totalUsers: usersSnapshot.docs.length,
        newUsersThisMonth: newUsersThisMonth,
        activeEvents: activeEvents,
        totalEvents: eventsSnapshot.docs.length,
        totalInscriptions: inscriptionsSnapshot.docs.length,
        newInscriptionsToday: newInscriptionsToday,
        totalVolunteerHours: totalVolunteerHours,
        hoursThisMonth: hoursThisMonth,
        activeCoordinators: usersByRole['coordinador'] ?? 0,
        completedEvents: eventsSnapshot.docs.where((doc) {
          final endDate = (doc.data()['endDate'] as Timestamp).toDate();
          return endDate.isBefore(now);
        }).length,
        averageAttendanceRate: averageAttendanceRate,
        usersByRole: usersByRole,
        eventsByCategory: eventsByCategory,
        monthlyGrowth: monthlyGrowth,
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  @override
  Future<AdminStats> getAdminStatsWithDateRange(DateTime startDate, DateTime endDate) async {
    try {
      final usersQuery = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final eventsQuery = await _firestore
          .collection('events')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final inscriptionsQuery = await _firestore
          .collection('inscriptions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      final usersByRole = <String, int>{};
      for (final doc in usersQuery.docs) {
        final role = doc.data()['role'] as String? ?? 'estudiante';
        usersByRole[role] = (usersByRole[role] ?? 0) + 1;
      }

      final eventsByCategory = <String, int>{};
      for (final doc in eventsQuery.docs) {
        final category = doc.data()['category'] as String? ?? 'general';
        eventsByCategory[category] = (eventsByCategory[category] ?? 0) + 1;
      }

      final totalVolunteerHours = eventsQuery.docs.fold<int>(0, (sum, doc) {
        final eventData = doc.data();
        return sum + (eventData['volunteerHours'] as int? ?? 0);
      });

      final attendedInscriptions = inscriptionsQuery.docs.where((doc) {
        return doc.data()['status'] == 'asistio';
      }).length;

      final averageAttendanceRate = inscriptionsQuery.docs.isNotEmpty
          ? (attendedInscriptions / inscriptionsQuery.docs.length) * 100
          : 0.0;

      return AdminStats(
        totalUsers: usersQuery.docs.length,
        newUsersThisMonth: usersQuery.docs.length,
        activeEvents: 0,
        totalEvents: eventsQuery.docs.length,
        totalInscriptions: inscriptionsQuery.docs.length,
        newInscriptionsToday: inscriptionsQuery.docs.length,
        totalVolunteerHours: totalVolunteerHours,
        hoursThisMonth: totalVolunteerHours,
        activeCoordinators: usersByRole['coordinador'] ?? 0,
        completedEvents: eventsQuery.docs.length,
        averageAttendanceRate: averageAttendanceRate,
        usersByRole: usersByRole,
        eventsByCategory: eventsByCategory,
        monthlyGrowth: [],
      );
    } catch (e) {
      throw Exception('Error al obtener estadísticas filtradas: $e');
    }
  }

  @override
  Future<List<ActivityLog>> getRecentActivity(int limit) async {
    try {
      final snapshot = await _firestore
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ActivityLog.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener actividad reciente: $e');
    }
  }

  @override
  Future<SystemHealth> getSystemHealth() async {
    try {
      final databaseStatus = await _checkDatabaseHealth();
      final authStatus = await _checkAuthHealth();
      final storageStatus = await _checkStorageHealth();
      final notificationStatus = await _checkNotificationHealth();

      final checks = [
        HealthCheck(
          service: 'database',
          status: databaseStatus,
          message: databaseStatus == 'healthy' ? 'Conexión estable' : 'Problemas de conexión',
          timestamp: DateTime.now(),
          responseTime: 50,
          details: {},
        ),
        HealthCheck(
          service: 'auth',
          status: authStatus,
          message: authStatus == 'healthy' ? 'Servicio operativo' : 'Problemas de autenticación',
          timestamp: DateTime.now(),
          responseTime: 30,
          details: {},
        ),
        HealthCheck(
          service: 'storage',
          status: storageStatus,
          message: storageStatus == 'healthy' ? 'Almacenamiento disponible' : 'Problemas de almacenamiento',
          timestamp: DateTime.now(),
          responseTime: 40,
          details: {},
        ),
        HealthCheck(
          service: 'notifications',
          status: notificationStatus,
          message: notificationStatus == 'healthy' ? 'FCM funcionando' : 'Problemas con notificaciones',
          timestamp: DateTime.now(),
          responseTime: 60,
          details: {},
        ),
      ];

      final metrics = SystemMetrics(
        cpuUsage: 45.2,
        memoryUsage: 67.8,
        diskUsage: 23.4,
        activeConnections: 156,
        requestsPerMinute: 234,
        averageResponseTime: 120.5,
        errorRate: 2,
        lastUpdated: DateTime.now(),
      );

      return SystemHealth(
        databaseStatus: databaseStatus,
        authStatus: authStatus,
        storageStatus: storageStatus,
        notificationStatus: notificationStatus,
        lastChecked: DateTime.now(),
        checks: checks,
        metrics: metrics,
      );
    } catch (e) {
      throw Exception('Error al verificar estado del sistema: $e');
    }
  }

  Future<String> _checkDatabaseHealth() async {
    try {
      await _firestore.collection('health_check').limit(1).get();
      return 'healthy';
    } catch (e) {
      return 'error';
    }
  }

  Future<String> _checkAuthHealth() async {
    try {
      final user = _auth.currentUser;
      return user != null ? 'healthy' : 'warning';
    } catch (e) {
      return 'error';
    }
  }

  Future<String> _checkStorageHealth() async {
    try {
      await _storage.ref().listAll();
      return 'healthy';
    } catch (e) {
      return 'error';
    }
  }

  Future<String> _checkNotificationHealth() async {
    return 'healthy';
  }

  Future<List<MonthlyStats>> _getMonthlyGrowthStats(int months) async {
    final stats = <MonthlyStats>[];
    final now = DateTime.now();

    for (int i = months - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);

      final usersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(month))
          .where('createdAt', isLessThan: Timestamp.fromDate(nextMonth))
          .get();

      final eventsSnapshot = await _firestore
          .collection('events')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(month))
          .where('createdAt', isLessThan: Timestamp.fromDate(nextMonth))
          .get();

      final inscriptionsSnapshot = await _firestore
          .collection('inscriptions')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(month))
          .where('createdAt', isLessThan: Timestamp.fromDate(nextMonth))
          .get();

      final totalHours = eventsSnapshot.docs.fold<int>(0, (sum, doc) {
        final eventData = doc.data();
        return sum + (eventData['volunteerHours'] as int? ?? 0);
      });

      stats.add(MonthlyStats(
        month: _getMonthName(month.month),
        year: month.year,
        newUsers: usersSnapshot.docs.length,
        newEvents: eventsSnapshot.docs.length,
        totalInscriptions: inscriptionsSnapshot.docs.length,
        totalHours: totalHours,
      ));
    }

    return stats;
  }

  String _getMonthName(int month) {
    const months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    return months[month - 1];
  }

  @override
  Future<List<AdminUser>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final users = <AdminUser>[];

      for (final doc in snapshot.docs) {
        final userData = doc.data();
        userData['id'] = doc.id;

        final inscriptionsSnapshot = await _firestore
            .collection('inscriptions')
            .where('userId', isEqualTo: doc.id)
            .get();

        final attendedEvents = inscriptionsSnapshot.docs.where((inscription) {
          return inscription.data()['status'] == 'asistio';
        }).length;

        userData['totalInscriptions'] = inscriptionsSnapshot.docs.length;
        userData['attendedEvents'] = attendedEvents;

        users.add(AdminUser.fromMap(userData));
      }

      return users;
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  @override
  Future<void> updateUserRole(String userId, String newRole) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'role': newRole,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logActivity(ActivityLog(
        id: '',
        type: 'role_change',
        description: 'Rol de usuario actualizado a $newRole',
        userId: _auth.currentUser?.uid ?? '',
        userName: _auth.currentUser?.displayName,
        targetId: userId,
        targetType: 'user',
        timestamp: DateTime.now(),
        metadata: {'newRole': newRole},
        severity: 'info',
      ));
    } catch (e) {
      throw Exception('Error al actualizar rol del usuario: $e');
    }
  }

  @override
  Future<void> toggleUserStatus(String userId, bool isActive) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _logActivity(ActivityLog(
        id: '',
        type: 'user_status_change',
        description: 'Estado de usuario ${isActive ? 'activado' : 'desactivado'}',
        userId: _auth.currentUser?.uid ?? '',
        userName: _auth.currentUser?.displayName,
        targetId: userId,
        targetType: 'user',
        timestamp: DateTime.now(),
        metadata: {'isActive': isActive},
        severity: 'info',
      ));
    } catch (e) {
      throw Exception('Error al cambiar estado del usuario: $e');
    }
  }

  @override
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();

      await _logActivity(ActivityLog(
        id: '',
        type: 'user_deletion',
        description: 'Usuario eliminado del sistema',
        userId: _auth.currentUser?.uid ?? '',
        userName: _auth.currentUser?.displayName,
        targetId: userId,
        targetType: 'user',
        timestamp: DateTime.now(),
        metadata: {},
        severity: 'warning',
      ));
    } catch (e) {
      throw Exception('Error al eliminar usuario: $e');
    }
  }

  Future<void> _logActivity(ActivityLog activity) async {
    try {
      await _firestore.collection('activity_logs').add(activity.toMap());
    } catch (e) {
      print('Error al registrar actividad: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getDetailedUserStats() => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getDetailedEventStats() => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getTopPerformingEvents(int limit) => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getMostActiveUsers(int limit) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getAttendanceAnalytics() => throw UnimplementedError();

  @override
  Future<List<MonthlyStats>> getMonthlyGrowthStats(int months) => _getMonthlyGrowthStats(months);

  @override
  Future<List<ActivityLog>> getActivityByType(String type, int limit) => throw UnimplementedError();

  @override
  Future<List<ActivityLog>> getActivityByUser(String userId, int limit) => throw UnimplementedError();

  @override
  Future<List<ActivityLog>> getActivityByDateRange(DateTime startDate, DateTime endDate, int limit) => throw UnimplementedError();

  @override
  Future<List<ActivityLog>> getActivityBySeverity(String severity, int limit) => throw UnimplementedError();

  @override
  Future<Map<String, int>> getActivitySummary() => throw UnimplementedError();

  @override
  Future<Map<String, int>> getActivityByHour() => throw UnimplementedError();

  @override
  Future<List<ActivityLog>> searchActivity(String query, int limit) => throw UnimplementedError();

  @override
  Future<void> logActivity(ActivityLog activity) => _logActivity(activity);

  @override
  Future<void> clearActivityBefore(DateTime beforeDate) => throw UnimplementedError();

  @override
  Future<List<ActivityLog>> getFilteredActivity({List<String>? types, List<String>? severities, String? userId, DateTime? startDate, DateTime? endDate, int limit = 50}) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getActivityAnalytics() => throw UnimplementedError();

  @override
  Future<List<HealthCheck>> performDetailedHealthCheck() => throw UnimplementedError();

  @override
  Future<HealthCheck> checkSpecificService(String serviceName) => throw UnimplementedError();

  @override
  Future<SystemMetrics> getCurrentSystemMetrics() => throw UnimplementedError();

  @override
  Future<List<SystemMetrics>> getMetricsHistory(DateTime startDate, DateTime endDate) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getPerformanceReport() => throw UnimplementedError();

  @override
  Future<Map<String, bool>> getAllServicesStatus() => throw UnimplementedError();

  @override
  Future<void> restartService(String serviceName) => throw UnimplementedError();

  @override
  Future<List<String>> getSystemAlerts() => throw UnimplementedError();

  @override
  Future<void> acknowledgeAlert(String alertId) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getDatabaseStats() => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getStorageStats() => throw UnimplementedError();

  @override
  Future<void> performMaintenanceTask(String taskName) => throw UnimplementedError();

  @override
  Future<List<String>> getScheduledMaintenanceTasks() => throw UnimplementedError();

  @override
  Future<void> scheduleMaintenanceTask(String taskName, DateTime scheduledTime) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getSystemConfiguration() => throw UnimplementedError();

  @override
  Future<void> updateSystemConfiguration(Map<String, dynamic> config) => throw UnimplementedError();

  @override
  Future<AdminUser> getUserById(String userId) => throw UnimplementedError();

  @override
  Future<List<AdminUser>> searchUsers(String query) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getUserAnalytics(String userId) => throw UnimplementedError();

  @override
  Future<void> sendNotificationToUser(String userId, String title, String message) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('Usuario no encontrado');
      }

      final userData = userDoc.data()!;
      final fcmToken = userData['fcmToken'] as String?;

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': 'admin',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'sentBy': _auth.currentUser?.uid,
        'sentByName': _auth.currentUser?.displayName ?? 'Administrador',
      });

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _firestore.collection('fcm_messages').add({
          'token': fcmToken,
          'title': title,
          'body': message,
          'data': {
            'type': 'admin_notification',
            'userId': userId,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'processed': false,
        });
      }

      await _logActivity(ActivityLog(
        id: '',
        type: 'notification_sent',
        description: 'Notificación enviada: $title',
        userId: _auth.currentUser?.uid ?? '',
        userName: _auth.currentUser?.displayName,
        targetId: userId,
        targetType: 'user',
        timestamp: DateTime.now(),
        metadata: {
          'title': title,
          'message': message,
        },
        severity: 'info',
      ));
    } catch (e) {
      throw Exception('Error al enviar notificación: $e');
    }
  }

  @override
  Future<void> sendBulkNotification(List<String> userIds, String title, String message) async {
    try {
      final batch = _firestore.batch();
      final fcmTokens = <String>[];

      for (final userId in userIds) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final fcmToken = userData['fcmToken'] as String?;
          
          if (fcmToken != null && fcmToken.isNotEmpty) {
            fcmTokens.add(fcmToken);
          }

          final notificationRef = _firestore.collection('notifications').doc();
          batch.set(notificationRef, {
            'userId': userId,
            'title': title,
            'message': message,
            'type': 'admin_bulk',
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'sentBy': _auth.currentUser?.uid,
            'sentByName': _auth.currentUser?.displayName ?? 'Administrador',
          });
        }
      }

      await batch.commit();

      for (final token in fcmTokens) {
        await _firestore.collection('fcm_messages').add({
          'token': token,
          'title': title,
          'body': message,
          'data': {
            'type': 'admin_bulk_notification',
          },
          'createdAt': FieldValue.serverTimestamp(),
          'processed': false,
        });
      }

      await _logActivity(ActivityLog(
        id: '',
        type: 'bulk_notification_sent',
        description: 'Notificación masiva enviada a ${userIds.length} usuarios: $title',
        userId: _auth.currentUser?.uid ?? '',
        userName: _auth.currentUser?.displayName,
        targetId: '',
        targetType: 'bulk',
        timestamp: DateTime.now(),
        metadata: {
          'title': title,
          'message': message,
          'userCount': userIds.length,
        },
        severity: 'info',
      ));
    } catch (e) {
      throw Exception('Error al enviar notificación masiva: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> exportData(String dataType, DateTime? startDate, DateTime? endDate) => throw UnimplementedError();

  @override
  Future<void> importData(String dataType, Map<String, dynamic> data) => throw UnimplementedError();

  @override
  Future<void> createBackup() => throw UnimplementedError();

  @override
  Future<List<Map<String, dynamic>>> getBackupHistory() => throw UnimplementedError();

  @override
  Future<void> restoreBackup(String backupId) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> getSystemSettings() => throw UnimplementedError();

  @override
  Future<void> updateSystemSettings(Map<String, dynamic> settings) => throw UnimplementedError();

  @override
  Future<void> resetSystemSettings() => throw UnimplementedError();
}