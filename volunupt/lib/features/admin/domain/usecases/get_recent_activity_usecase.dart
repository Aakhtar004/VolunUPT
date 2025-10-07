import '../entities/activity_log.dart';
import '../repositories/admin_repository.dart';

class GetRecentActivityUseCase {
  final AdminRepository _repository;

  GetRecentActivityUseCase(this._repository);

  Future<List<ActivityLog>> execute({int limit = 50}) async {
    try {
      return await _repository.getRecentActivity(limit);
    } catch (e) {
      throw Exception('Error al obtener actividad reciente: $e');
    }
  }

  Future<List<ActivityLog>> executeByType(ActivityType type, {int limit = 50}) async {
    try {
      return await _repository.getActivityByType(type.value, limit);
    } catch (e) {
      throw Exception('Error al obtener actividad por tipo: $e');
    }
  }

  Future<List<ActivityLog>> executeByUser(String userId, {int limit = 50}) async {
    try {
      return await _repository.getActivityByUser(userId, limit);
    } catch (e) {
      throw Exception('Error al obtener actividad del usuario: $e');
    }
  }

  Future<List<ActivityLog>> executeByDateRange(
    DateTime startDate,
    DateTime endDate, {
    int limit = 100,
  }) async {
    try {
      return await _repository.getActivityByDateRange(startDate, endDate, limit);
    } catch (e) {
      throw Exception('Error al obtener actividad por rango de fechas: $e');
    }
  }

  Future<List<ActivityLog>> executeBySeverity(
    ActivitySeverity severity, {
    int limit = 50,
  }) async {
    try {
      return await _repository.getActivityBySeverity(severity.value, limit);
    } catch (e) {
      throw Exception('Error al obtener actividad por severidad: $e');
    }
  }

  Future<Map<String, int>> getActivitySummary() async {
    try {
      return await _repository.getActivitySummary();
    } catch (e) {
      throw Exception('Error al obtener resumen de actividad: $e');
    }
  }

  Future<Map<String, int>> getActivityByHour() async {
    try {
      return await _repository.getActivityByHour();
    } catch (e) {
      throw Exception('Error al obtener actividad por hora: $e');
    }
  }

  Future<List<ActivityLog>> searchActivity(String query, {int limit = 50}) async {
    try {
      return await _repository.searchActivity(query, limit);
    } catch (e) {
      throw Exception('Error al buscar actividad: $e');
    }
  }

  Future<void> logActivity(ActivityLog activity) async {
    try {
      await _repository.logActivity(activity);
    } catch (e) {
      throw Exception('Error al registrar actividad: $e');
    }
  }

  Future<void> clearOldActivity(DateTime beforeDate) async {
    try {
      await _repository.clearActivityBefore(beforeDate);
    } catch (e) {
      throw Exception('Error al limpiar actividad antigua: $e');
    }
  }

  Future<List<ActivityLog>> getFilteredActivity({
    List<String>? types,
    List<String>? severities,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      return await _repository.getFilteredActivity(
        types: types,
        severities: severities,
        userId: userId,
        startDate: startDate,
        endDate: endDate,
        limit: limit,
      );
    } catch (e) {
      throw Exception('Error al obtener actividad filtrada: $e');
    }
  }

  Future<Map<String, dynamic>> getActivityAnalytics() async {
    try {
      return await _repository.getActivityAnalytics();
    } catch (e) {
      throw Exception('Error al obtener análisis de actividad: $e');
    }
  }
}