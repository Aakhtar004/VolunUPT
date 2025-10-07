import '../entities/event_qr_entity.dart';
import '../repositories/event_qr_repository.dart';

class GenerateQrCodeUsecase {
  final EventQrRepository _repository;

  GenerateQrCodeUsecase(this._repository);

  Future<EventQrEntity> call(String eventId, String userId) async {
    final existingQr = await _repository.getQrCode(eventId, userId);
    
    if (existingQr != null && existingQr.isValid) {
      return existingQr;
    }
    
    return await _repository.generateQrCode(eventId, userId);
  }
}