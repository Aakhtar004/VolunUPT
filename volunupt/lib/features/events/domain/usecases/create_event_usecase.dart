import '../entities/event_entity.dart';
import '../repositories/events_repository.dart';

class CreateEventUsecase {
  final EventsRepository _repository;

  CreateEventUsecase(this._repository);

  Future<String> call(EventEntity event) async {
    if (event.title.trim().isEmpty) {
      throw Exception('El título del evento es requerido');
    }
    
    if (event.description.trim().isEmpty) {
      throw Exception('La descripción del evento es requerida');
    }
    
    if (event.capacity <= 0) {
      throw Exception('La capacidad debe ser mayor a 0');
    }
    
    if (event.startDate.isBefore(DateTime.now())) {
      throw Exception('La fecha de inicio debe ser futura');
    }
    
    return await _repository.createEvent(event);
  }
}