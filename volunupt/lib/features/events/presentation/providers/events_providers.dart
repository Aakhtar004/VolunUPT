import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/firebase_events_repository.dart';
import '../../domain/entities/event_entity.dart';
import '../../domain/entities/inscription_entity.dart';
import '../../domain/repositories/events_repository.dart';
import '../../domain/usecases/get_events_usecase.dart';
import '../../domain/usecases/get_event_by_id_usecase.dart';
import '../../domain/usecases/inscribe_to_event_usecase.dart';
import '../../domain/usecases/get_user_inscriptions_usecase.dart';

final eventsRepositoryProvider = Provider<EventsRepository>((ref) {
  return FirebaseEventsRepository(FirebaseFirestore.instance);
});

final getEventsUsecaseProvider = Provider<GetEventsUsecase>((ref) {
  return GetEventsUsecase(ref.read(eventsRepositoryProvider));
});

final getEventByIdUsecaseProvider = Provider<GetEventByIdUsecase>((ref) {
  return GetEventByIdUsecase(ref.read(eventsRepositoryProvider));
});

final inscribeToEventUsecaseProvider = Provider<InscribeToEventUsecase>((ref) {
  return InscribeToEventUsecase(ref.read(eventsRepositoryProvider));
});

final getUserInscriptionsUsecaseProvider = Provider<GetUserInscriptionsUsecase>((ref) {
  return GetUserInscriptionsUsecase(ref.read(eventsRepositoryProvider));
});

final eventsProvider = FutureProvider<List<EventEntity>>((ref) async {
  final usecase = ref.read(getEventsUsecaseProvider);
  return await usecase();
});

final eventByIdProvider = FutureProvider.family<EventEntity?, String>((ref, eventId) async {
  final usecase = ref.read(getEventByIdUsecaseProvider);
  return await usecase(eventId);
});

final userInscriptionsProvider = FutureProvider.family<List<InscriptionEntity>, String>((ref, userId) async {
  final usecase = ref.read(getUserInscriptionsUsecaseProvider);
  return await usecase(userId);
});

final userEventInscriptionProvider = FutureProvider.family<InscriptionEntity?, ({String userId, String eventId})>((ref, params) async {
  final inscriptions = await ref.watch(userInscriptionsProvider(params.userId).future);
  try {
    return inscriptions.firstWhere((inscription) => inscription.eventId == params.eventId);
  } catch (e) {
    return null;
  }
});

final eventsNotifierProvider = StateNotifierProvider<EventsNotifier, AsyncValue<List<EventEntity>>>((ref) {
  return EventsNotifier(ref.read(getEventsUsecaseProvider));
});

final inscriptionsNotifierProvider = StateNotifierProvider.family<InscriptionsNotifier, AsyncValue<List<InscriptionEntity>>, String>((ref, userId) {
  return InscriptionsNotifier(ref.read(getUserInscriptionsUsecaseProvider), userId);
});

class EventsNotifier extends StateNotifier<AsyncValue<List<EventEntity>>> {
  final GetEventsUsecase _getEventsUsecase;

  EventsNotifier(this._getEventsUsecase) : super(const AsyncValue.loading()) {
    loadEvents();
  }

  Future<void> loadEvents() async {
    state = const AsyncValue.loading();
    try {
      final events = await _getEventsUsecase();
      state = AsyncValue.data(events);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshEvents() async {
    await loadEvents();
  }
}

class InscriptionsNotifier extends StateNotifier<AsyncValue<List<InscriptionEntity>>> {
  final GetUserInscriptionsUsecase _getUserInscriptionsUsecase;
  final String userId;

  InscriptionsNotifier(this._getUserInscriptionsUsecase, this.userId) : super(const AsyncValue.loading()) {
    loadInscriptions();
  }

  Future<void> loadInscriptions() async {
    state = const AsyncValue.loading();
    try {
      final inscriptions = await _getUserInscriptionsUsecase(userId);
      state = AsyncValue.data(inscriptions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshInscriptions() async {
    await loadInscriptions();
  }
}