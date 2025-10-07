import '../entities/admin_stats_entity.dart';

abstract class AdminStatsRepository {
  Future<AdminStatsEntity> getAdminStats({
    DateTime? startDate,
    DateTime? endDate,
  });

  Stream<AdminStatsEntity> getAdminStatsStream({
    DateTime? startDate,
    DateTime? endDate,
  });
}