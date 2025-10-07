import '../entities/user_stats_entity.dart';

abstract class UserStatsRepository {
  Future<UserStatsEntity> getUserStats(String userId);
  Stream<UserStatsEntity> getUserStatsStream(String userId);
}