class AdminStats {
  final int totalUsers;
  final int newUsersThisMonth;
  final int activeEvents;
  final int totalEvents;
  final int totalInscriptions;
  final int newInscriptionsToday;
  final int totalVolunteerHours;
  final int hoursThisMonth;
  final int activeCoordinators;
  final int completedEvents;
  final double averageAttendanceRate;
  final Map<String, int> usersByRole;
  final Map<String, int> eventsByCategory;
  final List<MonthlyStats> monthlyGrowth;

  const AdminStats({
    required this.totalUsers,
    required this.newUsersThisMonth,
    required this.activeEvents,
    required this.totalEvents,
    required this.totalInscriptions,
    required this.newInscriptionsToday,
    required this.totalVolunteerHours,
    required this.hoursThisMonth,
    required this.activeCoordinators,
    required this.completedEvents,
    required this.averageAttendanceRate,
    required this.usersByRole,
    required this.eventsByCategory,
    required this.monthlyGrowth,
  });

  factory AdminStats.fromMap(Map<String, dynamic> map) {
    return AdminStats(
      totalUsers: map['totalUsers'] ?? 0,
      newUsersThisMonth: map['newUsersThisMonth'] ?? 0,
      activeEvents: map['activeEvents'] ?? 0,
      totalEvents: map['totalEvents'] ?? 0,
      totalInscriptions: map['totalInscriptions'] ?? 0,
      newInscriptionsToday: map['newInscriptionsToday'] ?? 0,
      totalVolunteerHours: map['totalVolunteerHours'] ?? 0,
      hoursThisMonth: map['hoursThisMonth'] ?? 0,
      activeCoordinators: map['activeCoordinators'] ?? 0,
      completedEvents: map['completedEvents'] ?? 0,
      averageAttendanceRate: (map['averageAttendanceRate'] ?? 0.0).toDouble(),
      usersByRole: Map<String, int>.from(map['usersByRole'] ?? {}),
      eventsByCategory: Map<String, int>.from(map['eventsByCategory'] ?? {}),
      monthlyGrowth: (map['monthlyGrowth'] as List<dynamic>?)
          ?.map((item) => MonthlyStats.fromMap(item))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalUsers': totalUsers,
      'newUsersThisMonth': newUsersThisMonth,
      'activeEvents': activeEvents,
      'totalEvents': totalEvents,
      'totalInscriptions': totalInscriptions,
      'newInscriptionsToday': newInscriptionsToday,
      'totalVolunteerHours': totalVolunteerHours,
      'hoursThisMonth': hoursThisMonth,
      'activeCoordinators': activeCoordinators,
      'completedEvents': completedEvents,
      'averageAttendanceRate': averageAttendanceRate,
      'usersByRole': usersByRole,
      'eventsByCategory': eventsByCategory,
      'monthlyGrowth': monthlyGrowth.map((item) => item.toMap()).toList(),
    };
  }

  AdminStats copyWith({
    int? totalUsers,
    int? newUsersThisMonth,
    int? activeEvents,
    int? totalEvents,
    int? totalInscriptions,
    int? newInscriptionsToday,
    int? totalVolunteerHours,
    int? hoursThisMonth,
    int? activeCoordinators,
    int? completedEvents,
    double? averageAttendanceRate,
    Map<String, int>? usersByRole,
    Map<String, int>? eventsByCategory,
    List<MonthlyStats>? monthlyGrowth,
  }) {
    return AdminStats(
      totalUsers: totalUsers ?? this.totalUsers,
      newUsersThisMonth: newUsersThisMonth ?? this.newUsersThisMonth,
      activeEvents: activeEvents ?? this.activeEvents,
      totalEvents: totalEvents ?? this.totalEvents,
      totalInscriptions: totalInscriptions ?? this.totalInscriptions,
      newInscriptionsToday: newInscriptionsToday ?? this.newInscriptionsToday,
      totalVolunteerHours: totalVolunteerHours ?? this.totalVolunteerHours,
      hoursThisMonth: hoursThisMonth ?? this.hoursThisMonth,
      activeCoordinators: activeCoordinators ?? this.activeCoordinators,
      completedEvents: completedEvents ?? this.completedEvents,
      averageAttendanceRate: averageAttendanceRate ?? this.averageAttendanceRate,
      usersByRole: usersByRole ?? this.usersByRole,
      eventsByCategory: eventsByCategory ?? this.eventsByCategory,
      monthlyGrowth: monthlyGrowth ?? this.monthlyGrowth,
    );
  }
}

class MonthlyStats {
  final String month;
  final int year;
  final int newUsers;
  final int newEvents;
  final int totalInscriptions;
  final int totalHours;

  const MonthlyStats({
    required this.month,
    required this.year,
    required this.newUsers,
    required this.newEvents,
    required this.totalInscriptions,
    required this.totalHours,
  });

  factory MonthlyStats.fromMap(Map<String, dynamic> map) {
    return MonthlyStats(
      month: map['month'] ?? '',
      year: map['year'] ?? 0,
      newUsers: map['newUsers'] ?? 0,
      newEvents: map['newEvents'] ?? 0,
      totalInscriptions: map['totalInscriptions'] ?? 0,
      totalHours: map['totalHours'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'year': year,
      'newUsers': newUsers,
      'newEvents': newEvents,
      'totalInscriptions': totalInscriptions,
      'totalHours': totalHours,
    };
  }
}