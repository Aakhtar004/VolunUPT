import '../entities/inscription_entity.dart';
import '../repositories/events_repository.dart';

class InscribeToEventUsecase {
  final EventsRepository _repository;

  InscribeToEventUsecase(this._repository);

  Future<InscriptionEntity> call(String eventId, String userId, String userName) async {
    return await _repository.inscribeToEvent(eventId, userId, userName);
  }
}