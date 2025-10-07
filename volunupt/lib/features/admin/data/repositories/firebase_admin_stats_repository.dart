import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/admin_stats_entity.dart';
import '../../domain/repositories/admin_stats_repository.dart';

class FirebaseAdminStatsRepository implements AdminStatsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<AdminStatsEntity> getAdminStats({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final now = DateTime.now();
      final effectiveStartDate = startDate ?? now.subtract(const Duration(days: 30));
      final effectiveEndDate = endDate ?? now;

      final totalEvents = await _getTotalEvents();
      final totalUsers = await _getTotalUsers();
      final totalInscriptions = await _getTotalInscriptions();
      final activeEvents = await _getActiveEvents();
      final completedEvents = await _getCompletedEvents();
      final newUsersThisMonth = await _getNewUsersInPeriod(effectiveStartDate, effectiveEndDate);
      final activeUsers = await _getActiveUsers();
      final retentionRate = await _getRetentionRate();
      final popularEvents = await _getPopularEvents();
      final categoryStats = await _getCategoryStats();

      return AdminStatsEntity(
        totalEvents: totalEvents,
        totalUsers: totalUsers,
        totalInscriptions: totalInscriptions,
        activeEvents: activeEvents,
        completedEvents: completedEvents,
        newUsersThisMonth: newUsersThisMonth,
        activeUsers: activeUsers,
        retentionRate: retentionRate,
        popularEvents: popularEvents,
        categoryStats: categoryStats,
      );
    } catch (e) {
      return const AdminStatsEntity(
        totalEvents: 0,
        totalUsers: 0,
        totalInscriptions: 0,
        activeEvents: 0,
        completedEvents: 0,
        newUsersThisMonth: 0,
        activeUsers: 0,
        retentionRate: 0.0,
        popularEvents: [],
        categoryStats: [],
      );
    }
  }

  @override
  Stream<AdminStatsEntity> getAdminStatsStream({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return Stream.periodic(const Duration(minutes: 5), (_) async {
      return await getAdminStats(startDate: startDate, endDate: endDate);
    }).asyncMap((future) => future);
  }

  Future<int> _getTotalEvents() async {
    final snapshot = await _firestore.collection('events').get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  Future<int> _getTotalInscriptions() async {
    final snapshot = await _firestore.collection('inscriptions').get();
    return snapshot.docs.length;
  }

  Future<int> _getActiveEvents() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('events')
        .where('endDate', isGreaterThan: Timestamp.fromDate(now))
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getCompletedEvents() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection('events')
        .where('endDate', isLessThan: Timestamp.fromDate(now))
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getNewUsersInPeriod(DateTime startDate, DateTime endDate) async {
    final snapshot = await _firestore
        .collection('users')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();
    return snapshot.docs.length;
  }

  Future<int> _getActiveUsers() async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final snapshot = await _firestore
        .collection('users')
        .where('lastLoginAt', isGreaterThan: Timestamp.fromDate(thirtyDaysAgo))
        .get();
    return snapshot.docs.length;
  }

  Future<double> _getRetentionRate() async {
    final totalUsers = await _getTotalUsers();
    final activeUsers = await _getActiveUsers();
    
    if (totalUsers == 0) return 0.0;
    return (activeUsers / totalUsers) * 100;
  }

  Future<List<PopularEventEntity>> _getPopularEvents() async {
    final eventsSnapshot = await _firestore.collection('events').get();
    final List<PopularEventEntity> popularEvents = [];

    for (final eventDoc in eventsSnapshot.docs) {
      final eventData = eventDoc.data();
      final inscriptionsSnapshot = await _firestore
          .collection('inscriptions')
          .where('eventId', isEqualTo: eventDoc.id)
          .get();

      popularEvents.add(PopularEventEntity(
        id: eventDoc.id,
        name: eventData['title'] ?? 'Sin título',
        participantCount: inscriptionsSnapshot.docs.length,
      ));
    }

    popularEvents.sort((a, b) => b.participantCount.compareTo(a.participantCount));
    return popularEvents.take(5).toList();
  }

  Future<List<CategoryStatsEntity>> _getCategoryStats() async {
    final eventsSnapshot = await _firestore.collection('events').get();
    final Map<String, int> categoryCount = {};

    for (final eventDoc in eventsSnapshot.docs) {
      final eventData = eventDoc.data();
      final category = eventData['category'] ?? 'Sin categoría';
      categoryCount[category] = (categoryCount[category] ?? 0) + 1;
    }

    final totalEvents = eventsSnapshot.docs.length;
    final List<CategoryStatsEntity> categoryStats = [];

    categoryCount.forEach((category, count) {
      final percentage = totalEvents > 0 ? (count / totalEvents) * 100 : 0.0;
      categoryStats.add(CategoryStatsEntity(
        name: category,
        eventCount: count,
        percentage: percentage,
      ));
    });

    categoryStats.sort((a, b) => b.eventCount.compareTo(a.eventCount));
    return categoryStats;
  }
}