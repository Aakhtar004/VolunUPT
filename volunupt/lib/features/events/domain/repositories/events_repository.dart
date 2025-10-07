import '../entities/event_entity.dart';
import '../entities/inscription_entity.dart';

abstract class EventsRepository {
  Future<List<EventEntity>> getAllEvents();
  Future<EventEntity?> getEventById(String eventId);
  Future<InscriptionEntity> inscribeToEvent(String eventId, String userId, String userName);
  Future<List<InscriptionEntity>> getUserInscriptions(String userId);
  Future<bool> isUserInscribed(String eventId, String userId);
  Future<void> markAttendance(String eventId, String qrCode);
}