import '../entities/event_qr_entity.dart';
import '../repositories/event_qr_repository.dart';

class ValidateQrCodeUsecase {
  final EventQrRepository _repository;

  ValidateQrCodeUsecase(this._repository);

  Future<EventQrEntity?> call(String qrCode, String scannedBy) async {
    final qrEntity = await _repository.validateQrCode(qrCode);
    
    if (qrEntity == null || !qrEntity.isValid) {
      return null;
    }
    
    await _repository.markQrAsUsed(qrCode, scannedBy);
    
    return qrEntity.copyWith(
      isUsed: true,
      usedAt: DateTime.now(),
      scannedBy: scannedBy,
    );
  }
}