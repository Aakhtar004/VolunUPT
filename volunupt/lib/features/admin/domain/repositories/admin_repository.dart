import '../entities/admin_stats.dart';
import '../entities/activity_log.dart';
import '../entities/system_health.dart';
import '../../presentation/providers/admin_providers.dart';

abstract class AdminRepository {
  Future<AdminStats> getAdminStats();
  Future<AdminStats> getAdminStatsWithDateRange(DateTime startDate, DateTime endDate);
  Future<Map<String, dynamic>> getDetailedUserStats();
  Future<Map<String, dynamic>> getDetailedEventStats();
  Future<List<Map<String, dynamic>>> getTopPerformingEvents(int limit);
  Future<List<Map<String, dynamic>>> getMostActiveUsers(int limit);
  Future<Map<String, dynamic>> getAttendanceAnalytics();
  Future<List<MonthlyStats>> getMonthlyGrowthStats(int months);

  Future<List<ActivityLog>> getRecentActivity(int limit);
  Future<List<ActivityLog>> getActivityByType(String type, int limit);
  Future<List<ActivityLog>> getActivityByUser(String userId, int limit);
  Future<List<ActivityLog>> getActivityByDateRange(DateTime startDate, DateTime endDate, int limit);
  Future<List<ActivityLog>> getActivityBySeverity(String severity, int limit);
  Future<Map<String, int>> getActivitySummary();
  Future<Map<String, int>> getActivityByHour();
  Future<List<ActivityLog>> searchActivity(String query, int limit);
  Future<void> logActivity(ActivityLog activity);
  Future<void> clearActivityBefore(DateTime beforeDate);
  Future<List<ActivityLog>> getFilteredActivity({
    List<String>? types,
    List<String>? severities,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  });
  Future<Map<String, dynamic>> getActivityAnalytics();

  Future<SystemHealth> getSystemHealth();
  Future<List<HealthCheck>> performDetailedHealthCheck();
  Future<HealthCheck> checkSpecificService(String serviceName);
  Future<SystemMetrics> getCurrentSystemMetrics();
  Future<List<SystemMetrics>> getMetricsHistory(DateTime startDate, DateTime endDate);
  Future<Map<String, dynamic>> getPerformanceReport();
  Future<Map<String, bool>> getAllServicesStatus();
  Future<void> restartService(String serviceName);
  Future<List<String>> getSystemAlerts();
  Future<void> acknowledgeAlert(String alertId);
  Future<Map<String, dynamic>> getDatabaseStats();
  Future<Map<String, dynamic>> getStorageStats();
  Future<void> performMaintenanceTask(String taskName);
  Future<List<String>> getScheduledMaintenanceTasks();
  Future<void> scheduleMaintenanceTask(String taskName, DateTime scheduledTime);
  Future<Map<String, dynamic>> getSystemConfiguration();
  Future<void> updateSystemConfiguration(Map<String, dynamic> config);

  Future<List<AdminUser>> getAllUsers();
  Future<AdminUser> getUserById(String userId);
  Future<void> updateUserRole(String userId, String newRole);
  Future<void> toggleUserStatus(String userId, bool isActive);
  Future<void> deleteUser(String userId);
  Future<List<AdminUser>> searchUsers(String query);
  Future<Map<String, dynamic>> getUserAnalytics(String userId);
  Future<void> sendNotificationToUser(String userId, String title, String message);
  Future<void> sendBulkNotification(List<String> userIds, String title, String message);

  Future<Map<String, dynamic>> exportData(String dataType, DateTime? startDate, DateTime? endDate);
  Future<void> importData(String dataType, Map<String, dynamic> data);
  Future<void> createBackup();
  Future<List<Map<String, dynamic>>> getBackupHistory();
  Future<void> restoreBackup(String backupId);

  Future<Map<String, dynamic>> getSystemSettings();
  Future<void> updateSystemSettings(Map<String, dynamic> settings);
  Future<void> resetSystemSettings();
}