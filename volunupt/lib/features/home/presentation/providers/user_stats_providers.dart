import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_user_stats_repository.dart';
import '../../domain/entities/user_stats_entity.dart';
import '../../domain/repositories/user_stats_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

final userStatsRepositoryProvider = Provider<UserStatsRepository>((ref) {
  return FirebaseUserStatsRepository();
});

final userStatsProvider = StreamProvider.autoDispose<UserStatsEntity>((ref) {
  final repository = ref.watch(userStatsRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);

  return authState.when(
    data: (user) {
      if (user == null) {
        return Stream.value(
          const UserStatsEntity(
            completedEvents: 0,
            totalHours: 0,
            certificates: 0,
            activeInscriptions: 0,
            attendedEvents: 0,
          ),
        );
      }
      return repository.getUserStatsStream(user.id);
    },
    loading: () => Stream.value(
      const UserStatsEntity(
        completedEvents: 0,
        totalHours: 0,
        certificates: 0,
        activeInscriptions: 0,
        attendedEvents: 0,
      ),
    ),
    error: (_, __) => Stream.value(
      const UserStatsEntity(
        completedEvents: 0,
        totalHours: 0,
        certificates: 0,
        activeInscriptions: 0,
        attendedEvents: 0,
      ),
    ),
  );
});
