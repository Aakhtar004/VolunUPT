class AdminStatsEntity {
  final int totalEvents;
  final int totalUsers;
  final int totalInscriptions;
  final int activeEvents;
  final int completedEvents;
  final int newUsersThisMonth;
  final int activeUsers;
  final double retentionRate;
  final List<PopularEventEntity> popularEvents;
  final List<CategoryStatsEntity> categoryStats;

  const AdminStatsEntity({
    required this.totalEvents,
    required this.totalUsers,
    required this.totalInscriptions,
    required this.activeEvents,
    required this.completedEvents,
    required this.newUsersThisMonth,
    required this.activeUsers,
    required this.retentionRate,
    required this.popularEvents,
    required this.categoryStats,
  });

  factory AdminStatsEntity.fromMap(Map<String, dynamic> map) {
    return AdminStatsEntity(
      totalEvents: map['totalEvents'] ?? 0,
      totalUsers: map['totalUsers'] ?? 0,
      totalInscriptions: map['totalInscriptions'] ?? 0,
      activeEvents: map['activeEvents'] ?? 0,
      completedEvents: map['completedEvents'] ?? 0,
      newUsersThisMonth: map['newUsersThisMonth'] ?? 0,
      activeUsers: map['activeUsers'] ?? 0,
      retentionRate: (map['retentionRate'] ?? 0.0).toDouble(),
      popularEvents: (map['popularEvents'] as List<dynamic>?)
              ?.map((e) => PopularEventEntity.fromMap(e))
              .toList() ??
          [],
      categoryStats: (map['categoryStats'] as List<dynamic>?)
              ?.map((e) => CategoryStatsEntity.fromMap(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalEvents': totalEvents,
      'totalUsers': totalUsers,
      'totalInscriptions': totalInscriptions,
      'activeEvents': activeEvents,
      'completedEvents': completedEvents,
      'newUsersThisMonth': newUsersThisMonth,
      'activeUsers': activeUsers,
      'retentionRate': retentionRate,
      'popularEvents': popularEvents.map((e) => e.toMap()).toList(),
      'categoryStats': categoryStats.map((e) => e.toMap()).toList(),
    };
  }
}

class PopularEventEntity {
  final String id;
  final String name;
  final int participantCount;

  const PopularEventEntity({
    required this.id,
    required this.name,
    required this.participantCount,
  });

  factory PopularEventEntity.fromMap(Map<String, dynamic> map) {
    return PopularEventEntity(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      participantCount: map['participantCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'participantCount': participantCount,
    };
  }
}

class CategoryStatsEntity {
  final String name;
  final int eventCount;
  final double percentage;

  const CategoryStatsEntity({
    required this.name,
    required this.eventCount,
    required this.percentage,
  });

  factory CategoryStatsEntity.fromMap(Map<String, dynamic> map) {
    return CategoryStatsEntity(
      name: map['name'] ?? '',
      eventCount: map['eventCount'] ?? 0,
      percentage: (map['percentage'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'eventCount': eventCount,
      'percentage': percentage,
    };
  }
}