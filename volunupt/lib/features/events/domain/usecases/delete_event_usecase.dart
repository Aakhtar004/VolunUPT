import '../repositories/events_repository.dart';

class DeleteEventUsecase {
  final EventsRepository _repository;

  DeleteEventUsecase(this._repository);

  Future<void> call(String eventId) async {
    if (eventId.trim().isEmpty) {
      throw Exception('ID del evento es requerido');
    }
    
    return await _repository.deleteEvent(eventId);
  }
}