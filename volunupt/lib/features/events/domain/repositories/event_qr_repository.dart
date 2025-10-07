import '../entities/event_qr_entity.dart';

abstract class EventQrRepository {
  Future<EventQrEntity> generateQrCode(String eventId, String userId);
  Future<EventQrEntity?> getQrCode(String eventId, String userId);
  Future<EventQrEntity?> validateQrCode(String qrCode);
  Future<void> markQrAsUsed(String qrCode, String scannedBy);
  Future<List<EventQrEntity>> getEventQrCodes(String eventId);
  Future<List<EventQrEntity>> getUserQrCodes(String userId);
}