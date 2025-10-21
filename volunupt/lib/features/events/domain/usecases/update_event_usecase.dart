import '../entities/event_entity.dart';
import '../repositories/events_repository.dart';

class UpdateEventUsecase {
  final EventsRepository _repository;

  UpdateEventUsecase(this._repository);

  Future<void> call(EventEntity event) async {
    if (event.title.trim().isEmpty) {
      throw Exception('El título del evento es requerido');
    }
    
    if (event.description.trim().isEmpty) {
      throw Exception('La descripción del evento es requerida');
    }
    
    if (event.capacity <= 0) {
      throw Exception('La capacidad debe ser mayor a 0');
    }
    
    return await _repository.updateEvent(event);
  }
}