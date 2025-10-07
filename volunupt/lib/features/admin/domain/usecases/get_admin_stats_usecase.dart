import '../entities/admin_stats.dart';
import '../repositories/admin_repository.dart';

class GetAdminStatsUseCase {
  final AdminRepository _repository;

  GetAdminStatsUseCase(this._repository);

  Future<AdminStats> execute() async {
    try {
      return await _repository.getAdminStats();
    } catch (e) {
      throw Exception('Error al obtener estadísticas de administración: $e');
    }
  }

  Future<AdminStats> executeWithDateRange(DateTime startDate, DateTime endDate) async {
    try {
      return await _repository.getAdminStatsWithDateRange(startDate, endDate);
    } catch (e) {
      throw Exception('Error al obtener estadísticas filtradas: $e');
    }
  }

  Future<AdminStats> executeForPeriod(StatsPeriod period) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      
      switch (period) {
        case StatsPeriod.today:
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case StatsPeriod.thisWeek:
          startDate = now.subtract(Duration(days: now.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          break;
        case StatsPeriod.thisMonth:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case StatsPeriod.thisYear:
          startDate = DateTime(now.year, 1, 1);
          break;
        case StatsPeriod.lastMonth:
          final lastMonth = DateTime(now.year, now.month - 1, 1);
          startDate = lastMonth;
          break;
        case StatsPeriod.lastYear:
          startDate = DateTime(now.year - 1, 1, 1);
          break;
      }
      
      return await _repository.getAdminStatsWithDateRange(startDate, now);
    } catch (e) {
      throw Exception('Error al obtener estadísticas del período: $e');
    }
  }

  Future<Map<String, dynamic>> getDetailedUserStats() async {
    try {
      return await _repository.getDetailedUserStats();
    } catch (e) {
      throw Exception('Error al obtener estadísticas detalladas de usuarios: $e');
    }
  }

  Future<Map<String, dynamic>> getDetailedEventStats() async {
    try {
      return await _repository.getDetailedEventStats();
    } catch (e) {
      throw Exception('Error al obtener estadísticas detalladas de eventos: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTopPerformingEvents(int limit) async {
    try {
      return await _repository.getTopPerformingEvents(limit);
    } catch (e) {
      throw Exception('Error al obtener eventos con mejor rendimiento: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getMostActiveUsers(int limit) async {
    try {
      return await _repository.getMostActiveUsers(limit);
    } catch (e) {
      throw Exception('Error al obtener usuarios más activos: $e');
    }
  }

  Future<Map<String, dynamic>> getAttendanceAnalytics() async {
    try {
      return await _repository.getAttendanceAnalytics();
    } catch (e) {
      throw Exception('Error al obtener análisis de asistencia: $e');
    }
  }

  Future<List<MonthlyStats>> getMonthlyGrowthStats(int months) async {
    try {
      return await _repository.getMonthlyGrowthStats(months);
    } catch (e) {
      throw Exception('Error al obtener estadísticas de crecimiento mensual: $e');
    }
  }
}

enum StatsPeriod {
  today,
  thisWeek,
  thisMonth,
  thisYear,
  lastMonth,
  lastYear,
}