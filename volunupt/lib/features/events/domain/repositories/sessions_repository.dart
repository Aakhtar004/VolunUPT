import '../entities/session_entity.dart';

abstract class SessionsRepository {
  Future<List<SessionEntity>> getEventSessions(String eventId);
  Future<SessionEntity?> getSession(String eventId, String sessionId);
  Future<void> createSession(String eventId, SessionEntity session);
  Future<void> updateSession(String eventId, SessionEntity session);
  Future<void> deleteSession(String eventId, String sessionId);
}