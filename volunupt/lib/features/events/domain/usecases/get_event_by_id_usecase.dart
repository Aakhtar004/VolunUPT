import '../entities/event_entity.dart';
import '../repositories/events_repository.dart';

class GetEventByIdUsecase {
  final EventsRepository _repository;

  GetEventByIdUsecase(this._repository);

  Future<EventEntity?> call(String eventId) async {
    return await _repository.getEventById(eventId);
  }
}