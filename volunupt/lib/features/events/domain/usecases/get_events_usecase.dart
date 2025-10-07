import '../entities/event_entity.dart';
import '../repositories/events_repository.dart';

class GetEventsUsecase {
  final EventsRepository _repository;

  GetEventsUsecase(this._repository);

  Future<List<EventEntity>> call() async {
    return await _repository.getAllEvents();
  }
}