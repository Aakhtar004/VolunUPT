import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/event_qr_entity.dart';
import '../../domain/repositories/event_qr_repository.dart';
import '../../domain/usecases/generate_qr_code_usecase.dart';
import '../../domain/usecases/validate_qr_code_usecase.dart';
import '../../data/repositories/firebase_event_qr_repository.dart';

final eventQrRepositoryProvider = Provider<EventQrRepository>((ref) {
  return FirebaseEventQrRepository(FirebaseFirestore.instance);
});

final generateQrCodeUsecaseProvider = Provider<GenerateQrCodeUsecase>((ref) {
  return GenerateQrCodeUsecase(ref.read(eventQrRepositoryProvider));
});

final validateQrCodeUsecaseProvider = Provider<ValidateQrCodeUsecase>((ref) {
  return ValidateQrCodeUsecase(ref.read(eventQrRepositoryProvider));
});

final userQrCodesProvider = FutureProvider.family<List<EventQrEntity>, String>((ref, userId) async {
  final repository = ref.read(eventQrRepositoryProvider);
  return await repository.getUserQrCodes(userId);
});

final eventQrCodesProvider = FutureProvider.family<List<EventQrEntity>, String>((ref, eventId) async {
  final repository = ref.read(eventQrRepositoryProvider);
  return await repository.getEventQrCodes(eventId);
});

final eventUserQrProvider = FutureProvider.family<EventQrEntity?, ({String eventId, String userId})>((ref, params) async {
  final repository = ref.read(eventQrRepositoryProvider);
  return await repository.getQrCode(params.eventId, params.userId);
});

class QrCodeNotifier extends StateNotifier<AsyncValue<EventQrEntity?>> {
  final EventQrRepository _repository;
  final GenerateQrCodeUsecase _generateUsecase;
  final ValidateQrCodeUsecase _validateUsecase;

  QrCodeNotifier(this._repository, this._generateUsecase, this._validateUsecase) 
      : super(const AsyncValue.data(null));

  Future<EventQrEntity?> generateQrCode(String eventId, String userId) async {
    state = const AsyncValue.loading();
    try {
      final qrEntity = await _generateUsecase(eventId, userId);
      state = AsyncValue.data(qrEntity);
      return qrEntity;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return null;
    }
  }

  Future<EventQrEntity?> validateQrCode(String qrCode, String scannedBy) async {
    try {
      final qrEntity = await _validateUsecase(qrCode, scannedBy);
      return qrEntity;
    } catch (e) {
      throw Exception('Error al validar código QR: $e');
    }
  }

  Future<List<EventQrEntity>> getUserQrCodes(String userId) async {
    try {
      return await _repository.getUserQrCodes(userId);
    } catch (e) {
      throw Exception('Error al obtener códigos QR del usuario: $e');
    }
  }

  Future<List<EventQrEntity>> getEventQrCodes(String eventId) async {
    try {
      return await _repository.getEventQrCodes(eventId);
    } catch (e) {
      throw Exception('Error al obtener códigos QR del evento: $e');
    }
  }
}

final qrCodeNotifierProvider = StateNotifierProvider<QrCodeNotifier, AsyncValue<EventQrEntity?>>((ref) {
  return QrCodeNotifier(
    ref.read(eventQrRepositoryProvider),
    ref.read(generateQrCodeUsecaseProvider),
    ref.read(validateQrCodeUsecaseProvider),
  );
});