import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_admin_stats_repository.dart';
import '../../domain/entities/admin_stats_entity.dart';
import '../../domain/repositories/admin_stats_repository.dart';

final adminStatsRepositoryProvider = Provider<AdminStatsRepository>((ref) {
  return FirebaseAdminStatsRepository();
});

final adminStatsProvider =
    FutureProvider.family<AdminStatsEntity, DateTimeRange?>((
      ref,
      dateRange,
    ) async {
      final repository = ref.read(adminStatsRepositoryProvider);

      return await repository.getAdminStats(
        startDate: dateRange?.start,
        endDate: dateRange?.end,
      );
    });
